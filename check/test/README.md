# Flutter Test

Runs Flutter tests with optional coverage reporting and optionally deployment to GitHub Pages or artifacts.

## Usage

### Basic

```yaml
- name: Test
  uses: Spaccesi/flutter-ci-suite/check/test@main
```

### With Coverage Report & Deployment

```yaml
- name: Test with Coverage
  uses: Spaccesi/flutter-ci-suite/check/test@main
  with:
    run-coverage: 'true'
```

## Inputs

| Input | Description | Required | Default |
| --- | --- | --- | --- |
| `dart-define` | Command line arguments for `String.fromEnvironment`. | No | `''` |
| `dart-define-from-file` | Path to a `.json` or `.env` file for environments. | No | `''` |
| `flavor` | App flavor to use when running tests. | No | `''` |
| `concurrency` | Number of concurrent test processes. | No | `1` |
| `timeout` | Test timeout (e.g., `60s`, `2x`, `none`). | No | `60s` |
| `ignore-timeouts` | Ignore all timeouts. | No | `false` |
| `run-coverage` | Collect coverage (forces `lcov.info` generation). | No | `false` |
| `deploy-report` | Options: `none`, `github-pages`, `artifact`. | No | `none` |
| `github-token` | Token needed for `github-pages` deployment. | No | `''` |

## What It Does

1. Runs `flutter test .` with configured options.
2. Uses the GitHub reporter for rich logging.
3. If coverage is enabled (or `deploy-report` is set), appends `--coverage`.
4. If a report is requested, it installs `lcov`, runs `genhtml`, and:
    - Deploys to the `gh-pages` branch using `peaceiris/actions-gh-pages`.
    - OR uploads the HTML report as a GitHub artifact named `coverage-report`.

## Workspaces & Monorepos

This action runs tests from the current working directory. In monorepos with recent versions of Flutter and Dart, running this action from the root folder is sufficient.

Flutter versions that do not support workspaces are not supported at the moment.
