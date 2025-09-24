---
description: Use this command to enter complex prompts that may fail if entered directly into the prompt input.
argument-hint:
allowed-tools: 
---

STOP. The process should be:
1. Stub acceptance criteria for all tests to validate the feature we are creating (this is done)
2. Write 1 test: Start by using the debug utils to output the elements hierarchy
3. Verify the test passes
4. Refactor if needed
5. commit the test
6. Move to the next test

Given that, lets next focus on this failing test: testChartControlsAccessibility

✅ Chart accessibility label: 'Concentration Timeline Chart showing medication concentration over time'
    t =    59.23s Waiting 3.0s for "time-period-last week" Button to exist
    t =    60.26s     Checking `Expect predicate `existsNoRetry == 1` for object "time-period-last week" Button`
    t =    60.26s         Checking existence of `"time-period-last week" Button`
    t =    60.29s Checking existence of `"time-period-last month" Button`
    t =    60.32s Checking existence of `"time-period-last quarter" Button`
    t =    60.34s Checking existence of `"time-period-last year" Button`
    t =    60.35s Find the "time-period-last week" Button
    t =    60.39s Find the "time-period-last month" Button
    t =    60.42s Find the "time-period-last quarter" Button
    t =    60.44s Find the "time-period-last year" Button
    t =    60.46s Find the "time-period-last week" Button
/Users/gannonhall/dev/jab-tracker-ios/JabTrackerUITests/ChartControlsUITests.swift:195: error: -[JabTrackerUITests.ChartControlsUITests testChartControlsAccessibility] : XCTAssertEqual failed: ("Concentration Timeline Chart showing medication concentration over time") is not equal to ("Last Week") - Last Week button should have correct label

Do not assume the elemnts are missing. As always, they are not.