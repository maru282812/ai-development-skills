# デザインのハブ（媒体別の基準）

プロジェクトをまたいで使うデザインの基準を、媒体ごとに置く場所。
棚卸し: [../references/design-inventory-2026-11-02.md](../references/design-inventory-2026-11-02.md)

## 層

| 層 | どこにあるか |
|---|---|
| 共通（和文組版・AIっぽさ・正直なコピー・心理学） | `~/.claude/skills/hallmark`（`references/ja.md`・`references/polish/signs.md`・`references/psychology.md`）、`.skills/ui-ux-review/references/ui-psychology.md` |
| **媒体** | このフォルダ（下表） |
| ブランド | 未整備（棚卸し §4 の4） |
| プロジェクト | 各リポジトリの `design.md`・`tokens.css`・`globals.css` など。**ここが最優先** |

## 媒体

| 媒体 | 基準 | 状態 |
|---|---|---|
| アプリ・管理画面 | [app.md](app.md)・自動計測 [scripts/measure-app.mjs](scripts/measure-app.mjs) | 2026-11-02 作成・shiseki_ai で実地確認済み |
| サイト・LP | website-sales-ai が正本（参照のみ。動かさない）: `docs/design-system.md`（数値基準・8項目ゲート・`npm run measure:site`）、`sites/_base/MOODS.md` と `sites/_base/moods/*/mood.json`（雰囲気の型）、`sites/_base/compositions/`（構図の型）、`.claude/skills/design-tokens/references/visual-density.md`（画像密度） | 参照で運用 |
| SNS 画像・動画 | 起点候補: resto-sns `docs/ig-first/template-catalog.md` | 未整備（次の投稿案件で作る） |
| 資料 | `~/.claude/skills/shiryo-slides` | 既存スキルで運用 |

## 昇格ルール（案）

デザインで差し戻しを受けたとき、または合格した判断が出たときに判定する。

1. その学びは「この案件だけ」か「この媒体全体」か「全媒体」か。
2. 媒体全体なら、このフォルダの該当ファイルに1規則として追記し、末尾に【出どころ・日付】を付ける。
3. 全媒体なら hallmark の共通層（`ja.md` など）へ追記する。
4. 案件だけの話なら、そのリポジトリの `design.md` に残す。

グローバル CLAUDE.md への組み込みは棚卸し §4 の5で行う。
