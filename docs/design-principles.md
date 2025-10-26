# 設計原則・決定事項

このドキュメントでは、プロジェクト全体を貫く設計方針と、技術選定の決定理由を記録します。

## 設計哲学

- **小さく動かして大きく育てる**: まずは Hasura + Firebase で最小構成、必要に応じて拡張
- **スキーマファースト**: DB構造を Hasura migration に一元化
- **型安全**: クライアントもサーバも型で守る
- **権限中心設計**: Hasura パーミッションと Firebase カスタムクレームを軸に
- **環境を壊せる勇気**: local で試して dev に昇格、prod は最後に適用

---

## 設計原則一覧

| 項目 | 採用方針 | 理由・備考 |
|------|---------|-----------|
| **ID** | UUID v7 | 時系列ソート可能、分散生成可能 |
| **時刻** | UTC固定（timestamptz） | タイムゾーン変換はクライアント側 |
| **削除** | ソフトデリート（deleted_at） | 監査・復元の容易性 |
| **Enum** | lookupテーブル運用 | PostgreSQL enum は避ける（変更が困難） |
| **命名規則** | DB: snake_case / GraphQL: camelCase | Hasura が自動変換 |
| **認証** | Firebase Auth | JWT発行・管理 |
| **認可** | Hasura パーミッション（JWT RS256） | 行レベルセキュリティ |
| **マイグレーション** | Hasura CLI (migrations/metadata) | バージョン管理下で一元管理 |
| **実機アクセス** | dev Cloud Run | ローカルは実験、実機はdev環境 |
| **型安全** | graphql_codegen | .graphql → Dart型生成 |
| **デプロイ** | GitHub Actions → Cloud Run | CI/CD自動化 |
| **DB** | Neon（branch分離） | local: Docker / dev,prod: Neon |
| **環境** | local / dev / prod | 明確な役割分担 |

---

## 詳細決定事項

### 1. UUID v7 採用（条件付き）

**決定**:
- プライマリキーは **UUID v7** を採用
- 初期運用：クライアントまたはサーバ側でライブラリ生成
- 将来：PostgreSQL拡張（`pg_uuidv7`）に移行可能

**理由**:
- **UUID v4 の問題**: ランダム生成のため、インデックス効率が悪い
- **UUID v7 の利点**: タイムスタンプベースで時系列ソート可能、B-treeインデックス効率良好
- **分散環境での衝突回避**: クライアント生成でもほぼ衝突しない

**実装方針**:
```sql
-- DB側でのデフォルト値（将来）
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
  ...
);
```

```dart
// Dart側での生成（初期実装）
import 'package:uuid/uuid.dart';

const uuid = Uuid();
final userId = uuid.v7(); // UUID v7 生成
```

**代替案**:
- UUID v7 拡張が使えない場合: **UUID v4 + created_at ソート**で実害なし

---

### 2. Hasura パーミッション vs PostgreSQL RLS

**決定**:
- 基本は **Hasura パーミッションのみ** で運用
- PostgreSQL RLS は **オプション**（将来の多重防御として）

**用語の整理**:
- ~~RLS（Row Level Security）~~：**Hasura パーミッション**と表記統一
- PostgreSQL RLS：DB層の行レベルセキュリティ（別概念）

**Hasura パーミッション例**:
```json
{
  "filter": {
    "user_id": {"_eq": "X-Hasura-User-Id"},
    "tenant_id": {"_eq": "X-Hasura-Tenant-Id"}
  }
}
```

**PostgreSQL RLS を追加するケース**:
- Hasura 経由以外のDB接続を許可する場合（例：Metabase、データ分析ツール）
- バッチ処理がDB直接アクセスする場合
- 多重防御で安全性を高めたい場合

**現時点の方針**:
- Hasura パーミッションで十分（すべてのアクセスがHasura経由）
- 必要になったら PostgreSQL RLS を追加（後方互換性あり）

---

### 3. タイムゾーン管理

**決定**:
- DB には **UTC** で保存（`timestamptz` 型）
- クライアント側でローカルタイムゾーンに変換

**理由**:
- グローバル対応が容易
- サーバ側でタイムゾーン変換ロジックが不要
- サマータイム等の複雑性をクライアントに委譲

