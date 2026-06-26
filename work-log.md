# 作業ログ (work-log)

対象: `c:\work\ai-development-skills` の Skill 棚卸し / 開始日: 2026-06-24・継続: 2026-06-25

---

## 1. 調査したファイル

- ディレクトリ構成: `.skills/`（原本 32 + README）, `.agents/skills/`（17 ミラー）, `.claude/skills/`（19＝17+agent-planner/tester）
- [README.md](README.md)（ルート）/ [.skills/README.md](.skills/README.md)（Skill 選択ガイド・最新）
- 全 Skill の frontmatter（name/description）を一括ダンプし確認
- ファイル名規約: `skill.md`（小文字 **17本**）と `SKILL.md`（大文字 15本）の混在を確認（当初「16/16」と記載したが正確には 17/15）
- BOM 確認: 一部 `SKILL.md` に UTF-8 BOM（`EF BB BF`）。例: `.claude/skills/requirements-discovery/SKILL.md` は BOM 有、`.skills/legal-discovery/SKILL.md` は BOM 無
- `allowed-tools`: 全 Skill で**未宣言**（grep ヒット 0）
- 行数計測: Discovery 系が 400–660 行と長文（screen-design-architect 657 が最長）
- `evals/` 既存なし、`skill-creator` 関連ファイル既存なし

## 2. 確認した公式情報（出典付き）

