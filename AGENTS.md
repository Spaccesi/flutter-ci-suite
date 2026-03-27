# AGENTS.md — flutter-ci-suite

## Repository Overview

This is a **GitHub Actions composite action library** for Flutter CI/CD pipelines. There is no
Dart/Flutter source code here — the languages are **YAML** (action interfaces) and **Bash**
(implementations). Actions are consumed as:

```yaml
uses: Spaccesi/flutter-ci-suite/<subpath>@main
```

The four pipeline stages are: `prepare/` → `check/` → `build/` → `publish/`

---

## Architecture

### Two-tier action model

- **Orchestrator actions** — `action.yml` files that call other local actions in sequence
  (e.g., `check/action.yml` calls `check/analyze`, `check/license`, `check/test`)
- **Leaf actions** — a paired `action.yml` (YAML interface) + `<name>.sh` (Bash implementation)
  The YAML maps action `inputs:` to environment variables, then calls the shell script via
  `shell: bash`.

### Leaf action pattern
```
<stage>/<name>/
├── action.yml         # Declares inputs, sets env vars, runs the .sh script
├── <name>.sh          # All actual logic lives here
└── README.md          # Usage docs and input reference
```

### Monorepo support
`build_runner` and `gen-l10n` scripts auto-discover `pubspec.yaml` files up to 3 directory
levels deep using `find . -mindepth 1 -maxdepth 3 -type f -name "pubspec.yaml"`.

---

## CI / Test Commands

There are no local test commands — the test suite runs entirely in GitHub Actions.

**Trigger CI** by pushing to a `feature/*` branch or opening a pull request.

**CI jobs** (defined in `.github/workflows/test.yml`):

| Job | Runner | What it validates |
|---|---|---|
| `lint` | ubuntu-latest | `actionlint` on all YAML |
| `test-analyze` | ubuntu-latest | `check/analyze` action |
| `test-license` | ubuntu-latest | `check/license` action |
| `test-flutter-test` | ubuntu-latest | `check/test` action |
| `test-build-web` | ubuntu-latest | `build/web` action |
| `test-build-linux` | ubuntu-latest | `build/linux` action |
| `test-build-windows` | windows-latest | `build/windows` action |
| `test-build-android` | ubuntu-latest | `build/android` (debug, no signing) |
| `test-build-macos` | macos-latest | `build/macos` (debug, no signing) |
| `test-build-ios` | macos-latest | `build/ios` (debug, `code-sign: false`) |

**Bootstrap pattern** used in every test job — copies a freshly created Flutter app into the
workspace root so leaf actions have a valid Flutter project to operate on:
```bash
flutter create /tmp/test_app --project-name test_app --org com.example
cp -r /tmp/test_app/. .
flutter pub get
```

**To test a single action locally**, replicate the bootstrap and then invoke the action's shell
script directly, after exporting the required environment variables:
```bash
flutter create /tmp/test_app --project-name test_app --org com.example
cp -r /tmp/test_app/. .
flutter pub get
# Example: test the analyze script
export ANALYZE_FAILS_IF_INFOS=false
export ANALYZE_FAILS_IF_WARNINGS=false
export NO_PUB=true
bash check/analyze/analyze.sh
```

