# 開発フロー

このドキュメントでは、ローカル開発からマイグレーション作成、PR作成までの具体的な手順を説明します。

## 開発サイクル全体図

```mermaid
graph TB
    Start[ローカル環境起動] --> Console[Hasura Consoleで開発]
    Console --> Change{DB変更あり?}

    Change -->|Yes| CreateMig[migrate create]
    Change -->|No| Export[metadata export]

    CreateMig --> Export
    Export --> Commit[git commit]
    Commit --> Push[git push]
    Push --> CI[CI: Dev自動デプロイ]
    CI --> Test[実機テスト]

    Test --> OK{OK?}
    OK -->|NG| Console
    OK -->|OK| PR[PR作成・レビュー]

    PR --> Merge[マージ]
    Merge --> ProdDeploy[Prod手動デプロイ]

    style Start fill:#90CAF9
    style CI fill:#FFB74D
    style ProdDeploy fill:#EF5350
```

---

## ローカル開発環境のセットアップ

### 1. 初回セットアップ

```bash
# リポジトリクローン
git clone <repository-url>
cd hasura_flutter

# バックエンド環境変数設定
cd backend
cp .env.example .env
# .env を編集（POSTGRES_PASSWORD等）

# Hasura CLI設定
cd hasura
cp config.yaml.example config.yaml
# config.yaml を編集

# Docker起動
cd ..
docker compose up -d

# マイグレーション適用（既存のマイグレーションがある場合）
cd hasura
hasura migrate apply
hasura metadata apply
hasura seed apply  # テストデータ投入
```

### 2. 日常的な起動

```bash
cd backend
docker compose up -d

cd hasura
hasura console
```

ブラウザで自動的に開く:
- Hasura Console: `http://localhost:9695`
- GraphQL Endpoint: `http://localhost:8080/v1/graphql`

---

## DB変更の作成フロー

### ケース1: テーブル作成

```mermaid
sequenceDiagram
    participant Dev as 開発者
    participant Console as Hasura Console
    participant DB as Local DB
    participant CLI as Hasura CLI
    participant Git

    Dev->>Console: GUI でテーブル作成
    Console->>DB: CREATE TABLE 実行
    DB-->>Console: 成功

    Dev->>Console: パーミッション設定
    Console->>DB: メタデータ更新

    Dev->>CLI: hasura migrate create --from-server
    CLI->>DB: DB差分を検出
    CLI-->>Dev: migrations/<timestamp>_<name>/ 生成

    Dev->>CLI: hasura metadata export
    CLI->>DB: メタデータ取得
    CLI-->>Dev: metadata/ ファイル更新

    Dev->>Git: git add migrations/ metadata/
    Dev->>Git: git commit & push
```

**実際の手順**:

1. **Hasura Console でテーブル作成**:
   - `http://localhost:9695` → Data タブ
   - "Create Table" をクリック
   - テーブル名: `posts`
   - カラム追加:
     - `id` UUID, Primary Key, Default: `uuid_generate_v7()`
     - `tenant_id` UUID, Not Null
     - `title` Text, Not Null
     - `content` Text, Not Null
     - `created_at` Timestamp with timezone, Default: `now()`
   - "Add Table" クリック

2. **外部キー追加**:
   - "Modify" タブ → "Foreign Keys"
   - `tenant_id` → `organizations(id)`, ON DELETE CASCADE

3. **インデックス追加**:
   - SQL タブで実行:
   ```sql
   CREATE INDEX idx_posts_tenant_id ON posts(tenant_id);
   CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
   ```

4. **パーミッション設定**:
   - "Permissions" タブ
   - `user` ロールで `select` / `insert` / `update` / `delete` を設定

5. **マイグレーション生成**:
   ```bash
   cd backend/hasura
   hasura migrate create "create_posts_table" --from-server
   ```

   生成されるファイル:
   ```
   migrations/
   └── <timestamp>_create_posts_table/
       ├── up.sql    # テーブル作成SQL
       └── down.sql  # テーブル削除SQL
   ```

