---
name: testmaster-full-plan
allowed-tools: Read, Grep, Glob, Bash, Write
description: AI Testmaster の「フル網羅」テスト項目生成。対象アプリのサーフェス(API/画面/DBテーブル/外部連携)をスクリプトで決定論的に列挙し、観点カタログ(正常/検証/認証/認可/RLS/異常/境界/UI/DB整合/領域固有/受け入れ)を機械的に当てて、サーフェス×観点マトリクスの空セルをゼロにするまで項目を作り込む。設計網羅率(分母の十分性)を測れる状態にして1回でimportする。トリガー例「テスト項目をフル網羅で作って」「網羅的にテスト項目を洗い出して」「設計網羅率を出して」「抜けなくテスト項目を作って」「サーフェスを全部列挙してテスト項目にして」。部分的に領域だけ作り直すのは testmaster-test-plan。実行(合否記録)は testmaster-run-api / testmaster-run-screen。既存台帳を疑うのは testmaster-adversarial-review。
---

# testmaster-full-plan（フル網羅のテスト項目生成）

「テスト項目が十分か」を **主観でなく検査可能**にするための分母生成スキル。
[[testmaster-test-plan]] が「気になる領域を素早く作る/差分更新する」担当なのに対し、
このスキルは **アプリ全体のサーフェスを取りこぼさず**列挙し、各サーフェスに観点カタログを
機械的に当てて、**空セル(GAP)がゼロになるまで**項目を作り込む。

## なぜマトリクスなのか（設計の芯）

テストの十分性は絶対には証明できない。できるのは「参照モデルに対して埋まっているか」を測ることだけ。
そこで **サーフェス台帳(横軸) × 観点カタログ(縦軸)** を分母のさらに外側に置き、そこからの欠落を
GAP として数える。これで「思いつかなかったテスト項目」が **空セルとして可視化**され、
抜けを探す仕事が「創造」から「検査」に変わる。

- **サーフェス** = API endpoint / 画面 / DBテーブル / 外部連携。**スクリプトで決定論的に列挙**（発想に頼らない）。
- **観点** = `normal / validation / authn / authz / rls / error / boundary / ui / db-integrity / domain-specific / acceptance`。
- 各セルは **covered（項目あり）/ na（理由付き対象外）/ gap（項目ゼロ）**。
- **設計網羅率 = (covered + na) / 全セル**。実施率（passed/項目数）とは別物。両方見て初めて安心できる。

## 自走コントラクト

- 入力は最初に1回だけ確認（一問一答にしない）。以後フェーズ途中で止めない。
- 中間結果は **必ずファイルに書く**（コンテキスト圧縮で項目が消えるのを防ぐ。頭の中に溜めない）。
- GAP 計算は **サーバの設計網羅率に委ねる**（LLM に「抜けてないか数えて」とやらせない）。
- import は **全置換**。組み立ててから **1回だけ** 送る（分割送信は前回分を消す）。

### 起動時にまとめて確認する入力

- **projectId** — testmaster のプロジェクト ID（`C:\work` 配下フォルダ名の slug。例 `ai-chat-interview`）。
- **対象アプリのコードパス** — テスト項目を起こす対象リポジトリのルート（例 `c:\work\ai-chat-interview`）。
- **testmaster のベース URL** — 既定 `http://localhost:3400`。

## 固定ヘルパー

HTTP は [[testmaster-run-all]] 同梱の `tm.mjs`、サーフェス列挙は本スキル同梱の `inventory.mjs` を使う。

```bash
# サーフェス列挙（app router を決定論的に走査 → surfaces.json）
node "$HOME/.claude/skills/testmaster-full-plan/scripts/inventory.mjs" <targetRoot> <outFile>
# 台帳取得 / import（bodyFile は全置換ボディ）
node "$HOME/.claude/skills/testmaster-run-all/scripts/tm.mjs" get    <tmBase> <projectId>
node "$HOME/.claude/skills/testmaster-run-all/scripts/tm.mjs" import <tmBase> <projectId> <bodyFile>
node "$HOME/.claude/skills/testmaster-run-all/scripts/tm.mjs" fp     <sourceFile> [start] [end]
```

作業ファイル（surfaces.json / items.ndjson / body.json）はスクラッチ領域に UTF-8 で書く。

## パイプライン（1コマンドで通す）

```text
Pass 0  Inventory : inventory.mjs で surfaces.json を生成（機械列挙）
Pass 1  Classify  : 実コードを読み、各サーフェスの applicablePerspectives を確定。
                    対象外の観点は na に「理由」付きで落とす（理由なし除外は禁止）
Pass 2  Generate  : サーフェスを数個ずつ、applicablePerspectives の各観点に対応する
                    テスト項目を作り items.ndjson に追記（1行1項目・頭に溜めない）
Pass 3  Crosscut  : successCriteria 由来の受け入れ項目・複数サーフェスをまたぐフロー・
                    Project-wide リスクを追加
Pass 4  Import    : surfaces + items を1つの body.json にまとめ tm.mjs import（全置換）
Pass 5  GapCheck  : tm.mjs get で designCoverage.gaps を読む。GAP が残れば該当セルの
                    項目を Pass 2 の要領で足す → 再 import。GAP=0 になるまで周回（最大5周）
Pass 6  Report    : 設計網羅率 / 実施率 / 残 na（理由）を要約して停止
```

### Pass 0 — Inventory（機械列挙）

