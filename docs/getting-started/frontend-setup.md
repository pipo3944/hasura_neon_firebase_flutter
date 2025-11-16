# Flutter 開発環境のセットアップ

このドキュメントでは、Flutter アプリの開発環境セットアップ手順を説明します。

## 前提条件

- Flutter SDK（fvm推奨）
- Android Studio（Android開発用）
- Xcode（iOS開発用、macOSのみ）
- Firebase プロジェクト（dev/prod）

---

## 初回セットアップ

### 1. Flutter SDK のインストール（fvm使用）

このプロジェクトでは、プロジェクトルートに `.fvm` を配置して Flutter バージョンを管理します。

```bash
# fvm がインストールされていない場合
brew install fvm

# プロジェクトルートで Flutter バージョンを指定
cd /path/to/hasura_flutter
fvm use 3.35.7 --force

# Flutter コマンドは fvm 経由で実行
fvm flutter --version
```

**fvm 配置の理由**: [設計原則](../reference/design-principles.md) を参照

---

## 依存パッケージ一覧

このプロジェクトで使用する主要なパッケージ：

### 本番依存（dependencies）
- **Firebase**
  - `firebase_core: ^4.2.0` - Firebase初期化
  - `firebase_auth: ^5.3.4` - Firebase認証

- **GraphQL**
  - `graphql_flutter: ^5.1.2` - GraphQLクライアント
  - `gql: ^1.0.0` - GraphQLドキュメントパーサー

- **環境変数**
  - `flutter_dotenv: ^5.2.1` - .env ファイル管理

- **UUID生成**
  - `uuid: ^4.5.1` - UUID v7 生成用

- **ローカルストレージ**
  - `shared_preferences: ^2.3.4` - Key-Value ストレージ

- **ルーティング**
  - `go_router: ^14.6.2` - 宣言的ルーティング

- **状態管理**
  - `flutter_riverpod: ^2.6.1` - 状態管理ライブラリ

### 開発依存（dev_dependencies）
- **GraphQL Code Generation**
  - `build_runner: ^2.4.13` - コード生成ツール
  - `graphql_codegen: ^0.14.0` - GraphQL型生成

- **Linter**
  - `flutter_lints: ^5.0.0` - 推奨Lint設定

**インストール**:
```bash
cd app
fvm flutter pub get
```

---

## Firebase設定ファイルの配置

### Firebase プロジェクトから設定ファイルをダウンロード

Firebase Console で dev/prod 用の2つのプロジェクトを作成し、設定ファイルをダウンロードします。

