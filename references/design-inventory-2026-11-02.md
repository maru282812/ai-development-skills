# デザイン資産の棚卸し（2026-11-02）

目的: 複数プロジェクトに散らばったデザインの資産を「媒体 × 層」で並べ、重複・埋もれ・欠けを洗い出す。
次の段階（媒体別ハブ）の材料。調査範囲は `C:\work` 直下の全リポジトリと `~/.claude/skills`。

## 1. 資産マップ

### 層の定義

| 層 | 中身 |
|---|---|
| 共通 | どの媒体でも守ること（和文組版・AIっぽさ・正直なコピー・心理学・法令） |
| 媒体 | 媒体ごとの「良い」の基準・型・採点 |
| ブランド | 顧客や自社ごとの色・書体（媒体をまたいで使う） |
| プロジェクト | 上から選んだ結果と差分 |
| 工程 | 作り方・採点の回し方 |

### 媒体 × 層

| 媒体 | 共通・媒体の基準 | 型・カタログ | 採点 | 主な所在 |
|---|---|---|---|---|
| **サイト・LP** | ◎ `docs/design-system.md`（参照実測に基づく数値基準）、`visual-density.md`（画像密度） | ◎ 雰囲気6型（`sites/_base/moods/*/mood.json`）、構図13型、taste 3種、業種 skill 5種 | ◎ 8項目＋`npm run measure:site` 自動計測 | website-sales-ai |
| **アプリ・管理画面** | ○ `docs/admin-design.md`（tokens・compact密度・空/読込/エラーの3状態・エラー文の型・DON'Ts・管理画面ゲート）／PET `docs/signature-ui/design.md`（色の運用・共通部品・行アクション）／hallmark polish（unslop の9パス） | ✕ なし（各プロジェクトが hallmark でテーマを選び直している） | △ admin-design の管理画面ゲート（手採点）のみ | website-sales-ai・PET・hallmark |
| **SNS 画像・動画** | ✕ 見た目の基準なし（文字サイズ・安全領域・1秒判読など） | ○ resto-sns `docs/ig-first/template-catalog.md`（構成7型 × ムード × 色、D7 準拠）／ai-ideas `p03-brand-exterior-reference-chain.md`（ブランドキット→複数フォーマット）／ai-tube `viral-marketing-playbook.md` | ✕ なし | resto-sns・ai-ideas・ai-tube |
| **資料** | ○ shiryo-slides `core/rules.md` `validation.md` | ○ 5テーマ（A〜E） | ○ Playwright 撮影＋自己確認 | ~/.claude/skills/shiryo-slides |
| **ゲーム** | △ study_world `docs/screen-design/game-ui-redesign-instruction.md`、`world-design.md` | — | — | study_world・ai-game |

### 共通層・工程層

| 資産 | 所在 | 備考 |
|---|---|---|
| hallmark（統合版・和文規則 `references/ja.md`） | ~/.claude/skills/hallmark | 2026-11-02 に unslop を統合 |
| UI心理学 | ai-development-skills `.skills/ui-ux-review/references/ui-psychology.md` | hallmark の psychology.md と内容が近い |
| 訴求の外部調査（希少性・社会的証明・デフォルトだけが効く、色やCTA文言は効果ゼロ 等） | website-sales-ai `docs/デザインシステムv2_構想_2026-10-30.md` §8 | **媒体共通の知見なのにサイト案件の文書の中にある** |
| 好み判定ループ（篠原の ◎○× を貯めて AI 採点に入れる） | 同 §9 | **媒体共通に効く仕組みなのにサイト限定** |
| 制作工程と合格判定 | ai-development-skills `design-gate-loop` | 媒体共通。ここは共有済み |
| 参照探索・3案提示・見比べ | `design-reference-scout`・`design-variant-preview` | 共有済み |
| 方向だけ決める設計メモ | screen-design-architect 出力の `design-system-brief.md`（CLEAN-TOILET・nikki_world・suizokukan・ai-consul-docs） | 書式は揃っている |

### ブランド層

| ブランド | 所在 | 状態 |
|---|---|---|
| YOTTO（紺×琥珀） | claude.ai artifact「YOTTO Design System」＋写し `website-sales-ai/docs/design-system.md` ＋ `sites/yotto-lp-a/assets/css/tokens.css` | 汎用基準と自社ブランドが同じ tokens に同居（v2 構想 §1-1 でも指摘済み）。yotto-hp は別の custom navy |
| 顧客の店・会社 | website-sales-ai `sites/<slug>/design-md-{existing,marketing,bold}.md` | サイト専用。SNS・資料から引ける形ではない |

