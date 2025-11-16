# ドキュメント作成ガイドライン

## 概要

このガイドラインは、hasura_flutter プロジェクトのドキュメントを一貫性を持って管理し、**読者ターゲット別に読みやすく整理する**ためのルールとベストプラクティスをまとめたものです。

## このプロジェクトのドキュメント哲学

### 核心原則: 読者ファーストの情報設計

ドキュメントは**読者が求める情報**に応じて適切な粒度と範囲で分割します。

**3つの読者ターゲット**:

1. **システム理解者** - 全体像を把握したい
   - 目的: アーキテクチャ、データフロー、技術スタックの理解
   - 求める情報: 図が中心、簡潔な説明、技術選定の理由
   - 粒度: 高レベル（詳細な手順は不要）

2. **実装者** - システムを構築・拡張したい
   - 目的: 環境構築、開発ワークフロー、実装
   - 求める情報: 具体的な手順、コマンド例、設定方法
   - 粒度: ステップバイステップの詳細

3. **運用者** - システムをデプロイ・保守したい
   - 目的: デプロイ、トラブルシューティング、監視
   - 求める情報: 運用手順、よくあるエラーと対処法
   - 粒度: 実践的な手順とチェックリスト

**重要**: 1つのドキュメントに複数ターゲット向けの情報を詰め込まない。必要に応じて分割し、相互リンクで結ぶ。

## 基本原則

### 1. 孤立したドキュメントを作らない

*ルール*: すべてのドキュメントは、他のドキュメントから参照されている必要があります。

*注*: ドキュメントを独立して作成すること自体は問題ありません。重要なのは、作成したドキュメントが他のドキュメントからリンクされ、発見可能な状態にすることです。

*理由*:
- 孤立したドキュメントは発見されず、更新されず、やがて古くなる
- 相互リンクによってドキュメント間の関係性が明確になる
- ナビゲーションが容易になる

*悪い例*:
docs/design/new-feature.md  # どこからもリンクされていない

*良い例*:
docs/README.md
  └→ design/00-architecture-overview.md
       └→ design/new-feature.md

*実践方法*:
- 新しいドキュメントを作成したら、必ず [docs/README.md](../README.md) または関連ドキュメントにリンクを追加
- ドキュメント内に「関連ドキュメント」セクションを設け、相互リンクを明示

### 2. コード例は最小限に

*ルール*: ドキュメントにコード例を含める場合は、最小限に留めます。

*理由*:
- コードは変更されやすく、ドキュメントとの同期が困難
- 実装の自由度が失われる
- コードはコードベースが真実の情報源であるべき

*許可される例外*:
- インターフェースの定義（型シグネチャ程度）
- 使用例（CLIコマンド、設定例）
- 最小限のサンプルコード（概念を説明するため）

*悪い例*:
### 実装例