1. **Firebase Console** (https://console.firebase.google.com/) にアクセス
2. Dev プロジェクトを選択
3. プロジェクト設定 → アプリを追加:
   - Android: `google-services.json` をダウンロード
   - iOS: `GoogleService-Info.plist` をダウンロード
4. Prod プロジェクトでも同様に実施

### 配置場所

ダウンロードした設定ファイルを以下のディレクトリに配置:

**Android**:
- Dev: `app/android/app/src/dev/google-services.json`
- Prod: `app/android/app/src/prod/google-services.json`

**iOS**:
- Dev: `app/ios/Runner/Dev/GoogleService-Info.plist`
- Prod: `app/ios/Runner/Prod/GoogleService-Info.plist`

**重要**: これらのファイルは **gitにコミット**します（Firebase API Key は公開情報として設計されており、機密性は低い）。

---

## Flutter Flavor の設定

Flutter Flavor を使用することで、dev/prod 環境を同時にインストールでき、異なるFirebaseプロジェクトに接続できます。

**採用理由**: [設計原則](../reference/design-principles.md) を参照

---

### Android Flavor 設定

#### 1. build.gradle.kts の編集

`app/android/app/build.gradle.kts` に以下を追加:

```kotlin
android {
    namespace = "com.mizunoyusei.hasuraFlutter"

    defaultConfig {
        applicationId = "com.mizunoyusei.hasuraFlutter"  // キャメルケースで統一
        // ...
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Hasura Flutter (Dev)")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "Hasura Flutter")
        }
    }
}
```

**ポイント**:
- `namespace` と `applicationId` は `com.example` 以外を使用（Appleの予約語のため）
- `applicationIdSuffix` により、dev/prod が別アプリとして認識される
- `resValue` でアプリ名を動的に設定

#### 2. AndroidManifest.xml の編集

`app/android/app/src/main/AndroidManifest.xml` で動的なアプリ名を使用:

```xml
<application
    android:label="@string/app_name"
    ...>
```

#### 3. MainActivity のパッケージ確認

`app/android/app/src/main/kotlin/com/yourcompany/hasura_flutter/MainActivity.kt` のパッケージ宣言が `namespace` と一致していることを確認:

```kotlin
package com.yourcompany.hasura_flutter

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}
```

---

### iOS Flavor 設定

#### 1. Configurations の作成

Xcode で `app/ios/Runner.xcworkspace` を開き、プロジェクト設定 → Info タブ:

1. 既存の Configuration を複製:
   - `Debug` を複製 → `Debug-dev`
   - `Debug` を複製 → `Debug-prod`
   - `Release` を複製 → `Release-dev`
   - `Release` を複製 → `Release-prod`
   - `Profile` を複製 → `Profile-dev`
   - `Profile` を複製 → `Profile-prod`

2. 各 Configuration で Bundle Identifier を設定:
   - Build Settings → Product Bundle Identifier:
     - `Debug-dev`, `Profile-dev`, `Release-dev`: `com.yourcompany.hasuraFlutter.dev`
     - `Debug-prod`, `Profile-prod`, `Release-prod`: `com.yourcompany.hasuraFlutter`

**注意**: `com.example` は Apple によって予約されているため使用不可。

---

#### 2. Schemes の作成

Product → Scheme → Manage Schemes:

1. 新しい Scheme を作成: `dev`
   - Run: `Debug-dev`
   - Test: `Debug-dev`
   - Profile: `Profile-dev`
   - Archive: `Release-dev`

2. 新しい Scheme を作成: `prod`
   - Run: `Debug-prod`
   - Test: `Debug-prod`
   - Profile: `Profile-prod`
   - Archive: `Release-prod`

3. 各 Scheme で「Shared」にチェックを入れる（Git管理のため）

**ポイント**: Scheme 名は Flutter の Flavor 名（`dev`, `prod`）と一致させる。

---

#### 3. Firebase設定ファイルの自動切り替え

Build Phases → + → New Run Script Phase を追加し、**"Compile Sources" の前に配置**:

```bash
# Firebase GoogleService-Info.plist switcher
PLIST_DESTINATION="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"
RUNNER_DIR="${SRCROOT}/Runner"
RUNNER_PLIST="${RUNNER_DIR}/GoogleService-Info.plist"

if [[ "${CONFIGURATION}" == *"dev"* ]] || [[ "${CONFIGURATION}" == "Debug" ]] || [[ "${CONFIGURATION}" == "Profile" ]]; then
  echo "Using Dev Firebase configuration"
  cp "${RUNNER_DIR}/Dev/GoogleService-Info.plist" "${RUNNER_PLIST}"
  cp "${RUNNER_DIR}/Dev/GoogleService-Info.plist" "${PLIST_DESTINATION}" 2>/dev/null || true
elif [[ "${CONFIGURATION}" == *"prod"* ]] || [[ "${CONFIGURATION}" == "Release" ]]; then
  echo "Using Prod Firebase configuration"
  cp "${RUNNER_DIR}/Prod/GoogleService-Info.plist" "${RUNNER_PLIST}"
  cp "${RUNNER_DIR}/Prod/GoogleService-Info.plist" "${PLIST_DESTINATION}" 2>/dev/null || true
else
  echo "⚠️ Unknown configuration: ${CONFIGURATION}"
  cp "${RUNNER_DIR}/Dev/GoogleService-Info.plist" "${RUNNER_PLIST}"
fi
echo "✅ Copied GoogleService-Info.plist for ${CONFIGURATION}"
```

**このスクリプトの役割**:
- Build Configuration に応じて適切な Firebase 設定ファイルをコピー
- 2箇所にコピー（Runner/ と build output）することでXcodeが確実にファイルを見つけられる

---

#### 4. Deployment Target の設定

Firebase Core は iOS 15.0 以上を要求します。`app/ios/Podfile` を編集:

```ruby
# Uncomment this line to define a global platform for your project
platform :ios, '15.0'

# ...

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
```

その後、CocoaPods を更新:

```bash
cd app/ios
export LANG=en_US.UTF-8  # Ruby エンコーディングエラー回避
pod install
```

**Ruby エラーが出る場合**: [troubleshooting.md の「Ruby エンコーディングエラー」](troubleshooting.md#ruby-エンコーディングエラーpod-install時) を参照

---

## ビルド・実行

### コマンドラインか���実行

```bash
cd app

# Dev環境（デバッグモード）
fvm flutter run --flavor dev

# Dev環境（実機で確認、パフォーマンス測定）
fvm flutter run --flavor dev --profile

# Prod環境（リリースモード）
fvm flutter run --flavor prod --release
```

### デバイスの選択

```bash
# 接続されているデバイスを確認
fvm flutter devices

# 特定のデバイスで実行
fvm flutter run --flavor dev -d <device-id>
```

---

## VS Code / Cursor からデバッグ実行

GUIから環境（dev/prod）とモード（Debug/Profile/Release）を選択してデバッグ実行できます。

### 設定ファイルの作成

#### 1. `.vscode/launch.json`

プロジェクトルートに作成:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter Dev (Debug)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "debug",
      "args": ["--flavor", "dev"],
      "program": "lib/main.dart",
      "cwd": "app"
    },
    {
      "name": "Flutter Dev (Profile)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "profile",
      "args": ["--flavor", "dev"],
      "program": "lib/main.dart",
      "cwd": "app"
    },
    {
      "name": "Flutter Dev (Release)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "release",
      "args": ["--flavor", "dev"],
      "program": "lib/main.dart",
      "cwd": "app"
    },
    {
      "name": "Flutter Prod (Debug)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "debug",
      "args": ["--flavor", "prod"],
      "program": "lib/main.dart",
      "cwd": "app"
    },
    {
      "name": "Flutter Prod (Profile)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "profile",
      "args": ["--flavor", "prod"],
      "program": "lib/main.dart",
      "cwd": "app"
    },
    {
      "name": "Flutter Prod (Release)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "release",
      "args": ["--flavor", "prod"],
      "program": "lib/main.dart",
      "cwd": "app"
    }
  ]
}
```

**ポイント**:
- `"cwd": "app"` で Flutter プロジェクトのディレクトリを指定
- `"program": "lib/main.dart"` は `cwd` からの相対パス
- `"args": ["--flavor", "dev"]` で環境を指定

#### 2. `.vscode/settings.json`

プロジェクトルートに作成:

```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  "search.exclude": {
    "**/.fvm": true
  },
  "files.watcherExclude": {
    "**/.fvm": true
  }
}
```

**ポイント**:
- `"dart.flutterSdkPath"` でプロジェクトルートの `.fvm` を参照
- `.fvm` を検索対象から除外してパフォーマンス向上

---

### デバッグの実行方法

1. VS Code / Cursor の左サイドバーから「Run and Debug」（再生アイコン）を開く
2. ドロップダウンから実行したい設定を選択:
   - `Flutter Dev (Debug)`: dev環境でデバッグ実行（Hot Reload対応）
   - `Flutter Dev (Profile)`: dev環境でパフォーマンス測定
   - `Flutter Dev (Release)`: dev環境で本番モード実行
   - `Flutter Prod (*)`: prod環境で実行
3. **F5** キーまたは再生ボタンでデバッグ開始

**Hot Reload**:
- デバッグモード実行中に、コードを変更して保存すると自動的にHot Reload
- または、デバッグコンソールで `r` キーを押す

**Hot Restart**:
- アプリを再起動: デバッグコンソールで `R` キー

---

## 実機テスト

### iOS 実機テスト

#### 1. Apple Developer アカウント

無料の個人アカウントでもOK（署名期間が7日間）。

#### 2. Signing & Capabilities の設定

Xcode で:
1. Runner プロジェクトを選択
2. Signing & Capabilities タブ
3. Team を選択（Apple IDでログイン）
4. 各 Configuration で Bundle Identifier が一意であることを確認

#### 3. iPhone での証明書信頼

初回実行時、iPhone で以下の操作が必要:

1. iPhone で「設定」→「一般」→「VPNとデバイス管理」
2. 開発者アプリのセクションで自分のApple IDを選択
3. 「信頼」をタップ

詳細: [troubleshooting.md の「Certificate Trust Error」](troubleshooting.md#certificate-trust-error実機テスト時)

---

### Android 実機テスト

#### 1. 開発者オプションの有効化

Android デバイスで:
1. 設定 → デバイス情報 → ビルド番号を7回タップ
2. 開発者オプション → USBデバッグを有効化

#### 2. デバイスの接続確認

```bash
adb devices
```

デバイスが表示されない場合は、USBドライバのインストールが必要な場合があります。

---

## GraphQL Code Generation

Flutter アプリから Hasura API を型安全に呼び出すため、GraphQL コード生成を使用します。

### 1. パッケージのインストール

`app/pubspec.yaml` に追加:

```yaml
dependencies:
  graphql_flutter: ^5.1.2

