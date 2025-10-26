# トラブルシューティング

よくある問題と解決方法をまとめます。運用中に発生した問題もここに追記していきます。

## Hasura Console 関連

### 「Enter Hasura-Collaborator-Token」エラー

**症状**: `hasura console` で `http://localhost:9695` を開くと、Collaborator Tokenの入力を求められる

**原因**: Hasura CLI のチーム開発機能（Hasura Cloud向け）が有効化されている

**解決方法**:

```bash
# 方法1: TLS検証をスキップして起動
hasura console --insecure-skip-tls-verify

# 方法2: 環境変数で無効化
export HASURA_GRAPHQL_ENABLE_TELEMETRY=false
hasura console
```

**回避策**: `http://localhost:8080/console` を使う（ただし変更はマイグレーションファイルに記録されない）

---

### CLI Console の CORS エラー

**症状**: `hasura console` で `http://localhost:9695` にアクセスすると、以下のようなCORSエラーが出る

```
Access to fetch at 'http://localhost:8080/v1/metadata' from origin 'http://localhost:9695'
has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on
the requested resource.
```

**原因**: Hasura CLI Console と Hasura サーバー間の CORS 設定の問題（環境依存）

**確認方法**:
1. ブラウザの開発者ツール（Console）でエラーを確認
2. `.env` の CORS 設定を確認:
   ```bash
   HASURA_GRAPHQL_CORS_DOMAIN=http://localhost:*,https://yourdomain.com
   ```

**試した解決方法（うまくいかなかった）**:
```bash
# CORS設定を確認
cat backend/.env | grep CORS

# Dockerを再起動
docker compose down && docker compose up -d

# --insecure-skip-tls-verify フラグを試す
hasura console --insecure-skip-tls-verify
```

**実際の回避策（推奨）**:

CLI Console が使えない場合は、**サーバーConsole + 手動メタデータエクスポート** で対応できます：

1. **`http://localhost:8080/console` でGUI操作**:
   - テーブル作成
   - Track設定
   - Permissions設定

2. **マイグレーションファイルを手動作成**:
   ```bash
   cd backend/hasura/migrations/default
   mkdir $(date +%s)000_your_migration_name
   # up.sql と down.sql を作成
   ```

3. **メタデータを手動エクスポート**:
   ```bash
   cd backend/hasura
   hasura metadata export
   ```

4. **Git にコミット**:
   ```bash
   git add migrations/ metadata/
   git commit -m "Your migration message"
   ```

