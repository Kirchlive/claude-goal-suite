---
name: goal-suite
description: |
  Complete self-contained repo-enhancement cycle: bug fixing,
  optimization, performance, cleanup. Stack-agnostic via auto-detection
  (Node/Rust/Python/Go/Java/.NET/Ruby/PHP/Elixir/Swift/Make). Six-phase
  flow Discovery → Research → Planning → Execution → Verification →
  Commit. Phases 1, 2 and 5 run as read-only subagents (explore /
  external research / two-stage review); Phase 4 fans out as
  fork-agents in isolated worktrees; Phase 6 is always external.

  Triggers on: "enhance repo", "repo enhancer", "cleanup repo",
  "audit repo", "optimize repo", "clean up repo", "tidy up repo",
  "fix bugs and lint", or on explicit use of the /goal-suite slash
  command.

  Do not use for surgical single-file changes or feature implementation
  (use Superpowers brainstorm → write-plan → execute for that).
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Task", "Skill", "WebSearch", "WebFetch"]
---

# Claude-Goal-Suite Skill

This skill encapsulates a complete repo-hygiene cycle as a single
`/goal` run. Phase 6 (commit) is deliberately external so the rollback
guarantee (clean working tree on entry) is preserved.

## Actor model (the three-way split)

The skill follows a strict tool-property-driven split:

- **Subagent — read-only knowledge work.** Fresh constructed context,
  no inheritance, returns a report, never edits. Used by:
  - Phase 1 Discovery (`explore` subagent)
  - Phase 2 Research (external research subagent)
  - Phase 5 Verification (two-stage review subagent)
- **Fork-Agent — write/execution.** Inherits the full parent context,
  works in an isolated `.claude/worktrees/` worktree. Used by:
  - Phase 4 Execution (`prefer-fork-agents` / `fan-out-fork-agents`)
- **External (outside the goal).** Phase 6 commit / chain.

`subagent-driven-development` from Superpowers is **not** used as the
execution mechanism — that role belongs to the fork-agent stack from
Claude-Full-Context-Agent. Its valuable kernel (two-stage review:
spec compliance → code quality) lives in Phase 5 instead, where review
is read-only and therefore subagent territory.

## Superpowers wiring (per phase)

| Phase | Engine | Why |
|---|---|---|
| 1 Discovery | bespoke (explore subagent) | Discovery is the USP; no Superpowers equivalent |
| 2 Research | bespoke (external subagent) | Closes the cutoff-knowledge gap |
| 3 Planning | `writing-plans` | Produces `- [ ] [SEVERITY]` lines that the status/chain tools already parse |
| 4 Execution | `prefer-fork-agents` + `fan-out-fork-agents`; bug-tasks add `systematic-debugging` + `test-driven-development` | Root-cause discipline + regression test per bug |
| 5 Verification | bespoke two-stage review subagent + `requesting-code-review` + `receiving-code-review` + `verification-before-completion` | Iron-law commit gate: only with fresh transcript evidence |
| 6 Commit | external (`scripts/run-chain.sh`) | Preserves the rollback guarantee |

**Deliberately NOT integrated:** `brainstorming` (enhancer works on
existing code, not new features), `dispatching-parallel-agents` and
`using-git-worktrees` (overlap with the fork-agent stack), `writing-skills`
and `using-superpowers` (meta / authoring, no runtime role).

**One real conflict — neutralized:** `writing-plans` and
`executing-plans` ship with "frequent commits" and chain to
`finishing-a-development-branch` (merge/PR). Both collide with the
external Phase 6 model. The goal template uses the **plan format only**
and the systematic-debugging / TDD discipline only — the auto-commit
and branch-finishing portions are suppressed by the explicit
"NO auto-commits; Phase 6 is external" instruction in the goal block.

## Workflow

1. Run **preflight** (see `commands/preflight.md`)
2. Emit the **goal block** (see `references/goal-template.txt`)
3. Enable **Auto Mode** for unattended turns
4. The **goal runs autonomously** across Phases 1–5 until auto-clear
   or the turn limit (default 40)
