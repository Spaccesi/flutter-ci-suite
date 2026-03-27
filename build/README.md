# Flutter Build

Builds a Flutter application for a specific platform. Includes a top-level orchestrator action and platform-specific sub-actions.

## Structure

```bash
build/
├── ios/action.yaml     # iOS-specific build
├── android/action.yaml # Android-specific build 
├── web/action.yaml     # Web-specific build 
├── macos/action.yaml   # macOS-specific build 
├── windows/action.yaml # Windows-specific build 
└── linux/action.yaml   # Linux-specific build
```

## Important

This action only handles the build step. You must install Flutter and run `/prepare` before running any `/build` action.

## Usage

### Platform-Specific Actions

Use a platform sub-action directly when Flutter is already set up in a previous step:

```yaml
- name: Build iOS
  uses: spaccesi/flutter-ci-suite/build/ios@v1
  with:
    flavor: 'production'
    build-name: '1.0.0'
    build-number: '${{ github.run_number }}'
```

## Runner Requirements

| Platform | Runner |
| --- | --- |
| iOS | `macos-latest` |
| Android | `ubuntu-latest` |
| Web | `ubuntu-latest` |
| macOS | `macos-latest` |
| Windows | `windows-latest` |
| Linux | `ubuntu-latest` |
