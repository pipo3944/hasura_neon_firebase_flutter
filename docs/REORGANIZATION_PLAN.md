# ドキュメント整理計画

## 現状分析

### 現在のドキュメント構成

```
docs/
├── architecture.md               # アーキテクチャ全体（図中心）
├── authentication.md            # 認証設計（詳細すぎる）
├── database-design.md           # DB設計（ER図、スキーマ）
├── deployment.md                # CI/CD、デプロイ
├── design-principles.md         # 設計原則、技術選定理由
├── development-flow.md          # Backend開発フロー（マイグレーション手順）
├── development/
│   └── documentation-guide.md   # ドキュメントガイドライン
├── environment.md               # 環境構成（local/dev/prod）
├── flutter-setup.md             # Flutter環境構築
├── future-enhancements.md       # 将来の拡張アイデア
├── neon-setup.md                # Neon初期セットアップ
└── troubleshooting.md           # トラブルシューティング
```

### 問題点

1. **読者ターゲットが混在**
   - `authentication.md` が5,000行超で、設定手順・実装・設計背景が混在
   - システム理解者と実装者の両方を対象にしようとして中途半端

2. **ディレクトリ構造が不明確**
   - `development/` が存在するが、他のドキュメントは全部ルートに配置
   - 一貫性がない

3. **セットアップ系が分散**
   - `flutter-setup.md`, `neon-setup.md` がバラバラ
   - Backend セットアップドキュメントがない

4. **デプロイ系が1ファイルに集約**
   - `deployment.md` に CI/CD と手動デプロイが混在

---

## 新しいドキュメント構成

### 目標のディレクトリ構造

```
docs/
├── README.md                           # ドキュメントインデックス（新規作成）
│
├── overview/                           # 【システム理解者向け】
│   ├── architecture.md                 # 現: architecture.md
│   ├── tech-stack.md                   # 現: design-principles.md から抽出
│   ├── data-flow.md                    # 現: architecture.md から抽出
│   └── environments.md                 # 現: environment.md
│
├── getting-started/                    # 【実装者向け - 初回セットアップ】
│   ├── README.md                       # セットアップガイド総合索引
│   ├── backend-setup.md                # 新規作成（Docker, Hasura CLI）
│   ├── frontend-setup.md               # 現: flutter-setup.md
│   └── neon-setup.md                   # 現: neon-setup.md
│
├── development/                        # 【実装者向け - 日常開発】
│   ├── backend-workflow.md             # 現: development-flow.md
│   ├── frontend-workflow.md            # 新規作成（GraphQL Code Gen等）
│   ├── testing.md                      # 新規作成（テスト実行方法）
│   └── documentation-guide.md          # 現: development/documentation-guide.md
│
├── deployment/                         # 【運用者向け】
│   ├── cloud-run-deployment.md         # 現: deployment.md から抽出
│   ├── ci-cd.md                        # 現: deployment.md から抽出
│   └── troubleshooting.md              # 現: troubleshooting.md
│
└── reference/                          # 【設計判断の背景】
    ├── design-principles.md            # 現: design-principles.md
    ├── authentication.md               # 現: authentication.md を縮小
    ├── database-design.md              # 現: database-design.md
    └── multi-tenancy.md                # 新規作成（現: database-design.md から抽出）
```

---

## 移行計画

### Phase 1: ディレクトリ作成と移動

**作業内容**:
1. 新しいディレクトリ作成
   ```bash
   mkdir -p docs/{overview,getting-started,deployment,reference}
   ```

2. 既存ファイルの移動
   ```bash
   # Overview
   mv docs/architecture.md docs/overview/
   mv docs/environment.md docs/overview/environments.md

   # Getting Started
   mv docs/flutter-setup.md docs/getting-started/frontend-setup.md
   mv docs/neon-setup.md docs/getting-started/

   # Development (既存)
   mv docs/development-flow.md docs/development/backend-workflow.md

   # Deployment
   # deployment.md は分割するため後で処理

   # Reference
   mv docs/design-principles.md docs/reference/
   mv docs/authentication.md docs/reference/
   mv docs/database-design.md docs/reference/
   ```