**実装例**:
```sql
CREATE TABLE posts (
  id UUID PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

```dart
// Dart での表示時変換
final createdAt = DateTime.parse(post.createdAt).toLocal();
```

---

### 4. 監査カラム（Audit Columns）

**決定**:
- すべてのテーブルに以下のカラムを含める:
  - `created_at`: レコード作成日時
  - `updated_at`: レコード更新日時
  - `created_by`: 作成ユーザーID（UUID）
  - `updated_by`: 更新ユーザーID（UUID）

**理由**:
- 変更履歴の追跡
- デバッグ・監査の容易性
- 将来の分析に備える

**実装例**:
```sql
CREATE TABLE example (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL,
  updated_by UUID NOT NULL
);

-- トリガーで updated_at を自動更新
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_example_updated_at
BEFORE UPDATE ON example
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
```

---

### 5. ソフトデリート

**決定**:
- 物理削除ではなく、`deleted_at` カラムで論理削除

**理由**:
- データの復元が可能
- 誤削除の防止
- 監査証跡の保持

**実装例**:
```sql
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMPTZ;

-- Hasuraパーミッションで削除済みを除外
{
  "filter": {
    "deleted_at": {"_is_null": true}
  }
}
```

**削除処理**:
```dart
// ソフトデリート mutation
mutation DeleteUser($id: uuid!) {
  update_users_by_pk(
    pk_columns: {id: $id},
    _set: {deleted_at: "now()"}
  ) {
    id
  }
}
```

---

### 6. Enum 管理方針

**決定**:
- PostgreSQL の `ENUM` 型は使わない
- **lookup テーブル**で管理

**理由**:
- PostgreSQL ENUM は値の追加・削除が困難（ALTER TYPE が制限的）
- マイグレーションが複雑化
- lookup テーブルなら柔軟に変更可能

**実装例**:
```sql
-- status_types テーブル
CREATE TABLE status_types (
  value TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  sort_order INT NOT NULL
);

INSERT INTO status_types VALUES
  ('draft', 'Draft', 1),
  ('published', 'Published', 2),
  ('archived', 'Archived', 3);

-- 外部キーで参照
CREATE TABLE posts (
  id UUID PRIMARY KEY,
  status TEXT NOT NULL REFERENCES status_types(value)
);
```

---

### 7. インデックス戦略

**決定**:
- 以下に必ずインデックスを作成:
  - プライマリキー（自動）
  - 外部キー
  - 検索条件に使うカラム
  - `created_at`（時系列ソート用）
  - マルチテナント対応時の `tenant_id`

**理由**:
- クエリパフォーマンスの確保
- N+1 問題の回避

**実装例**:
```sql
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_tenant_id ON posts(tenant_id);

-- 複合インデックス（tenant + status + created_at）
CREATE INDEX idx_posts_tenant_status_created
ON posts(tenant_id, status, created_at DESC);
```

---

### 8. マルチテナント設計

**決定**:
- 初期から **`tenant_id`** カラムを含める
- Hasura パーミッションで自動フィルタリング
- **3段階のロール設計**: `user` / `tenant_admin` / `admin`

**理由**:
- 後から追加するとマイグレーションが複雑
- 「組織」「チーム」等のスコープ分離が必要になる想定
- 使わない場合でもカラム1つ増えるだけ
- `tenant_admin` でテナント内の管理業務を委譲可能

**ロール設計の考え方**:
- **user**: 自分が作成したデータのみ操作可能
- **tenant_admin**: 自分のテナント内の全データを操作可能（削除済み含む）
- **admin**: 全テナントの全データを操作可能（システム管理者）

**実装例**:
```sql
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE users (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES organizations(id),
  email TEXT UNIQUE NOT NULL,
  ...
);

CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
  tenant_id UUID NOT NULL REFERENCES organizations(id),
  user_id UUID NOT NULL REFERENCES users(id),
  ...
);

-- 複合ユニーク制約（テナント内でユニーク）
CREATE UNIQUE INDEX idx_posts_tenant_slug
ON posts(tenant_id, slug) WHERE deleted_at IS NULL;
```

**Hasura パーミッション**:
```json
{
  "filter": {
    "tenant_id": {"_eq": "X-Hasura-Tenant-Id"},
    "deleted_at": {"_is_null": true}
  }
}
```

---

### 9. 命名規則

**決定**:

| 対象 | 規則 | 例 |
|------|------|-----|
| テーブル名 | snake_case（複数形） | `users`, `blog_posts` |
| カラム名 | snake_case | `user_id`, `created_at` |
| インデックス | `idx_<table>_<column>` | `idx_users_email` |
| 外部キー | `fk_<table>_<column>` | `fk_posts_user_id` |
| GraphQL（Query） | camelCase | `blogPosts`, `userId` |
| GraphQL（Type） | PascalCase | `BlogPost`, `User` |

**理由**:
- PostgreSQL は小文字推奨（大文字は引用符が必要）
- Hasura が自動で snake_case → camelCase 変換
- 可読性と一貫性

---

### 10. 集計・分析クエリ最適化

**決定**:
- 複雑な集計は **View** または **Materialized View** で対応
- Hasuraで View を GraphQL として公開

**理由**:
- N+1 問題の回避
- 計算コストの削減
- クライアント側の複雑性軽減

**実装例**:
```sql
-- 通常のView（リアルタイム）
CREATE VIEW user_post_counts AS
SELECT
  user_id,
  COUNT(*) AS post_count
