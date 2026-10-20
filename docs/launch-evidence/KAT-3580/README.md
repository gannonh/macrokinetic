# KAT-3580 verification evidence

Branch commit under test: the commit that adds this file on top of `e069229a`. Debug and optimized Release (`Release-iphonesimulator`, no `debug.dylib`) builds, Xcode 27.0, iOS 27.0 simulators. Main comparison images come from `main` at `edd81bd7` (only the shared scheme differs from the audited baseline `35c7a195`).

## Tests

- Full `JabTrackerUnitTests`: 3,076 tests, 3,071 passed, 1 skipped, 4 failed. `NotificationServiceActionTests` reschedule and remind-later titration cases fail on `UNAuthorizationStatus=Denied` (the earlier full run on this branch failed only these two). `DoseCalendarViewModelTests` streak display and `WeightTrendDetailViewModelTests` difference are date-sensitive and failed only in this run; none of the four touch the diff. `ReleasePolicyTests` (13 flags off, scanner Label pill filtered out) and `OnboardingReleasePolicyTests` pass.
- `ReleaseSurfaceUITests`: 9 cases. 8 pass in Debug and 8 pass in Release. The failing case opens food detail from search and shows a blank sheet; it fails the same way on `main`. `before-release-food-detail.png` shows the state.
- Scanner case `testBarcodeScannerHidesGalleryAndLabelWhileTorchAndBarcodeRemain` passes in both configurations. Debug-first note: the scanner container identifier overrides its children, so the test matches controls by label (`Turn on flash`, `Barcode`, `Select from gallery`, `Label`).
- `BarcodeScanningUITests` (existing): 7 of 8 fail on `barcode-scanner-content` element queries. They were not run on `main`, so treat them as unverified rather than pre-existing.
- Hostile launch input (`--enable-*` arguments, `RELEASE_FEATURES` and `ENABLE_*` environment variables, `-subscriptions YES`-style defaults) leaves every hidden surface hidden: `live/release-hostile-shortcuts.png`, `live/release-hostile-more.png`.

## Live scenarios (integrated iPhone 18 Pro simulator)

13 UI cases ran there; 12 pass (same food-detail case fails). `review-timelapse-47s.mp4` is a 47 s timelapse (screenshots every 0.6 s played at 4 frames per second) of six cases, because `simctl recordVideo` reported "Host recording is already in progress".

1. Main vs branch, Dashboard to Food Log to More: `main/dashboard.png`, `main/food-log.png`, `main/more.png` against `live/scenario1-dashboard.png`, `live/scenario1-food-log.png`, `live/scenario1-more.png`, `live/scenario1-more-account.png`. Main's More lists Dashboard, Food Log and Shortcuts & Tabs placeholders, Subscription, FAQ and Help; the branch lists none.
2. More omits subscription: `live/scenario1-more-account.png`.
3. Add omits AI and photos: `live/release-shortcuts.png` (main: `main/shortcuts.png`).
4. Search omits AI: `live/release-search-methods.png`.
5. Library omits Recipes and Favorites: `live/release-library-tabs.png`. The scanner now also omits the Label scan type and the inert gallery button: `live/release-barcode-scanner.png`.
6. Strategy omits Edit Days and customization: `live/release-strategy.png`.
7. Metrics and calorie settings omit unverified controls: `live/release-supported-metrics.png`, `live/release-calorie-settings.png`.
8. Normal logging: Quick Add logs 250 kcal (`live/release-quick-add-entry.png`, `live/release-quick-add-logged.png`). Search to food detail is blocked on this branch alone by the blank-sheet defect; with the fix merged it passes (see Integration section).
9. Weight logging retains the saved value as the next default (`live/release-weight-sheet.png`, `live/release-weight-default-after-save.png`); Quick Dose logging passes in `DoseButtonUITests`.
10. Hostile relaunch keeps features off: `live/release-hostile-shortcuts.png`, `live/release-hostile-more.png`.

## Integration with the food-detail fix (temporary merge)

A throwaway merge of this branch (`0cff9719`) with the KAT-3598 branch head `86bd51d5` (integration commit `e04dd2ff`, one conflict in `FoodSearchSheet.swift` resolved by dropping the `showingComingSoon` and `showingFoodDetail` state lines that each branch removed) was built and tested, then discarded; it is not pushed. `ReleaseSurfaceUITests` passed 9 of 9 in Debug and 9 of 9 in an optimized Release build, and the food-detail case passed on the integrated iPhone 18 Pro simulator (`live/merged-before-release-food-detail.png`, `live/merged-release-food-detail-actions.png`: To Custom, Schedule and Add visible, Favorite hidden). Merge after the KAT-3598 PR; expect that textual conflict when the two land.

## Open

Nothing for this ticket once the food-detail fix lands. The split-dose second-time TODO and the finite reminder queue are filed as separate Backlog work.
