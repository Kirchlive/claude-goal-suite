# Stack Auto-Detection Reference

This table is the lookup the enhancer skill uses to detect the stack
from marker files at the repo root and derive the commands.

## Detection heuristic

Claude scans the project root (and, for monorepos, optionally the
first two subdirectory levels) for the following marker files — in
order of precedence from top to bottom. The first matching family
wins; on ambiguity, `.goal-suite/stack-override.txt` (one line, e.g.
`node-pnpm` or `rust` or `python-uv`) takes effect.

## Lookup table

| Marker file(s) | Stack ID | BUILD | TEST | LINT | FORMAT |
|---|---|---|---|---|---|
| `package.json` + `pnpm-lock.yaml` | `node-pnpm` | `pnpm build` | `pnpm test` | `pnpm lint` | `pnpm prettier --check .` |
| `package.json` + `yarn.lock` | `node-yarn` | `yarn build` | `yarn test` | `yarn lint` | `yarn prettier --check .` |
| `package.json` + `bun.lockb` | `node-bun` | `bun run build` | `bun test` | `bun run lint` | `bun x prettier --check .` |
| `package.json` (otherwise) | `node-npm` | `npm run build` | `npm test` | `npm run lint` | `npx prettier --check .` |
| additionally `tsconfig.json` | `+typescript` | + `npx tsc --noEmit` | (unchanged) | (unchanged) | (unchanged) |
| `Cargo.toml` | `rust` | `cargo build --release` | `cargo test --all` | `cargo clippy --all-targets --all-features -- -D warnings` | `cargo fmt --check` |
| `pyproject.toml` + `uv.lock` | `python-uv` | `uv build` | `uv run pytest -q` | `uv run ruff check` | `uv run ruff format --check` |
| `pyproject.toml` + `poetry.lock` | `python-poetry` | `poetry build` | `poetry run pytest -q` | `poetry run ruff check` | `poetry run ruff format --check` |
| `pyproject.toml` (otherwise) | `python-pep517` | `python -m build` | `pytest -q` | `ruff check` | `ruff format --check` |
| `requirements.txt` without `pyproject.toml` | `python-plain` | (n/a) | `pytest -q` | `ruff check` | `ruff format --check` |
| `go.mod` | `go` | `go build ./...` | `go test ./...` | `golangci-lint run` | `gofmt -l . \| (grep -v . && echo unformatted \|\| true)` |
| `pom.xml` | `java-maven` | `mvn -q -B verify -DskipTests` | `mvn -q -B test` | `mvn -q -B spotbugs:check` | `mvn -q -B spotless:check` |
| `build.gradle*` | `java-gradle` | `./gradlew build -x test` | `./gradlew test` | `./gradlew check -x test` | `./gradlew spotlessCheck` |
| `Gemfile` | `ruby` | `bundle exec rake build` | `bundle exec rspec` | `bundle exec rubocop` | (in lint) |
| `composer.json` | `php` | (n/a) | `vendor/bin/phpunit` | `vendor/bin/phpstan analyse --no-progress` | `vendor/bin/php-cs-fixer fix --dry-run --diff` |
| `*.csproj` or `*.sln` | `dotnet` | `dotnet build -c Release --nologo` | `dotnet test --nologo` | `dotnet format --verify-no-changes` | (in lint) |
| `mix.exs` | `elixir` | `mix compile --warnings-as-errors` | `mix test` | `mix credo --strict` | `mix format --check-formatted` |
| `Makefile` (fallback) | `make` | `make build` | `make test` | `make lint` | `make fmt-check` |

## Special stacks (rare but relevant)

| Marker | Stack ID | Note |
|---|---|---|
| `*.toc` + `*.lua` in addon layout | `wow-addon` | No standard tests. Only LINT via `luacheck`, no BUILD. Skill falls back to TODO inventory + lint run. |
| `Package.swift` | `swift` | `swift build`, `swift test`, `swiftlint`, `swift-format lint .` |
| `flake.nix` without other markers | `nix` | `nix build`, `nix flake check`, lint depends on stack |

## Monorepo handling

When multiple marker files coexist (e.g. `package.json` AND
`Cargo.toml` AND `pyproject.toml`), the following applies:

1. **Explicit override**: `.goal-suite/stack-override.txt` with a stack
   ID is preferred
2. **Workspace indicators**: `pnpm-workspace.yaml`, `[workspace]` in
   `Cargo.toml`, `[tool.uv.workspace]` in `pyproject.toml` -> skill
   makes one pass per workspace package, not at the root
3. **If unclear**: skill aborts with a clear question — no guessing

## When nothing is detected

The skill writes `.goal-suite/STACK.md` with `stack: unknown` and a
recommendation to set `.goal-suite/stack-override.txt` manually or to
start `/goal-suite` with an explicit stack argument:

```
/goal-suite stack=python-uv
```

## Validation steps before goal start

After stack detection, the skill must verify that the derived
commands are locally executable:

```bash
which <BUILD_TOOL> || echo "MISSING: BUILD"
which <TEST_TOOL>  || echo "MISSING: TEST"
which <LINT_TOOL>  || echo "MISSING: LINT"
which <FORMAT_TOOL> || echo "MISSING: FORMAT"
```

Missing tools are listed in `.goal-suite/STACK.md` under `missing_tools:`.
The goal still runs, but skips the affected verification steps (with
a warning in the report).
