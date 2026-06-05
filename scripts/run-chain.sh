#!/usr/bin/env bash
# run-chain.sh — Sequential chaining of /goal runs by severity
# ==================================================================
# Solves the "Phase 5 not possible inside a goal" problem via external
# iteration. Runs one pass per severity level with an intermediate
# git commit as audit trail.

set -euo pipefail

if [ ! -f .goal-suite/SPEC.md ]; then
  echo "No SPEC.md found. First run /goal-suite in Claude Code"
  echo "(does discovery + planning) — then start this chain."
  exit 1
fi

CHUNKS=("critical" "high" "medium" "low")
TURN_LIMITS=(40 30 25 20)

for i in "${!CHUNKS[@]}"; do
  SEV="${CHUNKS[$i]}"
  TURNS="${TURN_LIMITS[$i]}"

  echo
  echo "================================================================"
  echo "  Severity chunk: $SEV  (turn limit: $TURNS)"
  echo "================================================================"
  echo

  # Pre-check whether any tasks of this severity are open
  if [ -f .goal-suite/PLAN.md ]; then
    OPEN=$(grep -ciE "severity:?.{0,5}$SEV" .goal-suite/PLAN.md 2>/dev/null | tail -1 || echo 0)
    if [ "$OPEN" -eq 0 ]; then
      echo "No open $SEV tasks — skipping."
      continue
    fi
  fi

  # Submit the goal via headless Claude Code
  GOAL_CONDITION="Resume the repo-enhancement cycle. Process ONLY \
tasks with severity=$SEV from .goal-suite/PLAN.md. Read .goal-suite/STACK.md for \
commands. All other constraints from the claude-goal-suite skill apply (no \
test deletion, no suppressions, no .env/CI/migrations changes). Stop \
after $TURNS turns. Goal fulfilled when all $SEV tasks are [x] and BUILD/TEST/\
LINT/FORMAT exit 0."

  claude -p "/goal $GOAL_CONDITION" || {
    echo "[chain] Goal for severity=$SEV aborted or failed."
    echo "[chain] Check .goal-suite/PLAN.md and decide whether to continue."
    read -p "Continue with next severity? [y/N] " ANSWER
    if [[ ! "$ANSWER" =~ ^[Yy]$ ]]; then
      exit 1
    fi
  }

  # Intermediate commit
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    git add -A
    git commit -m "goal-suite: $SEV severity findings ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
    echo "[chain] Commit for $SEV created."
  else
    echo "[chain] No changes in the working tree — nothing to commit."
  fi
done

echo
echo "================================================================"
echo "  Chain finished. Most recent reviews:"
echo "================================================================"
echo
git log --oneline -10
echo
echo "Recommended: final check in Claude Code: /code-review"
