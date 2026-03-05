import * as core from '@actions/core'
import * as fs from 'fs'
import * as path from 'path'
import * as crypto from 'crypto'
import { HttpClient } from '@actions/http-client'
import * as yaml from 'js-yaml'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface MetadataFile {
  name?: string
  subtitle?: string
  description?: string
  keywords?: string
  release_notes?: string
  support_url?: string
  marketing_url?: string
  privacy_url?: string
}

interface AscResource {
  id: string
  type: string
  attributes: Record<string, unknown>
}

interface AscResponse<T> {
  data: T
  errors?: Array<{ title: string; detail: string }>
}

const EDITABLE_STATES = new Set([
  'PREPARE_FOR_SUBMISSION',
  'DEVELOPER_REJECTED',
  'REJECTED',
  'METADATA_REJECTED',
  'WAITING_FOR_REVIEW',
  'INVALID_BINARY',
  'WAITING_FOR_EXPORT_COMPLIANCE',
  'READY_FOR_REVIEW',
])

const VALID_PLATFORMS = ['IOS', 'MAC_OS'] as const
type Platform = (typeof VALID_PLATFORMS)[number]

// ---------------------------------------------------------------------------
// Input validation
// ---------------------------------------------------------------------------

function validateInputs(inputs: {
  apiKeyId: string
  apiIssuerId: string
  apiKeyContent: string
  appId: string
  platform: string
  metadataPath: string
  versionString: string
  submitForReview: string
}): void {
  const required: Array<[string, string]> = [
    ['apple-api-key-id', inputs.apiKeyId],
    ['apple-api-key-issuer-id', inputs.apiIssuerId],
    ['apple-api-key-content', inputs.apiKeyContent],
    ['app-id', inputs.appId],
  ]

  for (const [name, value] of required) {
    if (!value.trim()) {
      throw new Error(`Input '${name}' is required but was not provided.`)
    }
  }

  if (!VALID_PLATFORMS.includes(inputs.platform as Platform)) {
    throw new Error(
      `Invalid platform '${inputs.platform}'. Must be one of: ${VALID_PLATFORMS.join(', ')}.`
    )
  }

  if (!['true', 'false'].includes(inputs.submitForReview)) {
    throw new Error(
      `Invalid submit-for-review value '${inputs.submitForReview}'. Must be 'true' or 'false'.`
    )
  }

  // Validate base64 content (rough check — must not be plain text)
  try {
    const decoded = Buffer.from(inputs.apiKeyContent, 'base64').toString('utf8')
    if (!decoded.includes('BEGIN') && !decoded.includes('PRIVATE KEY')) {
      core.warning(
        "apple-api-key-content does not look like a PEM private key after base64 decoding. " +
        "Ensure it is base64-encoded content of a .p8 file."
      )
    }
  } catch {
    throw new Error('apple-api-key-content is not valid base64.')
  }

  // Validate metadata path exists
  if (!fs.existsSync(inputs.metadataPath)) {
    throw new Error(
      `metadata-path '${inputs.metadataPath}' does not exist. ` +
      `Create the folder and add one YAML file per locale (e.g. en-US.yaml).`
    )
  }

  // Validate semver-like version string if provided
  if (inputs.versionString && !/^\d+\.\d+\.\d+$/.test(inputs.versionString)) {
    throw new Error(
      `version-string '${inputs.versionString}' is not a valid version format. ` +
      `Expected format: MAJOR.MINOR.PATCH (e.g. 1.2.0).`
    )
  }
}

// ---------------------------------------------------------------------------
// Version string resolution
// ---------------------------------------------------------------------------

function resolveVersionString(versionString: string): string {
  if (versionString) return versionString

  core.info('version-string not provided — reading from pubspec.yaml')

  if (!fs.existsSync('pubspec.yaml')) {
    throw new Error(
      'pubspec.yaml not found in the working directory. ' +
      'Provide version-string explicitly or run this action from the Flutter project root.'
    )
  }

  const pubspec = fs.readFileSync('pubspec.yaml', 'utf8')
  const match = pubspec.match(/^version:\s*(\d+\.\d+\.\d+)/m)

  if (!match) {
    throw new Error(
      "Could not extract a MAJOR.MINOR.PATCH version from pubspec.yaml. " +
      "Ensure the file contains a 'version: X.Y.Z[+build]' field, or provide version-string explicitly."
    )
  }

  core.info(`Resolved version from pubspec.yaml: ${match[1]}`)
  return match[1]
}

