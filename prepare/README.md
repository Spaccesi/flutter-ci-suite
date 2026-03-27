# Flutter Prepare

A composite action that prepares a Flutter repository for builds and checks by installing dependencies and running code generation tasks.

## Usage

```yaml
- name: Prepare
  uses: Spaccesi/flutter-ci-suite/prepare@main
```

```yaml
- name: Prepare
  uses: Spaccesi/flutter-ci-suite/prepare@main
  with:
    run-build-runner: 'true'
    run-gen-l10n: 'true'
    gen-l10n-fails-if-untranslated: 'true'
```

## Sub-Actions

This composite action calls the following sub-actions:

- **Build Runner**: [`/prepare/build_runner`](./build_runner) - Code generation using `build_runner`.
- **Gen L10n**: [`/prepare/gen-l10n`](./gen-l10n) - Localization code generation using `flutter gen-l10n`.

## Inputs

| Input | Description | Required | Default |
| --- | --- | --- | --- |
| `run-build-runner` | Whether to run `build_runner` for code generation. | No | `true` |
| `run-gen-l10n` | Whether to run `gen-l10n` for localization code generation. | No | `true` |
| `gen-l10n-fails-if-untranslated` | Fail if untranslated strings are found during `gen-l10n`. | No | `false` |

## Behavior

1. Runs `flutter pub get` to install dependencies.
2. Runs `build_runner` across all packages that declare it as a dependency (if enabled).
3. Runs `gen-l10n` across all packages that have an `l10n.yaml` or `l10n.yml` configuration (if enabled).

Both sub-actions are **monorepo-aware**: they automatically discover all packages up to 3 directories deep and skip packages that don't require the respective code generation step.
