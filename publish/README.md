# Publish Actions

Leaf actions for publishing Flutter app artifacts to distribution platforms. Each action is independently usable via `uses: Spaccesi/flutter-ci-suite/publish/<store>@v1`.

## Available Actions

| Action | Path | Platform | Runner |
| --- | --- | --- | --- |
| **iOS App Store** | [`/publish/ios-app-store`](./ios-app-store) | iOS | `macos-latest` |
| **macOS App Store** | [`/publish/macos-app-store`](./macos-app-store) | macOS | `macos-latest` |
| **Play Store** | [`/publish/play-store`](./play-store) | Android | any |
| **Firebase App Distribution** | [`/publish/firebase-app-distribution`](./firebase-app-distribution) | iOS / Android | any |
| **Firebase Hosting** | [`/publish/firebase-hosting`](./firebase-hosting) | Web | any |
| **Snap Store** | [`/publish/snap-store`](./snap-store) | Linux | `ubuntu-latest` |
| **Microsoft Store** | [`/publish/microsoft-store`](./microsoft-store) | Windows | `windows-latest` |

---

## iOS App Store

Uploads a built `.ipa` to App Store Connect using the App Store Connect API.

**Prerequisites:** a signed `.ipa` produced by the `build/ios` action.

```yaml
- uses: Spaccesi/flutter-ci-suite/publish/ios-app-store@v1
  with:
    apple-api-key-id: ${{ secrets.APPLE_API_KEY_ID }}
    apple-api-key-issuer-id: ${{ secrets.APPLE_API_ISSUER_ID }}
    apple-api-key-content: ${{ secrets.APPLE_API_KEY_CONTENT }}
    ios-app-path: build/ios/ipa/MyApp.ipa
```

| Input | Required | Description |
| --- | --- | --- |
| `apple-api-key-id` | ✅ | App Store Connect API key ID |
| `apple-api-key-issuer-id` | ✅ | App Store Connect API issuer ID (UUID) |
| `apple-api-key-content` | ✅ | Base64-encoded `.p8` private key |
| `ios-app-path` | ✅ | Path to the `.ipa` file |

---

## macOS App Store

Packages a `.app` bundle into a `.pkg` and uploads it to App Store Connect.

**Prerequisites:** a signed `.app` produced by the `build/macos` action and a `3rd Party Mac Developer Installer` certificate in the keychain.

```yaml
- uses: Spaccesi/flutter-ci-suite/publish/macos-app-store@v1
  with:
    apple-api-key-id: ${{ secrets.APPLE_API_KEY_ID }}
    apple-api-key-issuer-id: ${{ secrets.APPLE_API_ISSUER_ID }}
    apple-api-key-content: ${{ secrets.APPLE_API_KEY_CONTENT }}
    macos-app-path: build/macos/Build/Products/Release/MyApp.app  # optional
```

| Input | Required | Description |
| --- | --- | --- |
| `apple-api-key-id` | ✅ | App Store Connect API key ID |
| `apple-api-key-issuer-id` | ✅ | App Store Connect API issuer ID (UUID) |
| `apple-api-key-content` | ✅ | Base64-encoded `.p8` private key |
| `macos-app-path` | — | Path to the `.app` bundle. Auto-detected from `build/macos/Build/Products/Release/` if omitted. |

---

## Play Store

Publishes an `.aab` or `.apk` to the Google Play Store.

```yaml
- uses: Spaccesi/flutter-ci-suite/publish/play-store@v1
  with:
    play-store-service-account-json: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT_JSON }}
    play-store-package-name: com.example.myapp
    play-store-track: internal
    play-store-release-files: build/app/outputs/bundle/release/app-release.aab
```

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `play-store-service-account-json` | ✅ | | Google Play service account JSON (plain, not base64) |
| `play-store-package-name` | ✅ | | App package name (e.g. `com.example.myapp`) |
| `play-store-track` | ✅ | | Track to publish to (`internal`, `alpha`, `beta`, `production`) |
| `play-store-release-files` | ✅ | | Path to the `.aab` or `.apk` release file |
| `play-store-status` | — | `completed` | Release status (`completed`, `draft`, `halted`, `inProgress`) |

