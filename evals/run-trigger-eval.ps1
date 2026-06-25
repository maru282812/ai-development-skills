<#
.SYNOPSIS
  Run skill-creator's trigger/description-optimization loop for one skill.

.DESCRIPTION
  Resolves the installed skill-creator path (from the plugins cache), then runs
  scripts.run_loop with this repo's trigger eval set for the given skill.

  REQUIREMENT: the `claude` CLI must be on PATH (run_loop invokes `claude -p` as a
  subprocess). If `claude` is not installed/on PATH, this will fail. Run it from a
  terminal where `claude --version` works.

.EXAMPLE
  powershell -File evals/run-trigger-eval.ps1 -Skill scope-discovery
  powershell -File evals/run-trigger-eval.ps1 -Skill requirements-discovery -MaxIterations 5

.NOTES
  ASCII-only on purpose (Windows PowerShell 5.1 corrupts BOM-less non-ASCII .ps1).
#>
param(
  [Parameter(Mandatory=$true)][string]$Skill,
  [string]$Model = "claude-opus-4-8",
  [int]$MaxIterations = 5
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot

# Pre-flight: claude CLI must exist
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  throw "claude CLI not found on PATH. run_loop needs 'claude -p'. Open a terminal where 'claude --version' works."
}

# Resolve skill-creator dir (version segment varies, so glob)
$scGlob = Join-Path $env:USERPROFILE ".claude/plugins/cache/anthropic-agent-skills/example-skills/*/skills/skill-creator"
$sc = @(Resolve-Path $scGlob -ErrorAction SilentlyContinue)
if (-not $sc -or $sc.Count -eq 0) { throw "skill-creator not found under plugins cache. Is example-skills installed?" }
$scPath = $sc[0].Path

$evalSet  = Join-Path $repo "evals/trigger/$Skill.json"
$skillDir = Join-Path $repo ".claude/skills/$Skill"
if (-not (Test-Path $evalSet))  { throw "eval set not found: $evalSet" }
if (-not (Test-Path $skillDir)) { throw "skill dir not found: $skillDir" }

Write-Host "skill-creator: $scPath"     -ForegroundColor Cyan
Write-Host "eval set:      $evalSet"     -ForegroundColor Cyan
Write-Host "skill path:    $skillDir"    -ForegroundColor Cyan
Write-Host "model:         $Model"       -ForegroundColor Cyan
Write-Host ""

Push-Location $scPath
try {
  python -m scripts.run_loop `
    --eval-set $evalSet `
    --skill-path $skillDir `
    --model $Model `
    --max-iterations $MaxIterations `
    --verbose
}
finally {
  Pop-Location
}
