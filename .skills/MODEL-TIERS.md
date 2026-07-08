# モデルティア方針（役割分担）

Skill を「どのクラスのモデルで実行するのが最適か」を定義する。
**具体的なモデル名（Fable 5 / Opus 4.8 など）は各 SKILL.md には一切書かない。**
モデル名との対応は本ファイルの「現在のマッピング」だけが持ち、モデルの入れ替わり・
提供終了・バージョンアップがあってもこのファイル1箇所の更新で済むようにする。

---

## ティア定義（モデル名非依存）

| ティア | 定義 | 向いている仕事 |
|---|---|---|
| `deep` | その時点で利用できる**最上位の推論クラス**のモデル | 判断・設計・監査・敵対的レビュー・文書横断の整合性チェック・優先順位付け・捨てる判断 |
| `standard` | 日常運用する**標準クラス**のモデル | 手順追従・チェックリスト実行・確定済み仕様の変換/文書化・調査・テンプレ生成・検証実行 |

分類基準は1つだけ:
**「出力の質が、手順の良し悪しではなくモデルの推論力に依存するか？」**
依存するなら `deep`、手順書どおりに進めれば品質が安定するなら `standard`。

## 現在のマッピング（2026-07 時点。ここだけ更新する）

| ティア | 現在のモデル | 代替（上位が使えない場合） |
|---|---|---|
| `deep` | Claude Fable 5（Mythos ティア） | Opus 系の最新（例: Opus 4.8） |
| `standard` | Opus 4.8 / Sonnet 系 | 利用可能な標準モデル |

## フォールバック規則（deep モデルが使えない場合）

`deep` 指定はあくまで**推奨**であり、実行資格ではない。上位モデルが使えない環境でも
スキルは中止せず実行する。ただし劣化運転として次を守る:

1. **断定を減らす** — 結論は「候補 + 根拠 + 確信度」で提示し、1本に絞り込まない
2. **工程を細かく切る** — 一度に全体を出さず、区切りごとにユーザー確認を挟む
3. **不可逆な提案では必ず停止する** — 削除・破壊的変更・本番適用は人間の確認を取る

逆に `standard` スキルを上位モデルで実行しても害はない（もったいないだけ）。
並行作業でモデル枠が競合するときは、`standard` スキルを標準モデルに逃がす。

---

## 分類表（全 Skill）

frontmatter の `metadata.reasoning-tier` が SSOT。この表はその一覧ビュー。

### deep（推論力依存 — 判断・設計・監査）

| Skill | 理由 |
|---|---|
| `project-discovery` | フェーズ間の矛盾検知と進行判断の質がモデルに依存 |
| `scope-discovery` | MVP の線引き＝「何を作らないか」の捨てる判断 |
| `business-discovery` | 事業仮説の立案・多視点での前提潰し |
| `legal-discovery` | 見落としが致命傷になる発見系。網羅性が推論力に依存 |
| `contract-discovery` | 同上（誰と・どの条件の契約が要るかの発見） |
| `risk-discovery` | 敵対的視点でのリスク発見 |
| `discovery-planner` | 「次に決めるべき1問」の優先順位判断 |
| `discovery-auditor` | 文書群の横断整合性監査（最も推論力が効く領域） |
| `saas-product-manager` | 機能仕様・MVP・優先順位の判断 |
| `db-designer` | データモデル設計。後戻りコストが最大の上流判断 |
| `api-designer` | インターフェース契約の設計判断 |
| `prompt-architect` | 失敗の切り分け・プロンプト構造の設計 |
| `screen-design-architect` | Screen Coverage Audit＋設計反復の判断 |
| `refactor-planner` | 構造改善の判断（何を触らないかの判断を含む） |
| `code-review` | バグ発見は推論力に直結する敵対的読解 |
| `security-review` | 敵対的レビューの代表格。攻撃者視点の網羅 |
| `migration-review` | 不可逆操作（本番 SQL）の安全判断 |
| `agent-planner` | バックログ優先順位と「次の1手」の判断 |
| `adversarial-review` | 汎用レッドチーム。反例の発見力が推論力に直結 |
| `legal-consistency-audit` | 法務文書群の横断矛盾検出（文書横断監査の法務版） |
| `tacit-knowledge-extractor` | 質問設計と矛盾検出が抽出の質を決める |

### standard（手順追従型 — どのモデルでも品質が安定）

| Skill | 理由 |
|---|---|
| `requirements-discovery` | 段階式チェックリストの追従 |
| `metrics-discovery` | チェックリスト駆動の発見 |
| `nfr-discovery` | 同上 |
| `operations-discovery` | 同上 |
| `data-discovery` | 同上 |
| `integration-discovery` | 同上 |
| `legal-publication-manager` | 手順型の公開物管理 |
| `system-investigator` | grep・参照追跡の手順型調査 |
| `bug-investigator` | 再現→切り分けの定型手順。**難航したら deep に切替** |
| `data-flow-mapper` | データ経路の追跡・可視化 |
| `feature-spec-writer` | 確定済み要件の仕様書化（変換作業） |
| `implementation-planner` | 確定済み仕様の分解・指示文生成。**大規模・高リスク案件は deep 推奨** |
| `test-planner` | テスト観点の列挙（敵対的監査は別スキルの領域） |
| `ui-ux-review` | ヒューリスティックベースのレビュー |
| `git-init-setup` | 完全な手順型セットアップ |
| `ops-guide-embedder` | テンプレに沿った埋め込み |
| `project-quality-tooling` | スタック検出→ツール選定の定型フロー |
| `dispatch-pattern-builder` | 確立済みパターンの適用 |
| `agent-tester` | 軽量検証（typecheck / test / diff レビュー）。定義上 standard |
| `handover-package` | スキャン→集約→テンプレ生成の手順追従型 |

---

## 運用ルール

0. **ディスパッチ方式の受け側スキル**（[[dispatch-pattern-builder]] が生成する `<feature>-run` 等）は
   「GET→処理→POST」の手順追従型なので原則 `standard`。台帳や成果物を疑う監査・レッドチーム系の
   受け側だけ `deep` にする。実行文テンプレ・受け側スキル本文にもモデル名は書かない
1. **新しい Skill を作ったら**、上の分類基準で `deep` / `standard` を決め、
   frontmatter に `metadata: reasoning-tier:` を書き、本ファイルの表に1行足す
2. **SKILL.md 本文・description に具体的なモデル名を書かない**（ティア名だけ使う）
3. モデルのラインナップが変わったら「現在のマッピング」だけを更新する
4. 変更後は `scripts/sync-skills.ps1 -Apply` でミラー同期し、
   `scripts/build-skills-dashboard.ps1` でダッシュボードを再生成する
