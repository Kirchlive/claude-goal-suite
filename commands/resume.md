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

## Checkbox semantics

- `[ ]` — open task, picked up by every resume.
- `[x]` — done, never re-attempted.
- `[?]` — open *with a question* (ambiguity, missing context, or 3
  failed attempts during execution). Treated as **terminal** by default;
  only the `retry-skipped` argument pulls them back into the resume set.

## Flow

1. Check `.goal-suite/PLAN.md` for open tasks (`[ ]`; `[?]` only with
   `retry-skipped`)
2. If none are open: print a success message and exit
3. Set a shortened goal:

```
Resume the repo-enhancement cycle. Read .goal-suite/PLAN.md and process
all remaining open tasks ([ ]). All rules and constraints from the
previous run still apply (see SKILL.md claude-goal-suite).

Important re-initialization:
1. Read .goal-suite/STACK.md for BUILD/TEST/LINT/FORMAT commands
2. Read .goal-suite/BASELINE.md for original pass/fail counts
3. Read .goal-suite/SPEC.md + RESEARCH.md (if present) for context;
   do NOT re-run Discovery or Research on resume
4. Check whether changes have happened in the constraint areas since
   the last run (git log since the last goal-suite: commit)

Execution: Fork-Agents (prefer-/fan-out-fork-agents) for parallelizable
tasks. Bug-tasks: systematic-debugging + TDD.

Verification (Phase 5): two-stage review subagent, then
verification-before-completion. CRITICAL count in
code-review.md must be 0 (echo via grep -c).

Goal is fulfilled when:
- All PLAN tasks are [x] or [?]
- BUILD, TEST (count >= baseline), LINT, FORMAT exit 0
- code-review.md shows no open CRITICAL findings

Constraints unchanged: no test deletion, no suppressions without
justification, no .env/CI/migrations changes.

Stop after 30 turns with a report.
```

4. Set the goal with `/goal <condition above>`
5. Keep / enable Auto Mode

## Arguments

- `severity=<level>` — only process tasks of this severity in the resume
- `retry-skipped` — also retry `[?]` tasks
