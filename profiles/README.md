# Profiles

profile は「この種類のプロジェクトでは、どの skill フォルダをコピーするか」を決めるためのガイドです。

| profile | 用途 | コピー方針 |
|---|---|---|
| [initial-set](initial-set/README.md) | 通常のアプリ開発・業務システム開発 | `.skills/` をコピー |
| [hp-creation](hp-creation/README.md) | HP・Web サイト作成 | `initial-set` をベースに、必要なら `.claude/skills/` の補助 skill を追加 |
| [claude-code-loop](claude-code-loop/README.md) | Claude Code 実装後の検証・次指示作成 | `.claude/skills/agent-tester` と `.claude/skills/agent-planner` を追加 |
| test-quality-loop | テスト設計・障害解析・migration 安全確認・レッドチーム | `install-discovery-chain.ps1` の配布チェーンに含まれる（test-planner / system-investigator / bug-investigator / migration-review / adversarial-review） |

## 運用ルール

1つのプロジェクトに複数 profile を重ねて使ってよいです。

HP 作成のように初期セットが前提になる用途は、profile 側に「base: initial-set」と書きます。

profile はコピー対象の説明を主目的にします。skill 本文そのものは `.skills/` または `.claude/skills/` を canonical とします。
