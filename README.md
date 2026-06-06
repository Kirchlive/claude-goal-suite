# claude-goal-suite

**Self-contained repo-enhancement cycle via native Claude Code command `/goal`.**
Bug fixing, optimization, performance, cleanup — stack-agnostic via
auto-detection (Node/Rust/Python/Go/Java/.NET/Ruby/PHP/Elixir/Swift/Make).

```
┌──────────────────────────────────────────────┐
│  Phase 1 · Discovery   (Subagent · explore)  │
│  → SPEC.md / STACK.md / BASELINE.md          │
├──────────────────────────────────────────────┤
│  Phase 2 · Research    (Subagent · extern)   │
│  → RESEARCH.md          [gated · skippable]  │
├──────────────────────────────────────────────┤
│  Phase 3 · Planning    (writing-plans)       │
│  → PLAN.md   (- [ ] + [severity] per task)   │
├──────────────────────────────────────────────┤
│  Phase 4 · Execution   (Fork-Agents)         │
│  prefer-/fan-out-fork · iterative per task   │
├──────────────────────────────────────────────┤
│  Phase 5 · Verification (Subagent · review)  │
│  two-stage review + verification-before-     │
│  completion gate                             │
├──────────────────────────────────────────────┤
│  Phase 6 · Commit & Chain  (external)        │
│  scripts/run-chain.sh                        │
└──────────────────────────────────────────────┘
```

## Why this skill?

`/goal` is a powerful autonomous loop native in Claude Code, but it 
has two structural limitations that sabotage "naive use":

1. **The evaluator has no tools** — it only reads the transcript.
   Conditions must be written so that shell output demonstrates them.
2. **Vague conditions lead to drift.** A verifiable
   end-state set is mandatory.

`claude-goal-suite` solves both problems: it detects the stack
automatically, generates the matching build/test/lint commands, writes
a structured plan to disk (survivable between sessions), and delivers
a goal block that stays under the 4000-character hard limit.

`/goal-suite` without description: Full autonomous enhancement cycle - 
bug-fix, optimization, performance improvements, and code cleanup. 
The order of implementation is based on relevance.

## Actor model — at a glance

Phases are split by *what kind of work* they do, not just by ordering:

- **Subagent (read-only)** — Phase 1 Discovery (`explore`), Phase 2
  Research (external), Phase 5 Verification (two-stage review). Fresh
  context, no edits, returns a report.
- **Fork-Agent (write/execution)** — Phase 4 Execution via
  `prefer-fork-agents` / `fan-out-fork-agents` in isolated worktrees.
  Inherits the full parent context.
- **External** — Phase 6 Commit / chain. Always outside the goal, so
  the rollback guarantee (clean tree on entry) is preserved.

## Prerequisites

- **Claude Code v2.1.151+** — `/goal` is available, *and* the native
  `/code-review` reuse/simplify behaviour Phase 5 relies on is stable
- **Superpowers** (`obra/superpowers-marketplace`) — `writing-plans`
  (Phase 3 format), `systematic-debugging` + `test-driven-development`
  (Phase 4 bug tasks), `requesting-/receiving-code-review` +
  `verification-before-completion` (Phase 5)
- **Claude-Full-Context-Agent** (`Kirchlive/Claude-Full-Context-Agent`)
  — `prefer-fork-agents` + `fan-out-fork-agents` for Phase 4
- **Auto Mode** active (for unattended turns)
- **Clean Git working tree** (rollback guarantee)
- **Web tools available to the agent** when Phase 2 (Research) is in
  scope — Research uses WebSearch/WebFetch; Phase 2 is skippable

### How Phase 5 verification works

Phase 5 reviews the local working-tree diff since `BASELINE.md` —
**no PR is required**. The primary engine is the native `/code-review`
(low/medium effort for high-confidence findings, **without `--fix`**
so the human review before commit stays meaningful). The goal block
adds gates the native command does not cover: test-pass count vs
`BASELINE.md`, and secret / anti-pattern greps — both as explicit
shell steps, so the tool-less evaluator sees the output in the
transcript.

The PR-oriented plugin `code-review @ claude-plugins-official` is
deliberately not used here: it skips without an open PR and needs
`gh`. It belongs in the real PR stage *after* Phase 6, where
confidence scoring and git-blame history apply.

