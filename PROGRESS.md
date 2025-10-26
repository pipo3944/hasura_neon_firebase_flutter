# プロジェクト進捗管理

最終更新: 2025-10-27

## 📍 現在のフェーズ: ローカル環境での動作確認完了 ✅

次のステップ: **Firebase Auth + Neon DB 設定**

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

### ドキュメント
- [x] アーキテクチャ概要（`docs/architecture.md`）
- [x] 設計原則（`docs/design-principles.md`）
- [x] データベース設計（`docs/database-design.md`）
- [x] 認証・認可（`docs/authentication.md`）
- [x] 開発フロー（`docs/development-flow.md`）- 実際のワークフローに更新
- [x] トラブルシューティング（`docs/troubleshooting.md`）- CORS問題追記
- [x] CLAUDE.md - tenant_adminロール、実際のワークフロー反映

---

## 🚧 次にやるべきこと（優先順位順）

### 1. Firebase Auth 設定 🎯 **← 次はここ！**
- [ ] Firebase プロジェクト作成
  - [ ] dev環境用プロジェクト（`myproject-dev`）
  - [ ] prod環境用プロジェクト（`myproject-prod`）
- [ ] Authentication 有効化
  - [ ] Email/Password 認証
  - [ ] Google 認証（オプション）
- [ ] Custom Claims 設定準備
  - [ ] Cloud Functions プロジェクト作成
  - [ ] setCustomUserClaims 関数実装
- [ ] JWT Secret 設定
  - [ ] Hasura の `HASURA_GRAPHQL_JWT_SECRET` 設定
  - [ ] RS256 公開鍵設定

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

### 6. Flutter アプリ開発
- [ ] Flutter プロジェクト作成
- [ ] パッケージ追加
  - [ ] `graphql_flutter`
  - [ ] `firebase_auth`
  - [ ] `firebase_core`
- [ ] GraphQL Code Generation 設定
- [ ] 認証フロー実装
- [ ] 基本的なCRUD画面実装

---

## 📊 各環境の状態

### Local（ローカル開発環境）
- **状態**: ✅ 完全動作確認済み
- **DB**: Docker Compose Postgres
- **Hasura**: Docker Compose（`localhost:8080`）
- **マイグレーション**: 適用済み（5 migrations）
- **メタデータ**: エクスポート済み
- **シードデータ**: 投入済み（組織2件、ユーザー5件、投稿13件）
- **パーミッションテスト**: 全ロール合格

### Dev（開発環境）
- **状態**: ❌ 未構築
- **DB**: Neon（未作成）
- **Hasura**: Cloud Run（未デプロイ）
- **Firebase**: 未作成

### Prod（本番環境）
- **状態**: ❌ 未構築
- **DB**: Neon（未作成）
- **Hasura**: Cloud Run（未デプロイ）
- **Firebase**: 未作成

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

- [x] **M1: ローカル環境構築** ← 完了！
- [x] **M2: ローカル環境での動作確認** ← 完了！
- [ ] **M3: Firebase Auth + Neon DB 設定** ← 次はここ
- [ ] **M4: Dev環境デプロイ**
- [ ] **M5: Flutter アプリ初期実装**
- [ ] **M6: CI/CD構築**
- [ ] **M7: Prod環境デプロイ**

---

## 📝 メモ・TODO

### 今後検討すること
- [ ] Preview環境の構築（Neon ブランチ機能活用）
- [ ] Hasura Actions の導入（複雑なビジネスロジック用）
- [ ] リアルタイムサブスクリプションのテスト
- [ ] パフォーマンステスト・インデックス最適化
- [ ] Materialized View の活用検討

### ドキュメント追記予定
- [ ] シードデータ作成方法（`docs/development-flow.md`）
- [ ] Firebase Auth 連携手順（`docs/authentication.md`）
- [ ] Neon DB セットアップ手順（`docs/environment.md`）
- [ ] デプロイ手順詳細（`docs/deployment.md`）

---

## 🔗 クイックリンク

- [README](./README.md) - プロジェクト概要
- [CLAUDE.md](./CLAUDE.md) - Claude Code 向けコンテキスト
- [開発フロー](./docs/development-flow.md) - 実際の開発手順
- [トラブルシューティング](./docs/troubleshooting.md) - 問題解決方法
- [設計原則](./docs/design-principles.md) - 技術選定の理由

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
