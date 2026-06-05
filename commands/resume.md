---
description: Resumes an interrupted or incomplete goal-suite run.
---

# /goal-suite:resume

Reactivates the goal with only the still-open tasks from PLAN.md.
Useful when the previous run was stopped by a turn limit, token
exhaustion, or a manual `/goal clear`.

## Prerequisites

- `.goal-suite/PLAN.md` must exist and contain at least one `[ ]` task
- Git working tree clean (or explicit permission to continue over
  working changes)
- Same stack configuration as the previous run

## Flow

1. Check `.goal-suite/PLAN.md` for open tasks (`[ ]` or `[?]`)
2. If none are open: print a success message and exit
3. If `[?]` tasks exist: ask whether they should be included in the
   resume run
4. Set a shortened goal:

```
Resume the repo-enhancement cycle. Read .goal-suite/PLAN.md and process
all remaining open tasks ([ ]). All rules and constraints from the
previous run still apply (see SKILL.md claude-goal-suite).

Important re-initialization:
1. Read .goal-suite/STACK.md for BUILD/TEST/LINT/FORMAT commands
2. Read .goal-suite/BASELINE.md for original pass/fail counts
3. Check whether changes have happened in the constraint areas since
   the last run (git log since the last goal-suite: commit)

Goal is fulfilled when:
- All PLAN tasks are [x] or [?]
- BUILD, TEST (count >= baseline), LINT, FORMAT exit 0
- /code-review shows no open CRITICAL findings

Constraints unchanged: no test deletion, no suppressions without
justification, no .env/CI/migrations changes.

Stop after 30 turns with a report.
```

5. Set the goal with `/goal <condition above>`
6. Keep / enable Auto Mode

## Arguments

- `severity=<level>` — only process tasks of this severity in the resume
- `retry-skipped` — also retry `[?]` tasks
