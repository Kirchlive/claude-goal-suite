---
description: Shows the status of a running or completed goal-suite run.
---

# /goal-suite:status

Prints a summary of the current goal-suite state.

## Implementation

```bash
if [ ! -d .goal-suite ]; then
  echo "No .goal-suite/ directory. No /goal-suite run yet."
  exit 0
fi

echo "=== Stack ==="
cat .goal-suite/STACK.md 2>/dev/null || echo "STACK.md missing"

echo
echo "=== Baseline ==="
cat .goal-suite/BASELINE.md 2>/dev/null || echo "BASELINE.md missing"

echo
echo "=== Research ==="
if [ -f .goal-suite/RESEARCH.md ]; then
  LOOKUPS=$(grep -ciE '^(source|url):' .goal-suite/RESEARCH.md 2>/dev/null || echo 0)
  echo "RESEARCH.md present (~$LOOKUPS source entries)"
else
  echo "RESEARCH.md missing (Phase 2 skipped or not yet run)"
fi

echo
echo "=== Plan progress ==="
# PLAN.md line format (writing-plans):
#   - [ ] [SEVERITY] T-N: desc (file:line) -- verify: <cmd>
if [ -f .goal-suite/PLAN.md ]; then
  TOTAL=$(grep -cE '^- \[[ x?]\]' .goal-suite/PLAN.md)
  DONE=$(grep -cE '^- \[x\]' .goal-suite/PLAN.md)
  SKIPPED=$(grep -cE '^- \[\?\]' .goal-suite/PLAN.md)
  OPEN=$((TOTAL - DONE - SKIPPED))
  echo "Total:   $TOTAL"
  echo "Done:    $DONE"
  echo "Skipped: $SKIPPED  (terminal; resume with retry-skipped only)"
  echo "Open:    $OPEN"
  echo
  echo "--- Open by severity ---"
  for S in CRITICAL HIGH MEDIUM LOW; do
    N=$(grep -cE "^- \[ \] \[$S\]" .goal-suite/PLAN.md 2>/dev/null || echo 0)
    printf '  %-9s %s\n' "$S" "$N"
  done
else
  echo "PLAN.md missing"
fi

echo
echo "=== Active goal ==="
```

From Claude Code additionally:
```
/goal
```

Shows: condition, runtime, turns evaluated, token spend, last
evaluator reason.

## When to use

- Interim status while the goal is running (in a second terminal tab)
- After goal auto-clear, to see what was marked as `[?]`
- Before `/goal-suite:resume`, to see how much is still open
