Fix these failing tests:

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/CalendarNavigationUITests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/CalendarNavigationUITests.swift:162 test_calendar_dateSelection(): XCTAssertTrue failed - Dose list should be visible for date with doses

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/CalendarScheduledDosesUITests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/CalendarScheduledDosesUITests.swift:53 testViewCalendarWithScheduledDosesDisplayed(): XCTAssertGreaterThan failed: ("0") is not greater than ("20") - Calendar should show multiple day elements for the month

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/CalendarScheduledDosesUITests.swift:239 testCalendarRefreshesWithScheduledDoses(): XCTAssertGreaterThan failed: ("0") is not greater than ("20") - Calendar should show multiple day elements for the month

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/CalendarScheduledDosesUITests.swift:284 testCalendarRenderingPerformanceWith90Days(): XCTAssertGreaterThan failed: ("0") is not greater than ("20") - Calendar should show multiple day elements for the month

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/CalendarScheduledDosesUITests.swift:327 testScheduledDosesLazyLoadedPerMonth(): XCTAssertGreaterThan failed: ("0") is not greater than ("20") - Calendar should show current month day elements

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/DesignSystemUITests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/DesignSystemUITests.swift:98 testTypographyRendering(): XCTAssertTrue failed - Headline should exist

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/DoseHistoryFilteringUITests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/DoseHistoryFilteringUITests.swift:33 test_doseHistory_searchFiltersInRealTime(): XCTAssertTrue failed - Search field should be available

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/DoseHistoryFilteringUITests.swift:82 test_doseHistory_searchClearsWhenTextRemoved(): XCTAssertTrue failed - Search field should be available

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/DoseHistoryFilteringUITests.swift:265 test_doseHistory_pullToRefreshUpdatesData(): XCTAssertTrue failed - History view should be available

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/DoseHistoryStatesUITests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/DoseHistoryStatesUITests.swift:52 test_doseHistory_showsEmptyStateWhenNoDoses(): XCTAssertTrue failed - Should have dose-history-list elements indicating we're on history view

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/DoseHistoryStatesUITests.swift:125 test_doseHistory_addFirstDose(): XCTAssertTrue failed - Should have dose-history-list elements

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/DoseHistoryStatesUITests.swift:282 test_doseHistory_editActionPrePopulatesDoseEntryForm(): XCTAssertTrue failed - Should have dose-history-list elements

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/DoseHistorySwipeActionsUITests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/DoseHistorySwipeActionsUITests.swift:72 test_doseHistory_swipeActionsDeleteDose(): XCTAssertTrue failed - Should have dose-history-list elements

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/DoseHistorySwipeActionsUITests.swift:118 test_doseHistory_swipeActionsDuplicateDose(): XCTAssertTrue failed - Should have dose-history-list elements

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/DoseHistorySwipeActionsUITests.swift:174 test_doseHistory_swipeActionsSkipDose(): XCTAssertTrue failed - Should have dose-history-list elements

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/DoseHistorySwipeActionsUITests.swift:250 test_doseHistory_deleteConfirmationPreventsAccidentalDeletion(): XCTAssertTrue failed - Should have dose-history-list elements

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/MedicationProfileCalculatorUITests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/MedicationProfileCalculatorUITests.swift:84 testCalculatorBasicCalculation(): XCTAssertTrue failed

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/MedicationProfileScheduleUITests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/MedicationProfileScheduleUITests.swift:295 testCancelDeactivateSchedule(): XCTAssertNotNil failed - Cancel button should exist in confirmation dialog

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/PKEngineUITests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/PKEngineUITests.swift:637 testConcentrationCalculationPerformance(): XCTAssertLessThan failed: ("5.797552943229675") is not less than ("5.0") - Dashboard navigation and concentration display should complete within 5 seconds

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SplitDoseIntegrationUITests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SplitDoseIntegrationUITests.swift:71 testQuickAddDoseShowsCorrectSplitDoseAmount(): XCTAssertTrue failed - Quick Dose sheet should appear after tapping + button

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUIBaseTests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUIBaseTests.swift:88 testBackNavigationDuringPurchaseFlow(): XCTAssertTrue failed - Should reach subscription screen after completing onboarding flow

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUIBaseTests.swift:88 testButtonStatesWhenNoProductsAvailable(): XCTAssertTrue failed - Should reach subscription screen after completing onboarding flow

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUIBaseTests.swift:88 testLoadingStatesDuringProductFetch(): XCTAssertTrue failed - Should reach subscription screen after completing onboarding flow

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUIBaseTests.swift:88 testMostPopularBadgeVisibility(): XCTAssertTrue failed - Should reach subscription screen after completing onboarding flow

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUIBaseTests.swift:88 testMultipleRestoreAttempts(): XCTAssertTrue failed - Should reach subscription screen after completing onboarding flow

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUIBaseTests.swift:88 testPurchaseCancellationFlow(): XCTAssertTrue failed - Should reach subscription screen after completing onboarding flow

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUIBaseTests.swift:88 testPurchasePendingState(): XCTAssertTrue failed - Should reach subscription screen after completing onboarding flow

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUIBaseTests.swift:88 testRapidPlanSwitching(): XCTAssertTrue failed - Should reach subscription screen after completing onboarding flow

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUIBaseTests.swift:88 testRestoreWithNoPreviousPurchases(): XCTAssertTrue failed - Should reach subscription screen after completing onboarding flow

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUIBaseTests.swift:88 testTermsAndPrivacyLinksInteraction(): XCTAssertTrue failed - Should reach subscription screen after completing onboarding flow

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUIBaseTests.swift:88 testVoiceOverNavigationThroughPricingCards(): XCTAssertTrue failed - Should reach subscription screen after completing onboarding flow

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUITests+Helpers.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUITests+Helpers.swift:59 testEnhancedSubscriptionPricingUI(): XCTAssertTrue failed - Should reach subscription screen after completing onboarding flow

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUITests+Helpers.swift:59 testSubscriptionRestoreFlow(): XCTAssertTrue failed - Should reach subscription screen after completing onboarding flow

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/SubscriptionUITests+Helpers.swift:59 testTrialCountdownAccuracyAfterPurchase(): XCTAssertTrue failed - Should reach subscription screen after completing onboarding flow

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/TitrationConfirmationDialogUITests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/TitrationConfirmationDialogUITests.swift:54 testTitrationDialogAppearsOnQuickDoseButtonTap(): XCTAssertTrue failed - Titration confirmation dialog should appear with Complete Now button for TODAY titration

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/TitrationConfirmationDialogUITests.swift:122 testCompleteNowUpdatesProfileAndShowsQuickDose(): XCTAssertTrue failed - Complete Now button should appear

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/TitrationConfirmationDialogUITests.swift:186 testRescheduleTitrationUpdatesDate(): XCTAssertTrue failed - Reschedule button should appear

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/TitrationConfirmationDialogUITests.swift:272 testRemindMeLaterThenShowsDialogAgain(): XCTAssertTrue failed - Remind Me Later button should appear

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/TitrationConfirmationDialogUITests.swift:346 testNoDialogForFutureTitrations(): XCTAssertTrue failed - Complete Now button should appear for TODAY titration

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/TitrationConfirmationDialogUITests.swift:404 testDialogShowsEarliestPendingTitration(): XCTAssertTrue failed - Dialog should appear for earliest titration

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/TitrationConfirmationDialogUITests.swift:492 testDialogHeightShowsFullContent(): XCTAssertTrue failed - Dialog title should be visible

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/Performance/ChartPerformanceUITests.swift
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/Performance/ChartPerformanceUITests.swift:92 testChartRenderingPerformance_30d(): XCTAssertLessThan failed: ("569.0610408782959") is not less than ("500.0") - 30d switch should be <500ms (actual: 569ms)

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/Performance/ChartPerformanceUITests.swift:166 testChartRenderingPerformance_90d(): XCTAssertLessThan failed: ("526.0670185089111") is not less than ("500.0") - 7d switch should be <500ms (actual: 526ms)

/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/Performance/ChartPerformanceUITests.swift:246 testChartRenderingPerformance_1y(): XCTAssertLessThan failed: ("582.3550224304199") is not less than ("500.0") - 7d switch should be <500ms after initial render (actual: 582ms)