5. **After the goal ends:** `git diff` by humans, then `git commit`
6. **Commit chain** via `scripts/run-chain.sh` if applicable

## Phase 2 — Research (default-off, auto-on)

Research is the gate against autonomous "confident modernizing" with
training-cutoff knowledge (deprecated-to-deprecated migrations, missed
CVEs, false anti-patterns).

**Default behaviour:**
- The Discovery subagent tags each finding with `needs-research: true|false`
- If **no** SPEC.md finding has `needs-research: true`, Phase 2 is
  skipped automatically (token saving for pure lint/format runs)
- If **at least one** finding has `needs-research: true`, Phase 2 runs
- `--no-research` argument skips Phase 2 unconditionally

**Hard caps in the goal block:**
- 5 lookups maximum per run
- Source URL mandatory per finding
- Low-confidence findings (no source) must not drive destructive change
- Output (`RESEARCH.md`) informs Planning; Research never edits code

`RESEARCH.md`'s absence is not a failure — it just means research was
skipped per rule. The Completion Gate accepts both states.

## Note on /code-review routing

The bundled `/code-review` skill does working-tree reviews. The official
marketplace plugin `code-review @ claude-plugins-official` registers a
command with the same name but only operates in PR context (skip logic
for non-PR calls). On a name collision, `/code-review` idles instead of
reviewing.

For this reason, Phase 5 does **not** call `/code-review` as a slash
command. It spawns an explicit two-stage review subagent (Task tool)
which reviews the diff since `BASELINE.md` independently of which
command happens to be registered under `/code-review` in the user's
session. The marketplace plugin can stay installed for GitHub PR
reviews without affecting Phase 5.

Phase 5 then applies `verification-before-completion`'s Iron Law: no
pass-claim without the verification command's fresh output in the
current message — including the `grep -c -iE 'CRITICAL'
.goal-suite/code-review.md` echo whose result must be 0.

## Working directory

All artifacts go into `.goal-suite/` at the project root:

```
.goal-suite/
├── STACK.md         # detected stack + commands (Phase 1)
├── BASELINE.md      # initial test/lint/build counts (Phase 1)
├── SPEC.md          # discovery findings + needs-research flag (Phase 1)
├── RESEARCH.md      # external ground-truth (Phase 2; optional)
├── PLAN.md          # writing-plans task list, - [ ] [SEVERITY] (Phase 3)
└── code-review.md   # Phase 5 two-stage review output
```

`.goal-suite/` should be added to `.gitignore` if the findings should
not be versioned — otherwise commit them intentionally as an audit
trail.

## PLAN.md line format

The Planning phase emits `writing-plans`-conform lines so `status.md`
and `run-chain.sh` can parse them mechanically:

```
- [ ] [CRITICAL] T-1: null-deref in auth flow (src/auth.ts:142) -- verify: pnpm test src/auth.test.ts
- [x] [HIGH]     T-2: replace deprecated foo() (src/api.ts:88)   -- verify: pnpm run lint
- [?] [MEDIUM]   T-3: N+1 query, scope unclear (src/db.ts:55)    -- verify: pnpm run test:db
```

Severity in upper-case in square brackets is mandatory — `run-chain.sh`
uses it for severity-filtered chunks.

## Checkbox semantics

- `[ ]` open
- `[x]` done
- `[?]` open with question (ambiguity or 3 failed attempts). Treated
  as terminal by default. `/goal-suite:resume retry-skipped` brings
  them back into scope.

## Pre-flight guarantees

Before the goal block, it must be CERTAIN that:

- `claude --version` ≥ 2.1.151 (`/code-review` reuse/simplify stable
  for Phase 5)
- `git status` shows `nothing to commit, working tree clean`
- Superpowers installed (`/plugin list` shows `superpowers`)
- Claude-Full-Context-Agent installed (`/plugin list` shows it)
- `CLAUDE_CODE_FORK_SUBAGENT=1` set in `~/.claude/settings.json`
- `.claude/worktrees/` in the project `.gitignore`
- Auto Mode active OR user will approve tool calls manually

On a failed guarantee: the skill aborts with the specific repair
instruction. No guessing, no improvisation.

