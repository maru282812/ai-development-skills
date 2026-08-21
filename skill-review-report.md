# Skill 棚卸しレポート (skill-review-report)

作成日: 2026-06-25 / 対象リポジトリ: `c:\work\ai-development-skills`

> 本レポートは「調査 → ギャップ分析 → 判断」までをまとめたもの。実施手順は [skill-migration-plan.md](skill-migration-plan.md)、調査ログは [work-log.md](work-log.md)、評価案は [evals/evals.json](evals/evals.json) を参照。
> **この時点では既存 SKILL を破壊的に変更していない。** 変更は migration-plan の承認後に行う。

---

## 0. 結論サマリ

- **公式 Skill で「丸ごと置換」できる自作 Skill は無い。** 自作はすべて日本語・Next.js+Supabase・SaaS Discovery という固有ワークフローで、公式（document-skills / example-skills / skill-creator）はドメインが異なる。
- **公式と重複するのは Claude Code の "バンドル済みコマンド" `/code-review` と `/security-review` の2つだけ。** ここは「自作を薄くして Supabase/RLS 特化レイヤとして残す」のが妥当（削除ではなくスリム化）。
- **最大の実利は skill-creator の導入。** 置換目的ではなく「自作 Skill の eval・description 最適化・トリガー精度測定」の保守ツールとして使う。今回の棚卸しを継続運用に変える鍵。
- **構造的な要修正が4点ある**（公式仕様準拠の阻害要因）: ①ファイル名 `skill.md`/`SKILL.md` 混在、②一部 BOM、③`allowed-tools` 未宣言、④3ディレクトリ手動ミラーの同期ドリフト。

---

## 1. 既存 Skill 一覧（34 ユニーク）

ディレクトリ規約（[memory]・[.skills/README.md](.skills/README.md) より）:
`.skills/` = **原本（canonical）** / `.agents/skills/` = Codex 用ミラー / `.claude/skills/` = Claude Code 用ミラー。

| # | Skill | 所在 | md名 | 行数(原本) | 分類 |
|---|---|---|---|---|---|
| 1 | project-discovery | 3箇所 | skill.md | 309 | Discovery（親） |
| 2 | scope-discovery | 3箇所 | SKILL.md | 306 | Discovery |
| 3 | requirements-discovery | 3箇所 | skill.md | 306 | Discovery |
| 4 | business-discovery | 3箇所 | SKILL.md | 449 | Discovery |
| 5 | operations-discovery | 3箇所 | SKILL.md | 463 | Discovery |
| 6 | legal-discovery | 3箇所 | SKILL.md | 283 | Discovery |
| 7 | legal-publication-manager | 3箇所 | SKILL.md | 197 | Discovery（運用） |
| 8 | risk-discovery | 3箇所 | SKILL.md | 420 | Discovery |
| 9 | data-discovery | 3箇所 | SKILL.md | 235 | Discovery |
| 10 | integration-discovery | 3箇所 | SKILL.md | 461 | Discovery |
| 11 | metrics-discovery | 3箇所 | SKILL.md | 430 | Discovery |
| 12 | nfr-discovery | 3箇所 | SKILL.md | 442 | Discovery |
| 13 | contract-discovery | 3箇所 | SKILL.md | 293 | Discovery |
| 14 | discovery-planner | 3箇所 | SKILL.md | 112 | Discovery（制御） |
| 15 | discovery-auditor | 3箇所 | SKILL.md | 96 | Discovery（制御） |
| 16 | screen-design-architect | 3箇所 | SKILL.md | 657 | Discovery（画面） |
| 17 | agent-planner | `.claude` のみ | SKILL.md | — | Claude実装ループ |
| 18 | agent-tester | `.claude` のみ | SKILL.md | — | Claude実装ループ |
| 19 | saas-product-manager | `.skills` | skill.md | 123 | 設計ライブラリ |
| 20 | db-designer | `.skills` | skill.md | 120 | 設計ライブラリ |
| 21 | api-designer | `.skills` | skill.md | 120 | 設計ライブラリ |
| 22 | feature-spec-writer | `.skills` | skill.md | 119 | 設計ライブラリ |
| 23 | implementation-planner | `.skills` | skill.md | 135 | 設計ライブラリ |
| 24 | prompt-architect | `.skills` | skill.md | 118 | 設計ライブラリ |
| 25 | system-investigator | `.skills` | skill.md | 137 | 調査ライブラリ |
| 26 | bug-investigator | `.skills` | skill.md | 126 | 調査ライブラリ |
| 27 | data-flow-mapper | `.skills` | skill.md | 125 | 調査ライブラリ |
| 28 | refactor-planner | `.skills` | skill.md | 110 | 設計ライブラリ |
| 29 | test-planner | `.skills` | skill.md | 117 | テスト |
| 30 | code-review | `.skills` | skill.md | 112 | レビュー（★公式重複） |
| 31 | security-review | `.skills` | skill.md | 117 | レビュー（★公式重複） |
| 32 | migration-review | `.skills` | skill.md | 112 | レビュー |
| 33 | ui-ux-review | `.skills` | skill.md | 111 | レビュー |
| 34 | project-quality-tooling | 3箇所 | SKILL.md | 203 | 初期化ツール |

