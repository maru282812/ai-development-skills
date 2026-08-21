<#
.SYNOPSIS
  Install the Loop Engineering "factory" skill chain globally and/or into a project,
  and (optionally) bootstrap a target repo with the thin factory files.

.DESCRIPTION
  The factory chain is the common manufacturing loop:
    SPEC -> PLAN -> [ MAKER -> GATES -> RUNTIME VERIFY -> CHECKER -> RECEIPT ] -> HUMAN GATE -> MAINTAIN

  Skills installed (canonical source: repo .skills/<name>):
    factory-bootstrap    install the thin per-repo files (docs/VERIFY.md, .claude/loop.md, CLAUDE.md section)
    verification-loop    runtime verification loop (gates + real screen/operation + receipt)
    phase-runner         autonomous phase-by-phase implementation with checker + receipt
    implementation-planner  produces the phase plan phase-runner consumes
    code-review / security-review / migration-review   checker deep-dives + human-gate DB check
    development-router   router that selects the right skill from a plain-language request

  Targets:
    -Global          : Codex  ~/.codex/skills/<name>
                       Claude ~/.claude/skills/<name>
    -Project <path>  : Codex  <path>/.agents/skills/<name>
                       Claude <path>/.claude/skills/<name>

  -Bootstrap <path>  prints the ready-to-paste request that runs factory-bootstrap
                     against that repo (this script does NOT write repo files itself;
                     the skill does, because it must detect the repo's real commands).

  Default is dry-run; use -Apply to write.

  NOTE: kept ASCII-only on purpose. Windows PowerShell 5.1 reads a BOM-less .ps1
  as the system ANSI codepage, which corrupts non-ASCII source.

.EXAMPLE
  powershell -File scripts/install-factory.ps1 -Global                      # dry-run, global
  powershell -File scripts/install-factory.ps1 -Global -Apply               # install globally
  powershell -File scripts/install-factory.ps1 -Project C:\work\resto-sns -Apply
  powershell -File scripts/install-factory.ps1 -Global -Apply -Bootstrap C:\work\resto-sns

.NOTES
  Global install is usually enough: global skills are visible from every project.
  Use -Project only when a repo must carry its own pinned copy.
#>
param(
  [switch]$Global,
  [string]$Project,
  [string]$Bootstrap,
  [switch]$Apply
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$srcSkills = Join-Path $repo ".skills"

# --- the factory (loop engineering) chain ---
# NOTE: code-review / security-review are intentionally EXCLUDED from the global
# install: Claude Code ships built-in /code-review and /security-review commands,
# and installing same-named skills into ~/.claude/skills shadows them (breaking
# e.g. "/code-review ultra"). Those two stay canonical in .skills/ and are reached
# via development-router (Read), not via the Skill tool.
$factory = @(
  # router (so a plain-language request reaches the right skill)
  "development-router",
  # the loop itself
  "factory-bootstrap", "verification-loop", "phase-runner",
  # plan input consumed by phase-runner
  "implementation-planner",
  # human-gate DB safety (no built-in name collision)
  "migration-review"
)

if (-not (Test-Path $srcSkills)) { throw "Canonical source not found: $srcSkills" }
if (-not $Global -and -not $Project -and -not $Bootstrap) {
  Write-Host "Nothing to do. Pass -Global and/or -Project <path> (and optionally -Bootstrap <path>)." -ForegroundColor Yellow
  Write-Host "Add -Apply to actually write (default is dry-run)."
  exit 0
}

$mode = if ($Apply) { "APPLY" } else { "DRY-RUN" }
Write-Host "=== install-factory ($mode) ===" -ForegroundColor Cyan
Write-Host ("factory skills: {0}" -f $factory.Count)

function Install-Set([string]$label, [string]$destDir, [string[]]$names) {
  Write-Host ""
  Write-Host ("--- {0}: {1} ---" -f $label, $destDir)
  if ($Apply -and -not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  }
  foreach ($name in $names) {
    $src = Join-Path $srcSkills $name
    if (-not (Test-Path $src)) { Write-Host ("  [MISS] {0}  (no canonical source)" -f $name) -ForegroundColor Red; continue }
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
  Install-Set "Codex global"  (Join-Path $userHome ".codex/skills")  $factory
  Install-Set "Claude global" (Join-Path $userHome ".claude/skills") $factory
}

if ($Project) {
  $proj = (Resolve-Path -LiteralPath $Project -ErrorAction SilentlyContinue)
  if (-not $proj) {
    if ($Apply) { throw "Project path not found: $Project" }
    $proj = $Project
  }
  Install-Set "Codex project"  (Join-Path $proj ".agents/skills") $factory
  Install-Set "Claude project" (Join-Path $proj ".claude/skills") $factory
}

Write-Host ""
if ($Apply) {
  Write-Host "Applied. Restart your CLI / reload skills to pick up changes." -ForegroundColor Cyan
} else {
  Write-Host "Dry-run complete. Re-run with -Apply to write." -ForegroundColor Cyan
}

if ($Bootstrap) {
  Write-Host ""
  Write-Host "--- next step: bootstrap the repo ---" -ForegroundColor Cyan
  Write-Host "Open Claude Code in that repo and say (either works):"
  Write-Host ""
  Write-Host ("  cd {0}" -f $Bootstrap) -ForegroundColor Yellow
  Write-Host "  loop shitechatte  /  /factory-bootstrap" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "The skill detects the repo's real commands and writes:"
  Write-Host "  docs/VERIFY.md  .claude/loop.md  CLAUDE.md (section appended)"
}
