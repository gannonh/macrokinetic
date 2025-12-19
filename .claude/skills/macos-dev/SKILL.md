---
name: macos-dev
description: macOS development patterns for Swift, SwiftUI, and SwiftData. Use when implementing macOS features, working with .swift files, project.yml, or XcodeGen projects. Covers SwiftUI patterns, SwiftData models, Swift Testing framework, XcodeGen workflow, AppKit integration, and macOS build commands.
---

# macOS Development Skill

Use this skill when implementing macOS features using Swift, SwiftUI, and SwiftData with Test-Driven Development practices.

## macOS Test Commands

```bash
# Run unit tests
./scripts/test.sh unit 1 <TestClassName> --platform macos

# Run all unit tests
./scripts/test.sh unit 1 --platform macos

# Run with coverage
./scripts/test.sh unit 1 --coverage --platform macos

# Run E2E tests
./scripts/test.sh ui 1 <TestClassName> --platform macos
```

## SwiftUI Patterns (macOS)

- Use `@Observable` (macOS 14+), never `ObservableObject`
- Apply `@MainActor` to ViewModels and Services that touch UI
- Extract reusable components to separate files
- Keep functions under 30 lines
- Use `NavigationSplitView` for macOS sidebar navigation
- Support keyboard shortcuts with `.keyboardShortcut()` modifier
- Implement menu bar items when appropriate

## macOS Window Management

- Use `WindowGroup` for document-based or multi-window apps
- Use `Window` for single-instance utility windows
- Use `Settings` scene for Preferences window
- Configure window styles with `.windowStyle()` and `.windowToolbarStyle()`
- Support window resizing constraints with `.frame(minWidth:maxWidth:minHeight:maxHeight:)`

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
# Build project for macOS
./scripts/build.sh --platform macos

# Run SwiftLint
swiftlint

# Full CI check
./scripts/check-all.sh --skip-ui --platform macos
```

## macOS-Specific Critical Rules

1. **Sandboxing**: Enable App Sandbox for Mac App Store distribution
2. **Hardened Runtime**: Required for notarization
3. **Code Signing**: Use Developer ID for distribution outside App Store
4. **CloudKit Test Environment**: Always disable CloudKit sync in tests
5. **macOS 14+ Simulators**: Required for Xcode 26 to avoid SwiftData crashes
6. **Lint violation exceptions**: To override SwiftLint violations, update or create a .swiftlint.yml in the file's directory

## macOS-Specific Patterns

### Menu Bar & Toolbars
```swift
.commands {
    CommandGroup(replacing: .newItem) {
        Button("New Document") { }
            .keyboardShortcut("n", modifiers: .command)
    }
}
```

### Touch Bar Support (Legacy)
```swift
.touchBar {
    Button(action: { }) {
        Label("Action", systemImage: "star")
    }
}
```

### Drag and Drop
```swift
.onDrop(of: [.fileURL], isTargeted: nil) { providers in
    // Handle dropped files
    return true
}
```

### File Access (Sandboxed)
- Use `NSOpenPanel` and `NSSavePanel` for user-initiated file access
- Store security-scoped bookmarks for persistent access
- Request entitlements for specific file system locations

## AppKit Integration

When SwiftUI doesn't provide needed functionality:
```swift
struct AppKitView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { }
    func updateNSView(_ nsView: NSView, context: Context) { }
}
```

## Entitlements for Common Features

| Feature | Entitlement Key |
| ------- | --------------- |
| Network (outgoing) | `com.apple.security.network.client` |
| Network (incoming) | `com.apple.security.network.server` |
| File Access (user-selected) | `com.apple.security.files.user-selected.read-write` |
| Camera | `com.apple.security.device.camera` |
| Microphone | `com.apple.security.device.audio-input` |
| Location | `com.apple.security.personal-information.location` |