\`\`\`python
class CSVReader(DataReader):
    def __init__(self, encoding='utf-8'):
        self.encoding = encoding

    def read(self, file_path: Path, lat_column: str, lon_column: str) -> gpd.GeoDataFrame:
        df = pd.read_csv(file_path, encoding=self.encoding)
        # ... 100行のコード ...
\`\`\`

*良い例*:
### CSVReader実装仕様

**責務**:
- CSV読み込み（pandas.read_csv）
- 緯度経度からジオメトリ生成（geopandas.points_from_xy）
- CRS設定（デフォルト: EPSG:4326）

**インターフェース**:
\`\`\`python
class CSVReader(DataReader):
    def can_read(file_path: Path) -> bool
    def read(file_path: Path, lat_column: str, lon_column: str) -> gpd.GeoDataFrame
\`\`\`

### 3. 具体的なファイルパスは記載しない

*ルール*: 実装ファイルの具体的なパスは記載せず、コンポーネント名と責務のみを記載します。

*理由*:
- ファイル構造が変更された際、ドキュメントも更新が必要になる
- 実装の自由度が制限される
- リファクタリングの障壁になる

*例外*:
- ディレクトリ構成（全体像の理解に必要）
- 設定ファイル（config/, params.yaml など）

*悪い例*:
### 実装ファイル
- `packages/poi-build/src/poi/readers/csv_reader.py`: CSVReader クラス
- `packages/poi-build/src/poi/selectors/coordinate_selector.py`: CoordinateColumnSelector

*良い例*:
### 実装コンポーネント

**新規作成**:
- **CSVReader**: CSVファイル読み込み、ジオメトリ生成
- **CoordinateColumnSelector**: 緯度経度カラムの自動推定・選択UI

**既存コンポーネント拡張**:
- **Readerファクトリ**: CSVReaderの登録
- **CLI**: CSV用オプション追加

### 4. ディレクトリ構成は記載OK

*ルール*: プロジェクト全体やモジュールのディレクトリ構成は記載して構いません。

*理由*:
- 全体像の理解に必要
- 頻繁には変更されない
- 新しい開発者のオンボーディングに役立つ

*例*:
## ディレクトリ構造

\`\`\`
packages/poi-build/
├── src/poi/
│   ├── readers/          # ファイル形式別読み込み
│   ├── transforms/       # ジオメトリ・CRS変換
│   ├── selectors/        # インタラクティブUI
│   └── filters/          # フィルタ条件ビルダー
└── tests/
    ├── unit/
    └── integration/
\`\`\`

### 5. 仕様と概念に集中

*ルール*: ドキュメントは「何を」「なぜ」に焦点を当て、「どのように」はコードに任せます。

*記載すべき内容*:
- ✅ 要件・目的
- ✅ 設計の意図・理由
- ✅ データフロー
- ✅ インターフェース（入出力）
- ✅ 制約・前提条件
- ✅ 使用例

*記載すべきでない内容*:
- ❌ 実装の詳細（アルゴリズム、内部処理）
- ❌ 変数名・関数の内部ロジック
- ❌ パフォーマンス最適化の技術的詳細

### 6. Mermaid図を積極的に活用

*ルール*: 複雑なフロー・関係性は図で表現します。

*理由*:
- 視覚的な理解が容易
- 言語に依存しない
- メンテナンスしやすい（テキストベース）

*使用すべきケース*:
- データフロー・処理フロー
- モジュール間の依存関係
- シーケンス図
- 状態遷移図

*例*:
mermaid
graph TD
    A[CSV入力] --> B[緯度経度カラム決定]
    B --> C[ジオメトリ生成]
    C --> D[CRS変換]
    D --> E[品質検証]
    E --> F[GeoParquet出力]

## ドキュメントの種類別ガイドライン

### このプロジェクトのドキュメント構成

```
docs/
├── README.md                           # ドキュメントインデックス（全ドキュメントへの入口）
│
├── overview/                           # 【システム理解者向け】
│   ├── architecture.md                 # アーキテクチャ概要（図中心）
│   ├── tech-stack.md                   # 技術スタック選定理由
│   └── data-flow.md                    # データフロー図
│
├── getting-started/                    # 【実装者向け - 初回セットアップ】
│   ├── backend-setup.md                # Backend環境構築（Docker, Hasura CLI）
│   ├── frontend-setup.md               # Flutter環境構築（fvm, Firebase）
│   └── neon-setup.md                   # Neon DB初期セットアップ
│
├── development/                        # 【実装者向け - 開発ワークフロー】
│   ├── backend-workflow.md             # Hasuraマイグレーション、パーミッション設定
│   ├── frontend-workflow.md            # Flutter開発、GraphQL Code Generation
│   ├── testing.md                      # テスト作成・実行方法
│   └── documentation-guide.md          # このファイル
│
├── deployment/                         # 【運用者向け】
│   ├── cloud-run-deployment.md         # Cloud Run デプロイ手順
│   ├── ci-cd.md                        # GitHub Actions設定
│   └── troubleshooting.md              # よくあるエラーと対処法
│
└── reference/                          # 【設計判断の背景】
    ├── design-principles.md            # 設計原則と技術選定理由
    ├── authentication.md               # 認証・認可設計
    ├── database-design.md              # DB設計（ER図、スキーマ）
    └── multi-tenancy.md                # マルチテナント設計
