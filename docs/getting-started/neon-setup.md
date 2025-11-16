# Neon DB 初期セットアップ手順

このドキュメントでは、Neon PostgreSQL の初回セットアップ手順を説明します。

## 前提条件

- ローカル環境でマイグレーションとメタデータが作成済み
- Docker がインストール済み
- Hasura CLI がインストール済み

## 1. Neon プロジェクト作成

### 1.1 アカウント作成

1. https://neon.tech にアクセス
2. GitHubアカウントでサインアップ（推奨）

### 1.2 プロジェクト作成

| 項目 | 設定値 |
|-----|--------|
| Project name | `hasura-flutter` |
| Cloud provider | **AWS** |
| Region | **AWS Asia Pacific 1 (Singapore)** |
| Postgres version | **17** (最新) |
| Enable Neon Auth | **OFF** ❌ |

**重要**: Enable Neon Auth は無効にしてください。認証は Firebase Auth で行います。

### 1.3 ブランチ確認

Neonは自動的に2つのブランチを作成します:

- **`production`** (Default) - 本番環境用
- **`development`** - 開発環境用

この設計により、1つのNeonプロジェクト内で環境分離を実現します。

## 2. 接続文字列の取得

### 2.1 Development ブランチの接続文字列

1. 左サイドバーの **BRANCH** セクションで `development` を選択
2. 上部メニューの **"Dashboard"** をクリック
3. **"Connection Details"** セクションで **"Direct connection"** を選択
4. 接続文字列をコピー

形式:
```
postgresql://[user]:[password]@[endpoint]/[database]?sslmode=require
```

**重要**: **Direct connection** を使用してください（`-pooler` が含まれないもの）。

- ✅ Direct: `ep-xxx.ap-southeast-1.aws.neon.tech`
- ❌ Pooler: `ep-xxx-pooler.ap-southeast-1.aws.neon.tech`

Hasuraは長時間接続とWebSocketサポートのため、Direct接続が必要です。

## 3. マイグレーションの適用

### 3.1 スクリプトを使った適用（推奨）

プロジェクトに用意されているスクリプトを使用します:

```bash
cd backend/hasura

# スクリプトを編集して接続文字列を設定
# DATABASE_URL='postgresql://...' の部分を更新
vim apply-migrations-to-neon.sh

# マイグレーション適用
bash apply-migrations-to-neon.sh
```

スクリプトの内容:
```bash
#!/bin/bash
set -e

DATABASE_URL='postgresql://neondb_owner:PASSWORD@ENDPOINT/neondb?sslmode=require'
MIGRATIONS_DIR="/path/to/backend/hasura/migrations"

echo "Applying migrations to Neon development branch..."

for migration_dir in "$MIGRATIONS_DIR/default/"*/; do
  migration_name=$(basename "$migration_dir")
  echo ""
  echo "📦 Applying migration: $migration_name"

  docker run --rm \
    -v "$MIGRATIONS_DIR:/migrations" \
    postgres:15 \
    psql "$DATABASE_URL" \
    -f "/migrations/default/$migration_name/up.sql"

  echo "✅ Migration $migration_name applied successfully"
done

echo ""
echo "🎉 All migrations applied successfully!"
```

### 3.2 マイグレーション確認

適用後、テーブルが作成されたことを確認:

```bash
docker run --rm postgres:15 psql 'YOUR_DATABASE_URL' -c "\dt"
```

期待される出力:
```
                 List of relations
 Schema |       Name        | Type  |    Owner
--------+-------------------+-------+--------------
 public | organizations     | table | neondb_owner
 public | post_status_types | table | neondb_owner
 public | posts             | table | neondb_owner
 public | users             | table | neondb_owner
(4 rows)
```

## 4. Lookup テーブルのデータ投入

マイグレーションの文字エンコーディング問題により、`post_status_types` テーブルのデータが正しく投入されない場合があります。

