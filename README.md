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
- Node.js 18+ (Hasura CLI用)
- Flutter SDK 3.10+ (アプリ開発時)

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd hasura_flutter
```

### 2. 環境変数の設定

```bash
# バックエンド用
cp backend/.env.example backend/.env
# 必要に応じて backend/.env を編集

# Hasura CLI用
cp backend/hasura/config.yaml.example backend/hasura/config.yaml
# endpoint と admin_secret を編集
```

### 3. ローカル環境の起動

```bash
cd backend
docker compose up -d
```

起動するサービス：
- PostgreSQL: `localhost:5432`
- Hasura Console: `http://localhost:8080`
- pgAdmin: `http://localhost:5050` (オプション)

### 4. Hasura Console を開く

```bash
cd backend/hasura
hasura console
```

ブラウザで `http://localhost:9695` が開きます。

### 5. 初期マイグレーションの適用（今後追加予定）

```bash
hasura migrate apply
hasura metadata apply
```

### 動作確認

Hasura Console の「API Explorer」で以下を実行：

```graphql
query {
  __typename
}
```

`{"data": {"__typename": "query_root"}}` が返れば成功です。

## ドキュメント

詳細な設計・運用方針は以下のドキュメントを参照してください：

### アーキテクチャ・設計
- [アーキテクチャ概要](docs/architecture.md) - システム全体図とコンポーネント責務
- [設計原則・決定事項](docs/design-principles.md) - UUID v7、命名規則、RLS等の方針
- [データベース設計](docs/database-design.md) - テーブル設計規約、マルチテナント対応

### 環境・運用
- [環境構成](docs/environment.md) - local/dev/prod の定義と使い分け
- [開発フロー](docs/development-flow.md) - ローカル開発・マイグレーション管理
- [デプロイフロー](docs/deployment.md) - CI/CD パイプライン・デプロイ手順

### セキュリティ
- [認証・認可](docs/authentication.md) - Firebase Auth × Hasura 連携、ロール設計

### その他
- [トラブルシューティング](docs/troubleshooting.md) - よくある問題と解決策
- [将来拡張](docs/future-enhancements.md) - Preview環境、Actions等の構想

## ディレクトリ構成

```
hasura_flutter/
├── README.md                      # このファイル
├── docs/                          # 設計ドキュメント
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

詳細は [開発フロー](docs/development-flow.md) を参照。

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

**次のステップ**: [アーキテクチャ概要](docs/architecture.md) を読んで全体像を把握してください。
