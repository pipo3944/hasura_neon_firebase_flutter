# プロジェクト進捗管理

最終更新: 2025-11-16

## 📍 現在のフェーズ: Firebase Auth実装（Phase 5）完了 ✅

次のステップ: **Neon DB + Cloud Run デプロイ（Dev環境構築）**

---

## ✅ 完了済みタスク

### 環境構築
- [x] リポジトリ初期化
- [x] ドキュメント構造作成（README, docs/, CLAUDE.md）
- [x] Docker Compose セットアップ（Postgres, Hasura, pgAdmin）
- [x] Hasura CLI インストール（`~/bin/hasura`）
- [x] PATH設定（`~/.zshrc`に追加）
- [x] `.env` ファイル設定（ローカル用）
- [x] `config.yaml` 設定（Hasura CLI用）

### データベース設計
- [x] 初期マイグレーション作成
  - [x] Helper functions（`update_updated_at_column` トリガー）
  - [x] `organizations` テーブル
  - [x] `users` テーブル
  - [x] `post_status_types` テーブル（lookup）
  - [x] `posts` テーブル
- [x] 全テーブルのTrack設定
- [x] Foreign key relationships の Track

### 権限設計
- [x] ロール設計（user / tenant_admin / admin）
- [x] 全テーブルのパーミッション設定
  - [x] organizations（user, tenant_admin）
  - [x] users（user, tenant_admin）
  - [x] posts（user, tenant_admin）
  - [x] post_status_types（user, tenant_admin）
- [x] パーミッション修正（userロールの分離強化）
- [x] メタデータエクスポート（`hasura metadata export`）

### ローカル環境での動作確認・テスト
- [x] シードデータ作成
  - [x] テスト用組織（2件: Acme Corp, Beta Inc）
  - [x] テストユーザー（5件: admin, tenant_admin x2, user x2）
  - [x] テスト投稿データ（13件、ソフトデリート2件含む）
- [x] GraphQL API テスト
  - [x] Admin Secret で基本クエリ実行
  - [x] 各ロールでのパーミッション動作確認（JWTトークン使用）
  - [x] リレーション（user, organization）の動作確認
- [x] パーミッションテスト（自動テストスクリプト作成）
  - [x] user ロール: 自分のデータのみアクセス可能
  - [x] tenant_admin ロール: テナント内全データアクセス可能（削除済み含む）
  - [x] admin ロール: 全データアクセス可能
  - [x] 削除済みデータ（`deleted_at`）のフィルタ動作確認
  - [x] マルチテナント分離の確認

### Flutter開発環境
- [x] Flutter SDK インストール（fvm 3.35.7）
- [x] Firebaseプロジェクト作成（dev/prod）
- [x] Firebase設定ファイル配置
  - [x] Android: `google-services.json`（dev/prod）
  - [x] iOS: `GoogleService-Info.plist`（dev/prod）
- [x] Flutter Flavor設定
  - [x] Android: productFlavors設定（dev/prod）
  - [x] iOS: Configurations & Schemes設定
  - [x] Bundle Identifier設定（com.mizunoyusei.hasuraFlutter）
  - [x] Firebase設定ファイル自動切り替えスクリプト
- [x] iOS Deployment Target更新（15.0+）
- [x] VS Code / Cursor デバッグ設定
  - [x] `.vscode/launch.json`作成（6環境）
  - [x] `.vscode/settings.json`作成（fvmパス設定）
- [x] 実機テスト（iPhone 14）
  - [x] 開発者証明書の信頼設定
  - [x] dev環境でのアプリ起動確認

### ドキュメント
- [x] アーキテクチャ概要（`docs/architecture.md`）
- [x] 設計原則（`docs/design-principles.md`）
  - [x] Flutter Flavor採用理由
  - [x] fvm配置の決定理由
  - [x] VS Code/Cursorデバッグ設定への参照
- [x] データベース設計（`docs/database-design.md`）
- [x] 認証・認可（`docs/authentication.md`）
- [x] 開発フロー（`docs/development-flow.md`）
  - [x] Backend専用に整理（Flutterセクション分離）
  - [x] 実際のワークフローに更新
- [x] **Flutter開発環境セットアップ（`docs/flutter-setup.md`）** - 新規作成
  - [x] Firebase設定ファイル配置手順
  - [x] Android/iOS Flavor設定詳細
  - [x] VS Code/Cursorデバッグ設定
  - [x] 実機テスト手順
  - [x] GraphQL Code Generation手順
