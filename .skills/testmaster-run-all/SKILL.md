---
name: testmaster-run-all
allowed-tools: Read, Grep, Glob, Bash, Edit, Write, Skill
description: AI Testmaster の1周（①テスト項目生成 → ②API合否記録 → ②画面/LIFF合否記録 → ③対抗レビュー → ④差し戻し反映）を、対象プロジェクトに対して停止せず一気通貫で自走させるオーケストレータ。対抗レビューの指摘がゼロになるまで自動で周回し、不合格が出たら「軽微(UI文言・明らかな小バグ)」は自動修正して再テスト、「重い(ロジック/DB/認可/課金/外部連携/破壊系)」は直さず不合格レポートに溜めて周回を止めて報告する。全ての HTTP/ fingerprint は固定ヘルパー scripts/tm.mjs 経由に集約し、アドホックな curl/sha1sum を出さないことで無人自走を可能にする。トリガー例「testmaster を一気に回して」「テスト作成から対抗レビューまで自走して」「<project> のテストを全部回して指摘ゼロまで自動で」「テストを止まらずに回して」「フル周回して」。単一フェーズだけ回したいときは testmaster-test-plan / testmaster-run-api / testmaster-run-screen / testmaster-adversarial-review を個別に使う。
---

# testmaster-run-all（テスト全周回の自走オーケストレータ）

testmaster の1サイクル（①生成 → ②API → ②画面 → ③対抗レビュー → ④差し戻し）を、
**フェーズ間で止まらず** 自動で周回させる担当。個別スキル（[[testmaster-test-plan]] /
[[testmaster-run-api]] / [[testmaster-run-screen]] / [[testmaster-adversarial-review]]）は
それぞれ末尾で停止ゲートを持つ設計なので、そのまま連結すると各フェーズで止まる。
このスキルは **フローを自分で保持** し、各フェーズの手順・判定基準は個別スキルのものを踏襲しつつ、
I/O を固定ヘルパーに集約して連続実行する。

## これは「2つのループ」を回している

- **ループA（台帳品質）**: ①〜④。分母生成 → 合否記録 → 対抗レビュー → 台帳の差し戻し。
  アプリのコードは触らない。**常に自動で回してよい**。
- **ループB（改修）**: テストが「不合格＝アプリのバグ」を出したときにアプリ本体を直す。
  **重さで線を引く**（下記「改修の線引き」）。軽微は自動、重いは止めて報告。

## 自走コントラクト（重要）

- 実行に必要な入力は **最初に1回だけまとめて** 確認する（一問一答にしない）。以後は止めない。
- フェーズ途中では **人間に確認を求めない**。判断はこのスキルの規則で機械的に下す。
- 例外的に周回を止めてよいのは次の2つだけ:
  1. **重い不合格 / 設計判断が必要な指摘** が出たとき → 直さず不合格レポートに溜め、周回終了時にまとめて報告。
  2. **入力不足・対象アプリが起動不能で全項目 blocked** など、続行が物理的に不可能なとき。
- それ以外はすべて自動で次フェーズ・次周回へ進む。

### 起動時にまとめて確認する入力

- **projectId** — testmaster のプロジェクト ID（`C:\work` 配下フォルダ名の slug。例 `ts-connect`）。
- **対象アプリのコードパス** — テスト対象リポジトリのルート（例 `c:\work\ts-connect`）。
- **testmaster のベース URL** — 既定 `http://localhost:3400`。
- **対象アプリのベース URL** — 実リクエスト/ブラウザで開く先（例 `http://localhost:3000`）。未起動なら起動方法。
- **改修の線引き** — 既定は「軽微は自動・重いは停止して報告」。ユーザーが別指定した場合のみ従う。
- **モード** — 通常（既定）か フル網羅か（トリガー文言で判定。「フル網羅」「設計網羅率」ならフル網羅モード）。

不足があればこの一覧を1回で提示して埋めてもらい、埋まったら止めずに進む。

