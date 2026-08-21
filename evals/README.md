# evals — Skill トリガー精度の評価

このディレクトリは、自作 Skill の **発火精度（should_trigger / should_not_trigger）** を検証するためのテストケースを置く場所です。

## 目的

- 兄弟 Skill（scope vs requirements、business vs operations、risk vs nfr など）の**誤発火**を抑える
- バンドル重複 Skill（`code-review` / `security-review`）が**汎用依頼で発火しすぎない**境界を確認する
- description 改善の前後で**トリガー精度の回帰**を検出する

## ファイル

- [evals.json](evals.json) — 人間可読の元データ（12 Skill、should_trigger / should_not_trigger / expected_output / notes）
- [trigger/](trigger/) — 上記を **skill-creator のトリガーeval形式**へ変換した skill 単位ファイル（`[{ "query": ..., "should_trigger": true|false }]`）。**A群13本は正10/負10=20件へ拡充済み**。残り3本（legal-publication-manager / migration-review / project-quality-tooling）は6件（B/C層のため次点）
- [run-trigger-eval.ps1](run-trigger-eval.ps1) — skill-creator の `run_loop` をワンコマンド／一括で回す runner（`claude` CLI が PATH にある端末で実行。内部で win/run_loop_win.py を使用）
- [win/run_loop_win.py](win/run_loop_win.py) — **Windows 対応 launcher**。skill-creator の Windows 非対応バグ（`select` on pipe）を本体改変なしで回避（後述）
- [skill-methodology.md](skill-methodology.md) — スキル別に「eval駆動(TDD)で詰める / 現状維持」を判定した方針

## skill-creator の eval は2系統ある（重要）

| 系統 | 何を測るか | フォーマット | 実行 | 我々の用途 |
|---|---|---|---|---|
| **出力eval** `evals/evals.json` | skill の**出力品質** | `{skill_name, evals:[{id, prompt, expected_output, files, expectations}]}` | subagent で with/without 比較 → benchmark | 今回は対象外 |
| **トリガーeval**（description最適化） | skill が**正しく発火するか** | `[{query, should_trigger}]`（推奨20件 = 正8〜10 / 負8〜10の近接ケース） | `scripts/run_loop.py`（`claude -p` をsubprocess起動） | ★ **これが目的**。兄弟競合・バンドル重複の発火境界を測る |

→ 我々の `evals.json`（should_trigger/should_not_trigger）は **トリガーeval** に対応する。`trigger/<skill>.json` がその正式形式。
→ 出力eval（`expectations` で出力検証）とは別物。混同しないこと。

## 実行手順（トリガー精度の測定・description最適化）

`claude` CLI が PATH にある端末で、同梱 runner を使うのが簡単（skill-creator パスは自動解決）:

```powershell
# A群13本を一括
powershell -File evals/run-trigger-eval.ps1 -All
# 1本だけ
powershell -File evals/run-trigger-eval.ps1 -Skill scope-discovery
```

手動で直接叩く場合（runner と等価）:

```bash
cd <SC>            # <SC> = plugins cache の skill-creator
python -m scripts.run_loop \
  --eval-set <repo>/evals/trigger/scope-discovery.json \
  --skill-path <repo>/.claude/skills/scope-discovery \
  --model claude-opus-4-8 \
  --max-iterations 5 --verbose
```

`run_loop` は eval を train 60% / test 40% に分け、現 description のトリガー率を各クエリ3回測定 →
失敗例をもとに description 改善案を生成 → 再評価、を最大5回。`best_description`（test スコアで選択＝過学習回避）を返す。

### 環境制約と Windows 対応（重要）

1. **`claude` CLI が必要**: `run_loop` 系は `claude -p` を subprocess 起動する。`claude --version` が通る端末で実行すること。
2. **skill-creator の発火検出は素の Windows では壊れる**: `run_eval.py` が `select.select([process.stdout], …)` で claude 出力を読むが、`select` は Windows ではソケット専用で**パイプに使えず `OSError [WinError 10093]`** になる。結果、**全クエリが「発火せず」と誤判定され trigger_rate が全部 0.0**（負例だけ trivially pass して見かけ50%）。**この 0.0 は description の良し悪しではなく測定バグ**。
3. **対応 = [win/run_loop_win.py](win/run_loop_win.py)**: skill-creator 本体を改変せず、`select`→スレッド読み取り / `ProcessPoolExecutor`→`ThreadPoolExecutor` に差し替えるモンキーパッチ launcher。検出ロジックは本体と同一。[run-trigger-eval.ps1](run-trigger-eval.ps1) はこの launcher 経由で動く。`python win/run_loop_win.py --selftest` で claude 無しに reader/検出を検証可能（PASS 済み）。
4. 代替: WSL/Linux/macOS（`select` がパイプで動く）で skill-creator を回す手もあるが、その環境にも `claude` が要る。

### 拡充の指針（skill-creator 推奨）

- 正例 8〜10: 同一意図の言い換え（フォーマル/口語）、skill 名やファイル種別を明示しない自然文も含める。
- 負例 8〜10: **近接ケース（near-miss）**を厚く。兄弟 skill のキーワードを共有しつつ別 skill が正解になる依頼、
  バンドル `/code-review` `/security-review` に委ねるべき汎用依頼など。明らかに無関係な負例は価値が低い。

## 使い方（skill-creator 連携）

評価の実行は公式 **skill-creator** を使う前提です（手動評価より再現性・分散分析が得られる）。

```text
# 1. 例集プラグイン（skill-creator を含む）を導入
/plugin install example-skills@anthropic-agent-skills

# 2. skill-creator に本 Skill と評価を渡してトリガー精度を測定・description を最適化
#    （対象 Skill ディレクトリと evals/evals.json を指定）
```

> **要確認 / 形式の注意:** 本 `evals.json` は本リポジトリ独自のスキーマ（`skills[].should_trigger` 等）です。
> skill-creator 同梱の eval フォーマットと**キー名・構造が異なる可能性**があります。
> 導入後にまず skill-creator のテンプレート eval を1件出力させ、本ファイルをそのスキーマへ変換してから実行してください。
> （[work-log.md](../work-log.md) の「未確認事項」3 参照）

## 評価観点（4軸）

1. **trigger_precision** — 想定依頼で正しく発火するか
2. **exclusivity** — 兄弟 Skill の依頼で誤発火しないか
3. **boundary** — 公式バンドルに委ねるべき汎用依頼で発火しすぎないか
4. **output** — 期待される一次成果物が宣言どおりか

## メンテナンス方針

- Skill を新規作成・description 改修するたびに、対応するケースを `evals.json` に追加する。
- 兄弟 Skill を増やしたら、既存 Skill 側の `should_not_trigger` に新スキルの代表依頼を足す（相互排他の維持）。