6. **メタデータエクスポート**:
   ```bash
   hasura metadata export
   ```

   更新されるファイル:
   ```
   metadata/
   ├── databases/
   │   └── default/
   │       └── tables/
   │           ├── public_posts.yaml  # 新規追加
   │           └── ...
   └── ...
   ```

7. **Git コミット**:
   ```bash
   git add migrations/ metadata/
   git commit -m "Add posts table with tenant support"
   git push origin main
   ```

---

### ケース2: カラム追加

1. **Hasura Console で追加**:
   - Data → `posts` テーブル → Modify
   - "Add a new column" で `slug` Text を追加

2. **マイグレーション生成**:
   ```bash
   hasura migrate create "add_slug_to_posts" --from-server
   ```

3. **メタデータエクスポート**:
   ```bash
   hasura metadata export
   ```

4. **Git コミット**:
   ```bash
   git add migrations/ metadata/
   git commit -m "Add slug column to posts table"
   git push
   ```

---

### ケース3: パーミッション変更のみ

パーミッション変更はメタデータのみの変更なので、マイグレーション不要:

1. **Hasura Console でパーミッション変更**:
   - Permissions タブで調整

2. **メタデータエクスポート**:
   ```bash
   hasura metadata export
   ```

3. **Git コミット**:
   ```bash
   git add metadata/
   git commit -m "Update user role permissions for posts"
   git push
   ```

---

## マイグレーションのベストプラクティス

### 1. 1つのマイグレーション = 1つの変更

❌ **悪い例**:
```bash
# 複数の変更を1つのマイグレーションに
hasura migrate create "add_multiple_tables"
```

✅ **良い例**:
```bash
hasura migrate create "create_posts_table"
hasura migrate create "create_comments_table"
hasura migrate create "add_index_posts_tenant"
```

### 2. `up.sql` と `down.sql` を必ず確認

生成された SQL を確認し、必要に応じて手動調整:

**up.sql**:
```sql
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
  tenant_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_posts_tenant_id ON posts(tenant_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- トリガー追加
CREATE TRIGGER update_posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

**down.sql**:
```sql
DROP TRIGGER IF EXISTS update_posts_updated_at ON posts;
DROP TABLE IF EXISTS posts CASCADE;
```

### 3. マイグレーション実行前に dry-run

```bash
# ローカルで確認
hasura migrate apply --dry-run

# 問題なければ適用
hasura migrate apply
```

### 4. メタデータとマイグレーションを分けて管理

- **マイグレーション**: DB構造の変更（テーブル、カラム、インデックス）
- **メタデータ**: Hasuraの設定（パーミッション、リレーション、Computed Fields）

---

## Flutter アプリ開発との連携

### GraphQL スキーマの自動生成

1. **`.graphql` ファイルを作成**:

`app/graphql/posts.graphql`:
```graphql
query GetPosts($tenantId: uuid!) {
  posts(
    where: {
      tenant_id: { _eq: $tenantId }
      deleted_at: { _is_null: true }
    }
    order_by: { created_at: desc }
  ) {
    id
    title
    content
    created_at
    user {
      id
      name
    }
  }
}

mutation CreatePost($tenantId: uuid!, $title: String!, $content: String!) {
  insert_posts_one(
    object: {
      tenant_id: $tenantId
      title: $title
      content: $content
      status: "draft"
    }
  ) {
    id
    title
  }
}
```

2. **コード生成**:

```bash
cd app
flutter pub run build_runner build --delete-conflicting-outputs
```

生成されるファイル:
```
app/lib/generated/
├── posts.graphql.dart
└── ...
```

3. **Flutter で使用**:

```dart
import 'package:app/generated/posts.graphql.dart';

// クエリ実行
final result = await client.query$GetPosts(
  Options$Query$GetPosts(
    variables: Variables$Query$GetPosts(
      tenantId: currentTenantId,
    ),
  ),
);

