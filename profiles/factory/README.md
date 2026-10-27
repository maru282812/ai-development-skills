# factory（製造ループ基盤）

全プロジェクト共通の製造ループ（Loop Engineering）を対象リポジトリに設置するための profile。

## 使い方（2段階）

### 1. スキルをインストールする（1回だけ）

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-factory.ps1 -Global -Apply
```

グローバル（`~/.claude/skills/` と `~/.codex/skills/`）に入るので、**全プロジェクトから使える**。
repo ごとのコピーは不要（特定 repo に固定したいときだけ `-Project <path> -Apply`）。

インストールされるのは: development-router / factory-bootstrap / verification-loop /
phase-runner / implementation-planner / migration-review。

> **code-review / security-review は意図的に除外**している。Claude Code に同名の組み込みコマンド
> （`/code-review ultra` 等）があり、同名スキルを `~/.claude/skills/` に置くと組み込み側を
> 覆い隠して壊すため。この2つは `.skills/` を canonical のまま development-router 経由で使う。

### 2. 各プロジェクトで「ループ」と言う

新規・既存どちらでも、対象 repo で Claude Code を開いて次のいずれかを言うだけ:

```
ループしちゃって / ループして / ループ入れて
製造ループを入れて / 製造ラインを整えて
/factory-bootstrap   ← 明示的に呼ぶ場合
```

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