3. 削除または統合
   ```bash
   # future-enhancements.md は README.md に統合
   # troubleshooting.md は deployment/ に移動
   mv docs/troubleshooting.md docs/deployment/
   ```

### Phase 2: 大きなファイルの分割

#### 2.1 `deployment.md` の分割

**Before**: `deployment.md` (1ファイル)

**After**:
- `deployment/cloud-run-deployment.md` - Cloud Runへの手動デプロイ手順
- `deployment/ci-cd.md` - GitHub Actions ワークフロー

#### 2.2 `authentication.md` の整理

**現状**: 認証フロー図、Firebase設定、Flutter実装、設計背景が混在

**整理後**:
- `overview/authentication-flow.md` (新規) - 認証フロー図のみ
- `getting-started/firebase-auth-setup.md` (新規) - Firebase初期設定
- `development/flutter-auth-implementation.md` (新規) - Flutter実装手順
- `reference/authentication.md` (縮小) - 設計背景のみ

#### 2.3 `architecture.md` の整理

**現状**: アーキテクチャ図、データフロー図、コンポーネント説明が混在

**整理後**:
- `overview/architecture.md` (縮小) - システム全体図のみ
- `overview/data-flow.md` (新規) - データフロー図とシーケンス図

#### 2.4 `design-principles.md` の整理

**現状**: 技術選定理由と設計原則が混在

**整理後**:
- `overview/tech-stack.md` (新規) - 技術スタック一覧と選定理由（簡潔版）
- `reference/design-principles.md` (詳細版) - 設計原則の詳細

### Phase 3: 新規ドキュメント作成

1. **`docs/README.md`** - ドキュメントインデックス
   - 各ディレクトリの説明
   - 読者ターゲット別のナビゲーション

2. **`getting-started/README.md`** - セットアップ総合ガイド
   - Backend → Frontend → Neon の順で案内

3. **`getting-started/backend-setup.md`**
   - Docker インストール
   - Hasura CLI インストール
   - ローカル環境起動手順

4. **`development/frontend-workflow.md`**
   - GraphQL Code Generation
   - Flavor切り替え
   - デバッグ実行

5. **`development/testing.md`**
   - ユニットテスト
   - 統合テスト
   - パーミッションテスト

6. **`reference/multi-tenancy.md`**
   - マルチテナント設計の詳細
   - テナント分離戦略

### Phase 4: 相互リンク修正

全ドキュメントの相互リンクを更新:
1. ドキュメント内のリンクを新しいパスに更新
2. `README.md` から各ドキュメントへのリンク
3. `CLAUDE.md` の参照リンク更新

---

## 作業優先順位

### 優先度 High（すぐやる）

1. ✅ `documentation-guide.md` の修正（完了）
2. ディレクトリ作成と既存ファイルの移動
3. `docs/README.md` 作成
4. `getting-started/README.md` 作成

### 優先度 Medium（次回）

5. `deployment.md` の分割
6. `authentication.md` の整理
7. 新規ドキュメント作成（`backend-setup.md`等）

### 優先度 Low（余裕があれば）

8. `architecture.md` の分割
9. `design-principles.md` の分割
10. 相互リンク修正

---

## 実行方法

### オプション1: 一気に全部やる（推奨しない）
- リスク: 大量のファイル移動でコンフリクト発生
- コミット履歴が追いにくい

### オプション2: 段階的に実施（推奨）
- Phase 1 → コミット
- Phase 2 → コミット
- Phase 3 → コミット
- Phase 4 → コミット

各Phaseごとにコミットすることで、問題があれば戻しやすい。

---

## 次のステップ

1. このプランをレビュー・承認
2. Phase 1 から順次実施
3. 各Phase完了後にコミット