// ---------------------------------------------------------------------------
// JWT generation (ES256)
// ---------------------------------------------------------------------------

function generateJwt(apiKeyId: string, apiIssuerId: string, privateKeyPem: string): string {
  const now = Math.floor(Date.now() / 1000)
  const exp = now + 1200 // 20 minutes

  const header = Buffer.from(JSON.stringify({ alg: 'ES256', kid: apiKeyId, typ: 'JWT' })).toString('base64url')
  const payload = Buffer.from(JSON.stringify({
    iss: apiIssuerId,
    iat: now,
    exp,
    aud: 'appstoreconnect-v1',
  })).toString('base64url')

  const signingInput = `${header}.${payload}`
  const sign = crypto.createSign('SHA256')
  sign.update(signingInput)
  const signature = sign.sign({ key: privateKeyPem, dsaEncoding: 'ieee-p1363' }).toString('base64url')

  return `${signingInput}.${signature}`
}

// ---------------------------------------------------------------------------
// ASC API client
// ---------------------------------------------------------------------------

class AscClient {
  private readonly http: HttpClient
  private readonly baseUrl = 'https://api.appstoreconnect.apple.com/v1'

  constructor(jwt: string) {
    this.http = new HttpClient('flutter-actions-suite/app-store-metadata', [], {
      headers: {
        Authorization: `Bearer ${jwt}`,
        'Content-Type': 'application/json',
      },
    })
  }

  async get<T>(path: string): Promise<AscResponse<T>> {
    const res = await this.http.get(`${this.baseUrl}${path}`)
    const body = await res.readBody()
    if (res.message.statusCode! < 200 || res.message.statusCode! >= 300) {
      throw new Error(`ASC API GET ${path} returned HTTP ${res.message.statusCode}: ${body}`)
    }
    return JSON.parse(body) as AscResponse<T>
  }

  async post<T>(path: string, data: unknown): Promise<AscResponse<T>> {
    const res = await this.http.post(`${this.baseUrl}${path}`, JSON.stringify(data))
    const body = await res.readBody()
    if (res.message.statusCode! < 200 || res.message.statusCode! >= 300) {
      throw new Error(`ASC API POST ${path} returned HTTP ${res.message.statusCode}: ${body}`)
    }
    return JSON.parse(body) as AscResponse<T>
  }

  async patch<T>(path: string, data: unknown): Promise<AscResponse<T>> {
    const res = await this.http.patch(`${this.baseUrl}${path}`, JSON.stringify(data))
    const body = await res.readBody()
    if (res.message.statusCode! < 200 || res.message.statusCode! >= 300) {
      throw new Error(`ASC API PATCH ${path} returned HTTP ${res.message.statusCode}: ${body}`)
    }
    return JSON.parse(body) as AscResponse<T>
  }
}

// ---------------------------------------------------------------------------
// Version resolution
// ---------------------------------------------------------------------------

async function resolveVersionId(
  client: AscClient,
  appId: string,
  platform: string,
  versionString: string
): Promise<string> {
  core.info(`Resolving App Store version for '${versionString}' (${platform})`)

  const res = await client.get<AscResource[]>(
    `/apps/${appId}/appStoreVersions?filter[versionString]=${versionString}&filter[platform]=${platform}`
  )

  const versions = res.data

  if (!versions || versions.length === 0) {
    core.info(`No version found for '${versionString}' — creating it`)
    return await createVersion(client, appId, platform, versionString)
  }

  // Find first version in an editable state
  const editable = versions.filter(v =>
    EDITABLE_STATES.has(v.attributes['appStoreState'] as string)
  )

  if (editable.length === 0) {
    const state = versions[0].attributes['appStoreState']
    throw new Error(
      `Version '${versionString}' exists on ${platform} but is in state '${state}', ` +
      `which cannot be edited. Resolve this in App Store Connect before retrying. ` +
      `Editable states: ${[...EDITABLE_STATES].join(', ')}.`
    )
  }

  if (editable.length > 1) {
    core.warning(
      `Multiple editable versions found for '${versionString}' on ${platform}. ` +
      `Using the first one (${editable[0].id}).`
    )
  }

  const version = editable[0]
  core.info(`Found version ID: ${version.id} (state: ${version.attributes['appStoreState']})`)
  return version.id
}