この方法でも CLI Console と同等の結果が得られます。詳細は [開発フロー](development-flow.md#実際の開発ワークフロー2つのアプローチ) を参照してください。

---

## 認証関連

### 「JWT is expired」エラー

**症状**:
```json
{
  "errors": [
    {
      "message": "Could not verify JWT: JWTExpired"
    }
  ]
}
```

**原因**: ID Token の有効期限切れ（1時間）

**解決**:
```dart
// Flutter側で自動リフレッシュを実装
FirebaseAuth.instance.idTokenChanges().listen((user) async {
  if (user != null) {
    final token = await user.getIdToken();
    // GraphQLクライアントのヘッダーを更新
    updateGraphQLClient(token);
  }
});
```

---

### 「x-hasura-user-id not found in JWT claims」

**症状**:
```
Error: x-hasura-user-id not found in JWT claims
```

**原因**: Firebase の JWT に `user_id` クレームが含まれていない

**確認方法**:
```dart
// Flutter側でトークンの内容を確認
final user = FirebaseAuth.instance.currentUser;
final token = await user?.getIdToken();
print(token);  // jwt.io でデコードして確認
```

**解決**:
1. Hasura の JWT設定を確認:
   ```json
   {
     "claims_map": {
       "x-hasura-user-id": {
         "path": "$.user_id"  // または "$.sub"
       }
     }
   }
   ```

2. Firebase では `user_id` と `sub` は同じ値なので、`$.sub` でも可:
   ```json
   "x-hasura-user-id": { "path": "$.sub" }
   ```

---

### Custom Claims が反映されない

**症状**: ロールを変更したのに権限が変わらない

**原因**: ID Token が1時間キャッシュされている

**解決**:
```dart
// クライアント側で強制リフレッシュ
final user = FirebaseAuth.instance.currentUser;
await user?.getIdToken(true);  // true = forceRefresh
```

サーバ側でのリフレッシュ指示方法は [認証ドキュメント](authentication.md#custom-claims-更新フロー) を参照。

---

## パーミッション関連

### 403 Forbidden エラー

**症状**:
```json
{
  "errors": [
    {
      "message": "field 'users' not found in type: 'query_root'"
    }
  ]
}
```

**原因**: 現在のロールにそのテーブルへのアクセス権限がない

**確認方法**:
1. Hasura Console → Data → テーブル → Permissions
2. 現在のロール（user/admin等）の権限を確認

**デバッグ**:
```graphql
# Admin Secretで実行（全権限）
query {
  users {
    id
    email
  }
}
```

Admin Secretで成功すれば、パーミッション設定の問題。

**解決**:
- Hasura Console でパーミッションを追加
- `hasura metadata export` でメタデータ保存
- Git コミット・デプロイ

---

### 「check constraint of an insert/update permission has failed」

**症状**:
```json
{
  "errors": [
    {
      "message": "Check constraint violation. insert check constraint failed"
    }
  ]
}
```

**原因**: `insert` パーミッションの `check` 条件に違反

**例**:
```json
{
  "check": {
    "tenant_id": {"_eq": "X-Hasura-Tenant-Id"}
  }
}
```

異なる `tenant_id` で insert しようとするとエラー。

**解決**:
- クライアント側で正しい `tenant_id` を送信
- または `set` でサーバ側で自動設定:
  ```json
  {
    "set": {
      "tenant_id": "X-Hasura-Tenant-Id"
    }
  }
  ```

---

## マイグレーション関連

### 「Migration version already exists」

**症状**:
```
Error: migration version <timestamp> already exists
```

**原因**: 同じタイムスタンプのマイグレーションファイルが既に存在

**解決**:
```bash
# 既存のマイグレーションを確認
ls backend/hasura/migrations/

# 重複しているファイルを削除または名前変更
# 新しいマイグレーションを作成
hasura migrate create "your_migration_name" --from-server
```

---

### 「relation does not exist」（マイグレーション適用時）

**症状**:
```
ERROR: relation "organizations" does not exist
```

**原因**: マイグレーションの依存順序が間違っている

**解決**:
1. マイグレーションファイルの順序を確認:
   ```bash
   ls -la backend/hasura/migrations/
   ```

2. `organizations` テーブルが `users` テーブルより先に作成されているか確認

3. 必要であればマイグレーションファイルのタイムスタンプを修正（非推奨）
   または、マイグレーションを作り直す

---

### 「down migration failed」

**症状**: ロールバック時にエラー

**原因**: `down.sql` が正しく定義されていない

**解決**:
1. `down.sql` を確認:
   ```sql
   -- up.sql
   CREATE TABLE posts (...);

   -- down.sql（正しい例）
   DROP TABLE IF EXISTS posts CASCADE;
   ```

2. `CASCADE` を付けて外部キー制約も削除

3. 手動でロールバック:
   ```bash
   # PostgreSQLに接続
   psql $DATABASE_URL

   # 手動でテーブル削除
   DROP TABLE posts CASCADE;
   ```

---

## Docker / ローカル環境

### 「port is already allocated」

**症状**:
```
Error: bind: address already in use
```

**原因**: ポート（5432, 8080等）が既に使用されている

**確認**:
```bash
# macOS/Linux
lsof -i :5432
lsof -i :8080

# プロセスを停止
kill -9 <PID>
```

**解決**:
```bash
# 既存のコンテナを停止
docker compose down

# 再起動
docker compose up -d
```

---

### Docker ボリュームのリセット

**症状**: DBが壊れた、データをリセットしたい

**解決**:
```bash
# コンテナとボリュームを削除
cd backend
docker compose down -v

# 再起動
docker compose up -d

# マイグレーション再適用
cd hasura
hasura migrate apply
hasura metadata apply
hasura seed apply
```

---

### 「hasura console」が起動しない

**症状**:
```
Error: cannot connect to Hasura endpoint
```

**原因**: `config.yaml` の設定が間違っている

**確認**:
```yaml
# backend/hasura/config.yaml
version: 3
endpoint: http://localhost:8080  # ← 正しいか確認
admin_secret: myadminsecretkey   # ← .env の値と一致するか
```

**解決**:
1. Hasuraコンテナが起動しているか確認:
   ```bash
   docker ps | grep hasura
   ```

2. エンドポイントにアクセスできるか確認:
   ```bash
   curl http://localhost:8080/healthz
   ```

3. `config.yaml` を修正して再実行

---

## GraphQL クエリ関連

### 「Conflicting objects」（upsert時）

**症状**:
```json
{
  "errors": [
    {
      "message": "Uniqueness violation. duplicate key value violates unique constraint"
    }
  ]
}
```

**原因**: ユニーク制約に違反

**解決**:
```graphql
# on_conflict を正しく指定
mutation UpsertUser($id: uuid!, $email: String!) {
  insert_users_one(
    object: { id: $id, email: $email }
    on_conflict: {
      constraint: users_pkey       # ← 正しい制約名
      update_columns: [email, updated_at]
    }
  ) {
    id
  }
}
```

制約名の確認:
```sql
-- PostgreSQL
SELECT conname FROM pg_constraint WHERE conrelid = 'users'::regclass;
```

---

### N+1 問題

**症状**: クエリが遅い、大量のSQLが実行される

**原因**: Hasura のリレーションを使っていない

**NG例**:
```dart
// Flutter側で個別に取得（N+1になる）
for (var post in posts) {
  final user = await fetchUser(post.userId);
}
```

**OK例**:
```graphql
query {
  posts {
    id
    title
    user {  # ← Hasuraが自動でJOIN
      id
      name
    }
  }
}
```

---

## Cloud Run / デプロイ関連

### 「Container failed to start」

**症状**: Cloud Run デプロイ後、コンテナが起動しない

**確認**:
```bash
# ログ確認
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=hasura-dev" --limit 50
```

**よくある原因**:
1. 環境変数の設定ミス:
   ```bash
   # DATABASE_URL が正しいか確認
   gcloud run services describe hasura-dev --format="value(spec.template.spec.containers[0].env)"
   ```

2. Secretが存在しない:
   ```bash
   gcloud secrets list
   gcloud secrets versions access latest --secret="hasura-admin-secret-dev"
   ```

3. ポート番号の不一致（Cloud Runは8080がデフォルト）

---

### CI/CD でマイグレーション失敗

**症状**: GitHub Actions でマイグレーション適用時にエラー

**確認**:
1. Actions のログを確認
2. Hasura エンドポイントにアクセスできるか:
   ```bash
   curl https://hasura-dev-xxx.run.app/healthz
   ```

**よくある原因**:
1. Secret の設定ミス（`DEV_HASURA_ADMIN_SECRET` 等）
2. エンドポイントURLの誤り（末尾の `/` に注意）
3. マイグレーションファイルのSQLエラー

---

## Neon DB 関連

### 接続エラー

**症状**:
```
Error: Connection refused
```

**確認**:
1. Neon のステータス: https://neon.tech/status
2. 接続文字列が正しいか:
   ```bash
   psql "$DATABASE_URL" -c "SELECT 1;"
   ```

**解決**:
- Neon が一時的にダウンしている場合は復旧を待つ
- IPアドレス制限を確認（Neonのプロジェクト設定）

---

### 「too many connections」

**症状**:
```
FATAL: too many connections for role "user"
```

**原因**: 接続プールの上限に達した

**解決**:
1. Hasura の接続プール設定:
   ```bash
   HASURA_GRAPHQL_PG_CONNECTIONS=10  # デフォルトは50
   ```

2. Neon のコネクション上限を確認（プラン依存）

3. Connection Pooling を有効化（PgBouncer等）

---

## Flutter アプリ関連

### 「NetworkException: Failed to connect」

**症状**: Flutter アプリから Hasura にアクセスできない

**確認**:
1. エンドポイントURL:
   ```dart
   print(Environment.hasuraEndpoint);
   ```

2. ネットワーク接続:
   ```bash
   # 実機から確認
   curl https://hasura-dev-xxx.run.app/healthz
   ```

**iOS の場合**:
`Info.plist` で HTTP アクセスを許可（開発時のみ）:
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

**Android の場合**:
`AndroidManifest.xml` で `INTERNET` パーミッション確認:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

---

### Code Generation エラー

**症状**:
```
Error: Could not find schema.graphql
```

**原因**: GraphQL スキーマファイルが見つからない

**解決**:
1. スキーマをダウンロード:
   ```bash
   cd app
   curl -X POST https://hasura-dev-xxx.run.app/v1/graphql \
     -H "x-hasura-admin-secret: $ADMIN_SECRET" \
     --data '{"query": "query IntrospectionQuery { __schema { types { name } } }"}' \
     > schema.graphql
   ```

2. `build.yaml` でスキーマパスを指定:
   ```yaml
   targets:
     $default:
       builders:
         graphql_codegen:
           options:
             schema: hasura|http://localhost:8080/v1/graphql
   ```

---

## パフォーマンス問題

### クエリが遅い

**確認**:
1. Hasura Console → GraphiQL で `EXPLAIN ANALYZE` 相当を確認
2. PostgreSQL で直接確認:
   ```sql
   EXPLAIN ANALYZE
   SELECT * FROM posts WHERE tenant_id = '...' ORDER BY created_at DESC;
   ```

**解決**:
1. インデックス追加:
   ```sql
   CREATE INDEX idx_posts_tenant_created ON posts(tenant_id, created_at DESC);
   ```

2. ページネーション:
   ```graphql
   query {
     posts(limit: 20, offset: 0) {
       id
       title
     }
   }
   ```

3. Materialized View の活用

---

## その他

### Hasura Console で変更が反映されない

**症状**: パーミッション等を変更したが、GraphQLで変わらない

**解決**:
```bash
# メタデータをリロード
hasura metadata reload
```

または Hasura Console の Settings → Reload Metadata

---

### ログが出ない

**確認**:
```bash
# Hasura のログレベル設定
HASURA_GRAPHQL_LOG_LEVEL=debug
HASURA_GRAPHQL_ENABLED_LOG_TYPES="startup, http-log, webhook-log, query-log"
```

**Cloud Run のログ確認**:
```bash
gcloud logging read "resource.type=cloud_run_revision" --limit 100
```

---

## サポート・問い合わせ先

- **Hasura**: https://hasura.io/docs/
- **Neon**: https://neon.tech/docs/
- **Firebase**: https://firebase.google.com/support

プロジェクト固有の問題は GitHub Issues で報告してください。

---

## まとめ

このドキュメントは随時更新していきます。新しい問題が発生した場合は、以下の形式で追記してください:

```markdown
### 問題のタイトル

**症状**: エラーメッセージまたは動作

**原因**: なぜ発生したか

**解決**: 具体的な手順
```

次は [将来拡張](future-enhancements.md) で今後の構想を確認してください。
