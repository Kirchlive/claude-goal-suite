# Changelog

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
