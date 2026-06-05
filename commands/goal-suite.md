---
description: Complete repo-enhancement cycle via /goal with stack auto-detection.
---

# /goal-suite

Starts the self-contained repo-enhancement cycle.

## Flow

1. Run `/goal-suite:preflight`
2. If preflight is OK: load `skills/goal-suite/references/goal-template.txt`
3. Submit the goal block via `/goal <content>`
4. Enable Auto Mode if not already active
5. The goal runs autonomously until auto-clear or turn limit 40

## Expected outputs

- `.goal-suite/SPEC.md` — discovery findings
- `.goal-suite/STACK.md` — detected stack + commands
- `.goal-suite/BASELINE.md` — initial build/test/lint counts
- `.goal-suite/PLAN.md` — task list with status
- `.goal-suite/code-review.md` — Phase 4 subagent review (NOT from the
  slash command `/code-review`, but via a Task-tool spawn — see SKILL.md)

## After the goal ends

```
git diff                  # human review of the diff
git add -A
git commit -m "goal-suite: full repo cleanup pass"
```

## On abort / turn limit reached

`/goal-suite:resume` reactivates the goal with only the open tasks
from PLAN.md.

## Arguments (optional)

- `stack=<stack-id>` — explicit stack choice, overrides auto-detection
- `scope=<path-glob>` — limits discovery to a subtree (e.g. `src/auth/`)
- `severity=<level>` — only process this severity (`critical`, `high`,
  `medium`, `low`) — useful for chain runs

## Implementation

Read the skill file and follow the workflow described there.
The central references:

- `skills/goal-suite/SKILL.md` — workflow description
- `skills/goal-suite/references/stacks.md` — stack lookup
- `skills/goal-suite/references/goal-template.txt` — the goal block

If preflight fails: STOP, print the exact repair instruction, do not
try to reproduce the bootstrap.