## 固定ヘルパー（プロンプト源を出さないための核）

全ての HTTP と fingerprint は **`scripts/tm.mjs`（このスキル同梱）経由** で行う。
アドホックな `curl` / `sha1sum` / インライン JSON を使わない（それらは許可ダイアログを出し自走を止めるため）。
呼び出しは常にこの正準形（絶対パス）で行う:

```bash
node "$HOME/.claude/skills/testmaster-run-all/scripts/tm.mjs" <cmd> ...
```

| 用途 | コマンド |
|---|---|
| 台帳取得 | `tm.mjs get <tmBase> <projectId>` → bundle(JSON) |
| 分母 import（全置換） | `tm.mjs import <tmBase> <projectId> <itemsFile>` |
| 合否 run 記録 | `tm.mjs run <tmBase> <projectId> <runFile>` |
| fingerprint 算出 | `tm.mjs fp <sourceFile> [start] [end]` → 16桁ハッシュ |
| 対象アプリへ実リクエスト | `tm.mjs req <METHOD> <url> [--json <file>] [--header k:v] [--token <bearer>]` → `STATUS <n>` + body |
| 疎通確認 | `tm.mjs ping <url>` → `STATUS <n>` / `DOWN` |

- import / run の payload、req の --json body は **Write ツールで UTF-8 ファイルに書き出してから** 渡す
  （日本語 notes の CP932 化けを回避。tm.mjs は生バイトを送る）。作業ファイルはスクラッチ領域に置く。
- ブラウザ操作（画面/LIFF）だけは `webapp-testing` skill（Playwright）を使う。ここは既に許可済み。

## モード（通常 / フル網羅）

起動時のトリガーで2モードを切り替える（P3/P4 の周回構造は共通）:

- **通常モード**（既定・「一気に回して」）: P1 は [[testmaster-test-plan]] 方式で対象コードから分母を生成/更新。
- **フル網羅モード**（「フル網羅で一気に回して」「設計網羅率を出して」）: P1 を [[testmaster-full-plan]] の
  パイプライン（inventory → 観点付け → 生成 → surfaces 同梱 import → GAP=0 まで）に差し替える。
  P2 の実行は既定で **critical+high の輪切り**（分母は全部あってよい／実行は優先度順）。
  対抗レビュー(P3)は `designCoverage` の gap/na（軸 D）も突く。

どちらのモードでも import は tm.mjs 経由。フル網羅の surfaces は import body に同梱する（`mode:"replace-all"` ＋ `surfaces`）。

## 周回の流れ

```text
[入力を1回で確定（モードも確定）] → ループ開始
 ├ P1 生成:   通常=対象コードから分母生成/更新 ／ フル網羅=full-plan パイプラインで生成し import
 ├ P2 API:    API契約系を tm.mjs req で実行し run 記録
 ├ P2 画面:   画面/LIFF系を webapp-testing で実行し run 記録
 ├ P3 対抗:   台帳を対抗レビューし、抜け/甘い/偽合格を検出
 ├ P4 差し戻し反映:
 │    ├ 台帳の差し戻し(抜け追加・甘い項目強化)   → 常に自動で P1 の生成に織り込む
 │    ├ 不合格が「軽微」                        → アプリを自動修正 → 触ったコードは fp が変わり stale 化 → 再テスト対象
 │    └ 不合格が「重い」/設計判断              → 直さず不合格レポートに追記（周回は続行）
 └ 終了判定:
      対抗レビューの指摘=0 かつ 未処理の軽微=0  → 完了して要約
      重い不合格のみ残る                        → 周回を止めて不合格レポート＋確認事項を提示
      それ以外                                  → 次周回へ（P1 へ戻る）
```

- **最大周回数を 5 でガード** する（無限ループ防止）。5 周しても指摘が収束しなければ、残課題を要約して止める。
- 各周回の頭で `tm.mjs get` を叩き直し、stale/untested を再計算してから進む。

### P1 生成（通常=[[testmaster-test-plan]] / フル網羅=[[testmaster-full-plan]] の方法を踏襲）

