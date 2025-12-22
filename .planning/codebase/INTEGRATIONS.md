# External Integrations

**Analysis Date:** 2025-12-22

## APIs & External Services

**Open Food Facts API:**
- Service: Open Food Facts REST API - Food search fallback
  - Base URL: `https://world.openfoodfacts.org` - `JabTracker/Services/OpenFoodFactsService.swift`
  - Auth: None (public API)
  - Timeout: 30s request, 60s resource
  - Endpoints: `/cgi/search.pl` (search), `/api/v0/product/{barcode}.json` (barcode lookup)
  - Rate limits: Undocumented (should add throttling)

**No Other External APIs:**
- All other functionality uses Apple frameworks or local data

## Data Storage

**Databases:**
- SwiftData + CloudKit - Primary user data store
  - Connection: Automatic via ModelContainer
  - Client: SwiftData `@Model` entities
  - Sync: CloudKit with graceful fallback to local-only
  - Container: `iCloud.com.gannonhall.JabTracker` - `JabTracker/JabTracker.entitlements`

- SQLite3 Local Food Database - Bundled offline database
  - Size: 382 MB with 1.7M+ foods
  - Path: `JabTracker/Resources/usda_foods.sqlite`
  - Client: `JabTracker/Services/LocalFoodDatabase.swift`
  - Technology: SQLite FTS5 (Full-Text Search)
  - Sources: USDA Foundation/SR Legacy + Open Food Facts dump

**File Storage:**
- Not applicable (no user file uploads)

**Caching:**
- `ChartDatasetCache` - In-memory chart data caching (`JabTracker/Services/ChartDatasetCache.swift`)
- No external caching service

## Authentication & Identity

**Auth Provider:**
- Sign in with Apple - Sole authentication method
  - Implementation: `JabTracker/AuthenticationManager.swift`
  - Token storage: Keychain via Security framework
  - Session management: Apple-managed credentials

**OAuth Integrations:**
- None (Sign in with Apple only)

**Biometric Auth:**
- Face ID/Touch ID - App access protection
  - Implementation: `JabTracker/BiometricAuthManager.swift`
  - Framework: LocalAuthentication

## Monitoring & Observability

**Error Tracking:**
- None currently (no Sentry, Crashlytics, etc.)

**Analytics:**
- None (no Mixpanel, Firebase, etc.)

**Logs:**
- OSLog framework - Local device logs only
  - Subsystem: `com.gannonhall.JabTracker`
  - Retention: iOS system log rotation

## CI/CD & Deployment

**Hosting:**
- App Store - Distribution via TestFlight
  - Bundle ID: `com.gannonhall.JabTracker`
  - Team: `ZBZKKWF95G`

**CI Pipeline:**
- Local scripts (`scripts/check-all.sh`, `scripts/test.sh`)
- No external CI service documented

## Environment Configuration

**Development:**
- Required: Xcode 26.2, macOS
- Launch arguments for testing: `--ui-testing`, `--reset-app-data`, `--seed-test-*`
- No secrets required (Apple APIs use system credentials)

**Production:**
- CloudKit container auto-configured via entitlements
- StoreKit products configured in App Store Connect

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## Data Sources Summary

| Source | Type | Format | Coverage |
|--------|------|--------|----------|
| USDA FoodData Central Foundation | Bundled | SQLite | ~7,000 foods |
| USDA SR Legacy | Bundled | SQLite | ~8,000 foods |
| Open Food Facts dump | Bundled | SQLite | ~1.7M branded products |
| Open Food Facts API | Remote | REST JSON | Fallback search |
| CloudKit | Cloud sync | SwiftData | User data |

---

*Integration audit: 2025-12-22*
*Update when adding/removing external services*
