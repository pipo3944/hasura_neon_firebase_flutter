# 環境構成

このドキュメントでは、local/dev/prod 3つの環境の定義と、それぞれの使い分けを説明します。

## 環境一覧

| 環境 | 目的 | DB | Hasura | Flutter向き先 |
|------|------|----|---------|----|
| **local** | 開発・migration作成・安全な実験場 | Docker PostgreSQL | Docker Compose | dev（実機テスト時） |
| **dev** | 統合検証・実機テスト | Neon dev branch | Cloud Run | dev |
| **prod** | 本番運用 | Neon main branch | Cloud Run | prod |

## 環境構成図

```mermaid
graph TB
    subgraph "Local Environment"
        LD[開発者PC]
        LF[Flutter App<br/>開発・デバッグ]
        LH[Hasura<br/>Docker Compose<br/>localhost:8080]
        LP[(PostgreSQL<br/>Docker<br/>localhost:5432)]
        LPG[pgAdmin<br/>localhost:5050]
    end

    subgraph "Dev Environment"
        DF[Flutter App<br/>実機テスト]
        DH[Hasura<br/>Cloud Run<br/>hasura-dev.example.com]
        DN[(Neon PostgreSQL<br/>dev branch)]
        DFA[Firebase Auth<br/>myproject-dev]
    end

    subgraph "Prod Environment"
        PF[Flutter App<br/>リリース版]
        PH[Hasura<br/>Cloud Run<br/>hasura.example.com]
        PN[(Neon PostgreSQL<br/>main branch)]
        PFA[Firebase Auth<br/>myproject-prod]
    end

    LD -->|開発| LF
    LF -->|GraphQL| LH
    LH --> LP
    LD -->|GUI管理| LPG
    LPG --> LP

    LF -.->|実機テスト時| DH

    DF -->|GraphQL| DH
    DF -->|認証| DFA
    DH --> DN
    DH -->|JWT検証| DFA

    PF -->|GraphQL| PH
    PF -->|認証| PFA
    PH --> PN
    PH -->|JWT検証| PFA

    style LH fill:#90CAF9
    style DH fill:#FFB74D
    style PH fill:#EF5350
```

---

## 1. Local 環境

### 目的
- **開発**: DB構造・パーミッション・クエリの試行錯誤
- **マイグレーション作成**: Hasura Console でスキーマ変更 → `migrate create`
- **安全な実験場**: 壊しても問題ない環境

### 構成

| コンポーネント | 実装 | アクセス先 |
|--------------|------|-----------|
| Flutter App | ローカルビルド | `flutter run` |
| Hasura | Docker Compose | `http://localhost:8080` |
| PostgreSQL | Docker Compose | `localhost:5432` |
| pgAdmin | Docker Compose（オプション） | `http://localhost:5050` |
| Firebase Auth | dev プロジェクト | API経由 |

### セットアップ手順

```bash
# 1. 環境変数設定
cd backend
cp .env.example .env
# .env を編集（POSTGRES_PASSWORD等）

# 2. Docker起動
docker compose up -d

# 3. Hasura Console起動
cd hasura
cp config.yaml.example config.yaml
# config.yaml を編集（endpoint, admin_secret）
hasura console
```

### Hasura Console URL
- Console: `http://localhost:9695`（Hasura CLIが起動）
- GraphQL Endpoint: `http://localhost:8080/v1/graphql`

### データベース接続情報
```
Host: localhost
Port: 5432
Database: hasura
User: postgres
Password: (POSTGRES_PASSWORD)
```

### 実機テスト時の挙動
- ローカルで開発した Flutter アプリを実機で動かす場合
- **dev環境の Hasura** を向く（`localhost` は実機から見えないため）
- 設定: `--dart-define=HASURA_ENDPOINT=https://hasura-dev.example.com/v1/graphql`

### リセット方法
```bash
# すべてのデータを削除してクリーンな状態に
docker compose down -v
docker compose up -d

# マイグレーションを再適用
hasura migrate apply
hasura metadata apply
```

---

## 2. Dev 環境

### 目的
- **統合検証**: ローカルで作成したマイグレーションをクラウド環境で検証
- **実機テスト**: iOS/Android 実機でのテスト
- **チーム共有**: 複数開発者が共通の環境を使用

### 構成

| コンポーネント | 実装 | アクセス先 |
|--------------|------|-----------|
| Flutter App | 実機・エミュレータ | 開発者各自 |
| Hasura | Cloud Run | `https://hasura-dev.example.com` |
| PostgreSQL | Neon dev branch | 内部接続 |
| Firebase Auth | myproject-dev | API経由 |

