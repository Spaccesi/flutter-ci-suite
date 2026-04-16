# Flutter Gen L10n

Automatically discovers and runs localization code generation using `flutter gen-l10n` for all Flutter packages in the repository.

## Usage

```yaml
- name: Localization
  uses: spaccesi/flutter-ci-suite/gen-l10n@v1
```

No inputs required. The action handles everything automatically.

## What It Does

1. Scans the repository for all `pubspec.yaml` files (up to 3 levels deep).
2. For each package, checks if `l10n` is configured in `pubspec.yaml`.
3. Runs `flutter gen-l10n` on matching packages.
4. Skips packages that don't have localization configured.

Output is grouped per package using GitHub Actions log groups for clean, readable logs.

## Workspaces & Monorepos

This action is **monorepo-aware by design**. It automatically discovers and processes all packages in your repository.

Example monorepo structure:

```
my_app/
├── pubspec.yaml                    # Has l10n config ✓
├── lib/l10n/
│   ├── app_en.arb
│   └── app_es.arb
├── packages/
│   ├── feature_auth/
│   │   ├── pubspec.yaml            # Has l10n config ✓
│   │   └── lib/l10n/
│   │       ├── auth_en.arb
│   │       └── auth_es.arb
│   └── design_system/
│       └── pubspec.yaml            # No l10n config ⊘ (skipped)
```

The action will run `gen-l10n` on `my_app` and `feature_auth`, and skip `design_system`.

> **Note**: Packages are discovered up to 3 directories deep. Make sure your localization ARB files and `l10n.yaml` (if used) are properly configured in each package.

> **Note**: In the future, this discovery step may not be needed depending on how workspaces evolve.