```

### 各ディレクトリの役割

#### `overview/` - システム理解者向け

**読者**: プロジェクトマネージャー、新規参加者、レビュワー

**特徴**:
- 図とダイアグラムが中心
- 技術選定の「なぜ」を簡潔に説明
- 詳細な手順は含まない
- 1ドキュメント = 1,000〜2,000文字程度

**含めるべき内容**:
- Mermaid図（アーキテクチャ、データフロー）
- 技術スタック一覧と選定理由（箇条書き）
- コンポーネント間の関係性
- 環境構成図（local/dev/prod）

**含めるべきでない内容**:
- ❌ 詳細なセットアップ手順
- ❌ コマンド例
- ❌ トラブルシューティング

#### `getting-started/` - 実装者向け（初回セットアップ）

**読者**: 新規開発者、環境構築を行う人

**特徴**:
- ステップバイステップの手順
- コマンド例を豊富に記載
- チェックリスト形式
- 1ドキュメント = 特定の環境セットアップ1つ

**含めるべき内容**:
- 前提条件
- インストール手順（コマンド例）
- 設定ファイルの編集方法
- 動作確認方法
- トラブルシューティング（そのセットアップ固有）

**分割基準**:
- Backend と Frontend は別ドキュメント
- 初回セットアップと日常開発は別ドキュメント

#### `development/` - 実装者向け（日常開発）

**読者**: 日々開発を行う開発者

**特徴**:
- 開発ワークフローに沿った構成
- コマンド例、設定例が中心
- ベストプラクティス
- 1ドキュメント = 1つの開発領域（Backend/Frontend）

**含めるべき内容**:
- マイグレーション作成・適用手順
- コード生成コマンド
- テスト実行方法
- デバッグ設定
- よく使うコマンド集

#### `deployment/` - 運用者向け

**読者**: デプロイを行う人、運用担当者

**特徴**:
- 本番運用を意識した構成
- 手動デプロイとCI/CD の両方をカバー
- トラブルシューティングが充実
- チェックリストとフローチャート

**含めるべき内容**:
- デプロイ前チェックリスト
- デプロイ手順（手動/自動）
- ロールバック手順
- よくあるエラーと対処法
- 監視・ログ確認方法

#### `reference/` - 設計判断の背景

**読者**: 設計を理解したい人、拡張を検討する人

**特徴**:
- 「なぜこの設計にしたか」が中心
- トレードオフの説明
- 変更可能性のある部分の明示
- 実装手順は含まない

**含めるべき内容**:
- 設計原則
- 技術選定理由（詳細版）
- ER図、スキーマ設計
- 認証・認可フロー
- 制約と前提条件

**含めるべきでない内容**:
- ❌ セットアップ手順
- ❌ 実装コード
- ❌ コマンド例

## ドキュメント作成フロー

### 1. 新規ドキュメント作成時

mermaid
graph TD
    A[新規ドキュメント作成] --> B[関連ドキュメントセクションを追加]
    B --> C{親ドキュメントが存在?}
    C -->|Yes| D[親ドキュメントにリンクを追加]
    C -->|No| E[docs/README.mdにリンクを追加]
    D --> F[相互リンクを確認]
    E --> F
    F --> G[完了]

*チェックリスト*:
- [ ] ドキュメント冒頭に「関連ドキュメント」セクションを追加
- [ ] 親ドキュメントまたは docs/README.md にリンクを追加
- [ ] 関連する他のドキュメントからもリンクを追加
- [ ] コード例は最小限に留める
- [ ] 具体的なファイルパスは記載しない
- [ ] Mermaid図で視覚化できる部分は図にする

### 2. 既存ドキュメント更新時

*チェックリスト*:
- [ ] 更新履歴セクションに日付と変更内容を追記
- [ ] 関連ドキュメントも影響を受けていないか確認
- [ ] リンク切れが発生していないか確認

### 3. ドキュメント削除時

*注意*: ドキュメントの削除は慎重に行う

*手順*:
1. そのドキュメントを参照しているすべての場所を特定
2. 参照元のリンクを削除または更新
3. 代替ドキュメントがあれば、そちらへのリンクに置き換え

## よくある質問

### Q: コンポーネント名はどの程度具体的に書くべき？

*A*: クラス名やモジュール名は記載OK。ファイルパスは不要。

*例*:
- ✅ AuthService: Firebase Auth認証サービス
- ✅ GraphQLConfig: 認証ヘッダー付きGraphQLクライアント設定
- ❌ app/lib/services/auth_service.dart

### Q: インターフェースはどこまで詳細に書くべき？

*A*: メソッドシグネチャ（引数と戻り値の型）まで。実装は不要。

*例*:
```dart
// ✅ Good
class AuthService {
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? organizationCode,
  });
}

