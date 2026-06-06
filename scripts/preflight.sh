#!/usr/bin/env bash
# preflight.sh — Pre-run check, can also run outside Claude Code
# ===================================================================
# Complements /goal-suite:preflight (which only runs inside Claude Code).
# This variant checks the shell-side prerequisites.

set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()    { echo -e "${GREEN}[ OK  ]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN ]${NC} $*"; }
fail()  { echo -e "${RED}[FAIL ]${NC} $*"; FAILED=1; }

FAILED=0

# 1. Claude Code version
if command -v claude >/dev/null 2>&1; then
  CV=$(claude --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  if [ -n "$CV" ] && [ "$(printf '%s\n' "2.1.151" "$CV" | sort -V | head -1)" = "2.1.151" ]; then
    ok "Claude Code $CV (>= 2.1.151)"
  else
    fail "Claude Code version $CV is too old (>= 2.1.151 required for native /code-review reuse/simplify in Phase 5)"
  fi
else
  fail "claude CLI not found"
fi

# 2. Git clean
if [ -d .git ]; then
  if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
    ok "Git working tree clean"
  else
    fail "Git working tree dirty — please commit or stash"
  fi
else
  warn "No git repo (init recommended)"
fi

# 3. CLAUDE_CODE_FORK_SUBAGENT env var in settings.json
SETTINGS="$HOME/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  if grep -q 'CLAUDE_CODE_FORK_SUBAGENT' "$SETTINGS"; then
    ok "CLAUDE_CODE_FORK_SUBAGENT set in $SETTINGS"
  else
    fail "CLAUDE_CODE_FORK_SUBAGENT missing — run /Claude-Full-Context-Agent:doctor in Claude Code"
  fi
else
  fail "$SETTINGS does not exist — plugins not yet installed"
fi

# 4. .gitignore entry
if [ -f .gitignore ] && grep -q '^\.claude/worktrees/' .gitignore; then
  ok ".claude/worktrees/ in .gitignore"
else
  warn ".claude/worktrees/ not in .gitignore (run bootstrap.sh again)"
fi

# 5. Stack marker
STACK_FOUND=""
for marker in package.json Cargo.toml pyproject.toml go.mod pom.xml \
              build.gradle build.gradle.kts Gemfile composer.json \
              *.csproj *.sln mix.exs Makefile Package.swift; do
  if compgen -G "$marker" >/dev/null 2>&1; then
    STACK_FOUND="$marker"
    break
  fi
done

if [ -n "$STACK_FOUND" ]; then
  ok "Stack marker found: $STACK_FOUND"
else
  if [ -f .goal-suite/stack-override.txt ]; then
    ok "Stack override found: $(cat .goal-suite/stack-override.txt)"
  else
    fail "No stack marker detected — set .goal-suite/stack-override.txt or pass stack=<id>"
  fi
fi

# 6. .goal-suite ready
if [ -d .goal-suite ]; then
  ok ".goal-suite/ directory exists"
else
  warn ".goal-suite/ missing — will be created automatically on first run"
fi

# 7. Optional: tools available
echo
echo "--- Optional tool checks ---"
for tool in jq rg fd gh; do
  if command -v "$tool" >/dev/null 2>&1; then
    ok "$tool available"
  else
    warn "$tool not available (optional, speeds up discovery)"
  fi
done

# 8. Phase 2 (Research) capability
echo
echo "--- Research (Phase 2) capability ---"
if command -v curl >/dev/null 2>&1; then
  ok "curl available (fallback web fetch)"
else
  warn "curl missing (Phase 2 uses WebSearch/WebFetch tools when granted; curl is only a CLI fallback)"
fi
echo "(Phase 2 is gated: runs only when SPEC.md has needs-research:true findings. Pass --no-research to skip unconditionally.)"

# Summary
echo
if [ "$FAILED" -eq 0 ]; then
  echo -e "${GREEN}===== PREFLIGHT OK =====${NC}"
  echo "Ready for /goal-suite in Claude Code."
  exit 0
else
  echo -e "${RED}===== PREFLIGHT FAILED =====${NC}"
  echo "Please fix the [FAIL] items above and run again."
  exit 1
fi