> **フル網羅モードのときは** 下記 2〜5 の代わりに [[testmaster-full-plan]] のパイプラインを回す:
> `inventory.mjs` でサーフェス列挙 → 実コードで観点付け（対象外は na＋理由）→ 観点ごとに項目生成 →
> `surfaces` を同梱して `mode:"replace-all"` で import → `tm.mjs get` の `designCoverage.gaps` がゼロになるまで周回。
> その後 P2 は critical+high の輪切りから実行する。

1. `tm.mjs get` で bundle を取得（初回は空でも可）。`project.context`（users/constraints/successCriteria）を読む。
2. 対象コードを Grep/Glob/Read で洗い出し、**実在する** endpoint/feature/画面だけを area に整理。
3. 観点を機械的に当てて項目を列挙。観点軸は [[test-planner]] のフレームを正とする:
   正常系 / 異常系（不正入力・失敗時挙動・エラー表示）/ 権限別（ロールごとの可否）/
   RLS別（他人・他テナント・未認証での到達不能性）/ UI操作（二重送信・画面状態）/
   API契約（status/response）/ DB整合性（制約・トリガー副作用）/ 境界 / 領域固有。
   successCriteria があれば `Project-wide` に直接検証項目を足す。**P3 の差し戻し（抜け・強化）をここで反映**。
4. 各項目に fingerprint を付与（`tm.mjs fp <file> [start end]`。同一 source 由来は同じ値を共有）。
5. 全項目を1つの items ファイルに書き出し、`tm.mjs import` で **全置換**（分割送信しない）。

### P2 API（[[testmaster-run-api]] の方法を踏襲）

1. `tm.mjs ping <targetBase>` で疎通。落ちていれば起動を試み、無理なら該当項目を blocked。
2. HTTP だけで判定できる項目を抽出（status/検証/認証認可/異常境界/本文契約）。
3. `tm.mjs req` で実リクエスト（認証系は無/不正トークン、検証系は欠落/不正 body、異常系は不存在 ID）。
4. 各項目の判定（passed/failed/blocked）を run ファイルに書き `tm.mjs run` で記録。notes に「何を送り何を確認したか」を必ず残す（証拠なし合格を作らない）。

### P2 画面（[[testmaster-run-screen]] の方法を踏襲）

1. `webapp-testing` skill でブラウザを起動し targetBase を開く。
2. 画面描画/遷移/フォーム/エラー画面/LIFF が要る項目を実行。各項目でスクショを取り根拠にする。
3. LIFF は dev/モックで開ける分だけ検証、実機必須で代替が無ければ blocked。
4. 判定を `tm.mjs run` で記録（notes に観察結果＋スクショパス）。

### P3 対抗レビュー（[[testmaster-adversarial-review]] の方法を踏襲）

1. `tm.mjs get` で最新 bundle を取り、各項目の現行状態（passed/failed/blocked/stale/untested）を自分で再計算。
2. 実コードと突き合わせ、三軸で批判: **A 抜け / B 甘い受け入れ / C 偽の合格（stale・証拠なし）**。
3. 認可/所有者系（IDOR 等）は「二段階検証」を守り、DB 層（RLS/service_role）を確認するまで断定しない。
   断定できないものは **重い/設計判断** として不合格レポートへ（自動修正しない）。
4. 指摘を重大度付きで内部レポート化。**このスキルは台帳を書き換えないルールの例外**として、
   差し戻し（抜け追加・甘い項目強化）は P4→P1 で自分の import に織り込む（外部の import/run 書き込みは tm.mjs のみ）。

### P4 差し戻し反映と改修

- **台帳側の差し戻し**（抜け・甘い項目）: 常に自動。次の P1 生成に反映して import。
- **アプリ側の不合格**: まず [[bug-investigator]] の手順で原因を切り分けてから
  （症状確定 → Next.js/Supabase のレイヤー特定 → 原因確定）、下の「改修の線引き」で軽微/重いを判定し分岐。
  **原因不明のまま軽微と判定しない**。切り分け結果（原因ファイル・レイヤー）は run の notes と不合格レポートに残す。