手動でデータを投入:

```bash
docker run --rm postgres:15 psql 'YOUR_DATABASE_URL' -c \
  "INSERT INTO post_status_types (value, label, sort_order) VALUES
   ('draft', 'Draft', 1),
   ('published', 'Published', 2),
   ('archived', 'Archived', 3)
   ON CONFLICT (value) DO NOTHING;"
```

確認:
```bash
docker run --rm postgres:15 psql 'YOUR_DATABASE_URL' -c \
  "SELECT * FROM post_status_types ORDER BY sort_order;"
```

## 5. シードデータの投入（開発環境のみ）

テストデータを投入します:

```bash
cd backend/hasura

# スクリプトを編集して接続文字列を設定
vim apply-seed-to-neon.sh

# シードデータ適用
bash apply-seed-to-neon.sh
```

スクリプトの内容:
```bash
#!/bin/bash
set -e

DATABASE_URL='postgresql://neondb_owner:PASSWORD@ENDPOINT/neondb?sslmode=require'
SEEDS_DIR="/path/to/backend/hasura/seeds"

echo "Applying seed data to Neon development branch..."

docker run --rm \
  -v "$SEEDS_DIR:/seeds" \
  postgres:15 \
  psql "$DATABASE_URL" \
  -f /seeds/default/1_test_data.sql

echo ""
echo "🎉 Seed data applied successfully!"
```

### 5.1 データ確認

```bash
docker run --rm postgres:15 psql 'YOUR_DATABASE_URL' -c \
  "SELECT COUNT(*) as organizations FROM organizations;
   SELECT COUNT(*) as users FROM users;
   SELECT COUNT(*) as posts FROM posts;"
```

期待される出力:
```
 organizations
---------------
             2

 users
-------
     5

 posts
-------
    13
```

## 6. 本番環境（Production ブランチ）の準備

本番環境では、シードデータは投入**しません**。

```bash
# 本番用接続文字列を取得（production ブランチ）
# 1. Neonダッシュボードで "production" ブランチを選択
# 2. Direct connection の接続文字列をコピー

# マイグレーションのみ適用
# apply-migrations-to-neon.sh の DATABASE_URL を本番用に変更
bash apply-migrations-to-neon.sh

# Lookup テーブルデータのみ投入
docker run --rm postgres:15 psql 'PROD_DATABASE_URL' -c \
  "INSERT INTO post_status_types (value, label, sort_order) VALUES
   ('draft', 'Draft', 1),
   ('published', 'Published', 2),
   ('archived', 'Archived', 3)
   ON CONFLICT (value) DO NOTHING;"
```

## トラブルシューティング

### psql コマンドが見つからない

Dockerを使用してpsqlを実行:

```bash
docker run --rm postgres:15 psql 'YOUR_DATABASE_URL' -c "\dt"
```

### 文字エンコーディングエラー

マイグレーションファイルに日本語が含まれている場合、UTF-8エンコーディングエラーが発生する可能性があります。

対処法: 手動でINSERT文を実行（上記 Step 4 参照）

### マイグレーションが重複適用される

Neonでは、Hasuraのマイグレーション管理テーブル（`hdb_catalog`）が存在しないため、スクリプトは単純に全マイグレーションを実行します。

冪等性（ON CONFLICT等）が保証されているため、重複実行しても問題ありません。

## 次のステップ

Neon DBのセットアップが完了したら、次は:

1. [Cloud Run Hasura デプロイ](deployment.md) - HasuraをCloud Runにデプロイ
2. [CI/CD構築](deployment.md#dev-環境への自動デプロイ) - 自動デプロイパイプライン構築

## 参考リンク

- [Neon Documentation](https://neon.tech/docs)
- [Neon Branching](https://neon.tech/docs/introduction/branching)
- [Hasura Migrations](https://hasura.io/docs/latest/migrations-metadata-seeds/migrations-metadata-setup/)
