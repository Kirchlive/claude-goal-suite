# bootstrap.ps1 — One-time setup for the claude-goal-suite skill (Windows)
# =================================================================
# PowerShell 7+ required.

$ErrorActionPreference = "Stop"

function Log    ($msg) { Write-Host "[bootstrap] $msg" -ForegroundColor Blue }
function Ok     ($msg) { Write-Host "[ ok ] $msg"      -ForegroundColor Green }
function Warn   ($msg) { Write-Host "[warn] $msg"      -ForegroundColor Yellow }
function ErrMsg ($msg) { Write-Host "[err ] $msg"      -ForegroundColor Red }

# --- 1. Claude Code version ---
Log "Checking Claude Code version..."
$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claudeCmd) {
    ErrMsg "claude CLI not found. Install via:"
    Write-Host "  npm install -g @anthropic-ai/claude-code"
    exit 1
}

$versionOutput = & claude --version 2>&1
$versionMatch  = [regex]::Match($versionOutput, '(\d+\.\d+\.\d+)')
if ($versionMatch.Success) {
    $current  = [version]$versionMatch.Groups[1].Value
    $required = [version]"2.1.139"
    if ($current -ge $required) {
        Ok "Claude Code $current (>= $required)"
    } else {
        ErrMsg "Claude Code $current is too old (>= $required required)"
        Write-Host "  Update: npm update -g @anthropic-ai/claude-code"
        exit 1
    }
} else {
    Warn "Could not parse Claude Code version — continuing, but verify manually"
}

# --- 2. Update .gitignore ---
Log "Updating .gitignore..."
if (-not (Test-Path .gitignore)) {
    New-Item -ItemType File -Path .gitignore | Out-Null
}

$gitignore = Get-Content .gitignore -Raw -ErrorAction SilentlyContinue
if ($null -eq $gitignore) { $gitignore = "" }

if ($gitignore -notmatch '(?m)^\.claude/worktrees/') {
    Add-Content .gitignore "`n# Claude Code fork worktrees (Claude-Full-Context-Agent)`n.claude/worktrees/"
    Ok ".claude/worktrees/ added to .gitignore"
} else {
    Ok ".claude/worktrees/ already in .gitignore"
}

if ($gitignore -notmatch '(?m)^\.goal-suite/') {
    Add-Content .gitignore "`n# claude-goal-suite artefacts`n.goal-suite/"
    Ok ".goal-suite/ added to .gitignore"
} else {
    Ok ".goal-suite/ already in .gitignore"
}

# --- 3. .goal-suite directory ---
Log "Creating .goal-suite/..."
New-Item -ItemType Directory -Force -Path .goal-suite | Out-Null
if (-not (Test-Path .goal-suite/.gitkeep)) {
    New-Item -ItemType File -Path .goal-suite/.gitkeep | Out-Null
}
Ok ".goal-suite/ ready"

# --- 4. Git state ---
Log "Checking git state..."
if (Test-Path .git) {
    $dirty = & git status --porcelain 2>$null
    if ($dirty) {
        Warn "Working tree is not clean. Commit before /goal-suite!"
        & git status --short
    } else {
        Ok "Working tree clean"
    }
} else {
    Warn "No git repo. Init recommended: git init"
}

# --- 5. Print instructions ---
$cwd = (Get-Location).Path

Write-Host ""
Write-Host "============================================================"
Write-Host "  MANUAL STEPS in Claude Code"
Write-Host "============================================================"
Write-Host ""
Write-Host "Start Claude Code and run the commands sequentially."
Write-Host "Restart where indicated."
Write-Host ""
Write-Host "  # ---- 1. Superpowers ----"
Write-Host "  /plugin marketplace add obra/superpowers-marketplace"
Write-Host "  /plugin install superpowers@superpowers-marketplace"
Write-Host ""
Write-Host "  # ---- 2. Claude-Full-Context-Agent ----"
Write-Host "  /plugin marketplace add Kirchlive/Claude-Full-Context-Agent"
Write-Host "  /plugin install Claude-Full-Context-Agent@Claude-Full-Context-Agent"
Write-Host ""
Write-Host "  # ---- 3. claude-goal-suite (this skill) ----"
Write-Host "  /plugin marketplace add $cwd"
Write-Host "  /plugin install claude-goal-suite@claude-goal-suite-marketplace"
Write-Host ""
Write-Host "  # ---- 4. Restart Claude Code ----"
Write-Host ""
Write-Host "  # ---- 5. Fork-subagent mode ----"
Write-Host "  /Claude-Full-Context-Agent:doctor"
Write-Host ""
Write-Host "  # ---- 6. Restart Claude Code AGAIN ----"
Write-Host ""
Write-Host "  # ---- 7. Auto Mode ----"
Write-Host "  /auto-mode on"
Write-Host ""
Write-Host "  # ---- 8. Verify ----"
Write-Host "  /plugin list"
Write-Host ""
Write-Host "============================================================"
Write-Host ""
Ok "Bootstrap finished. Follow the manual steps above."
Write-Host "Then: /goal-suite:preflight  -> first step before every run."
