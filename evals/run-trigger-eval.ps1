<#
.SYNOPSIS
  Run skill-creator's trigger/description-optimization loop for one skill, or all A-group skills.

.DESCRIPTION
  Resolves the installed skill-creator path (from the plugins cache), then runs
  scripts.run_loop with this repo's trigger eval set for the given skill.

  REQUIREMENT: the `claude` CLI must be on PATH (run_loop invokes `claude -p` as a
  subprocess). If `claude` is not installed/on PATH, this fails fast with a clear message.
  Run it from a terminal where `claude --version` works.

.EXAMPLE
  powershell -File evals/run-trigger-eval.ps1 -Skill scope-discovery
  powershell -File evals/run-trigger-eval.ps1 -All            # all A-group skills (20-case sets)
  powershell -File evals/run-trigger-eval.ps1 -All -MaxIterations 3

.NOTES
  ASCII-only on purpose (Windows PowerShell 5.1 corrupts BOM-less non-ASCII .ps1).
#>
param(
  [string]$Skill,
  [switch]$All,
  [string]$Model = "claude-opus-4-8",
  [int]$MaxIterations = 5
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot

# Force Python UTF-8 mode. run_loop.py reads the eval JSON with Path.read_text(),
# which defaults to the OS ANSI codepage (cp932 on Japanese Windows) and chokes on
# our UTF-8 Japanese. UTF-8 mode fixes all of run_loop/run_eval text I/O without
# touching the plugin source.
$env:PYTHONUTF8 = "1"
$env:PYTHONIOENCODING = "utf-8"

# A-group skills that have 20-case trigger sets (see evals/skill-methodology.md)
$AGroup = @(
  "scope-discovery","requirements-discovery","business-discovery","operations-discovery",
  "legal-discovery","contract-discovery","risk-discovery","nfr-discovery",
  "integration-discovery","metrics-discovery","screen-design-architect",
  "code-review","security-review"
)

if (-not $All -and -not $Skill) { throw "Specify -Skill <name> or -All." }

# Pre-flight: claude CLI must exist (run_loop calls 'claude -p')
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  throw "claude CLI not found on PATH. run_loop needs 'claude -p'. Open a terminal where 'claude --version' works."
}

# Resolve skill-creator dir (version segment varies, so glob)
$scGlob = Join-Path $env:USERPROFILE ".claude/plugins/cache/anthropic-agent-skills/example-skills/*/skills/skill-creator"
$sc = @(Resolve-Path $scGlob -ErrorAction SilentlyContinue)
if (-not $sc -or $sc.Count -eq 0) { throw "skill-creator not found under plugins cache. Is example-skills installed?" }
$scPath = $sc[0].Path

# code-review / security-review live only in .skills; discovery skills live in .claude/skills too.
function Resolve-SkillDir([string]$name) {
  foreach ($base in @(".claude/skills", ".skills")) {
    $p = Join-Path $repo (Join-Path $base $name)
    if (Test-Path (Join-Path $p "SKILL.md")) { return $p }
  }
  return $null
}

function Invoke-OneSkill([string]$name) {
  $evalSet  = Join-Path $repo "evals/trigger/$name.json"
  $skillDir = Resolve-SkillDir $name
  if (-not (Test-Path $evalSet)) { Write-Host "  skip $name (no eval set)" -ForegroundColor Yellow; return }
  if (-not $skillDir)            { Write-Host "  skip $name (no SKILL.md)" -ForegroundColor Yellow; return }

  Write-Host ""
  Write-Host "=== $name ===" -ForegroundColor Cyan
  Write-Host "  eval:  $evalSet"
  Write-Host "  skill: $skillDir"
  Push-Location $scPath
  try {
    python -m scripts.run_loop --eval-set $evalSet --skill-path $skillDir --model $Model --max-iterations $MaxIterations --verbose
  } finally { Pop-Location }
}

$targets = if ($All) { $AGroup } else { @($Skill) }
Write-Host "skill-creator: $scPath" -ForegroundColor Cyan
Write-Host "model: $Model | max-iterations: $MaxIterations | targets: $($targets.Count)" -ForegroundColor Cyan
foreach ($t in $targets) { Invoke-OneSkill $t }
Write-Host ""
Write-Host "Done. Apply each best_description to .skills/<skill>/SKILL.md, then: powershell -File scripts/sync-skills.ps1 -Apply" -ForegroundColor Green
