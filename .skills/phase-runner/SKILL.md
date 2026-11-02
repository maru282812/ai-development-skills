---
name: phase-runner
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, Skill
metadata:
  reasoning-tier: standard
  summary: "実装指示書(Phase 1..N)を、フェーズごとに fresh context のサブエージェントへ投げて自走実装するオーケストレータ。各フェーズは done ゲート(typecheck/test/build/verify。docs/VERIFY.md があればそれを優先)が緑→独立チェッカー(maker と別サブエージェント)が pass→Receipt 記録を経てから次へ進み、軽微な不具合は自動修正・重い問題(DB/認可/課金/破壊系/仕様の曖昧さ)は直さず周回停止して報告する。進捗は phase-status.md を唯一の真実として受け渡す。"
description: >-
  実装指示書(Phase 1..N)を、フェーズ間で止まらず自走実装させるオーケストレータ。
  各フェーズを fresh context のサブエージェントに丸投げして変動コンテキストの堆積をリセットし、
  親セッションは進捗(phase-status.md)と短い結果サマリだけを保持する。各フェーズは done ゲート
  (typecheck / test / build / /verify)が緑になってから次へ進む。不合格は「軽微(文言・小バグ・単一ファイル)」
  は自動修正、「重い(DB/スキーマ/認可/課金/外部連携/破壊系/ロジック変更/仕様の曖昧さ)」は直さず周回停止して報告する。
  トリガー例:
  「実装を自走して」「フェーズを止めずに回して」「Phase1から10まで自動で実装して」
  「実装指示書を最後まで回して」「AUTOで実装を進めて」「フェーズ自走」「実装フェーズを一気に回して」
  「セッションを分けながら自動で実装して」。
  実装計画/指示書そのものを作るのは implementation-planner / feature-spec-writer(このスキルはその出力を入力に取る)。
  1フェーズだけ手で実装したいときや小規模(実質3フェーズ以下)の改修には使わない。
---

# phase-runner（実装フェーズ自走オーケストレータ）

既にある実装指示書（Phase 1..N）を、**フェーズ間で止まらず** 自動で実装まで進める担当。
[implementation-planner](../implementation-planner/SKILL.md) / [feature-spec-writer](../feature-spec-writer/SKILL.md) が
作った Phase 分け指示文を **入力** に取り、各フェーズを **fresh context のサブエージェント** に投げて実装させ、
done ゲートで検証し、緑なら次フェーズへ進む。testmaster の [testmaster-run-all](../testmaster-run-all/SKILL.md) の
「実装版」にあたる自走オーケストレータ。

## なぜサブエージェント方式か（top-level セッション分割ではない）

「フェーズごとにセッションを割る」目的は **固定コスト削減ではなく、変動コンテキスト（長い会話ログ・死んだ探索・失敗ログ）の堆積をフェーズ境界でリセットすること**。

- top-level セッションを N 個に割ると、CLAUDE.md / MEMORY.md / ツール定義などの **固定コストを N 回払う**（コールドスタート×N）。狙いと逆行する。
- **サブエージェントは毎回コールド起動（fresh context）** なので、変動コンテキストだけをリセットできる。親（このスキル）は各フェーズの短い結果サマリだけを受け取り、ほぼ肥大化しない。
- よって本スキルは「フェーズ = 1サブエージェント」を基本単位にする。真のプロセス分離（headless `claude -p`）は非対話で権限プロンプトに詰まり監督しにくいため、正規フローには使わない。

### コンテキストリセットの3手段（なぜ /clear でも auto-compaction でもなくサブエージェントか）

| 手段 | リセット単位 | 自動化 | 固定コスト | 位置づけ |
|---|---|---|---|---|
| **/clear** | 同一セッションの文脈を手動で全消し | ❌ 人が毎フェーズ打つ | 減らない（毎回再読込） | 発想は本スキルと同じ（境界で変動分を捨てる）。ただし手動なので AUTO に乗らない。state をファイルに逃がさないと消える |
| **auto-compaction** | 長くなると自動要約 | ⭕ 勝手に効く | 減らない | 非可逆・要約で情報が落ち、境界を選べない |
| **サブエージェント（本スキル）** | フェーズ単位で fresh context | ⭕ 親が自動 dispatch | サブの分は小さい・親は amortize | AUTO で回せる正規手段 |

