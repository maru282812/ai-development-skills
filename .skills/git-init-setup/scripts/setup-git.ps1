#requires -Version 5.1
<#
.SYNOPSIS
  新規プロジェクトの Git を作り直して GitHub と連携する（全自動・安全ガード付き）。
.DESCRIPTION
  既存 .git を .git.bak-<timestamp> へ退避 → git init(main) → 初回コミット →
  GitHub リポジトリ作成(gh) → origin 連携 → 初回 push。
  既存プロジェクト（コミット履歴 + remote あり）は保護のため既定で中断し、.git に一切触れない。
  ドライブ直下/ホーム直下では実行拒否。.git をハード削除することは決してない（退避のみ）。
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File setup-git.ps1 -RepoName my-app -Visibility private
.EXAMPLE
  # 既存リポジトリ（テンプレートclone等）を意図的に作り直す場合のみ
  powershell -ExecutionPolicy Bypass -File setup-git.ps1 -Force
#>
[CmdletBinding()]
param(
    [string]$RepoName = "",
    [ValidateSet('private', 'public')]
    [string]$Visibility = 'private',
    [string]$Path = ".",
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Fail($msg) {
    Write-Host "ERROR: $msg" -ForegroundColor Red
    exit 1
}

# --- 対象ディレクトリを解決 ---
$target = (Resolve-Path -LiteralPath $Path).Path
Set-Location -LiteralPath $target

# --- 安全ガード 1: 広域ディレクトリでは実行しない ---
$root = [System.IO.Path]::GetPathRoot($target)
if ($target.TrimEnd('\', '/') -eq $root.TrimEnd('\', '/')) {
    Fail "ドライブ直下では実行できません: $target"
}
if ($target -eq $env:USERPROFILE) {
    Fail "ユーザーホーム直下では実行できません: $target"
}

# --- 安全ガード 2: gh の存在と認証 ---
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Fail "GitHub CLI (gh) が見つかりません。https://cli.github.com/ から導入し 'gh auth login' を実行してください。"
}
gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    Fail "gh が未認証です。先に 'gh auth login' を実行してください。"
}

# --- 安全ガード 3: 既存プロジェクトを保護（最重要） ---
# .git に「コミット履歴」と「remote」の両方があれば、運用中の既存リポジトリと判断し、
# .git には一切触れずに中断する。テンプレートclone等を本当に作り直すときだけ -Force。
$gitDir = Join-Path $target ".git"
$doBackup = $false
if (Test-Path -LiteralPath $gitDir) {
    git rev-parse --verify HEAD *> $null
    $hasCommits = ($LASTEXITCODE -eq 0)
    $remotes = (git remote 2>$null | Out-String)
    $hasRemote = -not [string]::IsNullOrWhiteSpace($remotes)

    if ($hasCommits -and $hasRemote -and -not $Force) {
        $originUrl = (git remote get-url origin 2>$null)
        if ([string]::IsNullOrWhiteSpace($originUrl)) { $originUrl = ($remotes.Trim()) }
        Fail @"
既存プロジェクトを検出したため中断しました。.git には一切変更を加えていません。
  コミット履歴あり + remote あり (origin: $originUrl)
運用中のリポジトリを誤って作り直す事故を防ぐため、既定では作り直しません。
本当に作り直す場合のみ -Force を付けて再実行してください
（-Force でも .git は削除せず .git.bak-<timestamp> へ退避します）。
"@
    }
    # ここに来るのは「新規スキャフォールド（remoteなし/履歴なし）」または -Force 指定時のみ
    $doBackup = $true
}

# --- 既存 .git は削除せず退避 ---
if ($doBackup) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupName = ".git.bak-$stamp"
    Write-Host "既存 .git を退避（削除しません）: $backupName" -ForegroundColor Yellow
    Rename-Item -LiteralPath $gitDir -NewName $backupName
}

Write-Host "対象        : $target"
Write-Host "リポジトリ名 : $RepoName ($Visibility)"

# --- リポジトリ名（既定はフォルダ名、英数 . _ - 以外は - に置換） ---
if ([string]::IsNullOrWhiteSpace($RepoName)) {
    $RepoName = Split-Path -Leaf $target
}
$RepoName = ($RepoName -replace '[^A-Za-z0-9._-]', '-')

# --- まっさらに初期化 ---
git init -b main | Out-Null
if ($LASTEXITCODE -ne 0) { Fail "git init に失敗しました。" }

# --- .gitignore が無ければ最小構成を作成（退避フォルダも無視） ---
$gitignore = Join-Path $target ".gitignore"
if (-not (Test-Path -LiteralPath $gitignore)) {
    $lines = @(
        "# created by git-init-setup",
        "node_modules/",
        ".env",
        ".env.local",
        ".git.bak-*/"
    )
    Set-Content -LiteralPath $gitignore -Value $lines -Encoding ascii
}

# --- 初回コミット（push できるよう最低1コミット） ---
git add -A | Out-Null
git commit -m "chore: initial commit" --allow-empty | Out-Null
if ($LASTEXITCODE -ne 0) { Fail "初回コミットに失敗しました。" }

# --- GitHub 作成 + origin 連携 + push ---
Write-Host "GitHub リポジトリを作成して push します..." -ForegroundColor Cyan
gh repo create $RepoName "--$Visibility" --source=. --remote=origin --push
if ($LASTEXITCODE -ne 0) {
    Fail "gh repo create に失敗しました（同名リポジトリが既に存在する可能性）。ローカルは init 済み・remote 未連携で停止します。"
}

$url = (gh repo view --json url -q .url)

Write-Host ""
Write-Host "完了しました。" -ForegroundColor Green
Write-Host "  ローカル : $target"
Write-Host "  リモート : $url"
$baks = Get-ChildItem -LiteralPath $target -Directory -Filter ".git.bak-*" -Force -ErrorAction SilentlyContinue
if ($baks) {
    Write-Host "  旧履歴   : $($baks.Name -join ', ') に退避済み（確認後に手動削除可）" -ForegroundColor Yellow
}
Write-Host "  次の工程 : 要件定義（requirements-discovery / project-discovery）へ"
