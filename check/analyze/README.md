# Flutter Analyze

Runs `flutter analyze` and formatting checks with configurable severity levels.

## Usage

```yaml
- name: Analyze
  uses: Spaccesi/flutter-ci-suite/check/analyze@main
  with:
    analyze-fails-if-warnings: true
    analyze-fails-if-infos: true
    no-pub: true
```

## Inputs

| Input | Description | Required | Default |
| --- | --- | --- | --- |
| `treat-infos-as-fatal` | Treat info level issues as fatal. | No | `true` |
| `treat-warnings-as-fatal` | Treat warning level issues as fatal. | No | `true` |
| `no-pub` | Skip `pub get` before analysis. | No | `true` |

## What It Does

1. Runs `flutter analyze .` with the specified severity flags.
2. If `no-pub` is true, it appends `--no-pub` to the command (default behavior).
3. If analysis finds issues exceeding the configured severity, the action fails.

## Workspaces & Monorepos 

This action runs the analyzer from the current working directory. In monorepos with recent versions of Flutter and Dart, running this action from the root folder is sufficient.

Flutter versions that do not support workspaces are not supported at the moment.