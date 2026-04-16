# Flutter Check Action

A composite action that orchestrates static analysis, dependency license checking, and automated testing for Flutter projects.

## Usage

```yaml
- name: Run Checks
  uses: Spaccesi/flutter-ci-suite/check@v1
  with:
    compatible-licenses-conf-path: 'licenses.yaml'
    run-coverage: 'true'
    deploy-report: 'artifact'
```

## Sub-Actions

This composite action calls the following sub-actions:

- **Analyze**: [`/check/analyze`](./analyze) - Static analysis and formatting.
- **License**: [`/check/license`](./license) - Compatibility check for dependency licenses.
- **Test**: [`/check/test`](./test) - Unit and widget tests with coverage support.

## Inputs

| Input | Description | Required | Default |
| --- | --- | --- | --- |
| `analyze` | Whether to run analysis. | No | `true` |
| `license` | Whether to run license check. | No | `true` |
| `test` | Whether to run tests. | No | `true` |
| `compatible-licenses-conf-path` | Path to compatible licenses file. | **Yes** | - |
| `analyze-fails-if-infos` | Fail if info issues found. | No | `true` |
| `analyze-fails-if-warnings` | Fail if warnings found. | No | `true` |
| `license-fails-on-warnings` | Fail if license warnings found. | No | `false` |
| `license-fails-on-info` | Fail if license info found. | No | `false` |
| `run-coverage` | Collect test coverage. | No | `false` |
| `no-pub` | Whether to skip `pub get` before running checks. | No | `true` |

> **Note**: For all inputs related to tests (dart-define, flavor, concurrency, timeout, ignore-timeouts), see the [Test Sub-Action README](./test/README.md).

## Behavior

1. **Setup**: Assumes Flutter is already installed (usually via the root action).
2. **Modular execution**: Each check can be disabled via boolean flags.
3. **Monorepo support**: Designed to work within monorepos when workspace is configured.