`phase-runner` は実質「**/clear を自動化し、オーケストレータに state（phase-status.md）を持たせた版**」。どの手段でも**固定コストは減らない**点は共通（＝「セッションを割れば固定コストが減る」は誤り。狙いは変動分の堆積抑制）。

## 使うとき / 使わないとき

- **使う**: 実質 **4フェーズ以上** の大型実装で、指示書が既にあり、各フェーズに機械判定できる完了条件があるもの。
- **使わない**:
  - 小規模（実質3フェーズ以下）→ オーケストレーション往復の方が高コスト。普通に1セッションで実装する。
  - 指示書がまだ無い → 先に [implementation-planner](../implementation-planner/SKILL.md) で Phase 分け指示文を作る。
  - 環境構築・アカウント作成など**コードを書かない準備工程（Phase 0系）** → 指示書から直接手順化する（implementation-planner の対象外境界と同じ）。

## 自走コントラクト（重要）

- 実行に必要な入力は **最初に1回だけまとめて** 確認する（一問一答にしない）。以後は止めない。
- フェーズ途中では **人間に確認を求めない**。判断はこのスキルの規則で機械的に下す。
- サブエージェントは **ユーザーに質問できない**（最終メッセージが親に返るだけ）。仕様が曖昧で決められない時は、サブは推測で進めず `blocked: needs-decision` を返し、**親が周回を止めて人間へ**エスカレーションする。
- 例外的に周回を止めてよいのは次の3つだけ:
  1. **重い不合格 / 設計判断が必要**（DB/認可/課金/破壊系/ロジック変更/仕様の曖昧さ）→ 直さず残課題に溜め、停止して報告。
  2. **done ゲートが規定回数リトライしても緑にならない** → 該当フェーズで停止し、失敗ゲート出力を添えて報告。
  3. **続行が物理的に不可能**（指示書欠落・対象リポジトリが開けない・全フェーズ blocked）。
- それ以外はすべて自動で次フェーズへ進む。

### 起動時にまとめて確認する入力

| 項目 | 内容 / 既定 |
|---|---|
| **実装指示書パス** | Phase 1..N を含むファイル（implementation-planner / feature-spec-writer の出力）。 |
| **対象リポジトリ root** | 実装先の絶対パス（例 `c:\work\ai-tube`）。 |
| **done ゲート** | 各フェーズ完了判定コマンド。**対象リポジトリに `docs/VERIFY.md`（factory-bootstrap 設置の検証レシピ）があればその §1 Gates ＋ §2 Runtime Verify を既定にする。** 無ければ既定 = `typecheck` → `test` → `build`（存在するものだけ）＋可能なら `/verify`。プロジェクト固有コマンドがあれば上書き。 |
| **progress ファイルパス** | 進捗の唯一の真実。既定 = 対象リポジトリ root の `phase-status.md`。既存があれば **続きから**再開する。 |
| **改修の線引き** | 既定「軽微は自動・重いは停止して報告」。ユーザー別指定時のみ従う。 |
| **開始 / 終了フェーズ** | 既定 = 1..N 全部。途中再開・部分実行の指定があれば従う。 |

不足があればこの一覧を1回で提示して埋めてもらい、埋まったら止めずに進む。

## progress ファイル（phase-status.md）＝受け渡しバトン

fresh session は文脈を持たない。**phase-status.md が唯一の handoff**。親が read/write の権威を持ち、サブは read して末尾に短い結果を追記する。

```md
# Phase Status: <機能名>
指示書: <path>  / 対象repo: <path>  / ゲート: <commands>

## Phases
| # | 名前 | 状態 | ゲート | 更新 |
|---|------|------|--------|------|
| 1 | ...  | done | green  | <ts> |
| 2 | ...  | in-progress / done / blocked / failed-gate / todo | ... | ... |

## 確定した決定 / 前提（後フェーズが依存）
- ...

## 未解決課題（重い・要人間判断）
- [ ] Phase k: <内容>

## フェーズ別ログ（サブが追記）
### Phase 2 — <ts>（Receipt）
- 変更ファイル: ...
- ゲート結果: <コマンドと結果（緑の証拠）>
- runtime verify: <確認した画面/操作・スクショ所在（該当時）>
- checker 判定: pass / minor対応済み（<内容>）
- 自動修正した軽微: ...
- 次フェーズへの申し送り: ...
```

## 周回の流れ

