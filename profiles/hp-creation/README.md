# hp-creation

HP・Web サイト作成向けの profile です。

## base

[initial-set](../initial-set/README.md)

## コピー対象

| コピー元 | コピー先 | 条件 |
|---|---|---|
| `.skills/` | 対象プロジェクトの `.skills/` | 必須 |
| `.claude/skills/requirements-discovery/` | 対象プロジェクトの `.claude/skills/requirements-discovery/` | Claude Code 側でも同じ要件探索 skill を使う場合 |
| `.claude/skills/agent-tester/` | 対象プロジェクトの `.claude/skills/agent-tester/` | Claude Code 実装後の検証ループを使う場合 |
| `.claude/skills/agent-planner/` | 対象プロジェクトの `.claude/skills/agent-planner/` | 検証結果から次の実装指示を作る場合 |

## HP 作成で主に使う skill

- `requirements-discovery`: 作る前に要件・画面・導線・例外を洗い出す
- `saas-product-manager`: MVP / Phase / 優先順位を整理する
- `ui-ux-review`: 画面導線・文言・スマホ表示を確認する
- `feature-spec-writer`: AI に渡せる実装仕様書へまとめる
- `implementation-planner`: 実装順序と作業範囲を分ける
- `test-planner`: 公開前の確認項目を作る

## 増やす時の置き場

HP 作成専用の汎用 skill は `.skills/hp-<name>/SKILL.md` に追加します。

特定プロジェクトの参考サイト・素材・要件は、このリポジトリではなく対象プロジェクト側に置きます。