- [x] トラブルシューティング（`docs/troubleshooting.md`）
  - [x] CORS問題追記
  - [x] Flutter関連エラー7件追加
    - iOS Deployment Target エラー
    - Ruby エンコーディングエラー
    - GoogleService-Info.plist Not Found
    - Bundle ID Registration Failed
    - Certificate Trust Error
    - Scheme Name Mismatch
    - VS Code デバッグパスエラー
- [x] CLAUDE.md
  - [x] tenant_adminロール、実際のワークフロー反映
  - [x] ドキュメントナビゲーション整理（Backend/Frontend/General分類）
- [x] README.md - Flutter開発環境セットアップへのリンク追加

---

## 🚧 次にやるべきこと（優先順位順）

### 1. Firebase Auth 実装 🎯 **← 進行中！**
- [x] Firebase プロジェクト作成
  - [x] dev環境用プロジェクト
  - [x] prod環境用プロジェクト
- [x] **Phase 1: データベース準備** ✅
  - [x] `organizations` テーブルに `code` カラム追加（マイグレーション作成）
  - [x] シードデータ更新（組織コード: ACME2024, BETA2024）
  - [x] ドキュメント更新（`database-design.md`）
- [x] **Phase 2: Backend - Hasura JWT設定** ✅
  - [x] JWT Secret を Firebase RS256 に更新（`backend/.env`）
  - [x] ドキュメント更新（`authentication.md`）
  - [x] Docker Compose 再起動
- [x] **Phase 3: Flutter - 依存パッケージとプロジェクト設定** ✅
  - [x] `pubspec.yaml` 更新（firebase_auth, graphql_flutter等）
  - [x] パッケージ名/Bundle ID 統一（`com.mizunoyusei.hasuraFlutter`）
  - [x] `firebase_options.dart` Flavor対応
  - [x] 環境変数ファイル作成（`.env.dev`, `.env.prod`）
  - [x] ドキュメント更新（`flutter-setup.md`）
  - [x] パッケージインストール
- [x] **Phase 4: Flutter - 認証UI実装** ✅
  - [x] プロジェクト構造作成（`config/`, `services/`, `screens/`, `providers/`, `graphql/`）
  - [x] Email/Password 認証実装（`auth_service.dart`）
  - [x] ログイン/サインアップ画面（組織コード入力対応）
  - [x] GraphQL クライアント設定（Authorization ヘッダー、`graphql_config.dart`）
  - [x] Token 自動リフレッシュ（`authStateProvider`, `idTokenChanges`）
  - [x] ユーザー同期（Hasura、`UpsertUser` mutation）
  - [x] GraphQLクエリ定義（`users.graphql`, `organizations.graphql`）
  - [x] ドキュメント更新（`authentication.md`）
- [x] **Phase 5: Cloud Functions - Custom Claims設定** ✅
  - [x] Cloud Functions プロジェクト作成（`backend/functions/`）
  - [x] setCustomUserClaims 関数実装（`index.ts`）
    - [x] `setCustomClaimsOnCreate`: ユーザー作成時のトリガー
    - [x] `refreshCustomClaims`: 手動リフレッシュ用callable関数
  - [x] Flutter連携サービス実装（`cloud_functions_service.dart`）
  - [x] 依存パッケージ追加（`cloud_functions: ^5.1.0`）
  - [x] ドキュメント作成（`backend/functions/README.md`）
  - [x] Firebase プロジェクト設定（`firebase init`, `firebase.json`）
  - [x] デプロイ（dev環境） ✅
    - [x] Node.js 20 ランタイムにアップグレード
    - [x] ESLint問題解決（predeploy から除外）
    - [x] クリーンアップポリシー設定（30日保持）
- [x] **Phase 6: 実機での初期動作確認** ✅（部分的）
  - [x] iOS実機でのアプリ起動確認（iPhone 14）
    - [x] CocoaPods依存関係の解決
  - [x] 実機接続テスト
    - [x] ローカルネットワーク経由でのHasura接続確認
    - [x] CORS設定の動作確認
  - [x] Firebase Auth サインアップ動作確認
  - [x] マイグレーション適用（`add_org_code_column`）
    - [x] UNIQUE制約エラー修正（段階的適用方式に変更）
  - [⚠️] JWT検証エラー（既知の問題）
    - Cloud FunctionsがローカルHasuraにアクセスできないため
    - 次のフェーズ（Cloud Run デプロイ）で解決予定

### 2. Neon DB + Cloud Run デプロイ（dev環境構築） 🎯 **← 次はここ！**

