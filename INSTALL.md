# Installation: claude-goal-suite

Complete step-by-step guide. Estimated duration: ~10 minutes,
of which ~3 minutes is wait time (plugin installs + 2x restart).

## Prerequisites (check before starting)

```bash
# Claude Code must be >= 2.1.139
claude --version

# If too old:
npm update -g @anthropic-ai/claude-code
```

## Step 1: Extract claude-goal-suite

```bash
cd ~/dev/tools                    # or wherever
unzip /path/to/claude-goal-suite.zip
cd claude-goal-suite
chmod +x scripts/*.sh             # Linux/macOS/WSL
```

## Step 2: Run the bootstrap script

**Linux/macOS/WSL/Git Bash:**
```bash
bash scripts/bootstrap.sh
```

**Windows PowerShell 7+:**
```powershell
.\scripts\bootstrap.ps1
```

The script:
- Checks the Claude Code version
- Adds entries to `.gitignore` (`.claude/worktrees/`, `.goal-suite/`)
- Creates the `.goal-suite/` directory
- Prints the manual Claude Code steps

## Step 3: Plugin installation in Claude Code

Start Claude Code in a test repo. Run the following commands
sequentially:

### 3.1 Superpowers
```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

Expected: "Plugin installed: superpowers v..."

### 3.2 Claude-Full-Context-Agent
```
/plugin marketplace add Kirchlive/Claude-Full-Context-Agent
/plugin install Claude-Full-Context-Agent@Claude-Full-Context-Agent
```

### 3.3 claude-goal-suite
Variant A — local repo:
```
/plugin marketplace add /absolute/path/to/claude-goal-suite
/plugin install claude-goal-suite@claude-goal-suite-marketplace
```

Variant B — if you push it to GitHub (e.g. `Kirchlive/claude-goal-suite`):
```
/plugin marketplace add Kirchlive/claude-goal-suite
/plugin install claude-goal-suite@claude-goal-suite-marketplace
```

## Step 4: First restart

Fully quit Claude Code and start it again. Plugins are loaded at
startup.

## Step 5: Enable fork-subagent mode

After restart, in Claude Code:
```
/Claude-Full-Context-Agent:doctor
```

The doctor command sets `CLAUDE_CODE_FORK_SUBAGENT=1` in
`~/.claude/settings.json`. Expected: "Set CLAUDE_CODE_FORK_SUBAGENT=1 in
settings.json"

## Step 6: Second restart

Quit Claude Code again and restart — environment variables are read
ONLY at startup, not at runtime.

## Step 7: Enable Auto Mode

```
/auto-mode on
```

(Alternatively via the UI settings panel)

## Step 8: Verification

```
/plugin list
```

Expected:
```
- superpowers v...
- Claude-Full-Context-Agent v...
- claude-goal-suite v0.1.0
```

```
echo $CLAUDE_CODE_FORK_SUBAGENT
```
or:
```bash
grep CLAUDE_CODE_FORK_SUBAGENT ~/.claude/settings.json
```
Expected: `"CLAUDE_CODE_FORK_SUBAGENT": "1"`

## Step 9: Per-repo setup

In every repo where you want to use `claude-goal-suite`:

```bash
# One-time:
bash /path/to/claude-goal-suite/scripts/bootstrap.sh

# Before every run (sanity check):
bash /path/to/claude-goal-suite/scripts/preflight.sh
```

or directly in Claude Code:
```
/goal-suite:preflight
```

## Step 10: First test run

In a small test repo:

```bash
git status                        # must be clean
```

In Claude Code:
```
/goal-suite:preflight
# If OK:
/goal-suite scope=src/
```

Watch the output stream:
1. STACK.md is written
2. BASELINE.md with current counts
3. SPEC.md with findings
4. PLAN.md with tasks
5. Tasks are iterated
6. Inline /code-review
7. Auto-clear on success

After the goal ends:
```bash
git diff                          # human review!
git add -A
git commit -m "goal-suite: first repo cleanup pass"
```

## Troubleshooting

### "/goal: unknown command"
Claude Code version too old. `npm update -g @anthropic-ai/claude-code`
and check with `claude --version` whether it is >= 2.1.139.

### "Plugin install failed"
The marketplace must be registered BEFOREHAND with `/plugin marketplace
add`. Order: first marketplace add, then plugin install.

### "Fork-subagent dispatch does not work"
1. Did you run `/Claude-Full-Context-Agent:doctor`?
2. Did you restart Claude Code after the doctor command?
3. Does `grep CLAUDE_CODE_FORK_SUBAGENT ~/.claude/settings.json` show `"1"`?

### "PLAN.md is not updated"
Is Auto Mode active? If not, you do not accept every write and Claude
hangs on the `Edit` tool. `/auto-mode on`.

### "Goal clears too early"
Condition too weak. Check `.goal-suite/PLAN.md` — are there `[?]` tasks
without justification? If so: the skill counted the `[?]` condition as
"fulfilled". Restart the goal with a stricter condition or use the
`severity=` filter.

### "Discovery takes forever / token budget explodes"
Repo too big for a single goal. Use:
- `scope=<subtree>` as an argument
- `scripts/run-chain.sh` for severity splits

### "/code-review not available" or "Understood — I'll wait..."
This does not affect `claude-goal-suite`. From v0.1.1, Phase 4 spawns
an explicit code-review subagent via the Task tool and never calls
`/code-review` as a slash command — so the marketplace plugin
`code-review @ claude-plugins-official` cannot block it. If you see
the message above, you invoked `/code-review` outside of
`claude-goal-suite`; that is a separate issue between the bundled
skill and the marketplace plugin and does not change Phase 4 behaviour.

## Uninstall

In Claude Code:
```
/plugin uninstall claude-goal-suite@claude-goal-suite-marketplace
/plugin uninstall Claude-Full-Context-Agent@Claude-Full-Context-Agent
/plugin uninstall superpowers@superpowers-marketplace
```

Remove the environment variable manually:
```bash
# Linux/macOS: in ~/.claude/settings.json, delete the
# CLAUDE_CODE_FORK_SUBAGENT entry from the env block (or restore the
# backup — doctor creates one automatically at
# ~/.claude/settings.json.pre-fork-backup-<TIMESTAMP>)
```

Restart Claude Code.

## Update

```bash
cd /path/to/claude-goal-suite
git pull         # if cloned as a Git repo
# or extract again and overwrite the old folder
```

In Claude Code:
```
/plugin reload claude-goal-suite
```

Or, for larger changes: uninstall + reinstall.
