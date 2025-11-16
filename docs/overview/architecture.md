# アーキテクチャ概要

このドキュメントでは、本プロジェクトのシステム全体像と各コンポーネントの責務を説明します。

## システム全体図

```mermaid
graph TB
    subgraph "Client Layer"
        FlutterApp[Flutter App]
    end

    subgraph "Authentication"
        FirebaseAuth[Firebase Auth]
    end

    subgraph "API Layer"
        Hasura[Hasura GraphQL Engine]
    end

    subgraph "Database Layer"
        NeonDB[(Neon PostgreSQL)]
    end

    FlutterApp -->|1\. Login| FirebaseAuth
    FirebaseAuth -->|2\. JWT Token| FlutterApp
    FlutterApp -->|3\. GraphQL + JWT| Hasura
    Hasura -->|4\. Verify JWT| FirebaseAuth
    Hasura -->|5\. Check Permissions| Hasura
    Hasura -->|6\. SQL Query| NeonDB
    NeonDB -->|7\. Data| Hasura
    Hasura -->|8\. GraphQL Response| FlutterApp

    style FlutterApp fill:#4FC3F7
    style FirebaseAuth fill:#FFCA28
    style Hasura fill:#9C27B0
    style NeonDB fill:#66BB6A
```

## コンポーネント責務

### 1. Flutter App（クライアント）

**役割**:
- ユーザーインターフェース
- Firebase Auth によるユーザー認証
- GraphQL クエリ・ミューテーションの実行
- 型安全なデータ操作（graphql_codegen使用）

**技術スタック**:
- Flutter SDK 3.10+
- `graphql_flutter` - GraphQLクライアント
- `graphql_codegen` - 型生成
- `firebase_auth` - 認証

**責務の範囲**:
- ビジネスロジックの一部（UI状態管理、バリデーション）
- 認証トークンの管理とリフレッシュ
- GraphQLリクエストへのJWT自動付与

### 2. Firebase Auth（認証基盤）

**役割**:
- ユーザー登録・ログイン管理
- JWT（IDトークン）の発行
- カスタムクレーム（ロール情報）の管理

**採用理由**:
- マネージドサービスで運用コスト低
- モバイルSDKが充実
- メール/Google/Apple等の認証プロバイダが統合済み
- Hasura と標準的な連携パターンが確立

**責務の範囲**:
- 認証のみ（認可はHasuraが担当）
- ユーザーのプロファイル情報は **Neon DB の users テーブル** で管理

### 3. Hasura GraphQL Engine（API層）

**役割**:
- GraphQL API の自動生成
- 認可（パーミッション制御）
- マイグレーション・メタデータ管理
- リアルタイムサブスクリプション

**機能**:
- **JWTベース認証**: Firebase の IDトークン を検証
- **行レベルセキュリティ**: Hasuraパーミッションで `X-Hasura-User-Id`、`X-Hasura-Tenant-Id` 等をチェック
- **スキーマ自動生成**: DB構造から GraphQL スキーマを自動生成
- **リレーション**: 外部キーから GraphQL のネスト構造を自動作成

**デプロイ先**:
- **local**: Docker Compose
- **dev/prod**: Cloud Run

**責務の範囲**:
- API エンドポイント提供
- 認可ルールの適用
- クエリの最適化（N+1問題の回避等）

### 4. Neon PostgreSQL（データ層）

**役割**:
- アプリケーションデータの永続化
- トランザクション管理
- 全文検索、集計等のDB機能提供

**採用理由**:
- サーバレスPostgreSQL（従量課金）
- **ブランチ機能**で環境分離が容易
- スケーリング自動対応
- バックアップ・PITR（ポイントインタイムリカバリ）標準装備

**ブランチ構成**:
- **main（prod）**: 本番データ
- **dev**: 開発・統合テスト用
- **local**: Docker Postgres（Neon使わない選択肢もあり）

**責務の範囲**:
- データの保存・取得
- 整合性制約の維持
- インデックスによるパフォーマンス最適化

## データフロー

### 通常のクエリ実行フロー

```mermaid
sequenceDiagram
    participant User
    participant Flutter
    participant Firebase
    participant Hasura
    participant Neon

    User->>Flutter: アプリ起動・操作
    Flutter->>Firebase: ログイン
    Firebase-->>Flutter: ID Token (JWT)

    Flutter->>Hasura: GraphQL Query<br/>(Authorization: Bearer TOKEN)
    Hasura->>Firebase: JWT検証<br/>(JWK公開鍵で署名確認)
    Firebase-->>Hasura: 検証OK + Claims

    Hasura->>Hasura: パーミッションチェック<br/>(X-Hasura-User-Id, Tenant-Id等)
    Hasura->>Neon: SQL実行<br/>(WHERE user_id = ...)
    Neon-->>Hasura: 結果セット
    Hasura-->>Flutter: GraphQL Response
    Flutter-->>User: UI更新
```

### 初回ログイン時のユーザー同期フロー

