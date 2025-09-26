# CLAUDE.md

> Think carefully and implement the most concise solution that changes as little code as possible.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## USE SUB-AGENTS FOR CONTEXT OPTIMIZATION

### 1. Always use the file-analyzer sub-agent when asked to read files.

The file-analyzer agent is an expert in extracting and summarizing critical information from files, particularly log files and verbose outputs. It provides concise, actionable summaries that preserve essential information while dramatically reducing context usage.

### 2. Always use the code-analyzer sub-agent when asked to search code, analyze code, research bugs, or trace logic flow.

The code-analyzer agent is an expert in code analysis, logic tracing, and vulnerability detection. It provides concise, actionable summaries that preserve essential information while dramatically reducing context usage.

## Philosophy

### Error Handling

- **Fail fast** for critical configuration (missing text model)
- **Log and continue** for optional features (extraction model)
- **Graceful degradation** when external services unavailable
- **User-friendly messages** through resilience layer

### Testing

- Always practice TDD (Test Driven Development).
- Do not use mock services for anything ever.
- Do not move on to the next test until the current test is complete.
- If the test fails, consider checking if the test is structured correctly before deciding we need to refactor the codebase.
- Tests to be verbose so we can use them for debugging.

## Tone and Behavior

- Criticism is welcome. Please tell me when I am wrong or mistaken, or even when you think I might be wrong or mistaken.
- Please tell me if there is a better approach than the one I am taking.
- Please tell me if there is a relevant standard or convention that I appear to be unaware of.
- Be skeptical.
- Be concise.
- Short summaries are OK, but don't give an extended breakdown unless we are working through the details of a plan.
- Do not flatter, and do not give compliments unless I am specifically asking for your judgement.
- Occasional pleasantries are fine.
- Feel free to ask many questions. If you are in doubt of my intent, don't guess. Ask.

## ABSOLUTE RULES:

- NO PARTIAL IMPLEMENTATION
- NO SIMPLIFICATION : no "//This is simplified stuff for now, complete implementation would blablabla"
- NO CODE DUPLICATION : check existing codebase to reuse functions and constants Read files before writing new functions. Use common sense function name to find them easily.
- NO DEAD CODE : either use or delete from codebase completely
- IMPLEMENT TEST FOR EVERY FUNCTIONS
- NO CHEATER TESTS : test must be accurate, reflect real usage and be designed to reveal flaws. No useless tests! Design tests to be verbose so we can use them for debuging.
- NO INCONSISTENT NAMING - read existing codebase naming patterns.
- NO OVER-ENGINEERING - Don't add unnecessary abstractions, factory patterns, or middleware when simple functions would work. Don't think "enterprise" when you need "working"
- NO MIXED CONCERNS - Don't put validation logic inside API handlers, database queries inside UI components, etc. instead of proper separation
- NO RESOURCE LEAKS - Don't forget to close database connections, clear timeouts, remove event listeners, or clean up file handles

## Project Management

@.claude/rules/pm-system.md

## Project context

### Essential Context

1. High-level understanding of the project: @.claude/context/product-context.md
2. Core purpose and goals: @.claude/context/project-brief.md
3. Technical stack and dependencies: @.claude/context/tech-context.md
4. Testing framework and setup: @.claude/context/testing-config.md

### Current State

5. Current status and recent work: @.claude/context/progress.md
6. Project structure: @.claude/context/project-structure.md

### Deep Context

7. Architecture and design patterns: @.claude/context/system-patterns.md
8. User needs and requirements: @.claude/context/product-context.md
9. Coding conventions: @.claude/context/project-style-guide.md
10. Long-term direction: @.claude/context/project-vision.md
11. Common workflows and commands: @.claude/context/development-commands.md

## Security Implementation Guidelines

- Never log sensitive authentication credentials in production code
- Store Apple ID credentials securely in Keychain with proper access controls
- Implement biometric authentication with proper fallback to device passcode
- Handle authentication errors gracefully with user-friendly guidance messages
- Clear authentication state properly on sign out to prevent credential leakage
- Use `@MainActor` for authentication UI updates to ensure thread safety
- Validate authentication state on app launch for proper flow control
- Implement test authentication bypass for reliable UI testing

# Technical Learnings & Best Practices

## Authentication Testing Patterns
- Use `--ui-testing` launch argument for predictable test authentication
- Reset app data with `--reset-app-data` for clean test states
- Mock authentication in UI tests to avoid Apple ID dependencies
- Separate test user creation for isolated test scenarios
- Handle biometric authentication differently in test vs production
- Use environment variables to differentiate test behavior
- UserDefaults can be unreliable in UI tests - use in-memory storage when needed

## CloudKit + SwiftData Integration
- Always implement graceful fallback when CloudKit is unavailable
- Check for test environment before enabling CloudKit to avoid test conflicts
- Use `@Published` properties for real-time sync status updates
- Provide clear user feedback about sync status with actionable guidance

