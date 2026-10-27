# Skill 移行・整理プラン (skill-migration-plan)

作成日: 2026-06-25 / 親レポート: [skill-review-report.md](skill-review-report.md)

> **方針: 削除しない・破壊しない。** 既存 Skill の内容は維持し、形式統一とバンドル併用に寄せる。各ステップに「差し戻し条件」を付す。

---

## A. 公式 Skill / バンドルへ寄せるもの

| 自作 | 寄せ先（公式） | 方法 | 残す固有部分 |
|---|---|---|---|
| code-review | バンドル `/code-review`・`/review` | 汎用観点はバンドルに委譲。自作は **Supabase/RLS/service_role/Next.js 境界** 特化レイヤに縮約 | 認可漏れ・RLS・コンポーネント境界の Supabase 固有チェック |
| security-review | バンドル `/security-review` | 同上。汎用脆弱性はバンドル、自作は **RLS/anon key/service_role/PII** に縮約 | Supabase 権限モデル固有の監査観点 |
| agent-tester | バンドル `/verify`・`/code-review`・`/loop` | 検証実体（typecheck/test/lint・起動確認）はバンドル/CLI を「呼ぶ」。自作はサイクル制御に縮約 | 「検証→停止→ユーザー確認」ゲート |

→ **いずれも"置換"ではなく"併用"。** 完全置換可能な自作は無い（review-report §3）。

---

## B. 自作として残すもの（公式に代替なし）

- **Discovery 16本**: project / scope / requirements / business / operations / legal / legal-publication-manager / risk / data / integration / metrics / nfr / contract / discovery-planner / discovery-auditor / screen-design-architect
- **設計・調査ライブラリ 11本**: saas-product-manager / db-designer / api-designer / feature-spec-writer / implementation-planner / prompt-architect / system-investigator / bug-investigator / data-flow-mapper / refactor-planner / test-planner
- **レビュー固有**: migration-review / ui-ux-review
- **初期化**: project-quality-tooling
- **Claude ループ制御**: agent-planner / agent-tester（縮約のうえ）

理由: 日本語・Next.js+Supabase・SaaS Discovery の固有ワークフロー。Skill の中核価値。

---

## C. 統合するもの

- 現時点で **内容統合（マージ）は行わない**。Discovery 兄弟は役割分担が明確で、統合するとオーケストレーション（project-discovery が名前で参照）が壊れる。
- 代わりに **description の排他化**（"〜はしない" 文の付与）で誤発火を抑える＝論理的分離の強化。

---

## D. 非推奨にするもの

- 現時点 **なし**。重複する code-review / security-review も固有知識があるため非推奨化せずスリム化で残置。
- 再評価条件: skill-creator の eval で「バンドルとの差分価値が出ない」と数値で示せたら、その時点で非推奨を検討。

---

## E. 削除候補

- **なし**（制約：即削除禁止／他チャット・他プロジェクト依存の可能性）。
- 監視対象（将来の削除候補になりうる）: 内容統合できなかった重複2本。**今回は据え置き。**

---

## F. 構造修正（内容不変・形式のみ）

| 修正 | 対象 | コマンド例 | 差し戻し条件 |
|---|---|---|---|
| F1 ファイル名統一 `SKILL.md` | 小文字 `skill.md` 16本 | `git mv .skills/<s>/skill.md .skills/<s>/SKILL.md` | リンク切れ/ロード不可が出たら revert |
| F2 相互リンク修正 | `skill.md` を指す相対リンク | `[..](../x/skill.md)` → `SKILL.md` 一括置換 | 同上 |
| F3 BOM 除去 | BOM 付き SKILL.md | UTF-8(no BOM) 再保存 | YAML パース不能化したら revert |
| F4 allowed-tools 宣言 | 調査/レビュー/Discovery 系 | frontmatter に `allowed-tools:` 追記 | 必要ツールが拒否され機能不全なら緩める |
| ~~F5 長文分離~~ | 400行超の Discovery 7本 | ~~手順/チェックリストを `references/*.md` へ~~ → **2026-06-25 見送り確定**（オーケストレーション skill はインライン手順で網羅性を担保。分離は挙動劣化リスクが利得を上回る） | — |
| F6 ミラー同期スクリプト | `.skills`→`.agents`/`.claude` | 下記 sync 案 | 差分が想定外なら手動に戻す |
| F7 README 整合 | ルート `README.md` | `.skills/README.md` に合わせ更新 | — |

### F6 同期スクリプト案（PowerShell・要レビュー）
```powershell
# 原本 .skills の Discovery+共通スキルを .agents / .claude へ同期（dry-run 既定）
$src = ".skills"; $mirrors = @(".agents/skills", ".claude/skills")
# 実行前に必ず git status / diff を確認すること。--apply を付けたら robocopy 等で反映。
```
> 実コマンドは F1–F5 確定後に作成（リネーム後の構成に合わせるため）。

---

## G. 実施順序（推奨）

1. **ブランチ作成**（`git switch -c chore/skill-audit`）— 破壊防止。
2. **F7 README 整合**（最も安全・即効）。
3. **F1+F2 ファイル名統一**（小文字→`SKILL.md` + リンク置換）。
4. **F3 BOM 除去**。
5. **F4 allowed-tools 宣言**（Skill 単位で段階導入）。
6. **A スリム化**（code-review / security-review / agent-tester に「バンドル併用」節を追記）。
7. **F5 長文分離**（Discovery 7本、1本ずつ）。
8. **F6 同期スクリプト作成 → ミラー反映**。
9. **skill-creator 導入 → evals 実行**（[evals/evals.json](evals/evals.json) を形式合わせ）。
10. PR レビュー後にマージ。

> 1ステップごとにコミット。**各ステップ前に対象ファイル一覧と理由を提示**（制約遵守）し、[work-log.md](work-log.md) に記録。

---

## H. 全体の差し戻し条件

- 既存 Skill が Claude Code / Codex で**発火しなくなった**ら、その変更を即 revert。
- ミラー間で**挙動差**が出たら同期を手動に戻し原因切り分け。
- eval で**トリガー精度が悪化**したら description 変更を戻す。

---

## I. 導入コマンド（実行は承認後・目的明示）

```text
# 目的: 自作 Skill の eval・description 最適化の保守ツールを入れる
/plugin install example-skills@anthropic-agent-skills      # skill-creator を含む例集
# 目的(任意): Discovery 成果物を docx/pdf/xlsx 化する能力を補完
/plugin install document-skills@anthropic-agent-skills
```
> インストール前に、社内/ローカルポリシーでのプラグイン許可を確認。秘密情報は Skill 本文・eval に含めない。