dev_dependencies:
  build_runner: ^2.4.6
  graphql_codegen: ^0.13.0
```

```bash
cd app
fvm flutter pub get
```

---

### 2. .graphql ファイルの作成

`app/graphql/` ディレクトリに GraphQL クエリ・ミューテーションを定義:

`app/graphql/posts.graphql`:
```graphql
query GetPosts($tenantId: uuid!) {
  posts(
    where: {
      tenant_id: { _eq: $tenantId }
      deleted_at: { _is_null: true }
    }
    order_by: { created_at: desc }
  ) {
    id
    title
    content
    created_at
    user {
      id
      name
    }
  }
}

mutation CreatePost($tenantId: uuid!, $title: String!, $content: String!) {
  insert_posts_one(
    object: {
      tenant_id: $tenantId
      title: $title
      content: $content
      status: "draft"
    }
  ) {
    id
    title
  }
}
```

---

### 3. コード生成の実行

```bash
cd app
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

生成されるファイル:
```
app/lib/generated/
├── posts.graphql.dart
└── ...
```

**自動生成されるもの**:
- 型安全なクエリ関数
- Variables の型定義
- レスポンスの型定義

---

### 4. Flutter アプリでの使用例

```dart
import 'package:app/generated/posts.graphql.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// GraphQL クライアントの初期化
final httpLink = HttpLink('https://hasura-dev-xxx.run.app/v1/graphql');

final authLink = AuthLink(
  getToken: () async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return 'Bearer $token';
  },
);

final link = authLink.concat(httpLink);

final client = GraphQLClient(
  cache: GraphQLCache(),
  link: link,
);

// クエリ実行
final result = await client.query$GetPosts(
  Options$Query$GetPosts(
    variables: Variables$Query$GetPosts(
      tenantId: currentTenantId,
    ),
  ),
);

if (result.hasException) {
  print('Error: ${result.exception}');
  return;
}

final posts = result.parsedData?.posts ?? [];
print('Posts count: ${posts.length}');
```