> 注: 17・18（agent-planner/tester）は `.claude` のみで原本が `.skills` に無い。Discovery 16本と project-quality-tooling は3箇所ミラー、設計/調査/レビューのライブラリ系は `.skills` 単独（Claude Code の能動ロードはされず「コピー用テンプレート」運用）。

---

## 2. 各 Skill の目的・使用場面・現状問題

### 2.1 Discovery スイート（#1–16）
- **目的**: 企画を「実装可能な状態」まで詰める。project-discovery がオーケストレータ、各 *-discovery が1ドメインを発見、planner/auditor がループ制御、screen-design-architect が画面化。
- **使用場面**: 新規 SaaS の立ち上げ〜要件凍結。
- **現状問題**:
  - SKILL.md が長い（400–660行）。公式ガイドの「SKILL.md は簡潔に、詳細は reference に分離」に反する。発火と本文肥大の両方でトークン負荷。
  - 兄弟 Skill のトリガー語が近接（scope vs requirements / business vs operations / risk vs nfr）。**誤発火リスク**。→ evals で should-not-trigger を要検証。
  - `[[wiki-link]]` 相互参照は Skill 機構の公式機能ではない（人間可読のメモ）。動作上は無害だが、リンク切れの幽霊参照が過去にあった（[memory] 参照）。

### 2.2 Claude 実装ループ（#17–18）
- **目的**: Claude Code 実装直後の軽量検証（tester）→ 次の1手決定（planner）。
- **現状問題**: agent-tester は Claude Code バンドルの `/verify`・`/code-review` と機能が重なる。ただし「検証→停止→計画」のサイクル制御という固有価値があるため統合ではなく**バンドルを内部から呼ぶ形に整理**したい。原本が `.skills` に無く `.claude` のみ＝原本/ミラー規約から外れている。

### 2.3 設計・調査ライブラリ（#19–29）
- **目的**: Next.js+Supabase 固有の DB/API/プロンプト/仕様書/実装計画/調査/テスト。
- **現状問題**: 公式に同等なし＝そのまま価値。問題は**形式の不統一**（`skill.md` 小文字 + BOM）と、`.skills` 単独で Claude Code から能動ロードされない点（意図的なテンプレート運用なら可、ただし README に明記が必要）。

### 2.4 レビュー（#30–33）
- code-review / security-review: **Claude Code バンドル `/code-review` `/security-review` と直接重複**（後述 §3）。
- migration-review: Supabase migration SQL の破壊性・RLS・rollback 確認。**公式に同等なし。残す。**
- ui-ux-review: 画面導線・文言レビュー。screen-design-architect から参照される。**公式に同等なし。残す。**

### 2.5 project-quality-tooling（#34）
- スタック検出 → Biome / SwiftLint+SwiftFormat / ktlint を選定し設定一括生成。**公式に同等なし。残す。** （skill-creator はスキャフォルドはするがスタック別 lint 選定はしない＝別物）

---

## 3. 公式 Skill / プラグイン / バンドルとの重複確認（確認済みのみ）