- [anthropics/skills](https://github.com/anthropics/skills): document-skills(docx/pdf/pptx/xlsx) / example-skills / skill-creator / template / spec
- インストール: `/plugin install document-skills@anthropic-agent-skills`、`example-skills@...`
- [skill-creator](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md): Skill 作成・改善・**eval 実行**・description トリガー最適化・分散分析
- [Claude Code Docs: Skills](https://code.claude.com/docs/en/skills): バンドル Skill（`/code-review` `/batch` `/debug` `/loop` `/claude-api` `/run` `/verify`）。`disableBundledSkills` で無効化可、custom で上書き可
- [Help Center: Automated Security Reviews](https://support.claude.com/en/articles/11932705-...): `/security-review` は 2025-08 導入・有料プラン
- 本セッションの組み込みコマンド一覧でも `/code-review` `/security-review` `/review` `/verify` `/run` `/loop` を確認

## 3. 判断内容（詳細は review-report §4）

- 公式で丸ごと置換できる自作 Skill は **無し**
- 公式と重複するのはバンドル `/code-review` `/security-review` の2点のみ → 自作は Supabase/RLS 特化に**スリム化して併用**（削除しない）
- Discovery 16本・設計/調査 11本・migration-review・ui-ux-review・project-quality-tooling・agent-planner/tester は**残す**
- 構造修正（形式のみ）: ファイル名統一・BOM 除去・allowed-tools・長文分離・ミラー同期・README 整合

## 4. 実施した変更

| 種別 | ファイル | 内容 |
|---|---|---|
| 新規作成 | [skill-review-report.md](skill-review-report.md) | 棚卸しレポート |
| 新規作成 | [skill-migration-plan.md](skill-migration-plan.md) | 移行・整理プラン |
| 新規作成 | [evals/evals.json](evals/evals.json) | eval テストケース案（12 Skill） |
| 新規作成 | [work-log.md](work-log.md) | 本ログ |

## 4.1 形式修正 F1–F3 実施（2026-06-25・ユーザー承認済み / ブランチ `chore/skill-audit`）

| ステップ | 内容 | 結果 |
|---|---|---|
| F1 | `.skills/` の小文字 `skill.md` **17本**を `git mv` で `SKILL.md` にリネーム | 完了（残 0、git は rename として追跡） |
| F2 | `skill.md` 参照リンク **53箇所**を `SKILL.md` に一括置換（.skills/.agents/.claude/profiles/references/README） | 完了（残 0） |
| F3 | UTF-8 BOM 付き **18本**（.skills 16 + .agents/.claude の requirements-discovery 2）から BOM 除去 | 完了（残 0、先頭 `2d2d2d`） |

- 検証: frontmatter 健全・相互リンク有効・BOM 消失を確認。`git status` で計44エントリ（R/RM=リネーム、M=リンク/BOM修正）。
- **未コミット**（コミット/PR はユーザー指示待ち）。
- 今後の方針をメモリ保存: [skill-creation-workflow](../../memory/skill-creation-workflow.md)（今後の Skill 作成は skill-creator 使用＋公式 Skill 取り込み）。

## 4.2 形式修正 F4・F6・F7 / スリム化 A 実施（2026-06-25・「順番にすべて行って」指示）

| ステップ | 内容 | 結果 |
|---|---|---|
| F7 | ルート [README.md](README.md) を全 skill セット（Discovery スイート＋新規＋Claude専用）に更新。原本/ミラー方針も明記 | 完了 |
| F4 | 全 **68 SKILL.md** の frontmatter に `allowed-tools` をカテゴリ別に挿入（review/investigation=Read,Grep,Glob,Bash／discovery・design=Read,Write,Edit,Grep,Glob／tooling=+Bash／agent-tester=Read,Edit,Grep,Glob,Bash／agent-planner=Read,Grep,Glob,Bash） | 完了（68/68） |
| A | code-review / security-review / agent-tester に「バンドルコマンドとの使い分け」節を追記（汎用は `/code-review` `/security-review` `/run` `/verify`、自作は Supabase/RLS・サイクル制御に特化）。**固有知識は削らず追記のみ** | 完了 |
| F6 | [scripts/sync-skills.ps1](scripts/sync-skills.ps1) 作成（原本 `.skills/`→ミラー、ミラー既存 skill のみ更新・メンバー追加なし・ミラー専用は touch しない）。dry-run 動作確認済み。ASCII-only（PS5.1 の BOM 無し .ps1 文字化け回避） | スクリプト完了／**-Apply は保留** |
| evals | [evals/README.md](evals/README.md) 追加（skill-creator 連携手順・形式突合の注意） | 完了 |

- **F6 -Apply 保留理由**: ミラーに legal-discovery のドリフト（session 開始時点で3箇所 M）。上書きは「大きな変更は確認してから」の制約に該当。ドリフトの正本確認後に流す。

### 4.3 F5（長文 reference 分離）→ ユーザー判断: 分離しない（見送り確定）
- 対象だった: 400行超の Discovery 7本（business 449 / operations 463 / integration 461 / nfr 442 / metrics 430 / risk 420 / screen-design-architect 657）×ミラー。
- **見送り理由**: これらは手順を**インラインで持つことで網羅性を担保するオーケストレーション skill**。reference へ切り出すとオンデマンド読み込みになり、モデルが参照を引かないと**手順欠落で挙動劣化**しうる（token 節約の利得より副作用リスクが大きい）。2026-06-25 ユーザー確認で「分離しない」を選択。
- 対応: 既存ファイルは変更しない。将来 token 負荷が問題化したら個別に再検討。

## 4.4 skill-creator 連携・トリガーeval整備（2026-06-25）

- skill-creator はプラグインとして利用可能（`example-skills:skill-creator`）。ただし **`/plugin` コマンドと `claude` CLI は本環境の PATH に無く**、`run_loop`（description最適化）は**この端末からは実行不可**。
- eval 系統を整理: skill-creator は「**出力eval**（evals.json、出力品質）」と「**トリガーeval**（[{query,should_trigger}]、発火精度）」の2系統。我々のデータは後者に対応。
- **変換**: [evals/trigger/](evals/trigger/) に12→16 skill のトリガーeval（skill-creator形式）を生成。
- **拡充**: 発火競合の強い **A群13本を正10/負10=20件**へ拡充（scope/requirements/business/operations/legal/contract/risk/nfr/integration/metrics/screen-design-architect/code-review/security-review）。risk/nfr/integration/metrics は新規作成。
- **runner**: [evals/run-trigger-eval.ps1](evals/run-trigger-eval.ps1)（skill-creator パス自動解決・`claude` 前提チェック・`-All` で A群一括）。glob 解決と run_loop.py 存在を確認、両モードのパース健全を確認。
- **方針**: [evals/skill-methodology.md](evals/skill-methodology.md) に スキル別 eval駆動(TDD)/現状維持/次点 を3層で判定。
- **descriptionの直接書き換えはしていない**: run_loop の測定なしに既存の良好な description（排他句あり）を手で書き換えると劣化リスクがあるため、最適化は measured loop に委ね、端末側で実行する設計にした。

## 4.5 run_loop 実行で判明した2つの不具合と修正（2026-06-26）

ユーザー端末（`claude` CLI あり）で `run-trigger-eval.ps1 -All` を実行して判明:

1. **UTF-8 デコードエラー**: `run_loop.py` が eval JSON を `Path.read_text()`（既定cp932）で読み、日本語で `UnicodeDecodeError`。
   → 修正: runner に `PYTHONUTF8=1` / `PYTHONIOENCODING=utf-8` を設定（コミット `46ccbf9`）。
2. **発火検出が全部 0.0**: 修正後に走ったが、**全クエリ・全description・全iterationで trigger_rate 0.0**（負例だけ pass で見かけ50%頭打ち）。
   原因を特定: `run_eval.py` の `select.select([process.stdout], …)` は **Windows でパイプ不可（`OSError [WinError 10093]`）**。`python -c` で再現確認済み。
   → **0.0 は description の品質ではなく測定バグ**。この数値で description を書き換えない。
   → 修正: [evals/win/run_loop_win.py](evals/win/run_loop_win.py) を新規作成。skill-creator 本体を改変せず
     `select`→スレッド+queue 読み取り / `ProcessPoolExecutor`→`ThreadPoolExecutor` にモンキーパッチ。
     検出ステートマシンは本体と同一。`--selftest` で reader/検出を claude 無しに検証（PASS）。
     runner はこの launcher 経由に変更。

→ メモリ追加: [skillcreator-trigger-eval-windows](../../memory/skillcreator-trigger-eval-windows.md)。

### description は未変更（重要）
- 壊れた 0.0 を根拠に description を書き換えていない。既存 description は排他句を備えており、構造監査でも良好。
- 正しい測定は、修正後の launcher 経由で再実行して得る。

## 4.6 測定実行と最終判断（2026-06-26）

ユーザー端末（claude 2.1.191）で security-review を実測（launcher 経由、UTF-8修正後）。

- **Windows 測定バグは解消**: trigger_rate に非ゼロが出た（例「権限モデルを攻撃者目線で監査して」「テナント横断…」「IDOR…」「anon key…」が 1/3）。前回の全0.0は再現せず。
- **結果の解釈**: precision=100%（負例で誤発火ゼロ）／recall 6–17%（強い under-trigger）。自動改善案は **元 description を上回れず、original が best**（4/8）。
- **低 recall はハーネス由来が大きい**: 素の `claude -p` にスキル1個だけ登録した一発質問では、Claude は自力でできるタスクでスキルを参照しにくい（skill-creator 公式も明記）。実プロジェクト内の発火条件とは異なり、絶対 recall は実使用より低めに出る。
- **最終判断（ユーザー: 「これでいい」）= 現状維持で確定**。理由: ①最適化ツールが元 description を上回れない、②precision 100%、③低 recall はハーネス由来。**description は一切変更しない。**

### 完了
- 棚卸し（F1–F4・A・F6・F7）＋ skill-creator 連携（トリガーeval整備・Windows対応launcher）まで完了。description は measured で validated のうえ据え置き。
- F5（長文分離）・description最適化はいずれも「見送り/据え置き」で確定。
- PR #1（chore/skill-audit）に全コミット反映済み。
- skill-creator 導入（プラグイン許可）→ evals.json を実フォーマットへ変換し実行
- 3ディレクトリ全件 diff でドリフト棚卸し

> **F1–F4・A・F7 以外の既存 SKILL 本文は未変更。** F5 と F6 反映は確認後に実施。

## 5. 未確認事項（要確認・判断保留）

1. ユーザー環境の Claude Code で `/code-review` `/security-review` が有効か（プラン/`disableBundledSkills` 依存）
2. example-skills の全 Skill 名の網羅列挙（カテゴリのみ確認。SaaS Discovery の代替が無いことは確信）
3. skill-creator の eval ファイルの**正確なスキーマ**（`evals/evals.json` は独自案。skill-creator 形式と要突合）
4. `.agents`(Codex) が大小区別環境で `skill.md`（小文字）を検出できるか（できない前提でリネーム提案）
5. BOM が現行 Claude Code の YAML パーサで実害を出しているか（混在は事実、影響は未測定）
6. 3ディレクトリ間の内容ドリフトの有無（git status で legal-discovery が3箇所同時変更＝手動同期の証跡。全件 diff は未実施）

## 6. 次に確認すべきこと

1. migration-plan の F1–F7・A を実施してよいか承認を得る（ブランチ `chore/skill-audit`）
2. skill-creator 導入可否（プラグイン許可ポリシー）→ 導入後 evals.json を実フォーマットへ調整し実行
3. `.skills` ↔ `.agents` ↔ `.claude` の全件 diff を取りドリフト棚卸し
4. 重複2本（code-review/security-review）の固有差分価値を eval で測定 → 非推奨の要否を再判断
