# Cloud Run Hasura デプロイ手順

このドキュメントでは、Hasura を Google Cloud Run にデプロイする手順を説明します。

## 前提条件

- Neon DB セットアップ完了（[getting-started/neon-setup.md](../getting-started/neon-setup.md)）
- Google Cloud SDK インストール済み
- Google Cloud プロジェクト作成済み（例: `hasura-flutter-dev`）

---

## Step 1: Google Cloud SDK のセットアップ

### 1.1 インストール

```bash
# Homebrew経由（macOS）
brew install google-cloud-sdk

# または公式サイトからダウンロード
# https://cloud.google.com/sdk/docs/install
```

### 1.2 初期化

```bash
gcloud init

# プロジェクト設定
gcloud config set project hasura-flutter-dev

# 認証
gcloud auth login
```

---

## Step 2: Secret Manager の設定

Hasuraの環境変数を Secret Manager に保存します。

### 2.1 Secret Manager API の有効化

```bash
gcloud services enable secretmanager.googleapis.com
```

### 2.2 DATABASE_URL の作成

```bash
# Neon development ブランチの接続文字列を使用
# ⚠️ 重要: 改行を含めないこと（tr -d '\n' を使用）
echo -n "postgresql://neondb_owner:YOUR_PASSWORD@YOUR_ENDPOINT.ap-southeast-1.aws.neon.tech/neondb?sslmode=require" | \
  gcloud secrets create HASURA_GRAPHQL_DATABASE_URL --data-file=-
```

### 2.3 ADMIN_SECRET の生成と作成

```bash
# ランダムな強力なシークレットを生成
# ⚠️ 重要: tr -d '\n' で改行を除去すること
openssl rand -hex 32 | tr -d '\n' > /tmp/admin_secret.txt

# Secret Manager に保存
gcloud secrets create HASURA_GRAPHQL_ADMIN_SECRET --data-file=/tmp/admin_secret.txt

# ローカルで保存（後で使用）
cp /tmp/admin_secret.txt ~/hasura-admin-secret.txt
chmod 600 ~/hasura-admin-secret.txt

# 確認（改行がないことを確認）
cat ~/hasura-admin-secret.txt
```

### 2.4 JWT_SECRET の作成

Firebase の JWT 設定を Secret Manager に保存:

```bash
# JWT設定をファイルに作成（改行なし）
cat > /tmp/jwt_secret.json << 'EOF'
{"type":"RS256","jwk_url":"https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com","issuer":"https://securetoken.google.com/hasura-flutter-dev","audience":"hasura-flutter-dev","claims_map":{"x-hasura-allowed-roles":{"path":"$.role","default":["user"]},"x-hasura-default-role":{"path":"$.role","default":"user"},"x-hasura-user-id":{"path":"$.user_id"},"x-hasura-tenant-id":{"path":"$.tenant_id"}}}
EOF

# 改行を除去してSecret Managerに保存
cat /tmp/jwt_secret.json | tr -d '\n' | gcloud secrets create HASURA_GRAPHQL_JWT_SECRET --data-file=-
```

