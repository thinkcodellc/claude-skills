# install.ps1 — Install VJ-Agent Claude Code customizations
# Clones settings, skills, agents, hooks to ~/.claude/ and workspace
#
# Usage: pwsh -File install.ps1 [-Workspace "C:\workspace\claude"] [-Force]

param(
    [string]$Workspace = (Get-Location).Path,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$CLAUDE_HOME = "$env:USERPROFILE\.claude"
$REPO_ROOT = Split-Path $PSCommandPath -Parent

Write-Host "`n═══ VJ-Agent Claude Code Installer ═══`n" -ForegroundColor Cyan
Write-Host "   Source : $REPO_ROOT"
Write-Host "   Target : $CLAUDE_HOME"
Write-Host "   Workspace: $Workspace"

if (-not $Force) {
    Write-Host "`n⚠️  This will MERGE settings.json (existing backed up) and overwrite skills/agents/hooks." -ForegroundColor Yellow
    $confirm = Read-Host "Proceed? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Aborted."
        exit 0
    }
}

# ── Create directories ───────────────────────────────────────────
$dirs = @(
    "$CLAUDE_HOME\skills",
    "$CLAUDE_HOME\agents",
    "$CLAUDE_HOME\hooks"
)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Write-Host "📁 Created $d"
    }
}

# ── Install skills ───────────────────────────────────────────────
Write-Host "`n── Installing skills ──`n" -ForegroundColor Yellow
$skillDirs = Get-ChildItem (Join-Path $REPO_ROOT "skills") -Directory
foreach ($sd in $skillDirs) {
    $target = Join-Path $CLAUDE_HOME "skills\$($sd.Name)"
    $source = $sd.FullName

    if (Test-Path $target) {
        Write-Host "⚠️  $($sd.Name) exists — overwriting" -ForegroundColor Yellow
    }
    Copy-Item -Path "$source\*" -Destination $target -Recurse -Force
    Write-Host "✅ $($sd.Name)"
}

# ── Install agents ───────────────────────────────────────────────
Write-Host "`n── Installing agents ──`n" -ForegroundColor Yellow
$agentFiles = Get-ChildItem (Join-Path $REPO_ROOT "agents") -File
foreach ($af in $agentFiles) {
    $target = Join-Path $CLAUDE_HOME "agents\$($af.Name)"
    Copy-Item -Path $af.FullName -Destination $target -Force
    Write-Host "✅ $($af.Name)"
}

# ── Install hooks ────────────────────────────────────────────────
Write-Host "`n── Installing hooks ──`n" -ForegroundColor Yellow
$hookFiles = Get-ChildItem (Join-Path $REPO_ROOT "hooks") -File
foreach ($hf in $hookFiles) {
    $target = Join-Path $CLAUDE_HOME "hooks\$($hf.Name)"
    Copy-Item -Path $hf.FullName -Destination $target -Force
    Write-Host "✅ $($hf.Name)"
}

# ── Install settings (with backup + merge warning) ───────────────
Write-Host "`n── Installing settings ──`n" -ForegroundColor Yellow
$sourceSettings = Join-Path $REPO_ROOT "settings\settings.json"
$targetSettings = Join-Path $CLAUDE_HOME "settings.json"

if (Test-Path $targetSettings) {
    $backup = "$targetSettings.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -Path $targetSettings -Destination $backup
    Write-Host "📋 Backed up existing settings → $backup"
    Write-Host "⚠️  Settings merged. REVIEW the result — model, paths, and permissions may differ." -ForegroundColor Yellow
}

# Smart merge: copy the source file but warn about review
Copy-Item -Path $sourceSettings -Destination $targetSettings -Force
Write-Host "✅ settings.json installed"
Write-Host "   ⚠️  Edit $targetSettings to adjust for this machine (paths, model, API keys)"

# ── Install CLAUDE.md ────────────────────────────────────────────
Write-Host "`n── Installing CLAUDE.md ──`n" -ForegroundColor Yellow
$sourceClaude = Join-Path $REPO_ROOT "claude-md\CLAUDE.md"
$targetClaude = Join-Path $Workspace "CLAUDE.md"

if (Test-Path $targetClaude) {
    Write-Host "⚠️  $targetClaude exists — manually merge the Self-Improvement section" -ForegroundColor Yellow
    Write-Host "   Source: $sourceClaude"
} else {
    Copy-Item -Path $sourceClaude -Destination $targetClaude
    Write-Host "✅ CLAUDE.md installed"
}

# ── Install tests ────────────────────────────────────────────────
Write-Host "`n── Installing tests ──`n" -ForegroundColor Yellow
$sourceTests = Join-Path $REPO_ROOT "tests"
$targetTests = Join-Path $Workspace "tests"

if (Test-Path $targetTests) {
    Write-Host "⚠️  tests/ exists — overwriting" -ForegroundColor Yellow
}
Copy-Item -Path $sourceTests -Destination $targetTests -Recurse -Force
Write-Host "✅ tests/ installed"

# ── Final checklist ──────────────────────────────────────────────
Write-Host "`n═══ Installation Complete ═══`n" -ForegroundColor Green
Write-Host "Post-install checklist:"
Write-Host "  [ ] Review ~/.claude/settings.json (model, paths, permissions)"
Write-Host "  [ ] Create .claude/vj-lessons.jsonl in workspace (empty file)"
Write-Host "  [ ] Install defuddle CLI + defuddle.py (see README)"
Write-Host "  [ ] Run validation: pwsh -File tests/vj-reflect/run_test.ps1"
Write-Host "  [ ] Restart Claude Code to load new hooks and skills"
Write-Host ""
