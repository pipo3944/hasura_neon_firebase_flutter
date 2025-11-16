# Hasura + Flutter + Firebase 検証プロジェクト

このプロジェクトは、**Hasura**（GraphQL Engine）、**Firebase Auth**、**Neon**（PostgreSQL）、**Flutter** を組み合わせたモバイルアプリケーション開発のアーキテクチャを検証するためのリファレンス実装です。

## プロジェクトの目的

実際に機能するサービスを作ることではなく、以下を検証・確立することが目的です：

- Firebase Auth × Hasura × Neon の連携パターン
- マイグレーション管理とCI/CDのベストプラクティス
- マルチテナント対応を見据えたDB設計
- Flutter での型安全なGraphQL操作
- 環境分離（local/dev/prod）の運用フロー

## 技術スタック

| レイヤー | 技術 | 役割 |
|---------|------|------|
| **認証** | Firebase Auth | JWT発行・ユーザー管理 |
| **API** | Hasura GraphQL Engine | GraphQL API自動生成・認可 |
| **DB** | Neon (PostgreSQL) | サーバレスDB（ブランチで環境分離） |
| **クライアント** | Flutter | モバイルアプリ |
| **インフラ** | Cloud Run (Hasura) | マネージドコンテナ実行環境 |
| **CI/CD** | GitHub Actions | 自動デプロイ・マイグレーション適用 |

## クイックスタート（5分で動かす）

### 前提条件

- Docker & Docker Compose
- Hasura CLI (`npm install -g hasura-cli` または [公式ドキュメント](https://hasura.io/docs/latest/hasura-cli/install-hasura-cli/))
- Node.js 18+ (Hasura CLI用、パーミッションテスト実行時)
- Flutter SDK 3.10+ (アプリ開発時)

### オプションA：自動セットアップ（推奨）

**1行でローカル環境を構築：**

```bash
git clone <repository-url>
cd hasura_flutter/backend/scripts
bash setup-local.sh
```

このスクリプトが自動で行うこと：
- `.env` と `config.yaml` の作成（初回のみ）
- Docker Compose でサービス起動
- マイグレーション適用
- メタデータ適用
- シードデータ投入

### オプションB：手動セットアップ（学習向け）

各ステップを理解しながら進めたい場合：

**1. リポジトリのクローン**

```bash
git clone <repository-url>
cd hasura_flutter
```

**2. 環境変数の設定**

```bash
# バックエンド用
cp backend/.env.example backend/.env
# 必要に応じて backend/.env を編集

# Hasura CLI用
cp backend/hasura/config.yaml.example backend/hasura/config.yaml
# endpoint と admin_secret を編集
```

**3. ローカル環境の起動**

```bash
cd backend
docker compose up -d
```

起動するサービス：
- PostgreSQL: `localhost:5432`
- Hasura Console: `http://localhost:8080`
- pgAdmin: `http://localhost:5050` (オプション)

**4. マイグレーションとメタデータの適用**

```bash
cd hasura
hasura migrate apply --database-name default
hasura metadata apply
```

**5. シードデータの投入（オプション）**

テスト用のデータを投入して、すぐに動作確認できます：

```bash
hasura seed apply --database-name default
```

投入されるデータ：
- 組織2件（Acme Corp, Beta Inc）
- ユーザー5件（admin, tenant_admin x2, user x2）
- 投稿13件（ソフトデリート2件含む）

---

### 動作確認

ブラウザで Hasura Console を開く：`http://localhost:8080/console`

「API Explorer」で以下を実行（Admin Secret: `hasura_local_admin_secret`）：

```graphql
query {
  organizations {
    id
    name
    slug
  }
}
```

組織データが返れば成功です！

### 7. パーミッションテスト（オプション）

JWT を使った各ロールのパーミッションをテスト：

```bash
cd backend
npm install
node test-permissions.js
```

## ドキュメント

詳細な設計・運用方針は以下のドキュメントを参照してください：

### Overview（システム理解）
- [アーキテクチャ概要](docs/overview/architecture.md) - システム全体図とコンポーネント責務
- [認証フロー](docs/overview/authentication-flow.md) - Firebase Auth × Hasura 連携、JWT設定
- [環境構成](docs/overview/environments.md) - local/dev/prod の定義と使い分け

### Getting Started（初期セットアップ）
- [セットアップ概要](docs/getting-started/README.md) - セットアップの全体像と順序
- [Backend セットアップ](docs/getting-started/backend-setup.md) - Docker、Hasura、PostgreSQL環境構築
- [Neon セットアップ](docs/getting-started/neon-setup.md) - Neon PostgreSQLの設定
- [Frontend セットアップ](docs/getting-started/frontend-setup.md) - Flutter、Firebase Auth、Flavor設定

### Development（開発ワークフロー）
- [Backend 開発ワークフロー](docs/development/backend-workflow.md) - マイグレーション作成、Hasura Console操作
- [ドキュメント作成ガイド](docs/development/documentation-guide.md) - ドキュメントの書き方・更新方法

### Deployment（デプロイ・運用）
- [Cloud Run デプロイ](docs/deployment/cloud-run-deployment.md) - Hasura の Cloud Run へのデプロイ
- [CI/CD](docs/deployment/ci-cd.md) - GitHub Actions パイプライン
- [トラブルシューティング](docs/deployment/troubleshooting.md) - よくある問題と解決策

### Reference（設計詳細）
- [設計原則](docs/reference/design-principles.md) - アーキテクチャ判断の背景と理由
- [データベース設計](docs/reference/database-design.md) - ER図、マルチテナント、インデックス戦略
- [認証設計](docs/reference/authentication-design.md) - JWT、カスタムクレーム、セキュリティ
- [将来拡張](docs/reference/future-enhancements.md) - Preview環境、Actions等の構想

## ディレクトリ構成

```
hasura_flutter/
├── README.md                      # このファイル
├── docs/                          # 設計ドキュメント（overview/getting-started/development/deployment/reference）
├── backend/
│   ├── hasura/                    # Hasura migrations & metadata
│   ├── docker-compose.yml         # ローカル開発環境
│   └── scripts/                   # セットアップ・テスト用スクリプト
└── app/                           # Flutter アプリケーション
```

## 開発フロー（概要）

1. **ローカルで開発**: Hasura Console でDB構造・パーミッション調整
2. **マイグレーション生成**: `hasura migrate create --from-server <name>`
3. **メタデータエクスポート**: `hasura metadata export`
4. **PR作成**: GitHub へプッシュ
5. **CI（dev）**: 自動で `migrate apply` → `metadata apply`
6. **動作確認**: dev環境で実機テスト
7. **本番デプロイ**: 承認後、手動で prod へ適用

詳細は [Backend開発ワークフロー](docs/development/backend-workflow.md) を参照。

## 開発哲学

- **小さく動かして大きく育てる**: 最小構成から開始し、必要に応じて拡張
- **スキーマファースト**: DB構造を Hasura migration で一元管理
- **型安全**: クライアント・サーバともに型で守る
- **権限中心設計**: Hasura パーミッションと Firebase カスタムクレームを軸に
- **環境を壊せる勇気**: local で試して dev に昇格、prod は最後に適用

## ライセンス

MIT License (検証プロジェクトのため)

## コントリビューション

このプロジェクトは検証・学習目的です。改善提案や質問は Issue でお願いします。

---

**次のステップ**: [アーキテクチャ概要](docs/overview/architecture.md) を読んで全体像を把握してください。