### デプロイ方法
- **自動デプロイ**: GitHub Actions（main ブランチへの push で自動）
- **手動デプロイ**: `gcloud run deploy` コマンド

### CI/CDフロー
```mermaid
sequenceDiagram
    participant Dev as 開発者
    participant GH as GitHub
    participant GA as GitHub Actions
    participant CR as Cloud Run (Dev)
    participant Neon as Neon (dev branch)

    Dev->>GH: git push origin main
    GH->>GA: Trigger workflow
    GA->>GA: hasura migrate apply
    GA->>GA: hasura metadata apply
    GA->>CR: Deploy Hasura container
    CR->>Neon: Connect
    GA->>GA: Smoke test
    GA-->>Dev: 結果通知（Slack等）
```

### 環境変数（Secret Manager）
```bash
HASURA_GRAPHQL_DATABASE_URL=postgres://user:pass@neon-dev.com/db
HASURA_GRAPHQL_JWT_SECRET={...}
HASURA_GRAPHQL_ADMIN_SECRET=xxx
```

### アクセス制限
- Cloud Run: 認証なしでアクセス可（CORS制限あり）
- または、Cloud IAP で IP制限

### データ管理
- **マイグレーションで管理**: 手動でのデータ変更は避ける
- **シードデータ**: `hasura seed apply` でテストデータ投入
- **リセット**: Neon の branch を削除 → 再作成

---

## 3. Prod 環境

### 目的
- **本番運用**: 実際のユーザーが使用する環境
- **安定性重視**: 承認なしの変更は行わない

### 構成

| コンポーネント | 実装 | アクセス先 |
|--------------|------|-----------|
| Flutter App | App Store / Google Play | エンドユーザー |
| Hasura | Cloud Run | `https://hasura.example.com` |
| PostgreSQL | Neon main branch | 内部接続 |
| Firebase Auth | myproject-prod | API経由 |

### デプロイ方法
- **手動承認**: GitHub Actions の manual approval
- **段階的ロールアウト**: Cloud Run のトラフィック分割機能

### CI/CDフロー
```mermaid
sequenceDiagram
    participant Approver as 承認者
    participant GA as GitHub Actions
    participant CR as Cloud Run (Prod)
    participant Neon as Neon (main branch)

    Approver->>GA: 手動トリガー（prod workflow）
    GA->>GA: Backup確認
    GA->>GA: hasura migrate apply (dry-run)
    GA-->>Approver: 適用内容の確認
    Approver->>GA: 承認
    GA->>GA: hasura migrate apply
    GA->>GA: hasura metadata apply
    GA->>CR: Deploy Hasura container
    CR->>Neon: Connect
    GA->>GA: Smoke test
    GA-->>Approver: デプロイ完了通知
```

### 環境変数（Secret Manager）
```bash
HASURA_GRAPHQL_DATABASE_URL=postgres://user:pass@neon-prod.com/db
HASURA_GRAPHQL_JWT_SECRET={...}
HASURA_GRAPHQL_ADMIN_SECRET=xxx
HASURA_GRAPHQL_ENABLE_CONSOLE=false  # 本番ではConsole無効化
```

### セキュリティ設定
- **Cloud Run**: 最小権限の Service Account
- **CORS**: 本番ドメインのみ許可
- **Rate Limiting**: Cloud Armor または Hasura Pro
- **監査ログ**: Cloud Logging で全リクエスト記録

### バックアップ戦略
- **Neon自動スナップショット**: 毎日自動実行
- **論理バックアップ**: 週次で `pg_dump`
- **リストア手順**: `docs/troubleshooting.md` に記載

---

## Firebase プロジェクト構成

### 2つのプロジェクトで分離

| 環境 | Firebase Project ID | 用途 |
|------|-------------------|------|
| **dev** | `myproject-dev` | 開発・テスト用ユーザー |
| **prod** | `myproject-prod` | 本番ユーザー |

**local 環境**: `myproject-dev` を使用

### 理由
- **データ分離**: dev/prod のユーザーが混在しない
- **安全性**: dev で実験しても本番に影響なし
- **Firebase設定の独立**: Analytics、Crashlytics等も分離

### JWT設定（Hasura側）

