# 認証フロー概要

このドキュメントでは、Firebase Auth と Hasura を組み合わせた認証・認可の仕組みを図で説明します。

## 認証・認可の分離

| 層 | 担当 | 役割 |
|----|------|------|
| **認証（Authentication）** | Firebase Auth | ユーザーが誰かを特定（JWT発行） |
| **認可（Authorization）** | Hasura | ユーザーが何をできるかを制御（パーミッション） |

## 全体フロー

```mermaid
sequenceDiagram
    participant User as ユーザー
    participant Flutter as Flutter App
    participant Firebase as Firebase Auth
    participant Functions as Cloud Functions
    participant Hasura as Hasura
    participant DB as Neon DB

    User->>Flutter: 1. サインアップ/ログイン
    Flutter->>Firebase: 2. createUserWithEmailAndPassword()
    Firebase-->>Flutter: 3. UserCredential

    Note over Firebase,Functions: onCreate Trigger
    Firebase->>Functions: 4. onCreate Event
    Functions->>Hasura: 5. ユーザー情報取得<br/>(Admin Secret)
    Hasura->>DB: 6. SELECT users WHERE id = ...
    DB-->>Hasura: 7. User data (role, tenant_id)
    Hasura-->>Functions: 8. User data
    Functions->>Firebase: 9. setCustomUserClaims()<br/>{role, tenant_id}

    Note over Flutter: Token取得
    Flutter->>Firebase: 10. getIdToken()
    Firebase-->>Flutter: 11. ID Token (JWT with custom claims)

    Note over Flutter: GraphQL通信
    User->>Flutter: 12. データ取得操作
    Flutter->>Hasura: 13. GraphQL Query<br/>Authorization: Bearer <TOKEN>

    Hasura->>Firebase: 14. JWT検証<br/>(公開鍵で署名確認)
    Firebase-->>Hasura: 15. 検証OK

    Hasura->>Hasura: 16. Claims抽出<br/>(user_id, role, tenant_id)
    Hasura->>Hasura: 17. パーミッションチェック

    Hasura->>DB: 18. SQL実行<br/>(WHERE条件自動追加)
    DB-->>Hasura: 19. フィルタ済みデータ
    Hasura-->>Flutter: 20. GraphQL Response
    Flutter-->>User: 21. UI表示
```

## Custom Claims 設定フロー

Custom Claims（カスタムクレーム）は、JWT に追加情報（`role`, `tenant_id`）を埋め込む仕組みです。

```mermaid
graph LR
    A[ユーザー作成] --> B[Cloud Functions<br/>onCreate Trigger]
    B --> C[Hasuraからユーザー情報取得]
    C --> D[Custom Claims設定<br/>role, tenant_id]
    D --> E[JWT発行<br/>Claims付き]
```

### Custom Claims の内容

```json
{
  "user_id": "firebase-uid-xxx",
  "role": "user",
  "tenant_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
}
```

これらが Hasura に以下のセッション変数として渡されます:
- `X-Hasura-User-Id`
- `X-Hasura-Role`
- `X-Hasura-Tenant-Id`

## ロール設計

### 4つのロール

| ロール | 権限 | 用途 |
|--------|------|------|
| `anonymous` | 公開データのみ閲覧 | 未認証ユーザー |
| `user` | 自分のデータのみ | 一般ユーザー |
| `tenant_admin` | テナント内全データ | 組織管理者 |
| `admin` | 全データ | システム管理者 |

### ロール判定フロー

```mermaid
graph TD
    Start[ユーザー作成] --> Check{users.role}
    Check -->|admin| SetAdmin[Claims: role=admin]
    Check -->|tenant_admin| SetTenantAdmin[Claims: role=tenant_admin]
    Check -->|user or NULL| SetUser[Claims: role=user]

    SetAdmin --> Done[JWT発行]
    SetTenantAdmin --> Done
    SetUser --> Done
```

## マルチテナント分離

Hasura は `X-Hasura-Tenant-Id` を使って、テナント間のデータを自動的に分離します。

```sql
-- User ロールのクエリは自動的に以下のWHERE条件が追加される
SELECT * FROM posts
WHERE tenant_id = 'X-Hasura-Tenant-Id'
  AND user_id = 'X-Hasura-User-Id'
  AND deleted_at IS NULL;
```

## Token リフレッシュフロー

Firebase ID Token は **1時間**で有効期限切れになります。

```mermaid
sequenceDiagram
    participant Flutter
    participant Firebase
    participant Hasura

    Note over Flutter: idTokenChanges() で監視

    loop Every hour
        Firebase->>Flutter: Token更新通知
        Flutter->>Firebase: getIdToken(forceRefresh: true)
        Firebase-->>Flutter: 新しいToken
        Flutter->>Hasura: GraphQL with新Token
    end
```

## 次のステップ

詳細な設計背景は以下を参照:
- [認証・認可の設計](../reference/authentication.md) - Hasura JWT設定、セキュリティ
- [環境構成](environments.md) - Local/Dev/Prod環境の違い
- [マルチテナント設計](../reference/multi-tenancy.md) - テナント分離戦略

実装手順は以下を参照:
- [Flutter環境セットアップ](../getting-started/frontend-setup.md) - Firebase Auth実装
- [Cloud Functions デプロイ](../deployment/cloud-functions-deployment.md) - Custom Claims設定
