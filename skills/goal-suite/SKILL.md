---
name: goal-suite
description: |
  Complete self-contained repo-enhancement cycle: bug fixing, optimization,
  performance, cleanup. Stack-agnostic via auto-detection
  (Node/Rust/Python/Go/Java/.NET/Ruby/PHP/Elixir/Make). Runs discovery
  (findings to .goal-suite/SPEC.md), planning (task list to .goal-suite/PLAN.md),
  execution (iterative per task) and verification (/code-review + final
  build/test/lint check) in a single /goal run.

  Triggers on: "enhance repo", "repo enhancer", "cleanup repo", "audit repo",
  "optimize repo", "clean up repo", "tidy up repo", "fix bugs and lint",
  or on explicit use of the /goal-suite slash command.

  Do not use for surgical single-file changes or feature implementation
  (use Superpowers brainstorm -> write-plan -> execute for that).
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
---

# Claude-Goal-Suite Skill

This skill encapsulates a complete repo-hygiene cycle as a single
`/goal` run. It is intentionally non-interactive (phases 4 human review
and 5 commit chain are invoked separately, not inside the goal itself).

## Prerequisite: bootstrap must have run once

Before this skill can be used meaningfully, `scripts/bootstrap.sh`
(Linux/macOS/WSL) or `scripts/bootstrap.ps1` (Windows) must have been
executed once on the system. The bootstrap script installs the
mandatory plugins (Superpowers, Claude-Full-Context-Agent) and sets the
environment variables required for the goal architecture.

If the skill is invoked and the bootstrap has not yet run,
`/goal-suite:preflight` must be executed first. On misconfiguration,
the skill aborts with a clear error message — it does NOT try to
reproduce the bootstrap from within a running session (that would
trigger a Claude Code restart, which would end the session).

## Workflow

1. Run **preflight** (see `commands/preflight.md`)
2. Emit the **goal block** (see `references/goal-template.txt`)
3. Enable **Auto Mode** for unattended turns
4. The **goal runs autonomously** until auto-clear or the turn limit
   is reached. Phase 4 (verification) is run INLINE through an
   explicit subagent spawn (Task tool) — NOT through `/code-review`,
   because that slash name can resolve differently depending on
   installed plugins (see note below).
5. **After the goal ends:** `git diff` by humans, then `git commit`
6. **Commit chain** via `scripts/run-chain.sh` if applicable

## Note on /code-review routing

The bundled `/code-review` skill does working-tree reviews. The
official marketplace plugin `code-review @ claude-plugins-official`
registers a command with the same name, but it only operates in PR
context (skip logic for non-PR calls). On a name collision,
`/code-review` idles instead of reviewing.

For this reason, `claude-goal-suite` Phase 4 does NOT use the slash
command but spawns an explicit code-review subagent via the Task tool.
This makes the behavior independent of the user's plugin configuration.

Recommendation: If both variants of `/code-review` are installed and
you do not work in a PR workflow, uninstall the marketplace plugin:
`/plugin uninstall code-review@claude-plugins-official`.

## Working directory

All artifacts go into `.goal-suite/` at the project root:

```
.goal-suite/
├── SPEC.md          # discovery findings (Phase 1)
├── PLAN.md          # task list with checkboxes (Phase 2)
├── STACK.md         # detected stack + commands (from stacks lookup)
├── BASELINE.md      # initial test/lint/build counts
└── code-review.md   # last /code-review output (Phase 4)
```

`.goal-suite/` should be added to `.gitignore` if the findings should not
be versioned — otherwise commit them intentionally as an audit trail.

## Pre-flight guarantees

Before the goal block, it must be CERTAIN that:

- `claude --version` >= 2.1.139 (otherwise no `/goal` available)
- `git status` shows `nothing to commit, working tree clean`
- Superpowers is installed (`/plugin list` shows `superpowers`)
- Claude-Full-Context-Agent is installed (`/plugin list` shows it)
- `CLAUDE_CODE_FORK_SUBAGENT=1` is set in `~/.claude/settings.json`
- `.claude/worktrees/` is in the project `.gitignore`
- Auto Mode is active OR the user will approve tool calls manually

On a failed guarantee: the skill aborts with the specific repair
instruction. No guessing, no improvisation.

## The goal block (phases 1-3 plus inline 4)

Loaded from `references/goal-template.txt` and emitted unchanged. The
condition is deliberately < 4000 characters because that is the hard
Anthropic limit. The stack-specific build/test/lint commands are
worded generically ("the detected BUILD command") and Claude resolves
them at runtime from `.goal-suite/STACK.md`.

## Stack detection logic

Lives in `references/stacks.md`. Claude reads the table, scans the
repo root for marker files, and writes the result to `.goal-suite/STACK.md`.
On ambiguity (e.g. monorepo with multiple stacks),
`.goal-suite/stack-override.txt` is the override point.

## Recovery / resume

If the goal run is aborted by token exhaustion, turn limit, or crash:

1. `SPEC.md` and `PLAN.md` survive on disk
2. `/goal-suite:resume` reads PLAN.md and sets a new goal on only
   the remaining `[ ]` tasks
3. On `--resume` / `--continue` of an old Claude Code session, the
   goal is restored automatically (with reset turn counter)

## What this skill does NOT do

- Install plugins (bootstrap script's job)
- Restart Claude Code
- Set environment variables
- Delete or skip tests (hard constraint in the goal)
- Major version bumps in package.json/Cargo.toml/etc.
- Changes to .env, CI/CD, DB migrations
- `eslint-disable` or similar suppressions without justification
- Change business logic on pure-refactor tasks

## Integration with other skills

- **Superpowers `brainstorming`**: deliberately NOT chained in front —
  the enhancer works on existing codebases, not on new features
- **Superpowers `subagent-driven-development`**: activated inside the
  goal when PLAN.md tasks are parallelizable
- **`prefer-fork-agents` (Full-Context-Agent)**: kicks in automatically
  when fork-subagent dispatch is required, thanks to
  CLAUDE_CODE_FORK_SUBAGENT=1
- **`fan-out-fork-agents` (Full-Context-Agent)**: provides the
  worktree-hygiene rules for parallel edit forks
- **`/code-review` (bundled skill)**: NOT called directly. Phase 4
  spawns a subagent (Task tool) instead, which independently reviews
  the diff since BASELINE.md. This bypasses the routing issue when the
  marketplace plugin `code-review @ claude-plugins-official` is
  installed in parallel.
- **`code-review @ claude-plugins-official` (optional)**: not used by
  this skill. Keep it only if you need it for a separate GitHub-PR
  review workflow — otherwise uninstall is recommended so the bundled
  skill is not overridden.

## Token-budget notes

- Discovery (Phase 1) is the most expensive part: 30-80k tokens for
  repos with 50k+ LoC. If needed, limit the scope to a subtree via
  `.goal-suite/scope.txt` (one line = one path glob).
- Execution scales linearly with the task count. About 5-15k tokens
  per task.
- Set a realistic turn limit (default 40) — for very large repos,
  prefer chunking via `scripts/run-chain.sh` over a single mega-goal.

## Security prerequisites

- Trust dialog in the workspace accepted (otherwise no `/goal`)
- No `disableAllHooks` configuration
- No `allowManagedHooksOnly` in managed settings
- Clean Git working tree before every run (rollback guarantee)