## 2. hallmark を使ったプロジェクトのトークン（アプリ系の作り直しの実態）

| プロジェクト | 選んだテーマ | 画面の種類 | 共通に効くはずの判断 |
|---|---|---|---|
| shiseki_ai | Cobalt 派生 | 業務管理画面 | 状態色を区分ごとに固定し「色＋記号＋文言」の三重表示 |
| ai-ideas / qr-order | Cobalt・Workbench（**同一ファイル**） | 業務ツール | タップ 56px 以上・本文 16px 以上・コントラスト強め |
| ai-MCP | Almanac | アプリ | — |
| nikki_world | Newsprint 調整（明朝・朱） | LP＋会員アプリ | 下タブ＋公開側は別ナビ |
| ai-Live-Study | Hum | アプリ | — |
| yotto-hp | custom（navy・Zen Kaku） | 自社HP | — |

hallmark 原本の「前回と違うテーマを選べ」という多様化ルールが、**アプリでは毎回ゼロからの作り直し**になっている。アプリ同士で揃えるべき判断（状態表示・密度・タップ領域・3状態部品）が共有されていない。

## 3. 問題点

### 3-1. 埋もれている（他プロジェクトでも効くのに、1プロジェクトに閉じている）
1. **website-sales-ai `admin-design.md`** — いま手元にある**アプリ媒体の規則でいちばん完成度が高い**のに、サイト案件のリポジトリの中にある。
2. website-sales-ai v2 構想 §8（訴求の外部調査）と §9（好み判定ループ）。
3. PET `signature-ui/design.md` の共通部品・行アクション・色の運用。
4. shiseki_ai の状態色三重表示、ai-ideas の utilitarian の上書き値。

### 3-2. コピーで重複している（別々に育ち始める）
- aci-browser-answer ⇔ ai-chat-interview の `mockups/campaign/*tokens.css`（同一）
- ai-ideas ⇔ qr-order の `tokens.css`（同一）
- wsa-extcases・wsa-yotto-lp は website-sales-ai の古い clone（`sites/` の設計文書が丸ごと重複）
- nikki_world ⇔ nikki_world-sitemap、hibi-site ⇔ hibi-site-sitemap
- YOTTO Design System は claude.ai artifact が正本で、リポジトリ内は写し（正本が2箇所）

### 3-3. 欠けている
- **SNS 画像・動画の見た目基準**（型はあるが、文字サイズ・安全領域・判読時間・ブランドの引き継ぎ方が無い）
- **ブランド層**（店・自社の色と書体を、サイト・SNS・資料から同じファイルで引く仕組み）
- **アプリの型カタログ**（サイトの雰囲気6型にあたるもの）と自動採点

### 3-4. 「design.md」の書式が乱立
hallmark の `design.md`／PET の `design.md`／ai-ideas の `DESIGN.template.md`／website-sales-ai の `design-md-*.md`／Google Stitch の `DESIGN.md`／screen-design-architect の `design-system-brief.md`。役割が近いのに書式が6種類ある。

## 4. 次の段階への提案（優先順）

| 順 | やること | 理由 |
|---|---|---|
| 1 | ✅ 2026-11-02 `design/app.md` 作成。**アプリ媒体の基準を1本にまとめる**（admin-design.md ＋ PET signature ＋ shiseki・qr-order の判断 ＋ hallmark polish） | 対象プロジェクトが最も多く（7件以上）、毎回作り直しているので効き目が最大 |
| 2 | **サイト媒体はハブから website-sales-ai を参照する**（正本は動かさない） | 自動計測・mood.json の仕組みと結びついている。website-sales-ai には v2 ロードマップが進行中なので、移さず参照 |
| 3 | **媒体共通の知見を共通層へ昇格**（v2 §8 訴求調査・§9 好み判定ループ・UI心理学の一本化） | どの媒体でも効く。好み判定はデータが貯まるほど価値が上がる |
| 4 | **ブランド層の書式を1つ決める**（mood.json 形式を流用し、design.md 系の書式もこれに寄せる） | SNS・資料でブランドを引き継ぐ前提になる |
| 5 | **昇格ルールをグローバル CLAUDE.md に入れる** | 無いとまた散らばる |
| 6 | SNS 媒体は次の投稿案件で、resto-sns の型カタログを起点に作る | 机上で作ると外れる |
| — | 重複コピーの整理（wsa-* clone の扱いなど） | 削除は人の判断 |