**⚠️ 重要な注意点**:
- シークレットに**改行文字が含まれていると認証が失敗します**
- 必ず `echo -n` または `tr -d '\n'` を使用して改行を除去すること
- 詳細は [troubleshooting.md](troubleshooting.md#secret-manager経由のシークレットが正しく読み込まれない) を参照

---

## Step 3: Cloud Run サービスの作成とデプロイ

### 3.1 Cloud Run API の有効化

```bash
gcloud services enable run.googleapis.com
```

### 3.2 サービスアカウントの作成

```bash
# サービスアカウント作成
gcloud iam service-accounts create hasura-dev \
  --display-name="Hasura Dev Service Account"

# Secret Manager へのアクセス権限付与
gcloud projects add-iam-policy-binding hasura-flutter-dev \
  --member="serviceAccount:hasura-dev@hasura-flutter-dev.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### 3.3 Cloud Run デプロイ

#### 方法1: 環境変数ファイルを使用（推奨）

カンマ区切りの値がある場合はYAMLファイルを使用します：

```bash
# 環境変数ファイル作成
cat > /tmp/hasura-env.yaml << 'EOF'
HASURA_GRAPHQL_ENABLE_CONSOLE: "true"
HASURA_GRAPHQL_DEV_MODE: "true"
HASURA_GRAPHQL_ENABLED_LOG_TYPES: "startup,http-log,webhook-log,websocket-log,query-log"
HASURA_GRAPHQL_CORS_DOMAIN: "*"
EOF

# デプロイ
gcloud run deploy hasura-dev \
  --image=hasura/graphql-engine:v2.36.0 \
  --platform=managed \
  --region=asia-northeast1 \
  --allow-unauthenticated \
  --service-account=hasura-dev@hasura-flutter-dev.iam.gserviceaccount.com \
  --port=8080 \
  --env-vars-file=/tmp/hasura-env.yaml \
  --set-secrets=HASURA_GRAPHQL_DATABASE_URL=HASURA_GRAPHQL_DATABASE_URL:latest,HASURA_GRAPHQL_ADMIN_SECRET=HASURA_GRAPHQL_ADMIN_SECRET:latest,HASURA_GRAPHQL_JWT_SECRET=HASURA_GRAPHQL_JWT_SECRET:latest \
  --cpu=1 \
  --memory=512Mi \
  --min-instances=0 \
  --max-instances=10 \
  --timeout=300
```

#### 方法2: インラインで指定

シンプルな環境変数のみの場合：

```bash
gcloud run deploy hasura-dev \
  --image=hasura/graphql-engine:v2.36.0 \
  --platform=managed \
  --region=asia-northeast1 \
  --allow-unauthenticated \
  --service-account=hasura-dev@hasura-flutter-dev.iam.gserviceaccount.com \
  --set-env-vars=HASURA_GRAPHQL_ENABLE_CONSOLE=true,HASURA_GRAPHQL_DEV_MODE=true,HASURA_GRAPHQL_CORS_DOMAIN=* \
  --set-secrets=HASURA_GRAPHQL_DATABASE_URL=HASURA_GRAPHQL_DATABASE_URL:latest,HASURA_GRAPHQL_ADMIN_SECRET=HASURA_GRAPHQL_ADMIN_SECRET:latest,HASURA_GRAPHQL_JWT_SECRET=HASURA_GRAPHQL_JWT_SECRET:latest \
  --cpu=1 \
  --memory=512Mi \
  --min-instances=0 \
  --max-instances=10
```

**重要な設定**:
- `--allow-unauthenticated`: 公開アクセス許可（CORS制限あり）
- `--region=asia-northeast1`: 東京リージョン（Neon Singaporeに近い）
- `--min-instances=0`: コスト削減（オートスケール）
- `HASURA_GRAPHQL_ENABLE_CONSOLE=true`: Dev環境のみ（Prodでは`false`）
- `--env-vars-file`: カンマ区切り値がある場合に推奨

### 3.4 デプロイ確認

```bash
# サービスURL取得
gcloud run services describe hasura-dev \
  --region=asia-northeast1 \
  --format='value(status.url)'

# 例: https://hasura-dev-xxxxx-an.a.run.app
```

---

## Step 4: 動作確認

### 4.1 ヘルスチェック

```bash
HASURA_URL=$(gcloud run services describe hasura-dev --region=asia-northeast1 --format='value(status.url)')

curl "$HASURA_URL/healthz"
# 期待される出力: OK
```

### 4.2 GraphQL エンドポイント確認

```bash
curl -X POST "$HASURA_URL/v1/graphql" \
  -H "Content-Type: application/json" \
  -H "x-hasura-admin-secret: YOUR_ADMIN_SECRET" \
  -d '{"query": "{ __schema { queryType { name } } }"}'
```

### 4.3 Hasura Console アクセス

ブラウザで以下にアクセス:

```
https://hasura-dev-xxxxx-an.a.run.app/console
```

Admin Secret を入力してログイン。

---

## Step 5: マイグレーションとメタデータの適用

### 5.1 ローカルからの適用

```bash
cd backend/hasura

# 環境変数設定
export HASURA_GRAPHQL_ENDPOINT="https://hasura-dev-xxxxx-an.a.run.app"
export HASURA_GRAPHQL_ADMIN_SECRET="YOUR_ADMIN_SECRET"

# マイグレーション適用
hasura migrate apply --database-name default

# メタデータ適用
hasura metadata apply

# メタデータリロード
hasura metadata reload
```

### 5.2 シードデータ適用（Dev環境のみ）

```bash
hasura seed apply --database-name default
```

---

## Step 6: Cloud Functions の接続設定

Cloud Functions から Cloud Run Hasura に接続するための設定を更新します。

### 6.1 環境変数ファイル作成

```bash
# Cloud Functions用の環境変数YAML作成
HASURA_URL=$(gcloud run services describe hasura-dev --region=asia-northeast1 --format='value(status.url)')
ADMIN_SECRET=$(cat ~/hasura-admin-secret.txt)

cat > /tmp/cloud-functions-env.yaml << EOF
HASURA_GRAPHQL_ENDPOINT: ${HASURA_URL}/v1/graphql
HASURA_GRAPHQL_ADMIN_SECRET: ${ADMIN_SECRET}
EOF
```

### 6.2 Cloud Functions デプロイ

```bash
cd backend/functions

# TypeScriptビルド
npm run build

# setCustomClaimsOnCreate デプロイ
gcloud functions deploy setCustomClaimsOnCreate \
  --runtime=nodejs20 \
  --region=us-central1 \
  --source=. \
  --entry-point=setCustomClaimsOnCreate \
  --trigger-event=providers/firebase.auth/eventTypes/user.create \
  --trigger-resource=hasura-flutter-dev \
  --env-vars-file=/tmp/cloud-functions-env.yaml \
  --project=hasura-flutter-dev

# refreshCustomClaims デプロイ
gcloud functions deploy refreshCustomClaims \
  --runtime=nodejs20 \
  --region=us-central1 \
  --source=. \
  --entry-point=refreshCustomClaims \
  --trigger-http \
  --allow-unauthenticated \
  --env-vars-file=/tmp/cloud-functions-env.yaml \
  --project=hasura-flutter-dev
```

**注意**: `.gcloudignore` が `lib/` ディレクトリを除外しないように設定されている必要があります

---

## トラブルシューティング

詳細なトラブルシューティングは [troubleshooting.md](troubleshooting.md) を参照してください。

### よくある問題

1. **Secret Manager経由のシークレットが正しく読み込まれない**
   - 原因: シークレットに改行文字が含まれている
   - 解決: [troubleshooting.md#secret-manager経由のシークレットが正しく読み込まれない](troubleshooting.md#secret-manager経由のシークレットが正しく読み込まれない)

2. **Secret にアクセスできない**
   - エラー: `Error: failed to read secret: ...`
   - 解決: サービスアカウントに権限を再付与
   ```bash
   gcloud projects add-iam-policy-binding hasura-flutter-dev \
     --member="serviceAccount:hasura-dev@hasura-flutter-dev.iam.gserviceaccount.com" \
     --role="roles/secretmanager.secretAccessor"
   ```

3. **Cloud Run が起動しない**
   - 解決: ログを確認
   ```bash
   gcloud run services logs read hasura-dev --region=asia-northeast1
   ```

4. **CORS エラー**
   - 解決: `HASURA_GRAPHQL_CORS_DOMAIN` を適切に設定
   ```bash
   # 特定ドメインのみ許可（本番推奨）
   gcloud run services update hasura-dev \
     --region=asia-northeast1 \
     --set-env-vars=HASURA_GRAPHQL_CORS_DOMAIN=https://yourdomain.com
   ```

5. **Cloud Functions デプロイで "lib/index.js does not exist" エラー**
   - 原因: `.gcloudignore` が `lib/` を除外している
   - 解決: `.gcloudignore` を修正して `lib/` を含めるようにする

---

## 本番環境（Prod）へのデプロイ

本番環境では、以下の違いがあります:

### 異なる設定

```bash
gcloud run deploy hasura-prod \
  --image=hasura/graphql-engine:v2.36.0 \
  --platform=managed \
  --region=asia-northeast1 \
  --allow-unauthenticated \
  --service-account=hasura-prod@hasura-flutter-prod.iam.gserviceaccount.com \
  --set-env-vars="HASURA_GRAPHQL_ENABLE_CONSOLE=false" \  # ❌ Console無効
  --set-env-vars="HASURA_GRAPHQL_DEV_MODE=false" \        # ❌ Dev Mode無効
  --set-env-vars="HASURA_GRAPHQL_ENABLED_LOG_TYPES=startup,http-log" \  # ログ最小化
  --set-env-vars="HASURA_GRAPHQL_CORS_DOMAIN=https://yourdomain.com" \  # ドメイン制限
  --set-secrets="HASURA_GRAPHQL_DATABASE_URL=HASURA_GRAPHQL_DATABASE_URL_PROD:latest" \
  --set-secrets="HASURA_GRAPHQL_ADMIN_SECRET=HASURA_GRAPHQL_ADMIN_SECRET_PROD:latest" \
  --set-secrets="HASURA_GRAPHQL_JWT_SECRET=HASURA_GRAPHQL_JWT_SECRET_PROD:latest" \
  --cpu=2 \                  # 本番はリソース増加
  --memory=1Gi \
  --min-instances=1 \        # 最低1インスタンス常駐
  --max-instances=100
```

### 本番デプロイ時の注意事項

1. **Console は無効化** (`HASURA_GRAPHQL_ENABLE_CONSOLE=false`)
2. **Dev Mode は無効化** (`HASURA_GRAPHQL_DEV_MODE=false`)
3. **CORS を適切に制限** (ワイルドカード `*` は使わない)
4. **最低インスタンス数を1以上に** (レスポンス速度確保)
5. **CI/CD経由でのみデプロイ** (手動デプロイは避ける)

---

## 参考リンク

- [Cloud Run ドキュメント](https://cloud.google.com/run/docs)
- [Hasura on Cloud Run](https://hasura.io/docs/latest/deployment/deployment-guides/google-cloud-run/)
- [Secret Manager](https://cloud.google.com/secret-manager/docs)
- [CI/CD設定](ci-cd.md)