**Lint YAML locally** using [actionlint](https://github.com/rhysd/actionlint):
```bash
actionlint
```

---

## YAML Style (action.yml files)

- **Inputs** use `kebab-case` names (e.g., `build-mode`, `dart-define-from-file`)
- Every input must have a `description:` and a `default:` (use `''` for optional string inputs,
  `'false'` for boolean flags, `'release'` for build mode)
- Boolean inputs are **strings** (`'true'` / `'false'`), not native YAML booleans — this is
  the GitHub Actions composite action limitation
- The `runs:` block uses `using: composite` with `steps:` that set `env:` from inputs and call
  the shell script: `run: bash ${{ github.action_path }}/<name>.sh`
- All steps must include `shell: bash` (required for composite actions)
- Pin external actions to a major version tag (e.g., `actions/checkout@v6`,
  `subosito/flutter-action@v2`) — never use `@latest` or floating SHAs
- Group related inputs with blank lines and inline comments

### Example action.yml structure
```yaml
name: 'Action Name'
description: 'One-line description'

inputs:
  build-mode:
    description: 'Build mode: debug, profile, or release'
    default: 'release'
  dart-define:
    description: 'Pass --dart-define to flutter (optional)'
    default: ''

runs:
  using: composite
  steps:
    - name: Run <name>
      shell: bash
      env:
        BUILD_MODE: ${{ inputs.build-mode }}
        DART_DEFINE: ${{ inputs.dart-define }}
      run: bash ${{ github.action_path }}/<name>.sh
```

---

## Shell Script Style

- **No shebang line** — scripts are always invoked explicitly as `bash <script>.sh`
- **Flag accumulation pattern** — build a `FLAGS` variable conditionally:
  ```bash
  FLAGS="--$BUILD_MODE"
  [ "$DART_DEFINE" != '' ] && FLAGS="$FLAGS --dart-define=$DART_DEFINE"
  [ "$NO_PUB" == 'true' ] && FLAGS="$FLAGS --no-pub"
  ```
- **Never use `-z`/`-n`** to test for empty strings — use `!= ''` and `== 'true'` consistently
- **GitHub Actions log grouping** for noisy install steps:
  ```bash
  echo "::group::ℹ️ Installing lcov"
  sudo apt-get install lcov -y
  echo "::endgroup::"
  ```
- **Status emoji conventions** (use consistently — they appear in CI logs):
  - `▶️` — operation starting (before a `flutter`/`dart` command)
  - `✅` — script completed successfully (last line of every script)
  - `☑️` — a prerequisite is confirmed or a sub-package step completed
  - `⏭️` — a step is being skipped
  - `ℹ️` — informational install/setup step
  - `🚨` — error condition (`echo "::error::🚨 message"`)
- **No `set -e`** — scripts rely on GitHub Actions' default behavior of stopping on non-zero
  exit codes; use explicit `exit 1` for error paths
- **Temporary files** go in `$RUNNER_TEMP`, not `/tmp`, for signing artifacts
- **Secret handling** — always decode base64 secrets to `$RUNNER_TEMP` files, never log them

---

## Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Action input names | `kebab-case` | `build-mode`, `no-pub` |
| Shell env var names | `SCREAMING_SNAKE_CASE` | `BUILD_MODE`, `NO_PUB` |
| Action directory names | `kebab-case` | `build/ios/`, `check/analyze/` |
| Shell script names | match directory name | `ios.sh`, `analyze.sh` |
| CI job names | `test-<stage>-<name>` | `test-build-ios`, `test-analyze` |

---

## Adding a New Action

1. Create `<stage>/<name>/action.yml` and `<stage>/<name>/<name>.sh`
2. Add a `README.md` with usage, inputs table, and runner requirements
3. Add a test job to `.github/workflows/test.yml` following the bootstrap pattern
4. If the action is platform-specific, use the correct runner (see table above)
5. Reference the new leaf action from the relevant orchestrator `action.yml` if applicable

---

## Known Issues / Gotchas

- **`check/analyze/analyze.sh`**: the `--no-fatal-infos` / `--no-fatal-warnings` flag logic is
  inverted — `FLAGS` receives the `--no-fatal-*` flag when the corresponding `*_FAILS_IF_*`
  env var is `'true'` (should be the opposite). Fix carefully and update the test job.
- **`prepare/gen-l10n/action.yml`**: calls `build_runner/build_runner.sh` instead of
  `gen-l10n/gen-l10n.sh` — a copy-paste bug.
- **Orchestrator actions** (`check/action.yml`, root `action.yml`) reference sub-actions by
  their published GitHub path, so CI always tests the *published* version of orchestrators,
  not local changes. Only leaf actions are tested on PRs.
- **`publish/`** and **`docs/`** are incomplete stubs — `publish/README.md` and
  `docs/README.md` contain only "TODO".
- The `examples/` folder referenced in the root `README.md` does not exist in the repository.
