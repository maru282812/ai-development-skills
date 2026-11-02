# デザインのハブ（媒体別の基準）

プロジェクトをまたいで使うデザインの基準を、媒体ごとに置く場所。
棚卸し: [../references/design-inventory-2026-11-02.md](../references/design-inventory-2026-11-02.md)

## 層

| 層 | どこにあるか |
|---|---|
| 共通（和文組版・AIっぽさ・正直なコピー・心理学・外部調査・好み判定） | `~/.claude/skills/hallmark`（`references/ja.md`・`references/polish/signs.md`・`references/psychology.md`・`references/research.md`・`references/taste-loop.md`）、`.skills/ui-ux-review/references/ui-psychology.md`（心理学の正本。hallmark 側は使い方だけ） |
| **媒体** | このフォルダ（下表） |
| ブランド | 書式 [brand.md](brand.md)・検査と CSS 書き出し [scripts/check-brand.mjs](scripts/check-brand.mjs)。自社は `brands/<id>/brand.json`（YOTTO 登録済み）、顧客はその案件のリポジトリ |
| プロジェクト | 各リポジトリの `design.md`・`tokens.css`・`globals.css` など。**ここが最優先** |

## 媒体

| 媒体 | 基準 | 状態 |
|---|---|---|
| アプリ・管理画面 | [app.md](app.md)・自動計測 [scripts/measure-app.mjs](scripts/measure-app.mjs) | 2026-11-02 作成・shiseki_ai で実地確認済み |
| サイト・LP | website-sales-ai が正本（参照のみ。動かさない）: `docs/design-system.md`（数値基準・8項目ゲート・`npm run measure:site`）、`sites/_base/MOODS.md` と `sites/_base/moods/*/mood.json`（雰囲気の型）、`sites/_base/compositions/`（構図の型）、`.claude/skills/design-tokens/references/visual-density.md`（画像密度） | 参照で運用 |
| SNS 画像・動画 | 起点候補: resto-sns `docs/ig-first/template-catalog.md` | 未整備（次の投稿案件で作る） |
| 資料 | `~/.claude/skills/shiryo-slides` | 既存スキルで運用 |

## 昇格ルール

デザインで差し戻しを受けたとき、または合格した判断が出たときに判定する。

1. その学びは「この案件だけ」か「この媒体全体」か「全媒体」か。
2. 媒体全体なら、このフォルダの該当ファイルに1規則として追記し、末尾に【出どころ・日付】を付ける。
3. 全媒体なら hallmark の共通層（`ja.md` など）へ追記する。
4. 案件だけの話なら、そのリポジトリの `design.md` に残す。

好み判定ループ（`taste-loop.md`）の月次レポートで採否が決まった型・× 理由も、この順で振り分ける。

2026-11-02 にグローバル CLAUDE.md（hallmark の項）へ組み込み済み。
