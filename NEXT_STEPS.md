# Next Steps - Firebase Cloud Functions デプロイと動作確認

Phase 5 (Cloud Functions実装) が完了しました！次の手順でデプロイとテストを行ってください。

## 📋 Phase 5 完了内容

### 実装済み
- ✅ Cloud Functions プロジェクト構造作成 (`backend/functions/`)
- ✅ Custom Claims設定関数実装
  - `setCustomClaimsOnCreate`: Firebase Authユーザー作成時に自動実行
  - `refreshCustomClaims`: 手動でClaimsをリフレッシュするcallable関数
- ✅ Flutter連携サービス実装 (`app/lib/services/cloud_functions_service.dart`)
- ✅ 依存パッケージ追加 (`cloud_functions: ^5.1.0`)

### デプロイ待ち
- ⏳ Firebase Cloud Functionsへのデプロイ（dev環境）
- ⏳ 動作確認・テスト

---

## 🚀 デプロイ手順

### 1. Flutterパッケージのインストール

```bash
cd app
fvm flutter pub get
```

### 2. Cloud Functions のビルド

```bash
cd backend/functions

# Node.js依存パッケージのインストール
npm install

# TypeScriptのビルド
npm run build
```

### 3. Firebase CLI の認証（初回のみ）

```bash
firebase login
```

### 4. Firebase プロジェクトの設定

```bash
cd backend/functions

# 現在のプロジェクトを確認
firebase projects:list

# dev環境プロジェクトに切り替え
firebase use hasura-flutter-dev
```

### 5. 環境変数の設定

Cloud Functionsが Hasura にアクセスするために必要な環境変数を設定します：

```bash
# Hasura エンドポイント（dev環境のCloud Run URL、まだない場合は後で設定）
# ローカルテスト時は localhost を使用
firebase functions:config:set hasura.endpoint="http://localhost:8080/v1/graphql"

# Hasura Admin Secret
firebase functions:config:set hasura.admin_secret="your-admin-secret-here"

# 設定を確認
firebase functions:config:get
```

### 6. Cloud Functions のデプロイ

```bash
# 全関数をデプロイ
firebase deploy --only functions

# または個別にデプロイ
firebase deploy --only functions:setCustomClaimsOnCreate
firebase deploy --only functions:refreshCustomClaims
```

デプロイには数分かかります。完了すると関数のURLが表示されます。

---

## 🧪 Phase 6: 動作確認とテスト

### 6.1 Flutter アプリの起動

```bash
cd app

# dev環境で起動
fvm flutter run --flavor dev
```

### 6.2 通常サインアップテスト

1. アプリを起動
2. "Sign Up" をタップ
3. 以下の情報を入力：
   - Name: Test User
   - Email: testuser@example.com
   - Password: password123
   - 組織コードは入力しない（デフォルト組織に自動割り当て）
4. "Sign Up" ボタンをタップ
5. **期待される動作**:
   - Firebase Authにユーザーが作成される
   - Cloud Functionが自動実行される
   - Hasuraにユーザーデータが同期される
   - Custom Claims (role, tenant_id) が設定される
   - ホーム画面に遷移し、ユーザー情報・組織情報・JWT Claimsが表示される

### 6.3 組織コード入力サインアップテスト

1. 別のメールアドレスでサインアップ
2. "I have an organization code" をONにする
3. 組織コード入力：
   - `ACME2024` または `BETA2024`
4. "Sign Up" ボタンをタップ
5. **期待される動作**:
   - 指定した組織に割り当てられる
   - ホーム画面の Organization セクションに正しい組織名が表示される

### 6.4 JWT Claims 確認

ホーム画面の "Authentication" セクションで以下を確認：
- `Role`: user
- `Tenant ID`: ユーザーの所属組織ID
- `Issued`: トークン発行時刻
- `Expires`: トークン有効期限（発行から1時間後）

### 6.5 Hasura パーミッションテスト

1. ホーム画面で表示されるデータが正しいか確認
2. GraphQL API テスト：
   - 自分の投稿のみ取得できるか
   - 他のテナントのデータは取得できないか
   - 削除済みデータは表示されないか

### 6.6 ログアウト・ログインテスト

1. ログアウトボタンをタップ
2. 同じ認証情報でログイン
3. **期待される動作**:
   - ログイン成功
   - JWT Claimsが正しく設定されている
   - 同じ組織に属している

---

## 🔧 トラブルシューティング

### Cloud Functions デプロイエラー

**エラー**: `Permission denied`
```bash
# Firebase プロジェクトの権限を確認
firebase projects:list

# 正しいプロジェクトにログインしているか確認
firebase login --reauth
```

**エラー**: `Missing required API`
- Firebase Console で Cloud Functions API を有効化してください
- https://console.firebase.google.com/project/YOUR_PROJECT/functions

### Custom Claims が設定されない

**確認事項**:
1. Cloud Functions が正常にデプロイされているか
```bash
firebase functions:log
```

2. Hasura エンドポイントが正しいか
```bash
firebase functions:config:get
```

3. Firebase Console で Function のログを確認
   - https://console.firebase.google.com/project/YOUR_PROJECT/functions/logs

### アプリが起動しない

**エラー**: `cloud_functions` パッケージが見つからない
```bash
cd app
fvm flutter pub get
```

**エラー**: Firebase 初期化エラー
- `.env.dev` ファイルが存在するか確認
- `HASURA_ENDPOINT` が正しく設定されているか確認

---

## 📝 チェックリスト

デプロイ前:
- [ ] `fvm flutter pub get` 実行済み
- [ ] `npm install` 実行済み（backend/functions/）
- [ ] `npm run build` 実行済み（backend/functions/）
- [ ] Firebase プロジェクトが選択されている（`firebase use`）
- [ ] 環境変数が設定されている（`firebase functions:config:get`）

デプロイ:
- [ ] `firebase deploy --only functions` 実行済み
- [ ] デプロイ成功メッセージを確認

テスト:
- [ ] 通常サインアップ成功
- [ ] 組織コード入力サインアップ成功
- [ ] ホーム画面でユーザー情報表示
- [ ] JWT Claims 表示（role, tenant_id）
- [ ] ログアウト・ログイン成功

---

## 🎉 Phase 6 完了後

全てのテストが成功したら：
1. `PROGRESS.md` の Phase 6 をチェック
2. `docs/troubleshooting.md` に遭遇した問題を追記（あれば）
3. `docs/authentication.md` の "Implementation Status" を更新

これで Firebase Auth + Hasura の基本的な連携が完成です！

次のステップ:
- GraphQL Code Generation & CRUD実装
- Neon DB 設定
- Cloud Run デプロイ（dev環境）