**Dev環境**:
```json
{
  "type": "RS256",
  "jwk_url": "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  "issuer": "https://securetoken.google.com/myproject-dev",
  "audience": "myproject-dev",
  "claims_map": {
    "x-hasura-allowed-roles": ["user", "admin"],
    "x-hasura-default-role": "user",
    "x-hasura-user-id": "user_id"
  }
}
```

**Prod環境**:
```json
{
  "issuer": "https://securetoken.google.com/myproject-prod",
  "audience": "myproject-prod",
  ...
}
```

---

## Neon ブランチ構成

```mermaid
gitGraph
    commit id: "Initial schema"
    branch dev
    checkout dev
    commit id: "Add users table"
    commit id: "Add posts table"
    checkout main
    merge dev tag: "v1.0"
    checkout dev
    commit id: "Add comments table"
    checkout main
    merge dev tag: "v1.1"
```

| ブランチ | 用途 | マイグレーション適用タイミング |
|---------|------|---------------------------|
| **main（prod）** | 本番データ | 手動承認後 |
| **dev** | 開発・テスト | CI自動適用 |
| **feature-xxx**（将来） | PR プレビュー | PR作成時に自動作成 |

### ブランチ作成例
```bash
# Neon CLI または Web UI でブランチ作成
neon branches create --name dev --parent main

# 接続文字列を取得
neon connection-string dev
```

---

## 環境切り替え（Flutter）

### `--dart-define` による切り替え

**Dev環境**:
```bash
flutter run \
  --dart-define=HASURA_ENDPOINT=https://hasura-dev.example.com/v1/graphql \
  --dart-define=FIREBASE_PROJECT_ID=myproject-dev \
  --dart-define=ENV=dev
```

**Prod環境**:
```bash
flutter run \
  --dart-define=HASURA_ENDPOINT=https://hasura.example.com/v1/graphql \
  --dart-define=FIREBASE_PROJECT_ID=myproject-prod \
  --dart-define=ENV=prod
```

### コード例
```dart
// lib/config/environment.dart
class Environment {
  static const hasuraEndpoint = String.fromEnvironment(
    'HASURA_ENDPOINT',
    defaultValue: 'http://localhost:8080/v1/graphql',
  );

  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'myproject-dev',
  );

  static const env = String.fromEnvironment(
    'ENV',
    defaultValue: 'local',
  );

  static bool get isProduction => env == 'prod';
  static bool get isDevelopment => env == 'dev';
  static bool get isLocal => env == 'local';
}
```

### ビルド設定（example）
```bash
# iOS
flutter build ios --dart-define=ENV=prod --release

# Android
flutter build apk --dart-define=ENV=prod --release
```

---

## 運用フロー

### 開発サイクル

```mermaid
graph LR
    A[Local開発] -->|migrate create| B[マイグレーション生成]
    B -->|git push| C[PR作成]
    C -->|CI| D[Dev自動デプロイ]
    D -->|実機テスト| E{OK?}
    E -->|NG| A
    E -->|OK| F[PR承認・マージ]
    F -->|手動承認| G[Prod デプロイ]

    style A fill:#90CAF9
    style D fill:#FFB74D
    style G fill:#EF5350
```

1. **Local**: Hasura Console で DB 変更 → `hasura migrate create --from-server <name>`
2. **Git**: `git add migrations/ metadata/` → commit → push
3. **CI (Dev)**: 自動で `migrate apply` → `metadata apply`
4. **テスト**: dev環境で実機テスト
5. **本番**: 承認後、手動で prod workflow 実行

詳細は [開発フロー](development-flow.md) を参照。

---

## 環境ごとの注意点

### Local
- ✅ 自由に壊せる（Docker volume削除で完全リセット）
- ✅ オフライン開発可能
- ❌ 実機からアクセス不可（dev環境経由）

### Dev
- ✅ チーム全体で共有
- ✅ 実機テストが可能
- ❌ マイグレーションは慎重に（壊れると全員に影響）
- ❌ 本番データは絶対に入れない

### Prod
- ✅ 安定性最優先
- ❌ 直接変更は禁止（必ずマイグレーション経由）
- ❌ Hasura Console は無効化
- ❌ テストデータ投入禁止

---

## まとめ

| 環境 | 開発 | 実機テスト | 本番運用 |
|------|------|----------|---------|
| **local** | ✅ | ❌ | ❌ |
| **dev** | ⚠️（共有） | ✅ | ❌ |
| **prod** | ❌ | ❌ | ✅ |

次は [開発フロー](development-flow.md) で具体的な開発手順を確認してください。
