---
name: ios-dev
description: iOS development patterns for Swift, SwiftUI, and SwiftData. Use when implementing iOS features, working with .swift files, project.yml, or XcodeGen projects. Covers SwiftUI patterns, SwiftData models, Swift Testing framework, XcodeGen workflow, and iOS build commands.
---

# iOS Development Skill

Use this skill when implementing iOS features using Swift, SwiftUI, and SwiftData with Test-Driven Development practices.

## iOS Test Commands

```bash
# Run unit tests
./scripts/test.sh unit 1 <TestClassName>

# Run all unit tests
./scripts/test.sh unit 1

# Run with coverage
./scripts/test.sh unit 1 --coverage

# Run E2E tests
./scripts/test.sh ui 1 <TestClassName>
```

## SwiftUI Patterns

- Use `@Observable` (iOS 17+), never `ObservableObject`
- Apply `@MainActor` to ViewModels and Services that touch UI
- Extract reusable components to separate files
- Keep functions under 30 lines
- Use `NavigationStack` for navigation architecture

## SwiftData Patterns

- Non-optional properties with sensible defaults
- Include `createdAt` and `updatedAt` timestamps
- Parent declares `@Relationship(inverse:)`, child uses plain property
- Test environment configuration:
  ```swift
  let configuration = ModelConfiguration(
      isStoredInMemoryOnly: true,
      cloudKitDatabase: .none
  )
  ```

## Swift Naming Conventions

| Type                | Convention        | Example               |
| ------------------- | ----------------- | --------------------- |
| Types/Classes       | PascalCase        | `UserViewModel`       |
| Variables/Functions | camelCase         | `currentUser`         |
| Constants           | camelCase         | `maxStreakCount`      |
| Protocols           | -able/-ing suffix | `Trackable`           |
| Files               | PascalCase        | `UserViewModel.swift` |

## XcodeGen Workflow

After adding any new Swift file, you MUST run:
```bash
xcodegen generate
```

New files won't appear in builds or tests until the project is regenerated.

## Build & Verification Commands

```bash
# Build project
./scripts/build.sh

# Run SwiftLint
swiftlint

# Full CI check
./scripts/check-all.sh --skip-ui
```

## iOS-Specific Critical Rules

1. **NSFaceIDUsageDescription**: Required in Info.plist before using LocalAuthentication
2. **CloudKit Test Environment**: Always disable CloudKit sync in tests
3. **iOS 26.1 Simulators**: Required for Xcode 26 to avoid SwiftData crashes
4. **Large Navigation Titles**: Use custom scrolling titles to avoid iOS 26.1 visual artifacts
5. **Lint violation exceptions**: To overide siwftlint violations, update or create a .swiftlint.yml in the file's directory. This is easier to manage than inline overrides.
