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
5. The goal runs autonomously across the six phases (Discovery →
   Research → Planning → Execution → Verification, then external
   Commit) until auto-clear or turn limit 40

## Expected outputs

- `.goal-suite/STACK.md` — detected stack + commands (Phase 1)
- `.goal-suite/BASELINE.md` — initial build/test/lint counts (Phase 1)
- `.goal-suite/SPEC.md` — discovery findings with `needs-research`
  flag (Phase 1)
- `.goal-suite/RESEARCH.md` — external ground-truth, sources mandatory
  (Phase 2; absent if research was skipped)
- `.goal-suite/PLAN.md` — writing-plans task list with `[ ]/[x]/[?]`
  status and `[SEVERITY]` tag per line (Phase 3)
- `.goal-suite/code-review.md` — Phase 5 two-stage review (spec
  compliance + code quality), produced by a read-only review subagent

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
- `scope=<path-glob>` — limits Discovery (Phase 1) **and** Planning
  (Phase 3) to a subtree (e.g. `src/auth/`). Wired in the goal template.
- `severity=<level>` — Planning (Phase 3) filters PLAN.md to that
  severity only (`critical`, `high`, `medium`, `low`) — useful for
  chain runs
- `--no-research` — skip Phase 2 unconditionally (default is auto:
  Phase 2 runs only when SPEC.md contains ≥1 finding with
  `needs-research: true`)

## Implementation

Read the skill file and follow the workflow described there.
The central references:

- `skills/goal-suite/SKILL.md` — workflow description
- `skills/goal-suite/references/stacks.md` — stack lookup
- `skills/goal-suite/references/goal-template.txt` — the goal block

If preflight fails: STOP, print the exact repair instruction, do not
try to reproduce the bootstrap.
