# 環境構成

このドキュメントでは、local/dev/prod 3つの環境の違いを図で説明します。

**詳細なセットアップ手順**:
- Backend環境構築 → [getting-started/backend-setup.md](../getting-started/backend-setup.md)
- Cloud Run デプロイ → [deployment/cloud-run-deployment.md](../deployment/cloud-run-deployment.md)
- CI/CD設定 → [deployment/ci-cd.md](../deployment/ci-cd.md)

---

## 環境一覧

| 環境 | 目的 | DB | Hasura | Firebase Auth |
|------|------|----|---------|----|
| **local** | 開発・migration作成 | Docker PostgreSQL | Docker Compose | dev project |
| **dev** | 統合検証・実機テスト | Neon dev branch | Cloud Run | dev project |
| **prod** | 本番運用 | Neon main branch | Cloud Run | prod project |

---

## 全体構成図

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
        DH[Hasura<br/>Cloud Run<br/>hasura-dev.run.app]
        DN[(Neon PostgreSQL<br/>dev branch)]
        DFA[Firebase Auth<br/>myproject-dev]
    end

    subgraph "Prod Environment"
        PF[Flutter App<br/>リリース版]
        PH[Hasura<br/>Cloud Run<br/>hasura-prod.run.app]
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

## 環境別の設定比較

### 1. Local 環境

**目的**: 開発・マイグレーション作成・安全な実験場

| 項目 | 設定値 |
|------|--------|
| **Hasura** | Docker Compose (`localhost:8080`) |
| **PostgreSQL** | Docker Compose (`localhost:5432`) |
| **Firebase Auth** | `myproject-dev` (API経由) |
| **Console** | ✅ 有効 (`localhost:9695`) |
| **データリセット** | ✅ 可能 (`docker compose down -v`) |
| **オフライン開発** | ✅ 可能 |
| **実機テスト** | ❌ 不可（devを経由） |

**特徴**:
- 完全にローカルで動作（オフラインOK）
- マイグレーション作成の拠点
- 壊しても問題ない

### 2. Dev 環境

**目的**: 統合検証・実機テスト・チーム共有

| 項目 | 設定値 |
|------|--------|
| **Hasura** | Cloud Run (`hasura-dev.run.app`) |
| **PostgreSQL** | Neon dev branch |
| **Firebase Auth** | `myproject-dev` |
| **Console** | ✅ 有効（開発用） |
| **デプロイ** | GitHub Actions（自動） |
| **CORS** | `*`（開発用） |
| **最小インスタンス** | 0（コスト削減） |

**特徴**:
- チーム全体で共有
- CI/CDで自動デプロイ
- 実機テスト可能

### 3. Prod 環境

**目的**: 本番運用

| 項目 | 設定値 |
|------|--------|
| **Hasura** | Cloud Run (`hasura-prod.run.app`) |
| **PostgreSQL** | Neon main branch |
| **Firebase Auth** | `myproject-prod` |
| **Console** | ❌ 無効（セキュリティ） |
| **デプロイ** | 手動承認必須 |
| **CORS** | 本番ドメインのみ |
| **最小インスタンス** | 1以上（レスポンス速度確保） |

**特徴**:
- 安定性最優先
- 承認なしの変更禁止
- 監査ログ有効

---

## Firebase プロジェクト分離

### プロジェクト構成

| 環境 | Firebase Project ID | 用途 |
|------|-------------------|------|
| **local** | `myproject-dev` | 開発用ユーザー |
| **dev** | `myproject-dev` | 開発・テスト用ユーザー |
| **prod** | `myproject-prod` | 本番ユーザー |

### JWT設定の違い

**Dev環境**:
```json
{
  "issuer": "https://securetoken.google.com/myproject-dev",
  "audience": "myproject-dev"
}
```

**Prod環境**:
```json
{
  "issuer": "https://securetoken.google.com/myproject-prod",
  "audience": "myproject-prod"
}
```

---

## Neon ブランチ戦略

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

| ブランチ | 環境 | マイグレーション適用 |
|---------|------|------------------|
| **main** | Prod | 手動承認後 |
| **dev** | Dev | CI自動適用 |
| **feature-xxx** | （将来）PR プレビュー | PR作成時 |

---

## 開発フロー

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

詳細は [Backend開発フロー](../development/backend-workflow.md) を参照。

---

## 環境ごとの注意点

### Local
- ✅ 自由に壊せる（Docker volume削除で完全リセット）
- ✅ オフライン開発可能
- ❌ 実機からアクセス不可（dev環境経由）

### Dev
- ✅ チーム全体で共有
- ✅ 実機テスト可能
- ❌ マイグレーションは慎重に（壊れると全員に影響）
- ❌ 本番データは絶対に入れない

### Prod
- ✅ 安定性最優先
- ❌ 直接変更禁止（必ずマイグレーション経由）
- ❌ Hasura Console 無効化
- ❌ テストデータ投入禁止

---

## まとめ

| 環境 | 開発 | 実機テスト | 本番運用 |
|------|------|----------|---------|
| **local** | ✅ | ❌ | ❌ |
| **dev** | ⚠️（共有） | ✅ | ❌ |
| **prod** | ❌ | ❌ | ✅ |

---

## 次のステップ

- **初回セットアップ**: [getting-started/README.md](../getting-started/README.md)
- **Backend環境構築**: [getting-started/backend-setup.md](../getting-started/backend-setup.md)
- **Cloud Run デプロイ**: [deployment/cloud-run-deployment.md](../deployment/cloud-run-deployment.md)