確認元: [anthropics/skills](https://github.com/anthropics/skills)、[Claude Code Docs: Skills](https://code.claude.com/docs/en/skills)、本セッションで利用可能な組み込みコマンド一覧。

| 公式アセット | 種別 | 内容 | 自作との重複 |
|---|---|---|---|
| `skill-creator` | 公式 Skill（anthropics/skills） | Skill 作成・改善・**eval 実行**・description トリガー最適化・分散分析 | **重複なし。保守ツールとして採用推奨** |
| document-skills（docx/pdf/pptx/xlsx） | 公式プラグイン | Office/PDF 生成・編集 | 重複なし（Discovery 成果物の書類化に**補完導入は可**） |
| example-skills | 公式プラグイン | 創作/技術/エンタープライズの例（artifacts-builder, mcp-builder, webapp-testing 等） | 重複なし（SaaS Discovery ドメインは無い） |
| `/code-review` | Claude Code **バンドル Skill** | diff のバグ/品質レビュー。**上書き可** | ★ code-review と重複 |
| `/security-review` | Claude Code **バンドル**（有料プラン, 2025-08〜） | 変更差分のセキュリティレビュー | ★ security-review と重複 |
| `/review` | Claude Code 組み込み | PR レビュー | code-review と部分重複 |
| `/verify`・`/run` | Claude Code バンドル | 実アプリ起動で挙動確認 | agent-tester と部分重複 |
| `/loop` | Claude Code バンドル | プロンプト/コマンドの反復実行 | agent-planner/tester のループ運用と部分重複 |

**要確認（未確認）**:
- ユーザー環境の Claude Code で `/code-review` `/security-review` が有効か（`disableBundledSkills`・プラン依存）。
- example-skills の全 Skill 名の網羅列挙（カテゴリは確認、個別名は未全列挙。ただし「SaaS Discovery の代替が無い」ことは確信）。
- skill-creator の eval ファイルの正確なスキーマ（`evals/evals.json` の構造は本リポジトリ独自案。skill-creator 同梱フォーマットと突き合わせ要）。

---

## 4. 判断結果（残す / 統合 / 公式置換 / 非推奨 / 削除候補）

| 判断 | 対象 | 理由 |
|---|---|---|
| **残す（公式に代替なし）** | Discovery 16本、agent-planner/tester、設計・調査ライブラリ11本、migration-review、ui-ux-review、project-quality-tooling | 日本語・Next.js+Supabase・SaaS Discovery の固有手順。公式は別ドメイン。Skill の価値そのもの。 |
| **スリム化＋バンドル併用（実質"公式を正"に寄せる）** | code-review、security-review | バンドル `/code-review` `/security-review` が汎用部分を担う。自作は **Supabase/RLS/service_role 特化の差分知識だけ**残し、汎用観点はバンドルに委譲。削除はしない（特化知識が消えるため）。 |
| **整理（バンドルを内部利用）** | agent-tester | typecheck/test/lint や `/verify` `/code-review` を「呼ぶ」前提に整理し、二重メンテを避ける。サイクル制御の固有価値は維持。 |
| **構造修正（内容は維持）** | 全 Skill | ファイル名 `SKILL.md` 統一・BOM 除去・`allowed-tools` 宣言・README/ミラー同期（§5）。 |
| **公式置換** | 該当なし | 丸ごと置換できる自作は存在しない。 |
| **非推奨** | 現時点なし | 重複しても固有知識があるため即非推奨にはしない。 |
| **削除候補** | 現時点なし | 制約に従い即削除はしない。重複2本もスリム化で残置。 |
| **補完で"追加導入"検討** | document-skills, skill-creator | 置換ではなく能力追加（書類出力 / 保守自動化）。 |

---

## 5. 構造的な改善方針（内容ではなく形式）

公式 SKILL.md 仕様への準拠と保守性のため、以下を提案（実施は migration-plan で承認後）。

1. **ファイル名統一 `SKILL.md`（大文字）**
   - 問題: 17本が `skill.md`（小文字）。公式仕様は `SKILL.md`。Windows は大小無視だが、**Codex / Linux / 大小区別 git** では自動検出されない。
   - 対応: 小文字 17本を `SKILL.md` にリネーム（`git mv`）。→ **2026-06-25 実施済み（F1）**。

2. **BOM 除去**
   - 問題: 一部ファイル先頭に UTF-8 BOM（`EF BB BF`）。YAML frontmatter パーサで稀に失敗。混在状態。
   - 対応: 全 SKILL.md を BOM なし UTF-8 に統一。

3. **`allowed-tools` 宣言（任意・推奨）**
   - 問題: 全 Skill で未宣言（=全ツール許可）。Discovery/レビュー/調査系は本来 **読み取り中心**。
   - 対応（例）: 調査・レビュー・Discovery 系は `allowed-tools: Read, Grep, Glob, WebSearch` 等に絞る。実装計画系は Write を許可。**安全性とトリガー意図の明確化**。

4. **長文 SKILL.md の reference 分離 → 見送り確定（2026-06-25）**
   - 問題: Discovery 7本が 400–660 行。
   - 当初案: 「目的・成功条件・判断基準・発火条件」を SKILL.md 本体に、詳細手順/チェックリスト/テンプレを `references/*.md` に分離。
   - **判断**: これらはオーケストレーション skill で、手順をインラインに持つことで網羅性を担保している。分離するとオンデマンド読み込みになり手順欠落で**挙動が劣化**しうるため、token 節約の利得を上回るリスクと判断し**分離しない**。将来 token 負荷が問題化したら個別再検討。

5. **ミラー同期の明文化**
   - 問題: `.skills`→`.agents`/`.claude` は手動コピーで**ドリフト**（git status で legal-discovery が3箇所同時変更＝手動同期の証跡）。
   - 対応: 「原本=`.skills`、同期はスクリプト1本」を README とコマンド化（migration-plan に同期スクリプト案）。agent-planner/tester は原本を `.skills` に置く。

6. **README 整合**
   - 問題: ルート [README.md](README.md) の「現在の基本セット」が16本のみで Discovery スイート・新規2本（legal-publication-manager / project-quality-tooling）を反映していない。
   - 対応: ルート README を `.skills/README.md`（最新）に合わせて更新。

---

## 6. description 改善観点（発火精度）

- **狭すぎ/広すぎの検査対象**: Discovery 兄弟（scope/requirements、business/operations、risk/nfr）。トリガー語が重なるため、各 description に「これは何を**しない**か」を1文入れて排他化（多くは既に "〜するスキルではない" を持つ＝良い）。
- **code-review / security-review**: description に「Supabase/RLS/service_role 前提」を明示し、汎用レビュー依頼ではバンドル側へ寄せる。
- 改善版 frontmatter の具体案は migration-plan の §SKILL.md 修正案に記載。

---

## 7. リスク

| リスク | 内容 | 緩和 |
|---|---|---|
| 別チャット/別プロジェクト依存 | 重複 Skill も他所で参照中の可能性 | 削除せずスリム化・非推奨も今回は見送り |
| 一括リネームの破壊 | `skill.md`→`SKILL.md` 変換でリンク切れ | `git mv` でリネーム、相互リンクの `skill.md` 参照も一括置換、変更前にブランチ切る |
| ミラー同期漏れ | 3箇所更新忘れで挙動差 | 同期スクリプト化 + 原本一元化 |
| 環境差分 | バンドルコマンドの有無がプラン/版で違う | 自作レビューを残置し fallback を確保 |
| eval スキーマ不一致 | evals.json が skill-creator 形式と違う | skill-creator 導入時に形式突合（§3 要確認） |

---

## 8. 今後の運用方針

1. **原本は `.skills/` の `SKILL.md`**。修正は原本→同期スクリプトでミラー反映。
2. **保守は skill-creator に乗せる**: 新規/改修時に eval 実行・description 最適化を必須化。
3. **レビューはバンドル優先・自作は特化差分**: 汎用は `/code-review` `/security-review`、Supabase/RLS 深掘りは自作。
4. **公式の補完導入は能力追加として検討**（document-skills で Discovery 成果物を docx/pdf 化など）。
5. 四半期ごとに本レポートを再走（インベントリ + 公式重複 + eval 合否）。

---

## Sources（確認した公式情報）
- [anthropics/skills (GitHub)](https://github.com/anthropics/skills)
- [skill-creator/SKILL.md](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md)
- [Claude Code Docs: Extend Claude with skills](https://code.claude.com/docs/en/skills)
- [Automated Security Reviews in Claude Code (Help Center)](https://support.claude.com/en/articles/11932705-automated-security-reviews-in-claude-code)
