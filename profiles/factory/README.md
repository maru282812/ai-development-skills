# factory（製造ループ基盤）

全プロジェクト共通の製造ループ（Loop Engineering）を対象リポジトリに設置するための profile。

## 使い方

対象プロジェクトに対して `factory-bootstrap` スキル
（`.skills/factory-bootstrap/SKILL.md` を Read して従う）を実行する。
skill フォルダを対象 repo にコピーする必要はない — 設置されるのは以下の薄いファイルだけ:

| ファイル | 役割 |
|---|---|
| `docs/VERIFY.md` | そのrepoの検証レシピ（Gates / Runtime Verify / Checker観点 / Human Gate / Receipt） |
| `.claude/loop.md` | `/loop` の保守ループ既定 |
| `CLAUDE.md` の「製造ループ」節 | 基盤の所在と運用ルールの道しるべ |

## 標準製造ループ

```text
SPEC → PLAN → [ MAKER → GATES → RUNTIME VERIFY → CHECKER → RECEIPT ]×Phase → HUMAN GATE → MERGE → MAINTAIN(/loop)
```

- Build = `/goal` / phase-runner（停止条件 = 受け入れ条件＋全ゲート緑＋checker pass）
- Verify = verification-loop（docs/VERIFY.md 準拠）
- Maintain = `/loop`（.claude/loop.md 準拠）

## 関連スキル（canonical は `.skills/`）

factory-bootstrap（設置）/ phase-runner（自走）/ verification-loop（実行時検証）/
implementation-planner（計画）/ code-review・security-review（checker の深掘り）/
migration-review（Human Gate 前の DB 確認）

新規プロジェクトは project-kickoff §5.5 が自動でこの profile を適用する。