## The goal block (Phases 1–5)

Loaded from `references/goal-template.txt` and emitted unchanged.
Designed to stay under the 4000-character hard limit; uses Superpowers
skill names as compact directives so the per-phase semantics are
inherited from the named skills (writing-plans, systematic-debugging,
TDD, requesting/receiving-code-review, verification-before-completion).

Stack-specific build/test/lint commands are worded generically ("the
detected BUILD command") and Claude resolves them at runtime from
`.goal-suite/STACK.md`.

## Stack detection logic

Lives in `references/stacks.md`. Claude reads the table, scans the
repo root for marker files, and writes the result to
`.goal-suite/STACK.md`. On ambiguity (monorepo with multiple stacks),
`.goal-suite/stack-override.txt` is the override point.

## Recovery / resume

If the goal run is aborted by token exhaustion, turn limit, or crash:

1. All `.goal-suite/*.md` files survive on disk
2. `/goal-suite:resume` reads PLAN.md and sets a new goal on only the
   remaining `[ ]` tasks (and `[?]` only with `retry-skipped`)
3. Discovery (Phase 1) and Research (Phase 2) are **not** re-run on
   resume — their artefacts are reused as-is
4. On `--resume` / `--continue` of an old Claude Code session, the
   goal is restored automatically with reset turn counter

## What this skill does NOT do

- Install plugins (bootstrap script's job)
- Restart Claude Code
- Set environment variables
- Delete or skip tests (hard constraint in the goal)
- Major version bumps in package.json/Cargo.toml/etc.
- Changes to .env, CI/CD, DB migrations
- `eslint-disable` or similar suppressions without justification
- Change business logic on pure-refactor tasks
- Auto-commit (Phase 6 is external, by design)

## Integration with other skills

- **Actor model:** subagents do read-only knowledge work (explore in
  Phase 1, external research in Phase 2, two-stage review in Phase 5);
  Fork-Agents from Claude-Full-Context-Agent do all write/execution in
  Phase 4
- **`prefer-fork-agents` (Claude-Full-Context-Agent):** primary
  dispatch mode for Phase 4; expects `CLAUDE_CODE_FORK_SUBAGENT=1`
- **`fan-out-fork-agents` (Claude-Full-Context-Agent):** worktree
  hygiene, registry tracking and soft cap of 6 parallel forks for
  parallel Phase 4 edits
- **Superpowers `writing-plans`:** Phase 3 plan format
- **Superpowers `systematic-debugging` + `test-driven-development`:**
  Phase 4 bug tasks (root cause + regression test first)
- **Superpowers `requesting-code-review` + `receiving-code-review`:**
  Phase 5 review discipline
- **Superpowers `verification-before-completion`:** Phase 5
  Completion Gate
- **`/code-review` (bundled):** not invoked directly by the goal —
  Phase 5 spawns its own review subagent to bypass the marketplace
  routing collision. The native command is still recommended for
  manual diff checks between runs.
- **`code-review @ claude-plugins-official` (optional):** not used by
  this skill. Safe to keep installed alongside `claude-goal-suite` for
  GitHub PR reviews — Phase 5 never goes through `/code-review` as a
  slash command.

## Token-budget notes

- Discovery (Phase 1) is the most expensive part: 30–80k tokens for
  repos with 50k+ LoC. Limiting via the `scope=<glob>` argument is
  applied **both** in Discovery and in Planning.
- Research (Phase 2) is capped at 5 lookups and is skippable; typical
  cost is well below Discovery.
- Execution (Phase 4) scales linearly with the task count; about
  5–15k tokens per task. Fan-out forks share the parent's prompt
  cache so wall-clock speed-up is real even when token cost stays
  per-task.
- Set a realistic turn limit (default 40) — for very large repos,
  prefer chunking via `scripts/run-chain.sh` over a single mega-goal.

## Security prerequisites

- Trust dialog in the workspace accepted (otherwise no `/goal`)
- No `disableAllHooks` configuration
- No `allowManagedHooksOnly` in managed settings
- Clean Git working tree before every run (rollback guarantee)
