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
echo "=== Plan progress ==="
if [ -f .goal-suite/PLAN.md ]; then
  TOTAL=$(grep -c '^\- \[' .goal-suite/PLAN.md)
  DONE=$(grep -c '^\- \[x\]' .goal-suite/PLAN.md)
  SKIPPED=$(grep -c '^\- \[?\]' .goal-suite/PLAN.md)
  OPEN=$((TOTAL - DONE - SKIPPED))
  echo "Total:   $TOTAL"
  echo "Done:    $DONE"
  echo "Skipped: $SKIPPED"
  echo "Open:    $OPEN"
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
