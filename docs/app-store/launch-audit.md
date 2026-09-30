# Submission audit and ticket ownership

Source inspection on September 30, 2026 used baseline `35c7a1959a805331ccc09a2821b8d801f42efc3c`. It found submission issues; it did not prove live acceptance. KAT-3185 owns delivery order and launch gates.

| Finding | Source evidence | Launch issue |
| --- | --- | --- |
| Mock subscription and unfinished settings | MoreView routes to SubscriptionSettingsView; fixed price/date and disabled restore are visible. | KAT-3580 |
| Reconstitution instructions and calculated units | MedicationFormComponents, ReconstitutionCalculator, and MedicationProfileHeader. | KAT-3581 |
| Logout contradicts retention message | AccountView promises retention; AuthenticationManager deletes User; User cascades doses, profiles, and goals. | KAT-3582 |
| CloudKit health-data policy conflict | DataController registers health models; MetricsService imports HealthKit weight into that context. | KAT-3584 |
| Missing privacy manifest and incomplete purpose strings | No PrivacyInfo.xcprivacy; UserDefaults use; HealthKit requests more types than Info.plist explains. | KAT-3585 |
| No explicit deletion action | AccountView has logout and restart; credential/data deletion is unproven. | KAT-3586 |
| Inert privacy, terms, and support | GeneralSettingsView and MoreView use static labels. | KAT-3592 |
| Dataset credits absent | Release data combines USDA and Open Food Facts; no credits/license screen found. | KAT-3593 |
| Internal-only export | testflight-release.yml sets testFlightInternalTestingOnly=true. | KAT-3594 |
| No candidate screenshot or metadata packet | Existing mocks and old PR images do not show the final launch candidate. | KAT-3591 |

Source configuration sets Xcode 26.5, iOS 17.5 minimum, iPhone-only, version 0.10.1/build 16. The actual signed SDK, entitlements, production schema, icon output, and Connect setup remain unverified. Apple requires iOS 26 SDK or later for uploads since April 28, 2026. [Apple SDK minimum](https://developer.apple.com/news/?id=ueeok6yw).

The existing Icon Composer source is legitimate source packaging. Its 512px transparent layer is not itself an opaque App Store icon. Validate compiled 1024px output and appearances from the final archive. Xcode can generate older-OS icons from a Composer source. [Apple icon guide](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer).

Internal-only TestFlight exports cannot be submitted for App Review. [Apple TestFlight tutorial](https://developer.apple.com/tutorials/develop-in-swift/test-your-beta-app).

OFF data uses ODbL, database contents use DbCL, and product images use CC BY-SA. Determine obligations for the normalized distributed database separately from the app code and private user records. USDA data uses public-domain CC0 and requests source attribution. KAT-3593 owns the notices and documented fulfilment. [OFF license guide](https://github.com/openfoodfacts/openfoodfacts-server/blob/main/docs/api/tutorials/license-be-on-the-legal-side.md), [USDA licensing](https://fdc.nal.usda.gov/api-guide/).
