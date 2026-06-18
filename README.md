# ai-development-skills

AI 開発で使う skill を蓄積し、他プロジェクトへ必要な分だけコピーして使うためのリポジトリです。

## フォルダ方針

| フォルダ | 役割 |
|---|---|
| `.skills/` | 汎用の初期 skill セット。多くのプロジェクトではまずここをコピーする |
| `.claude/skills/` | Claude Code 専用の skill。Claude Code の自走検証・計画ループなど、必要な時だけコピーする |
| `profiles/` | プロジェクト種別ごとの組み合わせガイド。どのフォルダをコピーするかを決める場所 |
| `references/` | 横断的な補足資料や設計メモの入口。skill 本文は置かない |

## 使い分け

通常の開発プロジェクトでは [initial-set](profiles/initial-set/README.md) を使います。

HP・Web サイト作成では [hp-creation](profiles/hp-creation/README.md) を使います。HP 作成が不要なプロジェクトでは、この profile はコピー対象に含めません。

Claude Code で実装後の検証と次指示作成を回す場合は [claude-code-loop](profiles/claude-code-loop/README.md) を追加します。

## 追加ルール

新しい汎用 skill は `.skills/<skill-name>/skill.md` に追加します。

Claude Code 専用 skill は `.claude/skills/<skill-name>/SKILL.md` に追加します。

特定用途の組み合わせが増えたら `profiles/<use-case>/README.md` を追加します。skill 本体を重複コピーしても構いませんが、まずは canonical な本体を `.skills/` または `.claude/skills/` に置き、profile にはコピー対象を明記します。

個別 skill だけで使う参考資料は `.skills/<skill-name>/references/` に置きます。複数 skill から参照する資料だけ `references/` に置きます。

## 現在の基本セット

`.skills/` には、要件探索、調査、設計、実装計画、レビュー、テストの初期セットが入っています。

- `requirements-discovery`
- `system-investigator`
- `bug-investigator`
- `data-flow-mapper`
- `saas-product-manager`
- `db-designer`
- `api-designer`
- `prompt-architect`
- `feature-spec-writer`
- `implementation-planner`
- `code-review`
- `security-review`
- `migration-review`
- `ui-ux-review`
- `refactor-planner`
- `test-planner`
