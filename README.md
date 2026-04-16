# Flutter Multi-Platform Github Actions Suite

This GitHub Action prepares, checks, builds and deploys Flutter applications for iOS, Android, Web, macOS, Windows, and Linux. It supports modular builds via boolean flags and deployment to App Store Connect, Firebase App Distribution, Firebase Hosting, Play Store, Microsoft Store, and Snap Store.

## Features

- **Modular Architecture**: Use the full pipeline or individual actions independently.
- **Pre-build hooks**: Automatic `build_runner` and `gen-l10n` code generation.
- **Checks and Testing**: Run checks and tests with coverage reports.
- **Build & Signing**: Automated signing setup for iOS and Android and support for iOS, Android, Web, macOS, Windows, and Linux builds.
- **Publish**:
    - iOS: App Store Connect, Firebase App Distribution.
    - Android: Play Store, Firebase App Distribution, Huawei App Gallery (future).
    - Web: Firebase Hosting, Github Pages.
    - macOS: App Store Connect.
    - Linux: Snap Store.
    - Windows: Windows Store.

# Usage

You have two options: use the [main action](/action.yml) to manage the full build and deployment of a Flutter project on a single platform, or use actions modularly to create your own flow.

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
| **Build** | [`/build/{platform}`](./build) | Build project (ios/android/web/macos/windows/linux). |
| **Publish** | [`/publish/{store}`](./publish) | Publish project (ios-app-store/macos-app-store/play-store/firebase-app-distribution/firebase-hosting/snap-store/microsoft-store/...)  |

You can use sub-actions to have more granular control:

```yaml
- name: Code Generation
  uses: Spaccesi/flutter-ci-suite/prepare/build_runner@v1

- name: Run Tests
  uses: Spaccesi/flutter-ci-suite/check/test@v1
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

## Inputs Reference

### Flutter

| Input | Default | Description |
| --- | --- | --- |
| `flutter-version` | | Flutter version to use. Defaults to latest stable if omitted. |
| `flutter-channel` | `stable` | Flutter channel (`stable`, `beta`, `dev`, `master`). |

### Prepare

| Input | Default | Description |
| --- | --- | --- |
| `run-build-runner` | `false` | Run `build_runner` for all packages with a `build_runner` dependency. |
| `run-gen-l10n` | `false` | Run `gen-l10n` for all packages with an `intl` dependency. |
| `gen-l10n-fails-if-untranslated` | `false` | Fail if untranslated strings are found after `gen-l10n`. |

### Check

| Input | Default | Description |
| --- | --- | --- |
| `run-analyze` | `false` | Run `flutter analyze`. |
| `run-test` | `false` | Run unit and widget tests. |
| `run-license-check` | `false` | Validate dependency licenses against an allowlist. |
| `analyze-fails-if-infos` | `false` | Fail analyze step on info-level issues. |
| `analyze-fails-if-warnings` | `false` | Fail analyze step on warning-level issues. |
| `licenses-conf-path` | | Path to a YAML file listing compatible licenses. Required when `run-license-check` is `true`. |
| `test-run-coverage` | `false` | Collect code coverage during tests. |
| `test-create-coverage-report` | `false` | Generate an HTML coverage report using `lcov`/`genhtml`. |

### Build

| Input | Default | Description |
| --- | --- | --- |
| `build-platforms` | | Platforms to build. Options: `android-apk`, `android-appbundle`, `ios`, `web`, `macos`, `windows`, `linux`. |
| `build-mode` | `release` | Build mode: `debug`, `profile`, or `release`. |
| `build-name` | | Version name shown to users. Defaults to `pubspec.yaml` value. |
| `build-number` | | Internal version number. Defaults to `pubspec.yaml` value. |
| `flavor` | | Flutter flavor to build. |
| `dart-define` | | Comma-separated `key=value` pairs passed as `--dart-define`. |

### Publish

| Input | Default | Description |
| --- | --- | --- |
| `publish-destinations` | | Publish targets. Options: `ios-app-store`, `macos-app-store`, `play-store`, `firebase-app-distribution`, `firebase-hosting`, `github-pages`, `snap-store`, `microsoft-store`. |
| `release-notes` | | Release notes forwarded to Firebase App Distribution and Play Store. |

### iOS signing & publish

| Input | Description |
| --- | --- |
| `ios-distribution-certificate-base64` | Base64-encoded P12 distribution certificate. Required for iOS builds. |
| `ios-distribution-certificate-password` | Password for the iOS distribution certificate. |
| `ios-provisioning-profile-base64` | Base64-encoded iOS provisioning profile. |
| `ios-export-options-plist` | Path to an `ExportOptions.plist` file. |
| `apple-api-key-id` | App Store Connect API key ID. Required for iOS/macOS App Store publish. |
| `apple-api-key-issuer-id` | App Store Connect API issuer ID (UUID). Required for iOS/macOS App Store publish. |
| `apple-api-key-content` | Base64-encoded `.p8` private key. Required for iOS/macOS App Store publish. |

### macOS signing & publish

| Input | Description |
| --- | --- |
| `macos-distribution-certificate-base64` | Base64-encoded P12 distribution certificate. Required for macOS builds. |
| `macos-distribution-certificate-password` | Password for the macOS distribution certificate. |
| `macos-installer-certificate-base64` | Base64-encoded P12 installer certificate (`3rd Party Mac Developer Installer`). Required for macOS App Store publish. |
| `macos-installer-certificate-password` | Password for the macOS installer certificate. |
| `macos-provisioning-profile-base64` | Base64-encoded macOS provisioning profile. |

### Android signing & publish

| Input | Description |
| --- | --- |
| `android-store-file-base64` | Base64-encoded JKS/PKCS12 keystore. Required for release/profile Android builds. |
| `android-key-alias` | Key alias within the keystore. |
| `android-store-password` | Keystore password. |
| `android-key-password` | Key password. |
| `play-store-service-account-json` | Google Play service account JSON (plain text, not base64). Required for Play Store publish. |
| `play-store-package-name` | App package name (e.g. `com.example.myapp`). Required for Play Store publish. |
| `play-store-track` | Play Store track: `internal`, `alpha`, `beta`, `production`. |
| `play-store-status` | Release status: `completed`, `draft`, `halted`, `inProgress`. Defaults to `completed`. |

### Web & Firebase

| Input | Description |
| --- | --- |
| `base-href` | Overrides the `<base href>` in `web/index.html`. Must start and end with `/`. |
| `firebase-service-account-base64` | Base64-encoded Firebase service account JSON. Required for Firebase Hosting and App Distribution. |
| `firebase-project-id` | Firebase project ID. Required for Firebase Hosting. |
| `firebase-hosting-target` | Firebase Hosting target name. |
| `firebase-app-distribution-app-id` | Firebase App ID (e.g. `1:1234567890:android:abcdef`). Required for Firebase App Distribution. |
| `firebase-app-distribution-groups` | Comma-separated tester groups for Firebase App Distribution. |

### Windows & Microsoft Store

| Input | Description |
| --- | --- |
| `microsoft-partner-center-tenant-id` | Azure AD tenant ID. |
| `microsoft-partner-center-seller-id` | Partner Center seller ID. |
| `microsoft-partner-center-client-id` | Azure AD app client ID. |
| `microsoft-partner-center-client-secret` | Azure AD app client secret. |
| `microsoft-store-app-id` | Microsoft Store app ID. |

### Linux & Snap Store

| Input | Description |
| --- | --- |
| `snap-store-token` | Snap Store API token with publish permissions. |