if (result.hasException) {
  // エラーハンドリング
}

final posts = result.parsedData?.posts ?? [];
```

---

## ローカル環境のリセット

### 完全リセット（DBを空に）

```bash
cd backend

# コンテナとボリュームを削除
docker compose down -v

# 再起動
docker compose up -d

# マイグレーション再適用
cd hasura
hasura migrate apply
hasura metadata apply
hasura seed apply
```

### マイグレーションのみリセット

```bash
# 全マイグレーションをロールバック
hasura migrate apply --down all

# 再適用
hasura migrate apply
```

---

## トラブルシューティング

### マイグレーション生成時のエラー

**問題**: `hasura migrate create` が失敗する

**原因**: Hasura Console を CLI 経由で起動していない

**解決**:
```bash
# ❌ 直接 http://localhost:8080/console にアクセス
# ✅ CLI 経由で起動
hasura console
```

### メタデータの競合

**問題**: `git pull` 後にメタデータが競合

**解決**:
```bash
# リモートのメタデータを優先
git checkout --theirs metadata/
hasura metadata apply

# ローカルのメタデータを優先
git checkout --ours metadata/
hasura metadata export
```

### Docker が起動しない

**問題**: `docker compose up` が失敗

**確認事項**:
1. Docker Desktop が起動しているか
2. ポート競合（5432, 8080, 5050）
   ```bash
   lsof -i :5432
   lsof -i :8080
   ```
3. `.env` ファイルが存在するか

---

## チーム開発時の注意点

### 1. マイグレーションの順序

マイグレーションはタイムスタンプ順に実行されます。

複数人が同時にマイグレーションを作成すると、タイムスタンプが前後する可能性があります。

**ベストプラクティス**:
- `git pull` してから新しいマイグレーション作成
- PR は小さく、頻繁にマージ

### 2. メタデータの衝突

パーミッション設定等のメタデータは YAML ファイルで管理されます。

**衝突を避ける方法**:
- 異なるテーブルを担当する
- PR をレビュー・マージしてから次の作業開始

### 3. Dev 環境の共有

Dev 環境はチーム全体で共有されます。

**注意事項**:
- テストデータの削除は慎重に
- 破壊的なマイグレーションは事前に通知
- ロールバックが必要な場合は Slack 等で共有

---

## CI/CD との連携

### GitHub Actions ワークフロー（簡易版）

`.github/workflows/deploy-dev.yml`:
```yaml
name: Deploy to Dev

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Hasura CLI
        run: |
          curl -L https://github.com/hasura/graphql-engine/raw/stable/cli/get.sh | bash

      - name: Apply Migrations
        env:
          HASURA_GRAPHQL_ENDPOINT: ${{ secrets.DEV_HASURA_ENDPOINT }}
          HASURA_GRAPHQL_ADMIN_SECRET: ${{ secrets.DEV_HASURA_ADMIN_SECRET }}
        run: |
          cd backend/hasura
          hasura migrate apply --endpoint $HASURA_GRAPHQL_ENDPOINT
          hasura metadata apply --endpoint $HASURA_GRAPHQL_ENDPOINT

      - name: Smoke Test
        run: |
          bash backend/scripts/smoke-test.sh
```

詳細は [デプロイフロー](deployment.md) を参照。

---

## まとめ

**ローカル開発フロー**:
1. Hasura Console で開発（DB変更・パーミッション設定）
2. `hasura migrate create --from-server <name>` でマイグレーション生成
3. `hasura metadata export` でメタデータ保存
4. Git コミット・プッシュ
5. CI で Dev 環境に自動デプロイ
6. 実機テスト → OK なら PR 作成
7. レビュー・マージ → Prod デプロイ

**ポイント**:
- Hasura Console は必ず CLI 経由で起動
- マイグレーションは小さく分割
- `up.sql` / `down.sql` を必ず確認
- メタデータとマイグレーションをセットでコミット

次は [デプロイフロー](deployment.md) で CI/CD の詳細を確認してください。
