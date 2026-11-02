---
name: git-init-setup
allowed-tools: Read, Write, Edit, Bash, Glob
metadata:
  reasoning-tier: standard
  summary: "新規プロジェクトの git/GitHub 初期化担当。既存 .git 退避→git init→初回コミット→GitHub private作成→remote連携→push を全自動で行う。安全ガードで既存リポジトリは保護する。"
description: >-
  新規プロジェクトの初期化時に、Gitリポジトリを作り直して GitHub と連携するまでを全自動で行うセットアップ・スキル。
  トリガー例:「git作成」「gitを初期化して」「リポジトリ作り直して」「新規プロジェクトのgitを作って」
  「GitHubにリポジトリ作って連携して」「git作成して」「このプロジェクトのgitを新規で作って」。
  既存の .git を退避（.git.bak-<timestamp> へリネーム）→ git init（main）→ 初回コミット →
  GitHub に private リポジトリを作成（gh repo create）→ remote origin 連携 → 初回 push、までを一気通貫で実行する。
  ユーザーが「git作成」と言ったら、たとえ明示的に手順を列挙していなくても、このスキルを使うこと。
  破壊的操作（.git の作り直し）と外向き操作（GitHubリポジトリ作成・push）を含むため、
  誤爆防止の安全ガード（ドライブ直下/ホーム直下では実行拒否・既存.gitは削除せず退避）を必ず通す。
  要件定義・スコープ整理はしない（それは [[requirements-discovery]] / [[project-discovery]] / [[scope-discovery]]）。
  本スキルは「新規プロジェクトの git/GitHub 初期化」だけに特化する。git作成が終わったら要件定義へ引き渡す。
---

# Purpose

新規プロジェクトを始めるとき、**Git の作り直しと GitHub への連携を毎回手作業でやる手間と事故を無くす**ためのスキル。

テンプレートやボイラープレートを clone/コピーして新規プロジェクトを始めると、元リポジトリの `.git`（他人の履歴・他人の remote）が残ってしまう。これを引きずったまま開発を進めると、誤って元リポジトリに push する・履歴が混ざるといった事故になる。このスキルは「**今いるディレクトリを、まっさらな自分の GitHub リポジトリに紐づけ直す**」を全自動で安全に行う。

ユーザーが「**git作成**」と言ったら（手順を細かく指示していなくても）このスキルを起動する。

役割の境界：

- **git-init-setup（本スキル）** … 新規プロジェクトの git/GitHub 初期化だけを行う。
- [[scope-discovery]] / [[requirements-discovery]] / [[project-discovery]] … その後の「何を / どこまで作るか」「要件定義書」を担当する。git作成が終わったらここへ渡す。

# 前提条件（実行前に確認）

1. **GitHub CLI (`gh`) が入っていて認証済みであること。** スクリプトが `gh auth status` で検査し、未認証なら中断する。未導入なら https://cli.github.com/ から入れて `gh auth login` を案内する。
2. **対象ディレクトリ＝いま作業しているプロジェクトのルート**であること。意図しない場所で走らせない（後述の安全ガードが二重に守る）。

# 安全ガード（全自動でも必ず通す）

このスキルは「全自動（確認ゲートなし）」で動くが、取り返しのつかない事故だけは構造で防ぐ。対話確認ではなく、危険を検知したら**自動で中断する**ガード：

- **【最重要】既存プロジェクトは作り直さない。** `.git` に「コミット履歴」と「remote」の**両方**があれば、運用中の既存リポジトリと判断し、`.git` に**一切触れず中断する**。既存プロジェクトを誤って初期化して履歴・連携を壊す事故を、構造的に起こさせない。これがユーザーの最優先要件。
  - テンプレートを clone してきた等で「履歴も remote もあるが本当に作り直したい」ケースだけ、**明示的に `-Force`（bash は `-f`）** を付けて再実行する。その場合でも `.git` は削除せず退避する。
  - 履歴が無い／remote が無いスキャフォールド（例: `create-next-app` のローカル init のみ）は、既存プロジェクトではないので退避して作り直してよい。
