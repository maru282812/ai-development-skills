#!/usr/bin/env bash
# 新規プロジェクトの Git を作り直して GitHub と連携する（全自動・安全ガード付き）。
# 既存 .git を .git.bak-<timestamp> へ退避 → git init(main) → 初回コミット →
# gh repo create → origin 連携 → push。
# 既存プロジェクト（コミット履歴 + remote あり）は保護のため既定で中断し .git に一切触れない。
# ドライブ直下/ホーム直下では実行拒否。.git をハード削除することは決してない（退避のみ）。
set -euo pipefail

REPO_NAME=""
VISIBILITY="private"
TARGET="."
FORCE=0

usage() { echo "usage: setup-git.sh [-n repo-name] [-v private|public] [-p path] [-f]"; exit 1; }

while getopts "n:v:p:fh" opt; do
  case "$opt" in
    n) REPO_NAME="$OPTARG" ;;
    v) VISIBILITY="$OPTARG" ;;
    p) TARGET="$OPTARG" ;;
    f) FORCE=1 ;;
    h|*) usage ;;
  esac
done

fail() { echo "ERROR: $*" >&2; exit 1; }

[ "$VISIBILITY" = "private" ] || [ "$VISIBILITY" = "public" ] || fail "visibility は private か public"

cd "$TARGET"
TARGET="$(pwd)"

# --- 安全ガード 1: 広域ディレクトリでは実行しない ---
[ "$TARGET" = "/" ] && fail "ルート直下では実行できません: $TARGET"
[ "$TARGET" = "$HOME" ] && fail "ホーム直下では実行できません: $TARGET"

# --- 安全ガード 2: gh の存在と認証 ---
command -v gh >/dev/null 2>&1 || fail "GitHub CLI (gh) が見つかりません。https://cli.github.com/ から導入し 'gh auth login' を実行してください。"
gh auth status >/dev/null 2>&1 || fail "gh が未認証です。先に 'gh auth login' を実行してください。"

# --- 安全ガード 3: 既存プロジェクトを保護（最重要） ---
# .git に「コミット履歴」と「remote」の両方があれば運用中の既存リポジトリと判断し、
# .git に一切触れず中断する。テンプレートclone等を本当に作り直すときだけ -f。
DO_BACKUP=0
if [ -d .git ]; then
  HAS_COMMITS=0; git rev-parse --verify HEAD >/dev/null 2>&1 && HAS_COMMITS=1
  HAS_REMOTE=0; [ -n "$(git remote 2>/dev/null)" ] && HAS_REMOTE=1
  if [ "$HAS_COMMITS" = 1 ] && [ "$HAS_REMOTE" = 1 ] && [ "$FORCE" != 1 ]; then
    ORIGIN="$(git remote get-url origin 2>/dev/null || git remote 2>/dev/null | head -n1)"
    fail "既存プロジェクトを検出したため中断（.git は未変更）。履歴+remote あり (origin: $ORIGIN)。運用中リポジトリの誤作り直しを防ぐため既定では作り直しません。本当に作り直すなら -f を付けて再実行（-f でも .git は削除せず .git.bak-* へ退避）。"
  fi
  DO_BACKUP=1
fi

# --- リポジトリ名（既定はフォルダ名、英数 . _ - 以外は - に置換） ---
[ -n "$REPO_NAME" ] || REPO_NAME="$(basename "$TARGET")"
REPO_NAME="$(printf '%s' "$REPO_NAME" | sed 's/[^A-Za-z0-9._-]/-/g')"

echo "対象        : $TARGET"
echo "リポジトリ名 : $REPO_NAME ($VISIBILITY)"

# --- 既存 .git は削除せず退避 ---
if [ "$DO_BACKUP" = 1 ]; then
  BACKUP=".git.bak-$(date +%Y%m%d-%H%M%S)"
  echo "既存 .git を退避（削除しません）: $BACKUP"
  mv .git "$BACKUP"
fi

# --- まっさらに初期化 ---
git init -b main >/dev/null

# --- .gitignore が無ければ最小構成を作成 ---
if [ ! -f .gitignore ]; then
  cat > .gitignore <<'EOF'
# created by git-init-setup
node_modules/
.env
.env.local
.git.bak-*/
EOF
fi

# --- 初回コミット ---
git add -A
git commit -m "chore: initial commit" --allow-empty >/dev/null

# --- GitHub 作成 + origin 連携 + push ---
echo "GitHub リポジトリを作成して push します..."
gh repo create "$REPO_NAME" "--$VISIBILITY" --source=. --remote=origin --push \
  || fail "gh repo create に失敗（同名リポジトリ既存の可能性）。ローカルは init 済み・remote 未連携で停止。"

URL="$(gh repo view --json url -q .url)"
echo ""
echo "完了しました。"
echo "  ローカル : $TARGET"
echo "  リモート : $URL"
ls -d .git.bak-* 2>/dev/null | sed 's/^/  旧履歴   : /;s/$/ に退避済み（確認後に手動削除可）/' || true
echo "  次の工程 : 要件定義（requirements-discovery / project-discovery）へ"
