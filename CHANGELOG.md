# Changelog

## [0.2.0] - 2026-06-06

### Added
- **Phase 2 — Research** (new). Read-only external subagent that
  enriches SPEC.md findings flagged with `needs-research: true`.
  Source-mandatory, capped at 5 lookups, skippable via `--no-research`.
  Output: `.goal-suite/RESEARCH.md`. Closes the gap where the previous
  flow could "modernize" with training-cutoff knowledge.
- **`needs-research` flag** in SPEC.md per finding.
- **Actor model split** documented and wired across the flow:
  Subagent for read-only knowledge work (explore in Phase 1, external
  research in Phase 2, two-stage review in Phase 5); Fork-Agent for
  Phase 4 execution; Phase 6 commit always external.
- **`scripts/preflight.sh`** now checks Phase 2 research capability
  and Claude Code ≥ 2.1.151.
- **README §"Actor model — at a glance"** for the new split.

### Changed
- **6-phase flow** (was 5): Discovery → Research → Planning →
  Execution → Verification → Commit.
- **Phase 3 Planning** now produces `writing-plans`-conform PLAN.md
  lines: `- [ ] [SEVERITY] T-N: description (file:line) -- verify:
  <cmd>`. Mechanical parsing by `status.md` and `run-chain.sh` works.
- **Phase 4 Execution** uses Fork-Agents (`prefer-fork-agents` /
  `fan-out-fork-agents`) instead of `subagent-driven-development`.
  Bug-tasks layer on `systematic-debugging` + `test-driven-development`.
- **Phase 5 Verification** runs the two-stage review subagent (spec
  compliance + code quality) and applies
  `verification-before-completion` as the Completion Gate. The
  CRITICAL count is echoed into the transcript via `grep -c -iE
  'CRITICAL'` so the tool-less evaluator can read it.
- **`/goal-suite:status`** and **`scripts/run-chain.sh`** parsers
  upgraded to the new PLAN.md format; `run-chain.sh` severity
  pre-check now correctly identifies open tasks per severity.
- **`commands/goal-suite.md`** wires `scope=`, `severity=` and
  `--no-research`; previous documentation was orphaned.
- **`commands/resume.md`** defines `[?]` as terminal-by-default and
  re-initialises from SPEC.md + RESEARCH.md without re-running
  Discovery/Research.
- **`hooks/post-goal-commit.example.json`** now requires a
  `.goal-suite/.commit-on-stop` sentinel so it cannot mid-goal commit
  and destroy the rollback guarantee. Warning about `--no-verify`
  added.
- **Claude Code minimum bumped to 2.1.151** for native `/code-review`
  reuse/simplify support.
- **Install flow** consolidated to one restart instead of two.
- **`SKILL.md`** rewritten around the actor model, lists the
  per-phase Superpowers skills and the deliberate non-integrations
  (no `brainstorming`, no parallel/worktree skills, no auto-commit
  via `executing-plans`/`finishing-a-development-branch`).
- `allowed-tools` extended with `Task`, `Skill`, `WebSearch`,
  `WebFetch` (the latter two for Phase 2).

### Why
Practical review surfaced three classes of issues: PLAN format
divergence between the generator and the parsers (status/chain were
no-ops), Superpowers declared as a hard dependency but never invoked,
and the absence of any external ground-truth before autonomous
modernization. The 6-phase Actor-Modell redesign addresses all three
in one pass.

## [0.1.1] - 2026-06-05

### Changed
- **Phase 4 (verification) no longer calls `/code-review`.** Instead,
  an explicit code-review subagent is spawned via the Task tool. This
  avoids a routing issue that occurs when the marketplace plugin
  `code-review @ claude-plugins-official` is installed in parallel: its
  command blocks the name but only operates in PR workflows and drops
  into an idle state without an open PR.
- Extended the goal template with Phase 4: explicit review aspects
  (CLAUDE.md compliance, bug patterns, test coverage regression,
  anti-patterns, secrets/URLs) and an output format with severity tags.
- SKILL.md, README.md: note on `/code-review` routing and recommendation
  to uninstall the marketplace plugin for non-CI usage.

### Why
Practical testing showed: a bare `/code-review` without PR context
idles when the marketplace plugin is installed ("Understood — I am
waiting for your instruction"), instead of reviewing the local diff.
The subagent spawn is more robust because it works independently of
slash-command routing.

## [0.1.0] - 2026-06-05

### Added
- Initial release.
- Skill `goal-suite` with complete workflow: discovery → planning →
  execution → verification.
- Stack auto-detection for Node (npm/pnpm/yarn/bun), Rust, Python (uv/poetry/pep517/plain),
  Go, Java (Maven/Gradle), Ruby, PHP, .NET, Elixir, Swift, Make fallback.
- Slash commands: `/goal-suite`, `/goal-suite:preflight`,
  `/goal-suite:status`, `/goal-suite:resume`.
- Bootstrap scripts for Linux/macOS/WSL (`bootstrap.sh`) and Windows
  (`bootstrap.ps1`).
- Preflight script for CLI sanity checks (`scripts/preflight.sh`).
- Chain runner for sequential severity chunks (`scripts/run-chain.sh`).
- Optional stop hook for auto-commits between goal phases
  (`hooks/post-goal-commit.example.json`).
- Complete documentation: README, INSTALL.

### Prerequisites
- Claude Code v2.1.139+ (for `/goal`).
- Superpowers (`obra/superpowers-marketplace`).
- Claude-Full-Context-Agent (`Kirchlive/Claude-Full-Context-Agent`).
- `/code-review` (bundled).

### Known Limitations
- Plugin install + restart cannot be triggered from a running `/goal`
  — bootstrap is a one-time manual step.
- The discovery phase can become expensive for large repos (>50k LoC →
  use `scope=` or chain runs).
- The evaluator (Haiku) has no tool access — verification must land as
  shell output in the transcript.
- Incompatible with the `disableAllHooks` and `allowManagedHooksOnly`
  settings.