- **`.git` をハード削除することは決してない。** 作り直す場合も `.git.bak-<timestamp>` へ**リネーム退避**する。「削除」ではなく「退避」であることをユーザーに必ず伝える。
- **ドライブ直下（例 `C:\`）・ユーザーホーム直下では実行拒否。** 広域ディレクトリの誤初期化を防ぐ。
- **`gh repo create` が失敗（同名リポジトリ既存など）したら中断**し、ローカルは init 済み・remote 未連携の状態で止める。勝手に別名で作らない。

退避した `.git.bak-*` は、新リポジトリが正しく push できたことを確認したうえで、ユーザーの判断で手動削除してもらう（スキルは自動削除しない）。

「既存プロジェクト検出で中断」した場合は、ユーザーへ「これは既存リポジトリに見えるので保護した。新規として作り直すなら -Force を付ける」と伝え、**勝手に -Force を付けて再実行しない**。

# 実行手順

基本は同梱スクリプトを実行するだけ。プラットフォームに合わせて選ぶ：

- **Windows（このユーザーの既定）**: `scripts/setup-git.ps1` を PowerShell で実行
- **macOS / Linux / Git Bash**: `scripts/setup-git.sh` を bash で実行

## PowerShell（Windows）

```powershell
# 既定: リポジトリ名=フォルダ名、private、カレントディレクトリ
powershell -ExecutionPolicy Bypass -File <skill>/scripts/setup-git.ps1

# 名前や公開設定を変えたいとき
powershell -ExecutionPolicy Bypass -File <skill>/scripts/setup-git.ps1 -RepoName my-app -Visibility private
```

## bash（macOS / Linux / Git Bash）

```bash
bash <skill>/scripts/setup-git.sh                 # 既定: フォルダ名 / private
bash <skill>/scripts/setup-git.sh -n my-app -v public
```

引数：

| 引数 | 既定 | 意味 |
| --- | --- | --- |
| RepoName / `-n` | カレントフォルダ名（英数記号以外は `-` に置換） | 作成する GitHub リポジトリ名 |
| Visibility / `-v` | `private` | `private` または `public` |
| Path / `-p` | `.` | 対象プロジェクトのルート |
| Force / `-f` | off | 既存プロジェクト保護を解除し、履歴+remote ありでも作り直す（退避は維持）。ユーザーが明示的に望んだときだけ付ける |

## スクリプトが内部で行うこと（手動でやる場合の参考）

スクリプトを使わず手で実行する場合も、必ずこの順序とガードを守る：

```bash
# 0) 前提チェック（gh 認証）
gh auth status            # 失敗したら中断して gh auth login を案内

# 1) 既存プロジェクト保護: 履歴 + remote の両方があれば中断（.git に触れない）
if [ -d .git ] && git rev-parse --verify HEAD >/dev/null 2>&1 && [ -n "$(git remote)" ]; then
  echo "既存プロジェクトに見えるため中断。作り直すなら明示的に -Force/-f"; exit 1
fi

# 2) 上記を抜けたら、既存 .git は「削除ではなく退避」
[ -d .git ] && mv .git ".git.bak-$(date +%Y%m%d-%H%M%S)"

# 4) まっさらに初期化（main ブランチ）
git init -b main

# 5) 初回コミット（push できるよう最低1コミット作る。空でも可）
git add -A
git commit -m "chore: initial commit" --allow-empty

# 6) GitHub に private リポジトリ作成 + origin 連携 + push を一気通貫
gh repo create "$(basename "$PWD")" --private --source=. --remote=origin --push
```

# 完了後の報告

実行後、ユーザーへ次を伝える：

- 作成した GitHub リポジトリ URL（`gh repo view --json url -q .url`）
- ローカルが新しい `origin` に連携され、初回 push 済みであること
- 旧履歴がある場合は `.git.bak-*` に退避してあり、確認後に手動削除してよいこと
- 次は要件定義（[[requirements-discovery]] / [[project-discovery]]）へ進めること

# このスキルがやらないこと

- 要件定義・仕様・スコープの整理（→ [[requirements-discovery]] / [[scope-discovery]] / [[project-discovery]]）
- CI/CD・ブランチ保護・Issue テンプレ等のリポジトリ運用設定（必要なら別途）
- 既存リポジトリへの追加コミットや通常の push 運用（これは初期化専用スキル）

# 実行モデルティア

推奨ティア: **standard**（手順追従型のため標準クラスのモデルで品質が安定する）。
最上位推論クラスのモデルを占有する必要はない。手順から外れる複雑な判断が
必要になったら、その論点を明示して deep ティアの設計・監査系スキルへ引き渡すこと。
具体的なモデル名はここに書かない（対応表は `.skills/MODEL-TIERS.md`）。