---

## Firebase App Distribution

Distributes a binary (`.ipa`, `.apk`, `.aab`) to testers via Firebase App Distribution.

```yaml
- uses: Spaccesi/flutter-ci-suite/publish/firebase-app-distribution@v1
  with:
    firebase-release-binary-file: build/app/outputs/flutter-apk/app-release.apk
    firebase-service-account-base64: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_BASE64 }}
    firebase-app-id: ${{ secrets.FIREBASE_APP_ID }}
    firebase-groups: testers
    firebase-release-notes: ${{ github.event.head_commit.message }}
```

| Input | Required | Description |
| --- | --- | --- |
| `firebase-release-binary-file` | ✅ | Path to the file to upload |
| `firebase-service-account-base64` | ✅ | Base64-encoded Firebase service account JSON |
| `firebase-app-id` | ✅ | Firebase App ID (e.g. `1:1234567890:android:abcdef`) |
| `firebase-groups` | — | Comma-separated tester groups |
| `firebase-testers` | — | Comma-separated tester email addresses |
| `firebase-release-notes` | — | Release notes text |
| `firebase-release-notes-file` | — | Path to a file containing release notes |
| `firebase-debug` | — | Enable debug logging (`true`/`false`, default `false`) |

> `firebase-groups`, `firebase-testers`, and `firebase-release-notes` each have a corresponding `*-file` variant that reads the value from a file.

---

## Firebase Hosting

Deploys a built web app to Firebase Hosting.

**Prerequisites:** a web build in `build/web` produced by `build/web`.

```yaml
- uses: Spaccesi/flutter-ci-suite/publish/firebase-hosting@v1
  with:
    firebase-service-account-base64: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_BASE64 }}
    firebase-project-id: my-firebase-project
```

| Input | Required | Description |
| --- | --- | --- |
| `firebase-service-account-base64` | ✅ | Base64-encoded Firebase service account JSON |
| `firebase-project-id` | — | Firebase project ID (inferred from service account if omitted) |
| `firebase-target` | — | Firebase Hosting target name |
| `firebase-message` | — | Deployment message |
| `firebase-debug` | — | Enable debug logging (`true`/`false`, default `false`) |

---

## Snap Store

Publishes a built snap package to the Snap Store.

**Prerequisites:** a `.snap` file produced by `build/linux`.

```yaml
- uses: Spaccesi/flutter-ci-suite/publish/snap-store@v1
  with:
    snap-store-token: ${{ secrets.SNAP_STORE_TOKEN }}
```

| Input | Required | Description |
| --- | --- | --- |
| `snap-store-token` | ✅ | Snap Store API token with publish permissions |

---

## Microsoft Store

Packages and publishes a Windows app to the Microsoft Store using the MS Store CLI.

**Prerequisites:** a Windows build produced by `build/windows`.

```yaml
- uses: Spaccesi/flutter-ci-suite/publish/microsoft-store@v1
  with:
    microsoft-partner-center-tenant-id: ${{ secrets.MS_TENANT_ID }}
    microsoft-partner-center-seller-id: ${{ secrets.MS_SELLER_ID }}
    microsoft-partner-center-client-id: ${{ secrets.MS_CLIENT_ID }}
    microsoft-partner-center-client-secret: ${{ secrets.MS_CLIENT_SECRET }}
    microsoft-store-app-id: ${{ secrets.MS_STORE_APP_ID }}
```

| Input | Required | Description |
| --- | --- | --- |
| `microsoft-partner-center-tenant-id` | ✅ | Azure AD tenant ID |
| `microsoft-partner-center-seller-id` | ✅ | Partner Center seller ID |
| `microsoft-partner-center-client-id` | ✅ | Azure AD app client ID |
| `microsoft-partner-center-client-secret` | ✅ | Azure AD app client secret |
| `microsoft-store-app-id` | ✅ | Microsoft Store app ID |
