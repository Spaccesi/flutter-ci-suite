# Flutter Multi-Platform Github Actions Suite

This GitHub Action prepares, checks, builds and deploys Flutter applications for iOS, Android, Web, macOS, Windows, and Linux. It supports modular builds via boolean flags and deployment to App Store Connect, Firebase App Distribution, Firebase Hosting, Play Store, Microsoft Store, and Snap Store.

## Features

- **Modular Architecture**: Use the full pipeline or individual actions independently.
- **Pre-build hooks**: Automatic `build_runner` and `gen-l10n` code generation.
- **Checks and Testing**: Run checks and tests with coverage reports.
- **Documentation**: Generate project documentation with `dartdoc`.
- **Build & Signing**: Automated signing setup for iOS and Android and support for iOS, Android, Web, macOS, Windows, and Linux builds.
- **Publish**:
    - iOS: App Store Connect, Firebase App Distribution.
    - Android: Play Store, Firebase App Distribution.
    - Web: Firebase Hosting, Github Pages.
    - macOS: App Store Connect.
    - Linux: Snap Store.
    - Windows: Windows Store.

# Usage

You have two options: use the [main action](/action.yml) to manage the full build and deployment of a Flutter project on a single platform, or use actions modularly to create your own flow. The [Examples](/examples/) folder is a good starting point — you may find what you are looking for there.

## Main action

The main action (action.yml) is a single-entry-point GitHub Action that manages the full CI/CD pipeline for a Flutter application on a chosen platform. It orchestrates four sequential stages:
1. Prepare
Sets up the Flutter environment, runs flutter pub get, and optionally executes code generation steps — build_runner (for generated Dart code) and gen-l10n (for localization files) — so the app is fully ready to build.
2. Check (Test & Analyze)
Runs static analysis, formatting checks, dependency license validation, and unit/widget tests — optionally with coverage reports. This acts as a quality gate before any build artifact is produced.
3. Build
Compiles the Flutter app for the target platform. Supported platforms are iOS, Android, Web, macOS, Windows, and Linux. Platform-specific signing is handled automatically for iOS (certificates/provisioning profiles) and Android (keystore).
4. Publish
Deploys the built artifact to one or more distribution destinations based on boolean flags provided as inputs. Supported destinations are:

- iOS/macOS → App Store Connect, Firebase App Distribution
- Android → Play Store, Firebase App Distribution
- Web → Firebase Hosting, GitHub Pages
- Linux → Snap Store
- Windows → Microsoft Store

Make sure you are building the right version of the app for the right platform where you are trying to publish.

The idea is that by setting a handful of input flags, a single workflow step covers the entire lifecycle from a clean repo to a published release — with no need to wire up the individual modular actions manually.

## Modular Actions

Each step of the pipeline is available as an independent action. This gives you full control over your CI/CD pipeline.

| Action | Path | Description |
| --- | --- | --- |
| **Check** | [`/check`](./check) | Composite action for analysis, licenses, and tests. |
| **Analyze** | [`/check/analyze`](./check/analyze) | Run static analysis and formatting checks. |
| **Test** | [`/check/test`](./check/test) | Run tests with optional coverage reports. |
| **License** | [`/check/license`](./check/license) | Check compatibility of dependency licenses. |
| **Prepare** | [`/prepare`](./prepare) | Composite action for environment setup and code generation. |
| **Build Runner** | [`/prepare/build_runner`](./prepare/build_runner) | Run `build_runner` across the repository. |
| **Gen L10n** | [`/prepare/gen-l10n`](./prepare/gen-l10n) | Run `gen-l10n` localization across the repository. |
| **Docs** | [`/docs`](./docs) | Generate project documentation with `dartdoc`. |
| **Build** | [`/build/{platform}`](./build) | Build project (ios/android/web/macos/windows/linux). |
| **Publish** | [`/publish/{store}`](./publish) | Publish project (ios-app-store/macos-app-store/play-store/firebase-app-distribution/firebase-hosting/snap-store/microsoft-store/...)  |

You can use sub-actions to have more granular control:

```yaml
- name: Code Generation
  uses: Spaccesi/flutter-ci-suite/prepare/build_runner@main

- name: Run Tests
  uses: Spaccesi/flutter-ci-suite/check/test@main
  with:
    run-coverage: 'true'
```

## Parallel multi-platform CI with jobs

The [flutter_ci_jobs.yml](./examples/flutter_ci_jobs.yml) example shows a recommended two-phase workflow that prepares your repository once and then builds every platform concurrently.

**Phase 1 — Prepare & Check** runs on a single `ubuntu-latest` runner and performs all the work that is shared across platforms: `flutter pub get`, optional code generation (`build_runner`, `gen-l10n`), static analysis, and tests. Once everything passes, the fully-prepared workspace is uploaded as a GitHub Actions artifact so the build jobs never need to re-run code generation.

**Phase 2 — Platform builds** start in parallel as soon as Phase 1 succeeds. Each job downloads the prepared workspace, restores pub packages from the Actions cache, and builds its target platform on the appropriate runner (ubuntu for Android/Web/Linux, macos for iOS/macOS, windows for Windows).

```
Phase 1                        Phase 2 (parallel)
──────────────────────         ──────────────────────────────────────────
prepare & check (ubuntu)  →    build-android  (ubuntu-latest)
                          →    build-ios      (macos-latest)
                          →    build-web      (ubuntu-latest)
                          →    build-windows  (windows-latest)
                          →    build-macos    (macos-latest)
                          →    build-linux    (ubuntu-latest)
```

This pattern avoids redundant code-generation on every runner, keeps total wall-clock time close to the slowest single platform build, and gates all platform builds behind a single quality gate.

See [examples/flutter_ci_jobs.yml](./examples/flutter_ci_jobs.yml) for the full workflow.

## Flutter version and workspaces

This action is primarily tested with the latest Flutter versions and is not tested with older versions of Flutter.
In particular, for monorepos, this package relies on workspaces to work correctly. Other implementations are not supported at the moment.

## Notes

- **macOS/iOS**: Requires `macos` runner.
- **Windows**: Requires `windows` runner.
- **Linux**: Requires `ubuntu` runner.