```mermaid
sequenceDiagram
    participant User
    participant Flutter
    participant Firebase
    participant Hasura
    participant Neon

    User->>Flutter: 初回ログイン
    Flutter->>Firebase: 認証実行
    Firebase-->>Flutter: ID Token + UID

    Note over Flutter: ユーザー同期処理
    Flutter->>Hasura: Mutation: upsertUser<br/>(on_conflict: do update)
    Hasura->>Hasura: JWT検証
    Hasura->>Neon: INSERT ... ON CONFLICT UPDATE
    Neon-->>Hasura: ユーザーレコード
    Hasura-->>Flutter: 同期完了

    Note over Flutter: 同期失敗時はリトライ<br/>(idempotent設計)
```

## 環境構成図

```mermaid
graph LR
    subgraph "Local Environment"
        LocalFlutter[Flutter<br/>--dart-define]
        LocalHasura[Hasura<br/>Docker Compose]
        LocalDB[(PostgreSQL<br/>Docker)]
    end

    subgraph "Dev Environment"
        DevFlutter[Flutter<br/>--dart-define DEV]
        DevHasura[Hasura<br/>Cloud Run]
        DevNeon[(Neon<br/>dev branch)]
    end

    subgraph "Prod Environment"
        ProdFlutter[Flutter<br/>--dart-define PROD]
        ProdHasura[Hasura<br/>Cloud Run]
        ProdNeon[(Neon<br/>main branch)]
    end

    LocalFlutter -.->|実機テスト時| DevHasura
    LocalFlutter --> LocalHasura
    LocalHasura --> LocalDB

    DevFlutter --> DevHasura
    DevHasura --> DevNeon

    ProdFlutter --> ProdHasura
    ProdHasura --> ProdNeon

    style LocalFlutter fill:#E3F2FD
    style DevFlutter fill:#FFF3E0
    style ProdFlutter fill:#FFEBEE
```

### 環境の使い分け

| 環境 | 用途 | DB | Hasura | Flutter向き先 |
|------|------|----|---------|----|
| **local** | 開発・migration作成・安全な実験場 | Docker PostgreSQL | Docker Compose | dev（実機テスト時） |
| **dev** | 統合検証・実機テスト | Neon dev branch | Cloud Run | dev |
| **prod** | 本番運用 | Neon main branch | Cloud Run | prod |

詳細は [環境構成ドキュメント](environment.md) を参照。

## CI/CD パイプライン概要

```mermaid
graph LR
    Dev[開発者] -->|1\. git push| GitHub[GitHub]
    GitHub -->|2\. Trigger| Actions[GitHub Actions]

    Actions -->|3\. migrate apply| DevHasura[Dev Hasura]
    Actions -->|4\. metadata apply| DevHasura
    DevHasura -->|5\. Apply| DevNeon[(Dev Neon)]

    Actions -->|6\. Smoke Test| DevHasura

    Actions -->|7\. 承認後<br/>手動実行| ProdActions[Prod Workflow]
    ProdActions -->|8\. migrate apply| ProdHasura[Prod Hasura]
    ProdActions -->|9\. metadata apply| ProdHasura
    ProdHasura -->|10\. Apply| ProdNeon[(Prod Neon)]

    style Actions fill:#4CAF50
    style ProdActions fill:#FF9800
```

詳細は [デプロイフロー](deployment.md) を参照。

## セキュリティレイヤー

```mermaid
graph TB
    Request[Client Request]

    Request --> AuthCheck{JWT検証}
    AuthCheck -->|Invalid| Reject1[401 Unauthorized]
    AuthCheck -->|Valid| ExtractClaims[Claims抽出<br/>user_id, role, tenant_id]

    ExtractClaims --> PermCheck{Hasuraパーミッション}
    PermCheck -->|Denied| Reject2[403 Forbidden]
    PermCheck -->|Allowed| BuildSQL[SQLクエリ生成<br/>WHERE句自動追加]

    BuildSQL --> Execute[DB実行]
    Execute --> Response[Response]

    style AuthCheck fill:#FFEB3B
    style PermCheck fill:#FF9800
    style Reject1 fill:#F44336
    style Reject2 fill:#F44336
```

**多層防御**:
1. **Firebase JWT検証**: 署名・有効期限・issuer/audienceチェック
2. **Hasuraパーミッション**: ロール・ユーザーID・テナントIDでフィルタリング
3. **（オプション）PostgreSQL RLS**: Hasura経由以外のアクセスに備えた二重防御

詳細は [認証・認可ドキュメント](authentication.md) を参照。

## スケーラビリティ戦略

### 現在の構成
- **Hasura**: Cloud Run でオートスケール
- **Neon**: サーバレスDB（自動スケール）
- **Firebase Auth**: フルマネージド（制限なし）

### 将来の拡張ポイント
- **キャッシュ層**: Redis（頻繁にアクセスされるデータ）
- **CDN**: Cloud CDN（静的アセット）
- **Read Replica**: Neon の読み取りレプリカ（分析クエリ分離）
- **Materialized View**: 集計処理の高速化

## まとめ

このアーキテクチャの特徴：

- **マネージドサービス中心**: 運用負荷を最小化
- **疎結合**: 各レイヤーが独立して変更可能
- **型安全**: DB → Hasura → Flutter まで一貫した型定義
- **環境分離**: local/dev/prod で安全な開発サイクル
- **拡張性**: 初期は最小構成、必要に応じて機能追加

次は [設計原則・決定事項](design-principles.md) で具体的な実装方針を確認してください。