`verification-before-completion`'s Iron Law applies as the
Completion Gate: no pass-claim without the verification command's
fresh output — including a `grep -c -iE 'CRITICAL'
.goal-suite/code-review.md` echo whose result must be 0.

## Install

**Install the plugin:**

```
/plugin marketplace add Kirchlive/claude-goal-suite
/plugin install claude-goal-suite@claude-goal-suite-marketplace
```

**Install dependencies:**

```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
/plugin marketplace add Kirchlive/Claude-Full-Context-Agent
/plugin install Claude-Full-Context-Agent@Claude-Full-Context-Agent
```

**Activate plugins + fork-subagent mode (no restart yet):**

```
/reload-plugins
/Claude-Full-Context-Agent:doctor
/auto-mode on
```

**Restart Claude Code once** (`CLAUDE_CODE_FORK_SUBAGENT=1` is read
only at startup). One restart picks up both the plugin load and the
env var.

**Verify:**

```
/goal-suite:preflight
```

All checks should show `[ OK ]`. The preflight validates the Claude
Code version, git state, plugin installation, fork-subagent mode, and
stack detection.

> **Per-repo `.gitignore`:** Before the first run in a repo, add
> `.claude/worktrees/` and `.goal-suite/` to its `.gitignore` (or run
> `bash scripts/bootstrap.sh` once — it does this plus other sanity
> checks). Detailed step-by-step guide in [`INSTALL.md`](./INSTALL.md).

## Usage

In Claude Code, at the project root:

```
/goal-suite:preflight     # 1. Pre-check
/goal-suite               # 2. Full run
```

On interruption:

```
/goal-suite:status        # What is still open?
/goal-suite:resume        # Continue
```

For very large repos — severity chain externally:

```bash
bash scripts/run-chain.sh   # critical → high → medium → low
```

## Optional arguments for `/goal-suite`

| Argument | Effect |
|---|---|
| `stack=<id>` | Override stack auto-detection (e.g. `stack=python-uv`) |
| `scope=<glob>` | Restrict Discovery (Phase 1) **and** Planning (Phase 3) to a subtree (e.g. `scope=src/auth/`) |
| `severity=<level>` | Planning (Phase 3) filters PLAN.md to that severity only (`critical`/`high`/`medium`/`low`) |
| `--no-research` | Skip Phase 2 unconditionally. Default is auto: Phase 2 runs only when SPEC.md has ≥1 finding with `needs-research: true` |

## Expected artifacts

```
.goal-suite/
├── STACK.md         # detected stack + commands (Phase 1)
├── BASELINE.md      # initial test/lint/build counts (Phase 1)
├── SPEC.md          # findings with needs-research flag (Phase 1)
├── RESEARCH.md      # external ground-truth (Phase 2; optional)
├── PLAN.md          # tasks · - [ ] [SEVERITY] T-N: … (Phase 3)
└── code-review.md   # two-stage review output (Phase 5)
```

## Caveats

1. **Bootstrap is a one-time manual step.** A `/goal` cannot trigger
   plugin install + restart for itself.
2. **Discovery (Phase 1) is expensive.** For repos >50k LoC: use the
   `scope=` argument or chain runs.
3. **Evaluator limitation.** Every verification must produce shell
   output in the transcript — don't just say "I ran the tests".
4. **Phase 5 human review.** Phase 5 produces `code-review.md`, but
   `git diff` by humans is *external and mandatory* before
   `git commit`.
5. **Phase 6 is always external.** Goal chain via `run-chain.sh`, not
   inside the goal — so the clean-working-tree rollback guarantee
   stays intact.
6. **Research (Phase 2) is informational.** Findings without a source
   URL are low-confidence and must not drive destructive change.

## Integration with your own workflows

- **Actor model:** subagents do read-only knowledge work
  (`explore` = Discovery, external research = Research, two-stage
  review = Verification). Execution runs through Fork-Agents
  (`prefer-fork-agents` / `fan-out-fork-agents`) — write operations
  in isolated worktrees.
- **Superpowers** supplies the phase skills: `writing-plans`
  (Planning), `systematic-debugging` + `test-driven-development`
  (bug tasks in Execution), `requesting-/receiving-code-review` +
  `verification-before-completion` (Verification). No
  `brainstorming`, no parallel/worktree skills (overlap with the
  fork stack).

## License

MIT. See [`LICENSE`](./LICENSE).
