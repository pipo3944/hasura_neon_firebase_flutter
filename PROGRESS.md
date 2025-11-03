# プロジェクト進捗管理

最終更新: 2025-11-03

## 📍 現在のフェーズ: Flutter開発環境セットアップ完了 ✅

次のステップ: **Firebase Auth実装 + Hasura連携**

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

### 1. Firebase Auth 実装 🎯 **← 次はここ！**
- [x] Firebase プロジェクト作成
  - [x] dev環境用プロジェクト
  - [x] prod環境用プロジェクト
- [ ] Flutter での Firebase Auth 初期化
  - [ ] `firebase_core` パッケージ設定
  - [ ] `firebase_auth` パッケージ設定
  - [ ] Flavor別の初期化処理
- [ ] 認証フロー実装
  - [ ] Email/Password 認証
  - [ ] ログイン/ログアウト画面
  - [ ] ユーザー登録画面
- [ ] Hasura との連携
  - [ ] ID Token の取得
  - [ ] GraphQL クライアント設定（Authorization ヘッダー）
  - [ ] Token 自動リフレッシュ
- [ ] Custom Claims 設定（後回しも可）
  - [ ] Cloud Functions プロジェクト作成
  - [ ] setCustomUserClaims 関数実装
  - [ ] role, tenant_id の設定

### 2. GraphQL Code Generation & 基本的なCRUD実装
- [ ] GraphQL クエリ定義（`.graphql` ファイル）
  - [ ] ユーザー情報取得
  - [ ] 投稿一覧取得
  - [ ] 投稿作成・更新・削除
- [ ] Code Generation 実行
- [ ] 基本的な画面実装
  - [ ] ホーム画面（投稿一覧）
  - [ ] 投稿詳細画面
  - [ ] 投稿作成・編集画面

### 3. Neon DB 設定
- [ ] Neon アカウント作成
- [ ] プロジェクト作成
  - [ ] dev ブランチ作成
  - [ ] prod ブランチ作成（main）
- [ ] 接続文字列取得
- [ ] ローカルマイグレーションを Neon に適用
  - [ ] dev ブランチに `hasura migrate apply`
  - [ ] メタデータ適用

### 4. Cloud Run デプロイ（dev環境）
- [ ] Cloud Run サービス作成
- [ ] Secret Manager 設定
  - [ ] `DATABASE_URL`
  - [ ] `HASURA_GRAPHQL_ADMIN_SECRET`
  - [ ] `HASURA_GRAPHQL_JWT_SECRET`
- [ ] デプロイ & 動作確認

### 5. CI/CD パイプライン構築
- [ ] GitHub Actions ワークフロー作成
  - [ ] dev 自動デプロイ
  - [ ] スモークテスト
- [ ] prod 手動デプロイワークフロー


---

## 📊 各環境の状態

### Local（ローカル開発環境）
- **状態**: ✅ 完全動作確認済み
- **Backend**:
  - **DB**: Docker Compose Postgres
  - **Hasura**: Docker Compose（`localhost:8080`）
  - **マイグレーション**: 適用済み（5 migrations）
  - **メタデータ**: エクスポート済み
  - **シードデータ**: 投入済み（組織2件、ユーザー5件、投稿13件）
  - **パーミッションテスト**: 全ロール合格
- **Frontend**:
  - **Flutter**: 3.35.7（fvm管理）
  - **Firebase**: dev/prodプロジェクト作成済み
  - **Flavor**: dev/prod設定完了（Android/iOS）
  - **デバッグ環境**: VS Code/Cursor設定完了
  - **実機テスト**: iPhone 14 で動作確認済み

### Dev（開発環境）
- **状態**: ❌ 未構築
- **DB**: Neon（未作成）
- **Hasura**: Cloud Run（未デプロイ）
- **Firebase**: プロジェクト作成済み、Auth未実装

### Prod（本番環境）
- **状態**: ❌ 未構築
- **DB**: Neon（未作成）
- **Hasura**: Cloud Run（未デプロイ）
- **Firebase**: プロジェクト作成済み、Auth未実装

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
