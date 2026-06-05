# claude-goal-suite

**Self-contained repo-enhancement cycle for Claude Code via `/goal`.**
Bug fixing, optimization, performance, cleanup — stack-agnostic via
auto-detection (Node/Rust/Python/Go/Java/.NET/Ruby/PHP/Elixir/Swift).

```
┌─ Phase 1: Discovery ─────────────┐  Stack detection + audit
│  → .goal-suite/SPEC.md              │  + issue inventory + baseline
└──────────────────────────────────┘
                  ▼
┌─ Phase 2: Planning ──────────────┐  Task list 2-5 min/task
│  → .goal-suite/PLAN.md              │  sorted by severity
└──────────────────────────────────┘
                  ▼
┌─ Phase 3: Execution (autonomous) ┐  iterative per task
│  /goal with Auto Mode            │  verify + checkbox
└──────────────────────────────────┘
                  ▼
┌─ Phase 4: Verification (inline) ─┐  /code-review
│  → .goal-suite/code-review.md       │  + final build/test/lint
└──────────────────────────────────┘
                  ▼
┌─ Phase 5: Commit & Chain (ext.) ─┐  git commit
│  scripts/run-chain.sh            │  + next severity
└──────────────────────────────────┘
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
- **NOT** the marketplace plugin `code-review @ claude-plugins-official`
  — see note below
- **Auto Mode** active (for unattended turns)
- **Clean Git working tree** (rollback guarantee)

### Note on the `code-review` marketplace plugin

The official Anthropic plugin `code-review @ claude-plugins-official` is
**made for GitHub PR reviews**, not for local working-tree reviews.
When installed, it blocks the `/code-review` name and idles
without an open PR — the bundled skill cannot get through.

`claude-goal-suite` avoids the problem entirely: Phase 4 spawns an
explicit code-review subagent via the Task tool instead of calling
`/code-review`. This makes the workflow independent of what is
registered under `/code-review`.

Recommendation: If you do not need the marketplace plugin for CI/PR
reviews, uninstall it:
```
/plugin uninstall code-review@claude-plugins-official
```

## Installation (one-time)

```bash
# 1. Clone or extract the repo
cd ~/dev/tools
unzip claude-goal-suite.zip
cd claude-goal-suite

# 2. Run bootstrap (plugin install instructions + .gitignore setup)
bash scripts/bootstrap.sh         # Linux/macOS/WSL
# or
pwsh scripts/bootstrap.ps1        # Windows PowerShell 7+

# 3. Work through the printed manual steps in Claude Code:
#    - 3 plugin installations
#    - 2x restart Claude Code
#    - /Claude-Full-Context-Agent:doctor
#    - /auto-mode on
```

Detailed step-by-step guide in [`INSTALL.md`](./INSTALL.md).

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
