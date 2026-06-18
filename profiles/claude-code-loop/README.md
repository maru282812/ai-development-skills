# claude-code-loop

Claude Code で実装した後に、検証レポート作成と次の実装指示作成を分けて回すための profile です。

## コピー対象

| コピー元 | コピー先 | 必須 |
|---|---|---|
| `.claude/skills/agent-tester/` | 対象プロジェクトの `.claude/skills/agent-tester/` | はい |
| `.claude/skills/agent-planner/` | 対象プロジェクトの `.claude/skills/agent-planner/` | はい |

## 前提

この profile は単体でも使えますが、通常は [initial-set](../initial-set/README.md) と組み合わせます。

## 役割

- `agent-tester`: 実装後に diff / typecheck / test / lint / 副作用を確認して検証レポートを出す
- `agent-planner`: 検証レポートと diff から次にやる 1 件だけを指示文にする

## 注意

この profile は自動で実装を進めるためのものではありません。各サイクルの境目でユーザー確認を挟む前提です。