async function createVersion(
  client: AscClient,
  appId: string,
  platform: string,
  versionString: string
): Promise<string> {
  const res = await client.post<AscResource>('/appStoreVersions', {
    data: {
      type: 'appStoreVersions',
      attributes: { platform, versionString },
      relationships: {
        app: { data: { type: 'apps', id: appId } },
      },
    },
  })
  core.info(`Created version ID: ${res.data.id}`)
  return res.data.id
}

// ---------------------------------------------------------------------------
// Metadata locale files
// ---------------------------------------------------------------------------

function discoverLocaleFiles(metadataPath: string): Array<{ locale: string; file: string }> {
  const entries = fs.readdirSync(metadataPath)
  const files = entries
    .filter(f => f.endsWith('.yaml') || f.endsWith('.yml'))
    .map(f => ({
      locale: path.basename(f, path.extname(f)),
      file: path.join(metadataPath, f),
    }))

  if (files.length === 0) {
    throw new Error(
      `No .yaml or .yml files found in '${metadataPath}'. ` +
      `Add one file per locale (e.g. en-US.yaml).`
    )
  }

  return files
}

function parseMetadataFile(filePath: string): MetadataFile {
  const raw = yaml.load(fs.readFileSync(filePath, 'utf8'))

  if (typeof raw !== 'object' || raw === null) {
    throw new Error(`Metadata file '${filePath}' is empty or not a valid YAML object.`)
  }

  const data = raw as Record<string, unknown>
  const SUPPORTED_FIELDS = [
    'name', 'subtitle', 'description', 'keywords',
    'release_notes', 'support_url', 'marketing_url', 'privacy_url',
  ]

  const unknown = Object.keys(data).filter(k => !SUPPORTED_FIELDS.includes(k))
  if (unknown.length > 0) {
    core.warning(`Unknown field(s) in '${filePath}': ${unknown.join(', ')}. Supported: ${SUPPORTED_FIELDS.join(', ')}.`)
  }

  // Validate URL fields
  const urlFields: Array<keyof MetadataFile> = ['support_url', 'marketing_url', 'privacy_url']
  for (const field of urlFields) {
    const val = data[field]
    if (val !== undefined && val !== null && val !== '') {
      try {
        new URL(val as string)
      } catch {
        throw new Error(`Field '${field}' in '${filePath}' is not a valid URL: '${val}'.`)
      }
    }
  }

  return {
    name: data['name'] as string | undefined,
    subtitle: data['subtitle'] as string | undefined,
    description: data['description'] as string | undefined,
    keywords: data['keywords'] as string | undefined,
    release_notes: data['release_notes'] as string | undefined,
    support_url: data['support_url'] as string | undefined,
    marketing_url: data['marketing_url'] as string | undefined,
    privacy_url: data['privacy_url'] as string | undefined,
  }
}

function buildLocalizationAttributes(meta: MetadataFile): Record<string, string> {
  // Maps YAML field names to ASC API attribute names
  const attrs: Record<string, string> = {}
  if (meta.name)          attrs['name']             = meta.name
  if (meta.subtitle)      attrs['subtitle']          = meta.subtitle
  if (meta.description)   attrs['description']       = meta.description
  if (meta.keywords)      attrs['keywords']           = meta.keywords
  if (meta.release_notes) attrs['whatsNew']           = meta.release_notes
  if (meta.support_url)   attrs['supportUrl']         = meta.support_url
  if (meta.marketing_url) attrs['marketingUrl']       = meta.marketing_url
  if (meta.privacy_url)   attrs['privacyPolicyUrl']   = meta.privacy_url
  return attrs
}