#### Step 1: Neon DB セットアップ ✅
- [x] Neon アカウント作成
- [x] プロジェクト作成（hasura-flutter）
- [x] dev ブランチ確認（自動作成: production, development）
- [x] 接続文字列取得（DATABASE_URL - Direct connection）
- [x] ローカルマイグレーションを Neon に適用
  - [x] マイグレーション適用スクリプト作成（`apply-migrations-to-neon.sh`）
  - [x] 6件のマイグレーション適用完了
  - [x] `post_status_types` データ手動投入（文字エンコーディング対応）
  - [x] シード適用スクリプト作成（`apply-seed-to-neon.sh`）
  - [x] テストデータ投入完了（組織2件、ユーザー5件、投稿13件）
- [x] ドキュメント作成（`docs/neon-setup.md`）

#### Step 2: Cloud Run Hasura デプロイ
- [ ] Google Cloud プロジェクト確認/作成
- [ ] Secret Manager 設定
  - [ ] `HASURA_GRAPHQL_DATABASE_URL`（Neon接続文字列）
  - [ ] `HASURA_GRAPHQL_ADMIN_SECRET`（新規生成）
  - [ ] `HASURA_GRAPHQL_JWT_SECRET`（Firebase RS256設定）
- [ ] Cloud Run サービス作成
  - [ ] Hasura イメージ指定（`hasura/graphql-engine:v2.x`）
  - [ ] 環境変数・Secret設定
  - [ ] 公開アクセス許可
- [ ] デプロイ & ヘルスチェック

#### Step 3: Cloud Functions 設定更新
- [ ] Cloud Functions 環境変数更新
  - [ ] `hasura.endpoint` → Cloud Run URL
  - [ ] `hasura.admin_secret` → 新規生成したシークレット
- [ ] 再デプロイ
  - [ ] `firebase deploy --only functions`

#### Step 4: Flutter アプリ設定更新
- [ ] `app/.env.dev` 更新
  - [ ] `HASURA_ENDPOINT` → Cloud Run URL
- [ ] アプリ再起動・動作確認

#### Step 5: 完全なE2Eテスト
- [ ] サインアップテスト（組織コードなし）
- [ ] サインアップテスト（組織コード入力）
- [ ] Custom Claims設定確認（Cloud Functions → Hasura）
- [ ] JWT検証確認（Flutter → Hasura）
- [ ] ユーザー情報取得（GraphQL クエリ）
- [ ] パーミッションテスト
  - [ ] user ロール: 自分のデータのみ
  - [ ] tenant_admin ロール: テナント内全データ

### 3. GraphQL Code Generation & 基本的なCRUD実装
- [ ] GraphQL クエリ定義（`.graphql` ファイル）
  - [ ] ユーザー情報取得
  - [ ] 投稿一覧取得
  - [ ] 投稿作成・更新・削除
- [ ] Code Generation 実行
- [ ] 基本的な画面実装
  - [ ] ホーム画面（投稿一覧）
  - [ ] 投稿詳細画面
  - [ ] 投稿作成・編集画面

### 4. CI/CD パイプライン構築
- [ ] GitHub Actions ワークフロー作成
  - [ ] dev 自動デプロイ
  - [ ] スモークテスト
- [ ] prod 手動デプロイワークフロー

### 5. Prod環境構築
- [ ] Neon prod ブランチ作成（main）
- [ ] Cloud Run prod サービス作成
- [ ] Cloud Functions prod デプロイ
- [ ] Flutter prod設定


---

## 📊 各環境の状態

### Local（ローカル開発環境）
- **状態**: ✅ 完全動作確認済み（DB開発用）
- **Backend**:
  - **DB**: Docker Compose Postgres
  - **Hasura**: Docker Compose（`localhost:8080`）
  - **マイグレーション**: 適用済み（6 migrations - `add_org_code_column`含む）
  - **メタデータ**: エクスポート済み
  - **シードデータ**: 投入済み（組織2件、ユーザー5件、投稿13件）
  - **パーミッションテスト**: 全ロール合格
- **Frontend**:
  - **Flutter**: 3.35.7（fvm管理）
  - **Firebase**: dev/prodプロジェクト作成済み
  - **Flavor**: dev/prod設定完了（Android/iOS）
  - **デバッグ環境**: VS Code/Cursor設定完了
  - **実機テスト**: 動作確認済み
  - **認証**: Firebase Auth 実装済み、サインアップ動作確認済み
  - **Note**: ローカル環境はDB開発用。アプリテストは次フェーズでDev環境を使用

