# Flutter Build Runner

Automatically discovers and runs code generation using `build_runner` for all Flutter packages in the repository.

## Usage

```yaml
- name: Code Generation
  uses: spaccesi/flutter-ci-suite/build_runner@v1
```

No inputs required. The action handles everything automatically.

## What It Does

1. Scans the repository for all `pubspec.yaml` files (up to 3 levels deep).
2. For each package, checks if `build_runner` is listed as a dependency.
3. Runs `dart run build_runner build --delete-conflicting-outputs` on matching packages.
4. Skips packages that don't use `build_runner`.

Output is grouped per package using GitHub Actions log groups for clean, readable logs.

## Workspaces & Monorepos

This action is **monorepo-aware by design**. It automatically discovers and processes all packages in your repository, so there's no need for matrix strategies or per-package configuration.

Example monorepo structure:

```
my_app/
├── pubspec.yaml                    # Root app (uses build_runner) ✓
├── packages/
│   ├── api_client/
│   │   └── pubspec.yaml            # Has build_runner dep ✓
│   ├── design_system/
│   │   └── pubspec.yaml            # No build_runner dep ⊘ (skipped)
│   └── models/
│       └── pubspec.yaml            # Has build_runner dep ✓
```

The action will run `build_runner` on `my_app`, `api_client`, and `models`, and skip `design_system`.

> **Note**: Packages are discovered up to 3 directories deep. Deeply nested packages beyond this depth won't be found automatically.
