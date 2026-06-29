<#
.SYNOPSIS
  Install the Discovery -> image-UI skill chain into any project and/or the
  global skill dirs for both Codex and Claude Code.

.DESCRIPTION
  The "chain" is the requirements-definition -> ... -> screen-design (Google
  Stitch / image UI) -> spec/impl handoff workflow. This script deploys that
  full chain so it works in BOTH tools and in ANY project.

  Canonical sources:
    - chain skills          -> repo .skills/<name>
    - Claude-only loop ctrl -> repo .claude/skills/<name> (agent-planner, agent-tester)

  Targets:
    -Global            : Codex  ~/.codex/skills/<name>   (chain)
                         Claude ~/.claude/skills/<name>  (chain + Claude-only)
    -Project <path>    : Codex  <path>/.agents/skills/<name>  (chain)
                         Claude <path>/.claude/skills/<name>  (chain + Claude-only)

  You may pass -Global, -Project, or both. Default is dry-run; use -Apply to write.
  Existing skill dirs at the target are replaced (clean copy). Unrelated skills
  in the target dirs are left untouched.

  NOTE: kept ASCII-only on purpose. Windows PowerShell 5.1 reads a BOM-less .ps1
  as the system ANSI codepage, which corrupts non-ASCII source.

.EXAMPLE
  powershell -File scripts/install-discovery-chain.ps1 -Global                 # dry-run, global
  powershell -File scripts/install-discovery-chain.ps1 -Global -Apply          # install globally
  powershell -File scripts/install-discovery-chain.ps1 -Project C:\work\foo -Apply
  powershell -File scripts/install-discovery-chain.ps1 -Global -Project C:\work\foo -Apply

.NOTES
  Review changes afterwards (git diff in the repo is unaffected; this writes to
  the target project / global dirs, not .skills).
#>
param(
  [switch]$Global,
  [string]$Project,
  [switch]$Apply
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$srcSkills = Join-Path $repo ".skills"
$srcClaude = Join-Path $repo ".claude/skills"

# --- the requirements-definition -> image-UI -> handoff chain (both tools) ---
$chain = @(
  # orchestrator + scope/requirements
  "project-discovery", "scope-discovery", "requirements-discovery",
  # discovery domains
  "business-discovery", "operations-discovery",
  "legal-discovery", "legal-publication-manager", "contract-discovery",
  "risk-discovery", "data-discovery", "integration-discovery",
  "metrics-discovery", "nfr-discovery",
  # loop control
  "discovery-planner", "discovery-auditor",
  # init tooling
  "git-init-setup", "project-quality-tooling",
  # screen design -> Google Stitch (image UI) -> implementation handoff
  "screen-design-architect", "ui-ux-review",
  "feature-spec-writer", "saas-product-manager", "implementation-planner"
)

# --- Claude Code only (post-image-UI implementation loop) ---
$claudeOnly = @("agent-planner", "agent-tester")

if (-not (Test-Path $srcSkills)) { throw "Canonical source not found: $srcSkills" }
if (-not $Global -and -not $Project) {
  Write-Host "Nothing to do. Pass -Global and/or -Project <path>." -ForegroundColor Yellow
  Write-Host "Add -Apply to actually write (default is dry-run)."
  exit 0
}

$mode = if ($Apply) { "APPLY" } else { "DRY-RUN" }
Write-Host "=== install-discovery-chain ($mode) ===" -ForegroundColor Cyan
Write-Host ("chain skills: {0} | Claude-only: {1}" -f $chain.Count, $claudeOnly.Count)

function Resolve-Source([string]$name) {
  $a = Join-Path $srcSkills $name
  if (Test-Path $a) { return $a }
  $b = Join-Path $srcClaude $name
  if (Test-Path $b) { return $b }
  return $null
}

function Install-Set([string]$label, [string]$destDir, [string[]]$names) {
  Write-Host ""
  Write-Host ("--- {0}: {1} ---" -f $label, $destDir)
  if ($Apply -and -not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  }
  foreach ($name in $names) {
    $src = Resolve-Source $name
    if (-not $src) { Write-Host ("  [MISS] {0}  (no canonical source)" -f $name) -ForegroundColor Red; continue }
    $dest = Join-Path $destDir $name
    Write-Host ("  [install] {0}" -f $name) -ForegroundColor Green
    if ($Apply) {
      if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
      Copy-Item -Recurse -Force $src $dest
    }
  }
}

$userHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }

if ($Global) {
  Install-Set "Codex global"  (Join-Path $userHome ".codex/skills")  $chain
  Install-Set "Claude global" (Join-Path $userHome ".claude/skills") ($chain + $claudeOnly)
}

if ($Project) {
  $proj = (Resolve-Path -LiteralPath $Project -ErrorAction SilentlyContinue)
  if (-not $proj) {
    if ($Apply) { throw "Project path not found: $Project" }
    $proj = $Project  # allow dry-run preview of a not-yet-existing path
  }
  Install-Set "Codex project"  (Join-Path $proj ".agents/skills") $chain
  Install-Set "Claude project" (Join-Path $proj ".claude/skills") ($chain + $claudeOnly)
}

Write-Host ""
if ($Apply) {
  Write-Host "Applied. Restart your CLI / reload skills to pick up changes." -ForegroundColor Cyan
} else {
  Write-Host "Dry-run complete. Re-run with -Apply to write." -ForegroundColor Cyan
}
