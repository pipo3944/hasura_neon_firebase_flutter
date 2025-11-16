# ドキュメントインデックス

hasura_flutter プロジェクトのドキュメントへようこそ。

このドキュメントは**読者ターゲット別**に整理されています。目的に応じて適切なセクションを選んでください。

---

## 🎯 読者ターゲット別ナビゲーション

### 📊 システムを理解したい（概要を知りたい）

プロジェクトマネージャー、新規参加者、レビュワー向け

**→ [overview/](overview/)** - 図とダイアグラムで全体像を把握

- [アーキテクチャ概要](overview/architecture.md) - システム全体図、技術スタック
- [認証フロー](overview/authentication-flow.md) - Firebase Auth × Hasura の認証フロー図
- [環境構成](overview/environments.md) - local/dev/prod の違い

**所要時間**: 15〜30分

---

### 🛠️ 環境を構築したい（初回セットアップ）

新規開発者、環境構築を行う人向け

**→ [getting-started/](getting-started/)** - ステップバイステップのセットアップ手順

- **[セットアップガイド](getting-started/README.md)** ← まずここから！
- [Backend環境構築](getting-started/backend-setup.md) - Docker, Hasura CLI インストール
- [Flutter環境構築](getting-started/frontend-setup.md) - fvm, Firebase 設定
- [Neon DB初期セットアップ](getting-started/neon-setup.md) - Neon プロジェクト作成、マイグレーション適用

**所要時間**: 1〜2時間

---

### 💻 開発したい（日常開発）

日々開発を行う開発者向け

**→ [development/](development/)** - 開発ワークフローとベストプラクティス

- [Backend開発フロー](development/backend-workflow.md) - Hasura マイグレーション、パーミッション設定
- [ドキュメント作成ガイド](development/documentation-guide.md) - ドキュメント整理方針

**今後追加予定**:
- Frontend開発フロー（GraphQL Code Generation等）
- テスト作成・実行方法

---

### 🚀 デプロイしたい（運用）

デプロイを行う人、運用担当者向け

**→ [deployment/](deployment/)** - デプロイ手順とトラブルシューティング

- [Cloud Run デプロイ](deployment/cloud-run-deployment.md) - Hasura を Cloud Run にデプロイ
- [CI/CD設定](deployment/ci-cd.md) - GitHub Actions ワークフロー
- [トラブルシューティング](deployment/troubleshooting.md) - よくあるエラーと対処法

---

### 📚 設計を理解したい（設計背景）

設計を理解したい人、拡張を検討する人向け

**→ [reference/](reference/)** - 設計判断の背景と技術的詳細

- [設計原則](reference/design-principles.md) - 技術選定理由、設計判断
- [認証・認可の設計](reference/authentication-design.md) - Hasura JWT設定、パーミッション設計
- [データベース設計](reference/database-design.md) - ER図、スキーマ設計、マルチテナント戦略

---

## 📁 ディレクトリ構造

```
docs/
├── README.md                           # このファイル
│
├── overview/                           # システム理解者向け
│   ├── architecture.md
│   ├── authentication-flow.md
│   └── environments.md
│
├── getting-started/                    # 初回セットアップ
│   ├── README.md
│   ├── backend-setup.md
│   ├── frontend-setup.md
│   └── neon-setup.md
│
├── development/                        # 日常開発
│   ├── backend-workflow.md
│   └── documentation-guide.md
│
├── deployment/                         # 運用
│   ├── cloud-run-deployment.md
│   ├── ci-cd.md
│   └── troubleshooting.md
│
└── reference/                          # 設計背景
    ├── design-principles.md
    ├── authentication-design.md
    └── database-design.md
```

---

## 🚦 クイックスタート

### 新しく参加した開発者向け

1. **概要を理解** → [overview/architecture.md](overview/architecture.md) (10分)
2. **環境構築** → [getting-started/README.md](getting-started/README.md) (1〜2時間)
3. **開発フロー確認** → [development/backend-workflow.md](development/backend-workflow.md) (15分)

### デプロイ担当者向け

1. **環境構成を理解** → [overview/environments.md](overview/environments.md) (10分)
2. **デプロイ手順** → [deployment/cloud-run-deployment.md](deployment/cloud-run-deployment.md) (30分)
3. **CI/CD設定** → [deployment/ci-cd.md](deployment/ci-cd.md) (20分)

---

## 🔍 検索のヒント

### よくある質問

| 質問 | 参照先 |
|------|--------|
| Firebase Auth の設定方法は？ | [getting-started/frontend-setup.md](getting-started/frontend-setup.md) |
| マイグレーションの作り方は？ | [development/backend-workflow.md](development/backend-workflow.md) |
| Neon へのマイグレーション適用は？ | [getting-started/neon-setup.md](getting-started/neon-setup.md) |
| Cloud Run デプロイ方法は？ | [deployment/cloud-run-deployment.md](deployment/cloud-run-deployment.md) |
| パーミッションの設計方針は？ | [reference/authentication-design.md](reference/authentication-design.md) |
| なぜこの技術を選んだ？ | [reference/design-principles.md](reference/design-principles.md) |
| エラーが出た！ | [deployment/troubleshooting.md](deployment/troubleshooting.md) |

---

## 📝 ドキュメント作成ガイドライン

新しいドキュメントを作成する際は、[development/documentation-guide.md](development/documentation-guide.md) を参照してください。

**核心原則**: 読者ターゲット別に情報を分割し、1つのドキュメントに複数ターゲット向けの情報を詰め込まない。

---

## 🔗 関連リンク

- [プロジェクトルート README](../README.md) - プロジェクト全体の概要
- [CLAUDE.md](../CLAUDE.md) - Claude Code 向けコンテキスト
- [PROGRESS.md](../PROGRESS.md) - 開発進捗管理

---

## 📅 更新履歴

- 2025-11-16: ドキュメント整理完了（Phase 3）
  - 読者ターゲット別に再構成
  - overview/getting-started/development/deployment/reference に分類
  - このREADME.md 作成