// ❌ Bad（実装まで書く）
class AuthService {
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? organizationCode,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(...);
    // ... 実装の詳細 ...
  }
}
```

### Q: 使用例はどこまで書くべき？

*A*: CLIコマンドや設定例は積極的に記載。コード例は最小限。

*例*:
```bash
# ✅ Good（コマンド使用例）
# マイグレーション適用
hasura migrate apply --database-name default

# Flutter dev環境で起動
flutter run --flavor dev --dart-define=ENV=dev

# Neon へのマイグレーション適用
bash backend/hasura/apply-migrations-to-neon.sh
```

### Q: ドキュメントが長くなりすぎたら？

*A*: 読者ターゲット別、または機能別に分割し、相互リンクで結ぶ。

*例*:
```
# ❌ Bad: 1つのファイルに全部詰め込む
docs/authentication.md (5,000行)
  ├── Firebase Auth設定
  ├── Custom Claims設定
  ├── Hasura JWT設定
  ├── Flutter実装手順
  ├── Cloud Functions実装
  ├── トラブルシューティング
  └── 設計判断の背景

# ✅ Good: 読者ターゲット別に分割
docs/
├── overview/authentication-flow.md          # 認証フロー図（システム理解者向け）
├── getting-started/firebase-auth-setup.md   # Firebase初期設定（実装者向け）
├── development/flutter-auth-implementation.md # Flutter認証実装（実装者向け）
├── deployment/cloud-functions-deployment.md  # Cloud Functions デプロイ（運用者向け）
└── reference/authentication-design.md       # 認証設計の背景（設計者向け）
```

### Q: 環境別のドキュメントはどう整理すべき？

*A*: このプロジェクトでは local/dev/prod の3環境があるが、環境別にドキュメントを分割しない。1つのドキュメント内で環境ごとのセクションで整理。

*例*:
```markdown
# ✅ Good
## Local環境
- 目的: 開発・マイグレーション作成
- 構成: Docker Compose

## Dev環境
- 目的: 統合検証・実機テスト
- 構成: Cloud Run + Neon

## Prod環境
- 目的: 本番運用
- 構成: Cloud Run + Neon
```

## 参考資料

- [docs/README.md](../README.md): ドキュメントインデックス
- [CLAUDE.md](../../CLAUDE.md): AI開発ガイドライン（ドキュメント管理ルール含む）

---

*更新履歴:*
- 2025-11-16: hasura_flutterプロジェクト用に改訂
  - 読者ターゲット別のドキュメント分類を追加（システム理解者/実装者/運用者）
  - プロジェクト固有のドキュメント構成定義（overview/getting-started/development/deployment/reference）
  - 環境別ドキュメント整理方針を追加
  - 例をDart/Flutter/Hasura向けに変更
-