```text
[入力を1回で確定] → phase-status.md を用意（無ければ指示書から生成 / あれば再開点を特定）
  loop  N = 開始..終了フェーズ:
   ├ 1. phase-status を read し、Phase N の状態が done なら skip
   ├ 2. Phase N を fresh サブエージェントへ dispatch（同期・run_in_background:false）
   │      サブへの指示 = 下記「サブエージェント指示テンプレ」
   ├ 3. サブの返却（done / failed-gate / blocked / heavy）を受け取る
   ├ 3.5 ゲート緑なら独立チェッカーへ dispatch（maker と別の fresh サブエージェント）
   │      指摘なし → 4 へ / 軽微指摘 → maker へ再 dispatch（リトライ K 回に含める）
   │      重い指摘 → 未解決課題に記録して停止
   ├ 4. 判定:
   │      done(ゲート緑+checker OK) → Receipt を phase-status に記録し done に更新 → 次 N へ
   │      failed-gate        → 同一フェーズを最大 K=2 回まで再 dispatch（失敗ゲート出力を渡す）→ 超過で停止
   │      blocked/heavy      → 未解決課題に記録し、周回を止めて報告
   └ 5. 進捗を毎回 phase-status.md に永続化（クラッシュしても再開できる状態を保つ）
  終了 → 完了レポート
```

- **フェーズ数ぶんの上限**でガードする（指示書の N を超えて勝手にフェーズを増やさない）。
- 各フェーズ dispatch の直前に phase-status を読み直し、依存する「確定した決定」をサブに渡す。

### サブエージェント指示テンプレ（親が組み立てて Agent に渡す）

> あなたは Phase N のみを実装する。**Phase N+1 以降には進まないこと。**
> 1. 実装指示書 `<path>` の **Phase N の節だけ** を読む。
> 2. `<repo>/phase-status.md` の「確定した決定/前提」と直前フェーズの申し送りを読み、それに従う。
> 3. Phase N を実装する。既存の実装パターン（クライアント使い分け・ディレクトリ構成・バリデーション）に合わせる。
> 4. done ゲート `<commands>` を実行し、**緑になるまで** Phase N の範囲で直す。
> 5. 実装中に「軽微」を超える判断（DB/スキーマ/認可/課金/外部連携/破壊的操作/ロジックの仕様変更/指示書が曖昧で複数解釈可能）に突き当たったら、**推測で進めず**その場で止め、`blocked: needs-decision` として論点を返す。
> 6. 返却フォーマット（親が phase-status に転記する）:
>    - `RESULT: done | failed-gate | blocked`
>    - `CHANGED:` 変更ファイル一覧
>    - `GATE:` 実行コマンドと結果（緑/赤の証拠。赤なら失敗出力の要点）
>    - `MINOR-FIXES:` 自動修正した軽微（無ければなし）
>    - `HANDOFF:` 次フェーズへの申し送り・前提
>    - `NEEDS-DECISION:` 人間判断が要る論点（blocked 時のみ）
> 調査だけで完結する下位タスクはさらに Explore サブエージェントに分けてよい。**指示書に無い機能を推測で足さない。**

### 独立チェッカー（Maker → Checker）

コードを書いた maker 自身に「問題ないか」を聞かない。ゲートが緑になったフェーズは、
**maker と別の fresh サブエージェント**（checker）に独立レビューさせてから done にする。

- checker への入力: Phase N の diff・指示書の Phase N 節・phase-status の確定した決定・
  対象 repo の `docs/VERIFY.md` §3（Checker 観点）。
- checker の観点（VERIFY.md が無い場合の既定）:
  1. 仕様との一致（受け入れ条件を満たすか。**指示書に無い機能を足していないか**）
  2. 型・境界・エラーハンドリング・既存機能への影響（[code-review](../code-review/SKILL.md) の観点）
  3. 認証認可・RLS・バリデーション（該当する変更のとき。深掘りは [security-review](../security-review/SKILL.md)）
  4. **ゲート改変の検出**（テスト削除・assert 緩和で緑にしていないか — 見つけたら「重い」で停止）
- checker は**指摘して返すだけ**で自分では直さない（修正は maker への再 dispatch）。
- 返却: `CHECK: pass | minor(<指摘一覧>) | heavy(<論点>)`。

### Receipt（証拠付き製造記録）

checker が pass したら、親はフェーズ別ログの追記を **Receipt** として完成させる
（下記テンプレの「ゲート結果」に加えて **runtime verify の確認内容・スクショ所在・checker 判定**まで
残す。形式は [verification-loop](../verification-loop/SKILL.md) の Receipt に合わせる）。
証拠の無い done を作らない — ゲート出力・確認内容を書けないフェーズは done にしない。

