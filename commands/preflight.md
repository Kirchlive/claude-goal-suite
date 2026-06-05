---
description: Checks whether all prerequisites for /goal-suite are met.
---

# /goal-suite:preflight

Verifies the prerequisites for a clean goal run. Aborts on every
failed check with the specific repair action.

## Checks (in order)

### 1. Claude Code version
```bash
claude --version
```
Must be >= 2.1.139. If not:
```
npm update -g @anthropic-ai/claude-code
```

### 2. Git working tree clean
```bash
git status --porcelain
```
Must be empty. If not:
```
git add -A && git commit -m "checkpoint before /goal-suite"
```

### 3. Plugins installed
From Claude Code:
```
/plugin list
```
Required:
- `superpowers` (from obra/superpowers-marketplace)
- `Claude-Full-Context-Agent` (from Kirchlive/Claude-Full-Context-Agent)
- `claude-goal-suite` (this skill)

If missing: run `scripts/bootstrap.sh` (Linux/macOS/WSL) or
`scripts/bootstrap.ps1` (Windows), then restart Claude Code.

### 4. Env variable CLAUDE_CODE_FORK_SUBAGENT
```bash
grep CLAUDE_CODE_FORK_SUBAGENT ~/.claude/settings.json
```
Must contain `"CLAUDE_CODE_FORK_SUBAGENT": "1"`. If not:
```
/Claude-Full-Context-Agent:doctor
```
Then restart Claude Code.

### 5. .gitignore entry for worktrees
```bash
grep -q '^\.claude/worktrees/' .gitignore
```
If missing:
```
echo '.claude/worktrees/' >> .gitignore
git add .gitignore && git commit -m "gitignore: worktrees"
```

### 6. Auto Mode enabled
From Claude Code:
```
/auto-mode status
```
If not active:
```
/auto-mode on
```

### 7. .goal-suite directory prepared
```bash
mkdir -p .goal-suite
```

### 8. Stack detection prerequisites
At least ONE marker file must exist:
```bash
ls package.json Cargo.toml pyproject.toml go.mod pom.xml \
   build.gradle* Gemfile composer.json *.csproj mix.exs Makefile 2>/dev/null
```
If nothing: start explicitly via the `stack=<id>` argument.

### 9. Trust dialog accepted
`/goal` only runs in trusted workspaces. If not accepted:
Claude Code will ask on the next tool call.

## Output

When all checks pass:
```
PREFLIGHT OK — ready for /goal-suite
Detected stack: <stack-id>
Expected commands:
  BUILD: <command>
  TEST:  <command>
  LINT:  <command>
  FORMAT: <command>
```

On a failure: exit with the specific next action. No auto-repair, no
guessing.
