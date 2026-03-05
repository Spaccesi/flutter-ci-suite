# Plan: publish/app-store-metadata

## Goal

A leaf action that reads per-locale YAML metadata files and pushes them to
App Store Connect via the REST API. Supports both iOS and macOS app stores.
Implemented in TypeScript (node20) for input validation, type safety, and
clean JSON/HTTP handling.

## File structure

```
publish/app-store-metadata/
├── action.yml         ← using: node20, main: dist/index.js
├── src/
│   └── index.ts       ← TypeScript source
├── dist/
│   └── index.js       ← compiled + bundled via ncc (committed to repo)
├── package.json
├── package-lock.json
└── tsconfig.json
```

## action.yml inputs

| Input                   | Required | Default        | Description                                              |
|-------------------------|----------|----------------|----------------------------------------------------------|
| apple-api-key-id        | true     | —              | App Store Connect API key ID                             |
| apple-api-key-issuer-id | true     | —              | App Store Connect issuer ID (UUID)                       |
| apple-api-key-content   | true     | —              | Base64-encoded .p8 private key                           |
| app-id                  | true     | —              | App Store Connect numeric app ID                         |
| platform                | false    | IOS            | IOS or MAC_OS                                            |
| metadata-path           | false    | ios/metadata   | Path to folder containing per-language YAML files        |
| version-string          | false    | ''             | Version string (e.g. 1.2.0). If omitted, read from pubspec.yaml |
| submit-for-review       | false    | false          | Submit the version for review after uploading metadata   |

## Metadata YAML schema (one file per locale, e.g. en-US.yaml)

```yaml
name: "My App"
subtitle: "The best app"
description: "Full description text..."
keywords: "flutter, app, productivity"
release_notes: "Bug fixes and improvements"
support_url: "https://example.com/support"
marketing_url: "https://example.com"
privacy_url: "https://example.com/privacy"
```

## src/index.ts logic

1. Read and validate all inputs (see validation table below)
2. Resolve version string from input or pubspec.yaml
3. Decode base64 API key content → PEM string
4. Generate ES256 JWT via Node built-in `crypto.createSign`
5. Resolve App Store version ID:
   a. GET /v1/apps/{app-id}/appStoreVersions?filter[versionString]=...&filter[platform]=...
      (no state filter — fetch all states)
   b. If empty → auto-create: POST /v1/appStoreVersions
      (no build validity check — build attachment is out of scope; see design decisions)
   c. If results found → find the first in an editable state
   d. If none editable → throw error surfacing the actual state name
   e. If multiple editable (edge case) → use first, emit core.warning
6. Discover .yaml/.yml files in metadataPath via fs.readdirSync
7. For each locale file:
   a. Parse with js-yaml; validate unknown fields and URL formats
   b. Map YAML fields to ASC API attribute names
   c. GET localization for this locale; PATCH if exists, POST to create if not
8. If submit-for-review === 'true': POST /v1/appStoreVersionSubmissions

## Input validation

| Input | Validation |
|---|---|
| apple-api-key-id/issuer-id/content/app-id | Required, non-empty |
| apple-api-key-content | base64-decodable; PEM key heuristic warning if not |
| platform | Enum: IOS or MAC_OS — fails immediately with valid options listed |
| submit-for-review | Enum: true or false |
| metadata-path | Directory must exist |
| version-string | Semver format X.Y.Z if provided; auto-detected from pubspec.yaml if omitted |
| YAML URL fields (support_url, marketing_url, privacy_url) | Valid URL via `new URL()` |
| Unknown YAML fields | core.warning emitted (not a failure) |

## Version state machine

Editable states (metadata can be pushed):
- PREPARE_FOR_SUBMISSION
- DEVELOPER_REJECTED
- REJECTED
- METADATA_REJECTED
- WAITING_FOR_REVIEW
- INVALID_BINARY
- WAITING_FOR_EXPORT_COMPLIANCE
- READY_FOR_REVIEW

Non-editable states (action throws with state name in message):
- PENDING_DEVELOPER_RELEASE
- PROCESSING_FOR_DISTRIBUTION
- READY_FOR_SALE
- REPLACED_WITH_NEW_VERSION

## Pipeline responsibilities

This action is designed to run after publish/ios-app-store in the same pipeline:

```
build/ios → publish/ios-app-store → publish/app-store-metadata
```

| Action                     | Responsibility                                                                      |
|----------------------------|-------------------------------------------------------------------------------------|
| publish/ios-app-store      | Uploads binary via xcrun altool. Triggers async processing on Apple servers.        |
| publish/app-store-metadata | Creates App Store Version if needed, pushes text metadata, optionally submits for review. |

## Key design decisions

- TypeScript + node20: input validation, type safety, proper error handling.
- JWT: ES256-signed via Node built-in `crypto.createSign` — no openssl shell tricks.
- YAML parsing: `js-yaml` npm package — no yq install at runtime.
- HTTP: `@actions/http-client` with typed responses and status code validation.
- Platform input (IOS vs MAC_OS) makes this action usable for both stores.
- No macOS runner requirement: all crypto and HTTP handled in Node.js.
- version-string is optional: auto-detected from pubspec.yaml if omitted.
- Version auto-creation: if no ASC version found for the given string, one is created.
- Build attachment is intentionally out of scope: xcrun altool upload triggers async
  processing on Apple's servers (typically minutes), so the build will not be VALID
  by the time the metadata action runs in the same CI job. Build attachment is left
  as a manual step in ASC or a future dedicated action.

## Build

```bash
cd publish/app-store-metadata
npm install
npm run build      # ncc bundles src/index.ts → dist/index.js (commit dist/)
npm run typecheck  # tsc --noEmit
```

## Status

- [x] action.yml — node20 runtime, all inputs declared
- [x] src/index.ts — full TypeScript implementation with input validation
- [x] dist/index.js — compiled and bundled with ncc (committed)
- [x] package.json / tsconfig.json
- [x] app-store-metadata.sh — removed (replaced by Node.js)
- [x] Plan updated: version management, pipeline responsibilities, Node.js migration
