<#
.SYNOPSIS
  Sync skills from the canonical .skills/ into the mirrors (.agents/skills, .claude/skills).

.DESCRIPTION
  Canonical source is .skills/. Only skills that ALREADY EXIST in a mirror are
  overwritten with the canonical content.
  - Skills missing from a mirror are NOT added (mirror membership is preserved).
  - Mirror-only skills not present in the source (e.g. agent-planner / agent-tester)
    are left untouched.
  Default is dry-run (lists actions only). Use -Apply to actually write.

  NOTE: kept ASCII-only on purpose. Windows PowerShell 5.1 reads a BOM-less .ps1 as
  the system ANSI codepage, which corrupts non-ASCII source. Do not add Japanese here
  unless the file is saved as UTF-8 with BOM.

.EXAMPLE
  powershell -File scripts/sync-skills.ps1            # dry-run
  powershell -File scripts/sync-skills.ps1 -Apply     # apply

.NOTES
  Ensure `git status` is clean before applying. Review `git diff` afterwards.
#>
param(
  [switch]$Apply
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$src  = Join-Path $repo ".skills"
$mirrors = @(
  (Join-Path $repo ".agents/skills"),
  (Join-Path $repo ".claude/skills")
)

if (-not (Test-Path $src)) { throw "Canonical source not found: $src" }

$mode = if ($Apply) { "APPLY" } else { "DRY-RUN" }
Write-Host "=== sync-skills ($mode) ===" -ForegroundColor Cyan
Write-Host "source: $src"

foreach ($mirror in $mirrors) {
  if (-not (Test-Path $mirror)) { Write-Host "  (mirror not found, skip) $mirror" -ForegroundColor DarkGray; continue }
  Write-Host ""
  Write-Host "--- mirror: $mirror ---"
  Get-ChildItem -Path $mirror -Directory | ForEach-Object {
    $name = $_.Name
    $srcSkill = Join-Path $src $name
    if (Test-Path $srcSkill) {
      Write-Host ("  [sync] {0}" -f $name) -ForegroundColor Green
      if ($Apply) {
        Remove-Item -Recurse -Force (Join-Path $mirror $name)
        Copy-Item -Recurse -Force $srcSkill (Join-Path $mirror $name)
      }
    } else {
      Write-Host ("  [keep] {0}  (mirror-only skill, not in source; left untouched)" -f $name) -ForegroundColor Yellow
    }
  }
}

Write-Host ""
if ($Apply) {
  Write-Host "Applied. Review changes with: git diff" -ForegroundColor Cyan
} else {
  Write-Host "Dry-run complete. Re-run with -Apply to write, then review git diff." -ForegroundColor Cyan
}