// ---------------------------------------------------------------------------
// Localization upsert
// ---------------------------------------------------------------------------

async function upsertLocalization(
  client: AscClient,
  versionId: string,
  locale: string,
  attributes: Record<string, string>
): Promise<void> {
  const res = await client.get<AscResource[]>(
    `/appStoreVersions/${versionId}/appStoreVersionLocalizations?filter[locale]=${locale}`
  )

  const existing = res.data?.[0]

  if (existing) {
    core.info(`  Localization found (${existing.id}) — updating`)
    await client.patch(`/appStoreVersionLocalizations/${existing.id}`, {
      data: {
        type: 'appStoreVersionLocalizations',
        id: existing.id,
        attributes,
      },
    })
    core.info(`  Updated locale ${locale}`)
  } else {
    core.info(`  No existing localization for ${locale} — creating`)
    await client.post('/appStoreVersionLocalizations', {
      data: {
        type: 'appStoreVersionLocalizations',
        attributes: { locale, ...attributes },
        relationships: {
          appStoreVersion: { data: { type: 'appStoreVersions', id: versionId } },
        },
      },
    })
    core.info(`  Created locale ${locale}`)
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function run(): Promise<void> {
  // Read inputs
  const apiKeyId       = core.getInput('apple-api-key-id')
  const apiIssuerId    = core.getInput('apple-api-key-issuer-id')
  const apiKeyContent  = core.getInput('apple-api-key-content')
  const appId          = core.getInput('app-id')
  const platform       = core.getInput('platform') || 'IOS'
  const metadataPath   = core.getInput('metadata-path') || 'ios/metadata'
  const versionInput   = core.getInput('version-string')
  const submitForReview = core.getInput('submit-for-review') || 'false'

  // Validate
  validateInputs({ apiKeyId, apiIssuerId, apiKeyContent, appId, platform, metadataPath, versionString: versionInput, submitForReview })

  // Resolve version
  const versionString = resolveVersionString(versionInput)

  // Decode private key
  const privateKeyPem = Buffer.from(apiKeyContent, 'base64').toString('utf8')

  // Generate JWT
  core.info('Generating App Store Connect JWT')
  const jwt = generateJwt(apiKeyId, apiIssuerId, privateKeyPem)
  core.info('JWT generated')

  // Build API client
  const client = new AscClient(jwt)

  // Resolve or create App Store version
  const versionId = await resolveVersionId(client, appId, platform, versionString)

  // Discover locale files
  const localeFiles = discoverLocaleFiles(metadataPath)
  core.info(`Found ${localeFiles.length} locale file(s): ${localeFiles.map(f => f.locale).join(', ')}`)

  // Process each locale
  for (const { locale, file } of localeFiles) {
    core.startGroup(`Processing locale: ${locale} (${file})`)
    try {
      const meta = parseMetadataFile(file)
      const attributes = buildLocalizationAttributes(meta)

      if (Object.keys(attributes).length === 0) {
        core.warning(`No supported fields found in '${file}' — skipping locale ${locale}.`)
        core.endGroup()
        continue
      }

      await upsertLocalization(client, versionId, locale, attributes)
    } finally {
      core.endGroup()
    }
  }

  core.info('All locales processed.')

  // Submit for review
  if (submitForReview === 'true') {
    core.info(`Submitting version ${versionString} for review`)
    await client.post('/appStoreVersionSubmissions', {
      data: {
        type: 'appStoreVersionSubmissions',
        relationships: {
          appStoreVersion: { data: { type: 'appStoreVersions', id: versionId } },
        },
      },
    })
    core.info('Version submitted for review.')
  } else {
    core.info('Skipping submission for review.')
  }

  core.info('App Store metadata upload complete.')
}

run().catch(err => {
  core.setFailed(err instanceof Error ? err.message : String(err))
})
