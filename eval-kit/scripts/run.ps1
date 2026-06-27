# eval-kit ランナー（Windows / PowerShell）
# 使い方:  .\scripts\run.ps1
# 事前に環境変数 ANTHROPIC_API_KEY を設定しておくこと（被験・Judge両方が使う）。
$ErrorActionPreference = "Stop"
Push-Location (Join-Path $PSScriptRoot "..")
try {
    if (-not $env:ANTHROPIC_API_KEY) {
        Write-Warning "ANTHROPIC_API_KEY が未設定です。判定/被験のモデル呼び出しに失敗します。"
    }
    New-Item -ItemType Directory -Force -Path "results" | Out-Null
    npx --yes promptfoo@latest eval -c promptfooconfig.yaml --output results/latest.json
    Write-Host "`n結果をブラウザで見る: npx promptfoo@latest view" -ForegroundColor Cyan
} finally {
    Pop-Location
}