## 改修の線引き（軽微 vs 重い）— testmaster-run-all と同一哲学

**軽微（サブが自動修正してよい）** — すべて満たすもの:
- UI 文言/ラベル/タイポ、明らかな小バグ（誤 default、null/空の表示崩れ、軽微な条件ミス）。
- 単一ファイルに閉じ diff が小さい（共有コンポーネント・複数呼び出し元に波及するなら「重い」へ昇格）。
- DB/スキーマ/マイグレーション・認証/認可・課金・外部API連携・破壊的操作に**触れない**。

**重い（直さず止めて報告）** — いずれか該当:
- ロジック/アルゴリズム変更、DB/スキーマ/マイグレーション、認証/認可、課金、外部連携、破壊的操作。
- 複数ファイル横断、設計判断が必要、**指示書が曖昧で複数解釈でき人間が決めるべき**もの。

重い項目は未解決課題に溜め、周回終了時にまとめて提示（Claude Code 用の改修/意思決定ドラフトを添える）。
改修ドラフトが DB/スキーマ/マイグレーション変更を含む場合は「適用前に [migration-review](../migration-review/SKILL.md) を通す」を必ず明記する。

## 完了時の出力

```md
# フェーズ自走レポート: <機能名>

## 結果
実行フェーズ N/総フェーズ M / 終了理由: <全フェーズ done | 重い課題で停止 | ゲート未達で停止 | 続行不能>

## フェーズ結果
| # | 名前 | 状態 | ゲート | 備考 |
|---|------|------|--------|------|

## 自動で行ったこと
- 実装したフェーズ / 各フェーズの主な変更
- 自動修正した軽微: <ファイル: 何を直したか>

## 止めて報告する項目（重い / 要人間判断）
| # | フェーズ | 種別 | 内容 | 提案する対応（Claude Code 用ドラフト） |
|---|---------|------|------|----------------------------------------|

## 確認事項（ユーザーが Yes/No で返せる）
- [ ] ...

## 再開方法
- phase-status.md は <path>。決定後、同じ入力で再実行すれば <Phase k> から続行する。
```

## やらないこと（境界）

- **重い改修を無人で実装しない**（DB/認可/課金/ロジック/破壊系/曖昧仕様）。溜めて報告して止まる。
- 実装指示書に**無い機能を推測で足さない**。指示書を唯一のスコープ源とする。
- サブが done ゲートを**でっち上げで緑にしない**（テストを削る・assert を緩める等）。ゲート改変は「重い」扱いで停止。
- top-level セッションを割って固定コストを二重払いしない（サブエージェントで変動分だけリセットする）。
- 小規模（3フェーズ以下）や準備工程には適用しない（上記「使わないとき」）。

## 関連

入力の指示書を作る [implementation-planner](../implementation-planner/SKILL.md) / [feature-spec-writer](../feature-spec-writer/SKILL.md)。
自走の雛形 [testmaster-run-all](../testmaster-run-all/SKILL.md)。各フェーズ内で使う補助:
不合格の原因切り分け [bug-investigator](../bug-investigator/SKILL.md) / 影響範囲確認 [system-investigator](../system-investigator/SKILL.md) /
DB変更の安全確認 [migration-review](../migration-review/SKILL.md)。フェーズ内の実行時検証手順は [verification-loop](../verification-loop/SKILL.md)、
検証レシピ（VERIFY.md）と保守ループの設置は [factory-bootstrap](../factory-bootstrap/SKILL.md)。実装後の軽量検証は [agent-tester](../agent-tester/SKILL.md)、
次の一手の抽出は [agent-planner](../agent-planner/SKILL.md)。方式そのもの（線引き・適用可否）を疑うときは [adversarial-review](../adversarial-review/SKILL.md)。

# 実行モデルティア

推奨ティア: **standard**（オーケストレーション自体は手順追従型）。ただし各フェーズのサブエージェントは
**実装の難度に応じてティアを選ぶ**（定型実装=standard、設計判断を含むフェーズ=deep）。
「軽微/重い」の線引き判断が難しいケースに突き当たったら、その論点を明示して停止し人間へ。
具体的なモデル名はここに書かない（対応表は `.skills/MODEL-TIERS.md`）。
