# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A **reusable GitHub Actions composite action library** for Flutter CI/CD. There is **no Dart/Flutter source code** — only YAML (action interfaces) and Bash (implementations). Actions are consumed as `uses: Spaccesi/flutter-ci-suite/<subpath>@main`.

See `AGENTS.md` for the full contributor guide. This file highlights what's most relevant for AI-assisted work.

## Testing / Linting

There are no local test commands. Tests run entirely in GitHub Actions on push to `feature/*` or a PR.

**Lint YAML locally:**
```bash
actionlint
```

**Test a leaf action locally** — bootstrap a Flutter project first, then run the script directly:
```bash
flutter create /tmp/test_app --project-name test_app --org com.example
cp -r /tmp/test_app/. .
flutter pub get
# Then invoke the script with required env vars, e.g.:
export BUILD_MODE=debug
export NO_PUB=true
bash build/web/web.sh
```

## Architecture

### Four pipeline stages
```
prepare/ → check/ → build/ → publish/
```

### Two-tier action model
- **Leaf actions**: `action.yml` (declares inputs, maps to env vars, calls `.sh`) + `<name>.sh` (all logic)
- **Orchestrator actions**: `action.yml` files that chain leaf actions in sequence (e.g. `check/action.yml`, root `action.yml`)

The root `action.yml` is a full orchestrator that inlines the prepare/check/build steps directly (does not call the sub-action `action.yml` files) and then delegates publish steps to the published `publish/*@main` sub-actions.

### iOS/macOS signing pattern
Both `build/ios/ios.sh` and `build/macos/macos.sh` gate all signing setup on `if [ "$CODE_SIGN" != 'false' ]` (default: runs unless explicitly disabled). The signing block:
1. Creates a temporary keychain in `$RUNNER_TEMP`
2. Imports the distribution certificate (p12)
3. Installs the provisioning profile with its UUID as the filename
4. Patches `project.pbxproj` via `sed` to set `CODE_SIGN_STYLE = Manual`

## Shell Script Conventions

These are enforced across all `.sh` files — follow them when editing:

- **No shebang** — scripts are invoked as `bash <name>.sh`
- **`set -e` is present** on all build scripts (added for safety; AGENTS.md says to avoid it but it is currently in use)
- **Flag accumulation**: build a `FLAGS` var conditionally, then pass it to the flutter command
- **Boolean checks**: use `!= ''` for presence, `== 'true'` / `!= 'false'` for boolean flags — never `-z`/`-n`
- **Log grouping** for noisy steps: `echo "::group::ℹ️ ..."` / `echo "::endgroup::"`
- **Temp files** go in `$RUNNER_TEMP`, never `/tmp`
- **Status emojis**: `▶️` starting, `✅` done, `☑️` prerequisite confirmed, `⏭️` skipped, `🚨` error

## Known Bugs in the Codebase

From `AGENTS.md` — these exist and should be fixed carefully:

- **`publish/` and `docs/`** are incomplete stubs
- **`examples/`** folder referenced in README does not exist