FROM posts
WHERE deleted_at IS NULL
GROUP BY user_id;

-- Materialized View（定期更新）
CREATE MATERIALIZED VIEW daily_stats AS
SELECT
  DATE(created_at) AS date,
  COUNT(*) AS post_count
FROM posts
WHERE deleted_at IS NULL
GROUP BY DATE(created_at);

-- リフレッシュ（バッチ処理で定期実行）
REFRESH MATERIALIZED VIEW daily_stats;
```

---

## ユーザー同期戦略

### 初回ログイン時の同期

**決定**:
- クライアント発火の **idempotent upsert**（`on_conflict`）
- ネットワークエラー時は **自動リトライ**

**実装例**:
```graphql
mutation UpsertUser($id: uuid!, $email: String!) {
  insert_users_one(
    object: {
      id: $id,
      email: $email,
      created_at: "now()",
      updated_at: "now()"
    },
    on_conflict: {
      constraint: users_pkey,
      update_columns: [email, updated_at]
    }
  ) {
    id
    email
  }
}
```

**将来の拡張**:
- Firebase Cloud Functions の `onCreate` トリガーでサーバサイド同期
- レースコンディション・不達の保険として併用

---

## GraphQL Code Generation

**決定**:
- 初期は **graphql_codegen + graphql_flutter**（軽量・シンプル）
- 将来必要なら **ferry**（高度なキャッシュ・楽観的更新）

**移行判断基準**:
- オフラインキャッシュが必須になった時
- 楽観的更新（Optimistic UI）が複雑化した時
- リアルタイム同期の要件が増えた時

---

## CI/CD・デプロイ方針

### スモークテスト（CI必須項目）

**決定**:
- CI で以下を自動実行:
  1. Hasura `/healthz` チェック
  2. DB接続確認
  3. 基本クエリ実行（`query { __typename }`）
  4. ロール別パーミッション検証（anonymous/user/admin）

**実装方針**:
```bash
# backend/scripts/smoke-test.sh
#!/bin/bash
set -e

# 1. Health check
curl -f $HASURA_ENDPOINT/healthz || exit 1

# 2. Basic query
QUERY='{"query": "{ __typename }"}'
curl -X POST $HASURA_ENDPOINT/v1/graphql \
  -H "Content-Type: application/json" \
  -H "x-hasura-admin-secret: $HASURA_ADMIN_SECRET" \
  -d "$QUERY" || exit 1

# 3. Permission tests
# ... (各ロールでのクエリテスト)
```

### デプロイフロー

**local → dev**:
- GitHub に push
- GitHub Actions が自動で `migrate apply` → `metadata apply`

**dev → prod**:
- 手動承認後、prod workflow を実行
- 本番DBへの適用前にバックアップ確認

詳細は [デプロイフロー](deployment.md) を参照。

---

## 環境変数管理

**決定**:

| レイヤー | 管理方法 | ローカル開発 |
|---------|---------|------------|
| **backend** | Secret Manager | `.env.local`（gitignore） |
| **Hasura CLI** | `config.yaml` | `config.yaml.example` をコピー |
| **Flutter** | `--dart-define` | `.env.dev.json` 等 |

**補助ツール**:
- `direnv`: ディレクトリ移動で自動環境変数ロード
- `envsubst`: テンプレート展開

---

## まとめ

この設計原則により、以下を実現します:

- **型安全**: UUID v7、timestamptz、lookup テーブル
- **監査可能**: 監査カラム、ソフトデリート
- **拡張性**: マルチテナント対応、View/Materialized View
- **安全性**: Hasura パーミッション、環境分離
- **運用性**: CI/CD、スモークテスト、明確な命名規則

次は [データベース設計](database-design.md) で具体的なテーブル構造を確認してください。
