#!/usr/bin/env bash
# bootstrap.sh — One-time setup for the claude-goal-suite skill
# ========================================================
# Installs plugin dependencies (Superpowers, Claude-Full-Context-Agent),
# configures the env variables and prepares the project.
#
# What this script does NOT do:
# - Plugin install inside Claude Code itself (that happens via /plugin)
# - Restart of Claude Code (manual by the user)
# - Setting CLAUDE_CODE_FORK_SUBAGENT (done by /Claude-Full-Context-Agent:doctor)
#
# Instead, it prints a sequential instruction list for the user to work
# through in Claude Code. Everything that CAN be automated is:
# - .gitignore additions
# - creating the .goal-suite/ directory
# - version checks
# - safety checks

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log()  { echo -e "${BLUE}[bootstrap]${NC} $*"; }
ok()   { echo -e "${GREEN}[ ok ]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err ]${NC} $*"; }

# ------------------------------------------------------------------
# 1. Check Claude Code version
# ------------------------------------------------------------------
log "Checking Claude Code version..."
if ! command -v claude >/dev/null 2>&1; then
  err "claude CLI not found. Install via:"
  echo "  curl -fsSL https://claude.ai/install.sh | bash"
  exit 1
fi

CLAUDE_VERSION=$(claude --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
if [ -z "$CLAUDE_VERSION" ]; then
  warn "Could not parse Claude Code version — continuing, but verify manually"
else
  REQUIRED="2.1.151"
  if [ "$(printf '%s\n' "$REQUIRED" "$CLAUDE_VERSION" | sort -V | head -n1)" = "$REQUIRED" ]; then
    ok "Claude Code $CLAUDE_VERSION (>= $REQUIRED)"
  else
    err "Claude Code $CLAUDE_VERSION is too old (>= $REQUIRED required for native /code-review reuse/simplify)"
    echo "  Update: curl -fsSL https://claude.ai/install.sh | bash"
    exit 1
  fi
fi

# ------------------------------------------------------------------
# 2. Update .gitignore
# ------------------------------------------------------------------
log "Updating .gitignore..."
if [ ! -f .gitignore ]; then
  touch .gitignore
fi

if ! grep -q '^\.claude/worktrees/' .gitignore; then
  echo '' >> .gitignore
  echo '# Claude Code fork worktrees (Claude-Full-Context-Agent)' >> .gitignore
  echo '.claude/worktrees/' >> .gitignore
  ok ".claude/worktrees/ added to .gitignore"
else
  ok ".claude/worktrees/ already in .gitignore"
fi

if ! grep -q '^\.goal-suite/' .gitignore; then
  echo '' >> .gitignore
  echo '# claude-goal-suite artefacts (optional: remove if you want them versioned)' >> .gitignore
  echo '.goal-suite/' >> .gitignore
  ok ".goal-suite/ added to .gitignore"
else
  ok ".goal-suite/ already in .gitignore"
fi

# ------------------------------------------------------------------
# 3. Prepare .goal-suite directory
# ------------------------------------------------------------------
log "Creating .goal-suite/ directory..."
mkdir -p .goal-suite
if [ ! -f .goal-suite/.gitkeep ]; then
  touch .goal-suite/.gitkeep
fi
ok ".goal-suite/ ready"

# ------------------------------------------------------------------
# 4. Git-state sanity check
# ------------------------------------------------------------------
log "Checking git state..."
if [ -d .git ]; then
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    warn "Working tree is not clean. Commit before /goal-suite!"
    git status --short | head -10
  else
    ok "Working tree clean"
  fi
else
  warn "No git repo detected. Init recommended: git init"
fi

# ------------------------------------------------------------------
# 5. Print plugin install instructions
# ------------------------------------------------------------------
echo
echo "============================================================"
echo "  MANUAL STEPS in Claude Code"
echo "============================================================"
echo
echo "Start Claude Code and run the following commands in order."
echo "Restart where indicated."
echo
echo "  # ---- 1. Superpowers ----"
echo "  /plugin marketplace add obra/superpowers-marketplace"
echo "  /plugin install superpowers@superpowers-marketplace"
echo
echo "  # ---- 2. Claude-Full-Context-Agent ----"
echo "  /plugin marketplace add Kirchlive/Claude-Full-Context-Agent"
echo "  /plugin install Claude-Full-Context-Agent@Claude-Full-Context-Agent"
echo
echo "  # ---- 3. claude-goal-suite (this skill) ----"
echo "  # If this repo is local:"
echo "  /plugin marketplace add $(pwd)"
echo "  /plugin install claude-goal-suite@claude-goal-suite-marketplace"
echo
echo "  # ---- 4. Activate plugins + fork-subagent mode (no restart yet) ----"
echo "  /reload-plugins"
echo "  /Claude-Full-Context-Agent:doctor"
echo "  /auto-mode on"
echo
echo "  # ---- 5. Restart Claude Code (once) ----"
echo "  # Picks up the plugin loads AND CLAUDE_CODE_FORK_SUBAGENT=1"
echo "  # (env vars are only read at startup)."
echo
echo "  # ---- 6. Verify ----"
echo "  /plugin list"
echo "  # should show: superpowers, Claude-Full-Context-Agent, claude-goal-suite"
echo
echo "============================================================"
echo
ok "Bootstrap script done. Follow the manual steps above."
echo
echo "Then: /goal-suite:preflight  -> first step before every run."