`inventory.mjs <targetRoot> <scratch>/surfaces.json` を実行。API endpoint（route.ts の各 HTTP メソッド）・
画面（page.tsx）・DBテーブル（migrations）・外部連携（package.json の既知SDK）を列挙する。
**app/ が無い等でスクリプトが列挙できない場合のフォールバック**: pages router / 非 Next.js は
skill が実コードを読んで surfaces.json を同じスキーマで手起こしする（endpoint・画面・テーブル・連携を漏れなく）。

### Pass 1 — Classify（観点の確定）

surfaces.json の各サーフェスについて実コードを読み、`applicablePerspectives` を確定する。
inventory の既定（api = normal/validation/error/boundary 等）に、コードから読み取れる観点を足し引きする:

- 認証が要る endpoint → `authn` を足す。認可/ロール分岐があれば `authz`。他人/他テナントのデータを扱うなら `rls`。
- 副作用で DB 制約・トリガーに触れるなら `db-integrity`。フォーム/画面状態が絡むなら `ui`。
- コードの分岐・状態遷移から固有リスクがあれば `domain-specific`。
- **適用しない観点は消すのではなく `na` に理由付きで落とす**（例: 公開APIなので `authz` は na「認証不要の公開エンドポイント」）。
  理由なしの除外は禁止（対抗レビューで "怪しい na" として突かれる）。

### Pass 2 — Generate（観点→項目）

サーフェスを数個ずつ処理し、`applicablePerspectives` の各観点に **少なくとも1つ**の項目を作る。
description は「何を送ると、どの status/挙動になるべきか」を **反証可能**に書く
（弱い「表示される」ではなく、強い「0件で 200・`items:[]`・500 でない」）。各項目:

```
{ "area": "<surface.area と一致させる>", "title": "...", "description": "...",
  "category": "<観点: normal|validation|authn|...>", "priority": "critical|high|medium|low",
  "level": "detailed", "sourceFingerprint": "<派生元コードのハッシュ>" }
```

- `category` は観点カタログの値をそのまま入れる（サーバが設計網羅率の突き合わせに使う。未知は domain-specific に寄る）。
- `sourceFingerprint` は `tm.mjs fp <file> [start end]`（同一 source 由来は同じ値を共有）。
- **Context を踏まえ priority を寄せる**。successCriteria/constraints に近いものを critical/high に。
- 1項目ずつ `items.ndjson` に追記する（全部を頭に保持しない）。

### Pass 3 — Crosscut（横断）

- `project.context.successCriteria` があれば、それを直接検証する `acceptance` 項目を `Project-wide` に足す。
- 複数サーフェスをまたぐ主要フロー（登録→本人確認→回答 等）を1本の項目にする。
- データ分離（別プロジェクト/別テナントで漏れない）等の Project-wide リスク。

### Pass 4 — Import（全置換・1回）

surfaces.json の surfaces と items.ndjson の items を1つの body にまとめる:

```json
{ "mode": "replace-all",
  "surfaces": [ { "key":"api:GET /api/x", "kind":"api", "name":"GET /api/x",
                  "area":"API GET /api/x", "applicablePerspectives":["normal","validation","authn"],
                  "na":[{"perspective":"authz","reason":"認証のみ・ロール無し"}] } ],
  "items": [ ... ] }
```

`tm.mjs import <tmBase> <projectId> <bodyFile>` で送る。応答の `surfaceWarnings` に未知観点の捨て漏れが出たら直す。

### Pass 5 — GapCheck（空セルをゼロに）

`tm.mjs get` の応答 `designCoverage` を読む:

- `designCoverage.percent` = 設計網羅率。`gaps[]` = 項目ゼロのセル（`surfaceName` × `perspective`）。
- `gaps` が残っていれば、そのセルに対応する項目を Pass 2 の要領で足すか、正当なら surface の `na` に理由付きで移す。
- items/surfaces を更新して **再 import**（全置換）。`gaps.length === 0` になるまで周回（**最大5周**でガード）。

### Pass 6 — Report

```md
# フル網羅生成レポート: <projectId>
## サーフェス: api <n> / screen <n> / table <n> / integration <n>
## 設計網羅率: <p>%  （covered <c> / na <n> / gap <g> / 全 <t> セル）
## 実施率(参考): passed <y> / total <x> (<z>%) — 実行は run-api / run-screen で
## 残 na（理由付き対象外）: <数>  ／ 主要な na 理由
## 次の一手: critical+high から実行を回す（分母は全部揃った。実行は優先度順でよい）
```

## やらないこと（境界）

- 内蔵の Anthropic/OpenAI API は**呼ばない**（このエージェントが生成主体）。
- 実在しない endpoint/feature/画面を**推測で足さない**（サーフェスは inventory と実コードが根拠）。
- na に**理由を書かずに**観点を落とさない（GAP 隠しになる）。
- 対象アプリのコードは**変更しない**（読むだけ）。testmaster のスキーマ/コードも変えない（import API を使うだけ）。
- import は全置換。**分割送信しない**（前回分が消える）。巨大でも1 body にまとめる。

## 関連

部分生成・差分更新は [[testmaster-test-plan]]、合否記録は [[testmaster-run-api]] / [[testmaster-run-screen]]、
生成物を疑うのは [[testmaster-adversarial-review]]、1周自走は [[testmaster-run-all]]（フル網羅モードで本スキルを P1 に使う）。
観点軸の正は [[test-planner]]。
