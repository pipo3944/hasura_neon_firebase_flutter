# Firebase Cloud Functions

Firebase Auth用のCustom Claims設定関数です。

## セットアップ

### 1. 依存パッケージのインストール

```bash
cd backend/functions
npm install
```

### 2. 環境変数の設定

```bash
# .env.yaml を作成（ローカルテスト用）
cp .env.example .env.yaml

# 実際の値を設定
# - HASURA_GRAPHQL_ENDPOINT: Hasuraエンドポイント
# - HASURA_GRAPHQL_ADMIN_SECRET: Hasura Admin Secret
```

### 3. ビルド

```bash
npm run build
```

## デプロイ

### Dev環境へのデプロイ

```bash
# 環境変数を設定
firebase functions:config:set \
  hasura.endpoint="https://hasura-dev-xxxxx.run.app/v1/graphql" \
  hasura.admin_secret="your-dev-admin-secret" \
  --project hasura-flutter-dev

# デプロイ
firebase deploy --only functions --project hasura-flutter-dev
```

### Prod環境へのデプロイ

```bash
# 環境変数を設定
firebase functions:config:set \
  hasura.endpoint="https://hasura-prod-xxxxx.run.app/v1/graphql" \
  hasura.admin_secret="your-prod-admin-secret" \
  --project hasura-flutter-prod

# デプロイ
firebase deploy --only functions --project hasura-flutter-prod
```

## 関数一覧

### `setCustomClaimsOnCreate`

**トリガー**: Firebase Auth - ユーザー作成時

**動作**:
1. 新しいユーザーがFirebase Authで作成される
2. HasuraからユーザーデータをAdmin Secretで取得
3. `role`と`tenant_id`をCustom Claimsに設定

**環境変数**:
- `HASURA_GRAPHQL_ENDPOINT`: Hasuraエンドポイント
- `HASURA_GRAPHQL_ADMIN_SECRET`: Hasura Admin Secret

### `refreshCustomClaims`

**トリガー**: Callable Function（クライアントから呼び出し）

**動作**:
1. クライアントから呼び出される（ロール変更後など）
2. HasuraからユーザーデータをAdmin Secretで取得
3. Custom Claimsを更新

**使用例（Flutter）**:
```dart
import 'package:cloud_functions/cloud_functions.dart';

final functions = FirebaseFunctions.instance;
final callable = functions.httpsCallable('refreshCustomClaims');

try {
  final result = await callable.call();
  print('Claims refreshed: ${result.data}');
} catch (e) {
  print('Error: $e');
}
```

## ローカルエミュレータでのテスト

```bash
# Firebase Emulatorを起動
firebase emulators:start

# 別のターミナルで関数をテスト
firebase functions:shell
```

## トラブルシューティング

### 関数のログを確認

```bash
# Dev環境
firebase functions:log --project hasura-flutter-dev

# Prod環境
firebase functions:log --project hasura-flutter-prod
```

### ローカルでビルドエラーが出る場合

```bash
rm -rf node_modules package-lock.json
npm install
npm run build
```
