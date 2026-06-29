# ai-development-skills

AI 開発で使う skill を蓄積し、他プロジェクトへ必要な分だけコピーして使うためのリポジトリです。

## フォルダ方針

| フォルダ | 役割 |
|---|---|
| `.skills/` | **原本（canonical）**。汎用 skill セット。多くのプロジェクトではまずここをコピーする |
| `.agents/skills/` | Codex 用ミラー（原本 `.skills/` を同期したもの） |
| `.claude/skills/` | Claude Code 用ミラー＋Claude Code 専用 skill（自走検証・計画ループ） |
| `profiles/` | プロジェクト種別ごとの組み合わせガイド。どのフォルダをコピーするかを決める場所 |
| `references/` | 横断的な補足資料や設計メモの入口。skill 本文は置かない |

> 原本は `.skills/`。修正は原本 `SKILL.md` を更新してからミラー（`.agents/` `.claude/`）へ同期する。詳細な選択ガイドは [.skills/README.md](.skills/README.md)。
> 棚卸し・整理の記録は [skill-review-report.md](skill-review-report.md) / [skill-migration-plan.md](skill-migration-plan.md) / [work-log.md](work-log.md)。

## どんなプロジェクトでも使う（Codex / Claude Code 両対応）

「要件定義 → 各 Discovery → 画面設計（Google Stitch=画像UI へ投げる）→ 実装引き渡し」の
チェーン全体を、Codex と Claude Code の両方・任意のプロジェクトで使えるように配布します。

```powershell
# グローバル導入（~/.codex/skills と ~/.claude/skills に全チェーンを入れる＝全プロジェクトで自動利用）
powershell -File scripts/install-discovery-chain.ps1 -Global -Apply

# 特定プロジェクトへ導入（<path>/.agents/skills と <path>/.claude/skills へ一括コピー）
powershell -File scripts/install-discovery-chain.ps1 -Project C:\work\foo -Apply

# 両方まとめて／まず dry-run（-Apply を外すと書き込まずプレビュー）
powershell -File scripts/install-discovery-chain.ps1 -Global -Project C:\work\foo
```

- 配布されるチェーン（両ツール・21本）: project / scope / requirements / business / operations /
  legal / legal-publication-manager / contract / risk / data / integration / metrics / nfr /
  discovery-planner / discovery-auditor / project-quality-tooling / screen-design-architect /
  ui-ux-review / feature-spec-writer / saas-product-manager / implementation-planner。
- Claude Code には加えて実装ループ専用の agent-planner / agent-tester も入る（Codex には入れない）。
- 原本は常に `.skills/`（チェーン本体）と `.claude/skills/`（Claude 専用2本）。スクリプトはここからコピーする。

## 使い分け

通常の開発プロジェクトでは [initial-set](profiles/initial-set/README.md) を使います。

HP・Web サイト作成では [hp-creation](profiles/hp-creation/README.md) を使います。HP 作成が不要なプロジェクトでは、この profile はコピー対象に含めません。

Claude Code で実装後の検証と次指示作成を回す場合は [claude-code-loop](profiles/claude-code-loop/README.md) を追加します。

## 追加ルール

新しい汎用 skill は `.skills/<skill-name>/SKILL.md` に追加します。

Claude Code 専用 skill は `.claude/skills/<skill-name>/SKILL.md` に追加します。

特定用途の組み合わせが増えたら `profiles/<use-case>/README.md` を追加します。skill 本体を重複コピーしても構いませんが、まずは canonical な本体を `.skills/` または `.claude/skills/` に置き、profile にはコピー対象を明記します。

個別 skill だけで使う参考資料は `.skills/<skill-name>/references/` に置きます。複数 skill から参照する資料だけ `references/` に置きます。

## 現在の skill セット

`.skills/` には、Project Discovery スイートと、調査・設計・実装計画・レビュー・テストの汎用 skill が入っています。

### Project Discovery スイート（企画→実装可能な状態まで詰める）

- `project-discovery`（オーケストレータ）
- `scope-discovery` / `requirements-discovery`
- `business-discovery` / `operations-discovery`
- `legal-discovery` / `legal-publication-manager` / `contract-discovery`
- `risk-discovery` / `data-discovery` / `integration-discovery`
- `metrics-discovery` / `nfr-discovery`
- `discovery-planner` / `discovery-auditor`（ループ制御）
- `screen-design-architect`（画面設計）

### 設計・調査・実装計画

- `system-investigator` / `bug-investigator` / `data-flow-mapper`
- `saas-product-manager` / `db-designer` / `api-designer` / `prompt-architect`
- `feature-spec-writer` / `implementation-planner` / `refactor-planner`
- `project-quality-tooling`（新規案件の lint/format 初期セットアップ）

### レビュー・テスト

- `code-review` / `security-review` / `migration-review` / `ui-ux-review`
- `test-planner`

> `code-review` / `security-review` は Claude Code バンドルの `/code-review` `/security-review` と重複する。汎用レビューはバンドル、Supabase/RLS 特化の差分は自作 skill を使う（[skill-review-report.md](skill-review-report.md) 参照）。

### Claude Code 専用（`.claude/skills/` のみ）

- `agent-tester`（実装直後の軽量検証）/ `agent-planner`（次の1手決定）