### Dev（開発環境）
- **状態**: ⚠️ 部分的構築（Neon DB + Cloud Functions）
- **DB**: Neon ✅
  - プロジェクト: `hasura-flutter`
  - ブランチ: `development` (AWS Singapore)
  - マイグレーション: 適用済み（6件）
  - データ: 組織2件、ユーザー5件、投稿13件
- **Hasura**: Cloud Run（未デプロイ）← 次のステップ
- **Firebase**:
  - **Auth**: プロジェクト作成済み（hasura-flutter-dev）
  - **Cloud Functions**: デプロイ済み ✅
    - `setCustomClaimsOnCreate` - onCreate trigger
    - `refreshCustomClaims` - callable function
    - ⚠️ Cloud Run Hasuraに接続後に動作確認予定

### Prod（本番環境）
- **状態**: ❌ 未構築
- **DB**: Neon（未作成）
- **Hasura**: Cloud Run（未デプロイ）
- **Firebase**: プロジェクト作成済み（hasura-flutter-prod）、未実装

---

## ⚠️ 既知の問題・制約

### CLI Console CORS エラー
- **問題**: `hasura console` (localhost:9695) が CORS エラーで動作しない
- **回避策**: `localhost:8080/console` + 手動マイグレーション + `hasura metadata export`
- **影響**: マイグレーションファイルを手動作成する必要がある
- **状態**: 回避策で運用中、問題なし

### UUID v7 vs UUID v4
- **現状**: `gen_random_uuid()` (UUID v4) を使用
- **理想**: UUID v7 で時系列ソート可能に
- **対応**: 将来的に `pg_uuidv7` 拡張または Dart 側で生成に移行予定

### マイグレーションファイルの文字エンコーディング
- **問題**: `post_status_types` マイグレーションの日本語ラベルが文字化け
- **影響**: マイグレーション適用時にINSERTが失敗する
- **回避策**: 手動でデータ投入（英語ラベル使用）
- **対応**: マイグレーションファイルを英語化または UTF-8 BOM なしで保存

---

## 🎯 マイルストーン

- [x] **M1: ローカル環境構築（Backend）** ← 完了！
- [x] **M2: ローカル環境での動作確認（Backend）** ← 完了！
- [x] **M3: Flutter開発環境セットアップ** ← 完了！
- [ ] **M4: Firebase Auth実装 + Hasura連携** ← 次はここ
- [ ] **M5: 基本的なCRUD実装**
- [ ] **M6: Neon DB設定 + Dev環境デプロイ**
- [ ] **M7: CI/CD構築**
- [ ] **M8: Prod環境デプロイ**

---

## 📝 メモ・TODO

### 今後検討すること
- [ ] Preview環境の構築（Neon ブランチ機能活用）
- [ ] Hasura Actions の導入（複雑なビジネスロジック用）
- [ ] リアルタイムサブスクリプションのテスト
- [ ] パフォーマンステスト・インデックス最適化
- [ ] Materialized View の活用検討

### ドキュメント追記予定
- [ ] Firebase Auth 実装詳細（`docs/authentication.md`）
- [ ] Neon DB セットアップ手順（`docs/environment.md`）
- [ ] デプロイ手順詳細（`docs/deployment.md`）

---

## 🔗 クイックリンク

### プロジェクト全体
- [README](./README.md) - プロジェクト概要
- [CLAUDE.md](./CLAUDE.md) - Claude Code 向けコンテキスト
- [設計原則](./docs/design-principles.md) - 技術選定の理由

### Backend開発
- [開発フロー](./docs/development-flow.md) - Hasura開発手順・マイグレーション管理

### Frontend開発
- [Flutter環境セットアップ](./docs/flutter-setup.md) - Firebase/Flavor設定・デバッグ環境

### トラブルシューティング
- [トラブルシューティング](./docs/troubleshooting.md) - Backend/Frontend共通の問題解決方法

---

## 📌 新しいスレッドで作業を再開する際のチェックリスト

新しい Claude Code セッションを開始する際は、以下を確認してください：

1. [ ] `PROGRESS.md` を読んで現在の状態を把握
2. [ ] Docker が起動しているか確認（`docker ps`）
3. [ ] Hasura が起動しているか確認（`http://localhost:8080/healthz`）
4. [ ] 最新の main ブランチを pull（`git pull origin main`）
5. [ ] 必要に応じてマイグレーション適用（`hasura migrate apply`）
6. [ ] 「次にやるべきこと」セクションから作業開始

---

**このファイルは作業の進捗に応じて随時更新してください。**