## 改修の線引き（軽微 vs 重い）

**軽微（＝自動修正してよい）** — 全て満たすもの:
- UI 文言/ラベル/タイポ、明らかな小バグ（誤 default 値、null/空の表示崩れ、軽微な条件ミス）。
- 単一ファイルに閉じ、diff が小さい（修正前に [[system-investigator]] の方法で該当箇所の利用元を確認し、
  共有コンポーネント・複数呼び出し元に波及するなら「重い」へ昇格する）。
- DB/スキーマ/マイグレーション・認証/認可・課金・外部 API 連携・破壊的操作に**触れない**。

軽微を修正したら: 触ったソースの fingerprint が変わる → 次の P1 で該当項目が **stale** に落ちる →
自動で再テスト対象になる（履歴は残る）。修正内容は不合格レポートに「自動修正済み」として記録する。

**重い（＝直さず止めて報告）** — いずれかに該当:
- ロジック/アルゴリズムの変更、DB/スキーマ/マイグレーション、認証/認可、課金、外部連携。
- 破壊的操作を含む、複数ファイル横断、設計判断が必要（対抗レビューの所有者/仕様ズレ系）。

重い不合格は不合格レポートに溜め、周回終了時にまとめて提示（Claude Code 用の改修指示ドラフトを添える）。
勝手にアプリの重い改修を実装しない。改修指示ドラフトが DB/スキーマ/マイグレーション変更を含む場合は、
「適用前に [[migration-review]] を通す」ことを指示文に必ず含める。

## 完了時の出力

```md
# testmaster 全周回レポート: <projectId>

## 結果
周回数 N / 終了理由: <指摘ゼロで完了 | 重い不合格が残存 | 最大周回到達>

## Coverage
- total <x> / passed <y> (<z>%) / important(critical+high) <..>% / stale <..> / untested <..>

## 自動で行ったこと（ループA + 軽微改修）
- 分母: 追加/強化した area・観点
- 記録した run: passed/failed/blocked の内訳
- 軽微改修: <ファイル: 何を直したか>（→ stale 化して再テスト済み/対象）

## 止めて報告する項目（重い不合格 / 設計判断）
| # | area / 項目 | 種別 | 内容 | 提案する改修指示（Claude Code 用） |
|---|---|---|---|---|

## 確認事項（ユーザーが Yes/No で返せる）
- [ ] ...
```

## やらないこと（境界）

- **重いアプリ改修を無人で実装しない**（DB/認可/課金/ロジック/破壊系）。溜めて報告して止まる。
- testmaster への書き込みは **tm.mjs（import/run）経由のみ**。手打ち curl でスキーマ外の書き込みをしない。
- 本番/共有データへの破壊的テストをしない（隔離が無ければ blocked）。
- 推測で endpoint/feature を増やして分母を汚さない。**実在するコード**を根拠にする。
- 対象が全項目 blocked（未起動・環境不能）なら、無理に passed をでっち上げず理由を残して止める。

## 関連

分母生成 [[testmaster-test-plan]]（部分・差分）/ フル網羅生成 [[testmaster-full-plan]] /
API実行 [[testmaster-run-api]] / 画面実行 [[testmaster-run-screen]] /
対抗レビュー [[testmaster-adversarial-review]] を1周に束ねたもの。ブラウザ基盤は `webapp-testing`。
補助スキル: 観点軸 [[test-planner]] / 不合格の原因切り分け [[bug-investigator]] /
影響範囲確認 [[system-investigator]] / DB変更の安全確認 [[migration-review]]。
台帳以外の判断物（テスト方針・線引きそのもの）を疑うときは [[adversarial-review]]。
重い改修は実装フェーズ（[[agent-planner]] → Claude Code 実装 → [[agent-tester]]）へ引き渡す。
