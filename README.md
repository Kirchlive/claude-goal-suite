# claude-goal-suite

**Self-contained repo-enhancement cycle for Claude Code via `/goal`.**
Bug fixing, optimization, performance, cleanup — stack-agnostic via
auto-detection (Node/Rust/Python/Go/Java/.NET/Ruby/PHP/Elixir/Swift).

```
┌──────────────────────────────────────────────┐
│  Phase 1 · Discovery                         │
│  → .goal-suite/SPEC.md                       │
│  Stack detection + audit + baseline          │
└──────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│  Phase 2 · Planning                          │
│  → .goal-suite/PLAN.md                       │
│  Task list (2–5 min/task) by severity        │
└──────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│  Phase 3 · Execution  (autonomous)           │
│  /goal with Auto Mode                        │
│  Iterative per task · verify + checkbox      │
└──────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│  Phase 4 · Verification  (inline)            │
│  → .goal-suite/code-review.md                │
│  Subagent review + final build / test / lint │
└──────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│  Phase 5 · Commit & Chain  (external)        │
│  scripts/run-chain.sh                        │
│  git commit + next severity                  │
└──────────────────────────────────────────────┘
```

## Why this skill?

`/goal` is a powerful autonomous loop, but it has two structural
limitations that sabotage "naive use":

1. **The evaluator has no tools** — it only reads the transcript.
   Conditions must be written so that shell output demonstrates them.
2. **Vague conditions lead to drift or infinite loops.** A
   verifiable end-state set is mandatory.

`claude-goal-suite` solves both problems: it detects the stack
automatically, generates the matching build/test/lint commands, writes a
structured plan to disk (survivable between sessions), and delivers a
4000-character-compliant goal block.

## Prerequisites

- **Claude Code v2.1.139+** (`/goal` is only available from this version)
- **Superpowers** (`obra/superpowers-marketplace`) — for brainstorm/plan/TDD skills
- **Claude-Full-Context-Agent** (`Kirchlive/Claude-Full-Context-Agent`) —
  for fork-subagent mode with full context inheritance
- **Auto Mode** active (for unattended turns)
- **Clean Git working tree** (rollback guarantee)

### How Phase 4 reviews work

Phase 4 (verification) does **not** call `/code-review` as a slash
command. Instead, it spawns an explicit code-review subagent via the
Task tool with a fixed prompt — review the diff since `BASELINE.md`
for bug patterns, test-coverage regression, anti-patterns, secrets,
and CLAUDE.md compliance. Output lands in `.goal-suite/code-review.md`.

This makes the workflow safe to use alongside the official
`code-review @ claude-plugins-official` marketplace plugin: there is no
name collision, no idle-on-non-PR behaviour, and no dependency on
which command happens to be registered under `/code-review` in your
session. Keep the marketplace plugin installed for GitHub PR reviews
if you use it — `claude-goal-suite` ignores it.

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

**Activate Plugins:**

```
/reload-plugins
```

**Setup:**


```
/Claude-Full-Context-Agent:doctor
/auto-mode on
```

Restart Claude Code

**Verify:**

```
/goal-suite:preflight
```

All checks should show `[ OK ]`. The preflight validates Claude Code
version, git state, plugin installation, fork-subagent mode, and stack
detection.

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
| `scope=<glob>` | Limit discovery to a subtree (e.g. `scope=src/auth/`) |
| `severity=<level>` | Only process this severity (`critical`/`high`/`medium`/`low`) |

## Expected artifacts

```
.goal-suite/
├── SPEC.md          # Discovery findings, categorized by severity
├── STACK.md         # Detected stack + commands
├── BASELINE.md      # Initial test/lint/build counts
├── PLAN.md          # Task list with [ ]/[x]/[?] status
└── code-review.md   # Phase 4 output
```

## Caveats

1. **Bootstrap is a one-time manual step.** A `/goal` cannot trigger
   plugin install + restart for itself.
2. **Discovery is expensive.** For repos >50k LoC: use the `scope=`
   argument or chain runs.
3. **Evaluator limitation.** Every verification must produce shell
   output in the transcript — don't just say "I ran the tests".
4. **Phase 4 human review.** Inline `/code-review` is part of the goal,
   but `git diff` by humans is *external and mandatory* before
   `git commit`.
5. **Phase 5 always external.** Goal chain via `run-chain.sh`, not
   inside the goal.

## Integration with your own workflows

- **Enable-Claude-Fork-Agent / fan-out-fork-agents**: When
  `CLAUDE_CODE_FORK_SUBAGENT=1` is active, execution is automatically
  parallelized for independent tasks
- **Superpowers `subagent-driven-development`**: Used automatically for
  parallelizable PLAN.md tasks

## License

MIT. See [`LICENSE`](./LICENSE).