---

## 環境変数の管理

### .env ファイルの使用（オプション）

開発環境ごとに異なるエンドポイントを管理する場合:

`app/.env.dev`:
```
HASURA_ENDPOINT=https://hasura-dev-xxx.run.app/v1/graphql
```

`app/.env.prod`:
```
HASURA_ENDPOINT=https://hasura-prod-xxx.run.app/v1/graphql
```

**flutter_dotenv** パッケージで読み込み:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

await dotenv.load(fileName: ".env.dev");
final endpoint = dotenv.env['HASURA_ENDPOINT'];
```

または **--dart-define** で実行時に指定:

```bash
fvm flutter run --flavor dev --dart-define=HASURA_ENDPOINT=https://...
```

---

## 確認ポイント

セットアップが完了したら、以下を確認:

- [ ] Dev/Prod アプリが同時にインストールされる
- [ ] ホーム画面で「Hasura Flutter (Dev)」と「Hasura Flutter」が区別できる
- [ ] それぞれ異なるFirebaseプロジェクトに接続される
- [ ] VS Code / Cursor から環境を切り替えてデバッグ実行できる
- [ ] Hot Reload が動作する
- [ ] GraphQL コード生成が成功する

---

## トラブルシューティング

よくあるエラーと解決策は [troubleshooting.md の「Flutter アプリ関連」](troubleshooting.md#flutter-アプリ関連) を参照してください。

特に以下は頻出:
- [iOS Deployment Target エラー](troubleshooting.md#ios-deployment-target-エラー)
- [GoogleService-Info.plist Not Found](troubleshooting.md#googleservice-infoplist-not-foundios)
- [Bundle ID Registration Failed](troubleshooting.md#bundle-id-registration-failedios)
- [Certificate Trust Error](troubleshooting.md#certificate-trust-error実機テスト時)

---

## 次のステップ

Flutter 環境のセットアップが完了したら:

1. [authentication.md](authentication.md) で Firebase Auth の実装方法を確認
2. [development-flow.md](development-flow.md) で Hasura との連携フローを理解
3. 実際に機能を実装開始

---

## 参考リンク

- [Flutter公式ドキュメント](https://docs.flutter.dev/)
- [FlutterFire公式ドキュメント](https://firebase.flutter.dev/)
- [graphql_flutter](https://pub.dev/packages/graphql_flutter)
- [fvm（Flutter Version Manager）](https://fvm.app/)
