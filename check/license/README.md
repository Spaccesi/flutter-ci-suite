# Flutter License Check

Check that all dependency licenses are compatible with your project. This action uses [license_checker](https://pub.dev/packages/license_checker) to verify licenses.

## Usage

```yaml
- name: Check Licenses
  uses: Spaccesi/flutter-ci-suite/check/license@main
  with:
    compatible-licenses-conf-path: 'config/compatible_licenses.yaml'
```

## Inputs

| Input | Description | Required | Default |
| --- | --- | --- | --- |
| `compatible-licenses-conf-path` | Path to a file containing a list of compatible licenses. | **Yes** | - |

## Compatible Licenses Configuration

The configuration file (e.g., `licenses.yaml`) should list the licenses you accept. Example:

```yaml
permittedLicenses:
  - mit
  - bsd_3_clause
  - apache_2_0
```

## What It Does

1. Activates the `license_checker` Dart package globally.
2. Runs `lic_ck check-licenses` using the provided configuration path.
3. Parses the output for the "No package licenses need approval!" string; if not found, the action fails.