## Testing Framework Migration
- Swift Testing provides cleaner, more modern test syntax than XCTest
- xcbeautify offers better Swift Testing output support than xcpretty
- Never use `CODE_SIGNING_ALLOWED=NO` for UI tests - prevents app launch
- File-based test organization improves maintainability

## Info.plist Configuration
- Custom Info.plist required for CloudKit background notifications
- `remote-notification` background mode essential for CloudKit push notifications
- XcodeGen's auto-generated Info.plist doesn't handle all CloudKit requirements

## Development Tooling
- xcbeautify > xcpretty for modern Xcode output formatting
- Clean DerivedData resolves filesystem/result bundle issues
- Comprehensive pre-merge checks prevent integration issues

## XcodeGen Workflow
- **CRITICAL**: Always run `xcodegen generate` after adding new Swift files
- Project uses XcodeGen for automatic project file management
- New test files won't appear in test runs until project is regenerated
- Auto-includes all Swift files in respective directories (JabTracker/, JabTrackerTests/, JabTrackerUITests/)

## Authentication Implementation Gotchas
- Biometric authentication simulator limitations - test on real devices for accuracy
- UserDefaults can be unreliable in UI tests - use in-memory storage when needed
- Authentication state must be checked on app launch for proper flow control
- Face ID prompt timing can cause test flakiness - add appropriate waits and timeouts
- Environment variables and launch arguments are key for test/production differentiation
- Always provide authentication bypass for UI testing to avoid external dependencies
- Keychain access can fail in test scenarios - implement proper error handling

## SwiftData Model Design Best Practices
- **Avoid All-Optional Properties**: Make required fields non-optional with sensible defaults
- **Use Proper Relationship Attributes**: Always specify `@Relationship` with appropriate `inverse` and `deleteRule`
- **Include Apple ID Linking**: Add `appleUserId` field for Sign in with Apple authentication
- **Provide Sensible Defaults**: Use defaults like `UUID()`, `Date()`, and reasonable values for required fields
- **Maintain Audit Trail**: Include `createdAt` and `updatedAt` timestamps for all models
- **Test Model Relationships**: Comprehensive testing of SwiftData relationships prevents runtime issues
- **Use `final` Classes**: Mark SwiftData model classes as `final` for better performance
- **Explicit Default Values**: Set explicit defaults (`= nil`, `= ""`, `= 0.0`) for clarity and consistency

## Code Quality Improvement Patterns
- **Consolidate Duplicate Code**: Look for similar methods and consolidate them (e.g., duplicate sign-in handlers)
- **Remove Unsafe Force Unwrapping**: Replace `fatalError` with graceful error handling in production code
- **Conditional Debug Logging**: Use `#if DEBUG` for development-only console output
- **Model Validation**: Ensure required fields have appropriate defaults rather than optionals
- **Authentication Flow Simplification**: Reduce complexity by consolidating authentication state handling
- **Relationship Configuration**: Fix missing `@Relationship` attributes that cause sync and cascade issues

## SwiftData Model Architecture Lessons
- All-optional model properties create runtime uncertainty and complex nil-checking throughout the app
- Required fields should have non-optional types with sensible defaults to prevent crashes
- Missing authentication linking fields (`appleUserId`) cause integration issues with Sign in with Apple
- Proper relationship configuration with `inverse` prevents cascade delete and CloudKit sync problems
- Code quality improvements often reveal architectural inconsistencies that need addressing
- Medical apps require especially careful data modeling - weight, doses, timestamps must be reliable
- Audit trails (`createdAt`, `updatedAt`) are essential for debugging and data integrity
- Default values should be meaningful - empty strings for required text, sensible numbers for medical data

## Architectural Lessons Learned
- All-optional SwiftData models create unnecessary complexity and runtime uncertainty
- Missing relationship configurations cause CloudKit sync and cascade delete issues
- Authentication flows can accumulate duplicate code that needs regular consolidation
- Medical apps need especially reliable data models with meaningful defaults
- Code quality analysis reveals architectural decisions that need documentation

## User Onboarding Implementation Patterns
- **Step-Based Navigation**: Use enum-driven state machines for multi-step flows (OnboardingStep enum with computed properties)
- **Coordinator Pattern**: Separate navigation logic (OnboardingCoordinator) from business logic (OnboardingViewModel)
- **Testing Arguments**: Command-line arguments are essential for reliable UI testing (`--force-onboarding`, `--ui-testing`)
- **Permission Flow**: Always explain value proposition before requesting permissions (notifications, HealthKit)
- **State Persistence**: Use UserDefaults for completion tracking, SwiftData for user-generated content
- **Medical Data Modeling**: Enum-based medication system with computed properties ensures data consistency and medical accuracy

# Reminders
- Use NavigationStack instead of NavigationView: https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types
- Always test iCloud sync scenarios: available, unavailable, not signed in
- Swift Testing framework docs: https://developer.apple.com/documentation/testing
- XcodeBuildMCP provides a range of useful tools for working with the project.
- Simulator name always includes OS: `iPhone 15,OS=17.5`
- **Medical accuracy is critical** - validate all calculations and dose ranges
