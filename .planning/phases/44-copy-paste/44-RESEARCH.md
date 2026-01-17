# Phase 44: Copy/Paste - Research

**Researched:** 2026-01-17
**Domain:** SwiftUI in-app clipboard, context menus, session state management
**Confidence:** HIGH

## Summary

This phase implements a copy/paste feature for food logging, allowing users to duplicate entire days or individual meals. The feature uses an **in-app session clipboard** (not the system UIPasteboard) that persists until app termination or a new copy operation.

The implementation involves:
1. A lightweight `FoodClipboardService` to hold copied food entry data
2. Context menus on meal section headers and day views for "Copy" actions
3. A confirmation dialog when pasting to choose "Add" or "Replace" behavior
4. Integration with existing `MealLogService` for creating duplicate entries

**Primary recommendation:** Use a simple `@Observable` service class for the clipboard state, attach `.contextMenu` modifiers to meal section headers and day views, and use `.confirmationDialog` for the paste action choice.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | Context menus, confirmation dialogs | Native framework, already in use |
| Observation | iOS 17+ | `@Observable` for clipboard state | Project convention per CONVENTIONS.md |
| SwiftData | iOS 17+ | FoodEntry model queries | Already managing food entries |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Foundation | N/A | Date/UUID handling | Creating copied entries with new timestamps |
| OSLog | N/A | Logging clipboard operations | Debug and info level logging |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| In-app clipboard | UIPasteboard | UIPasteboard persists across app launches, requires Codable serialization, overkill for session-only requirement |
| `@Observable` service | Environment key | Environment is heavier for simple state; service pattern matches codebase conventions |
| Context menu | Custom gesture recognizer | Context menu is standard iOS pattern, accessible, automatic haptic feedback |

**Installation:**
```bash
# No additional packages needed - all native frameworks
```

## Architecture Patterns

### Recommended Project Structure
```
JabTracker/
├── Services/
│   └── FoodClipboardService.swift     # NEW: Session clipboard state
├── Views/
│   └── FoodLog/
│       ├── FoodLogView.swift          # MODIFY: Add context menus, paste dialog
│       ├── WeekCalendarStrip.swift    # MODIFY: Add context menu to day cells
│       └── MealSectionHeader.swift    # NEW: Extract header for context menu
└── Models/
    └── ClipboardContent.swift         # NEW: Copied data structure
```

### Pattern 1: Session Clipboard Service

**What:** An `@Observable` class holding optional clipboard content, cleared on new copy or app termination (natural lifecycle).

**When to use:** For transient, session-only data that needs to be accessible from multiple views.

**Example:**
```swift
// Source: Project conventions + SwiftUI @Observable pattern
import Foundation
import OSLog

/// Content types that can be copied to the food clipboard
enum FoodClipboardContent: Equatable {
    case day(date: Date, entries: [ClipboardEntry])
    case meal(date: Date, meal: MealSection, entries: [ClipboardEntry])

    var entryCount: Int {
        switch self {
        case .day(_, let entries), .meal(_, _, let entries):
            return entries.count
        }
    }
}

/// Lightweight snapshot of a FoodEntry for clipboard storage
struct ClipboardEntry: Equatable, Identifiable {
    let id = UUID()
    let foodId: UUID
    let foodName: String
    let foodBrand: String?
    let mealSection: MealSection
    let servingGrams: Double
    let servingDescription: String?
    let servingOptionsJSON: String
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let fiberPer100g: Double
    let notes: String?

    init(from entry: FoodEntry) {
        self.foodId = entry.foodId
        self.foodName = entry.foodName
        self.foodBrand = entry.foodBrand
        self.mealSection = entry.meal
        self.servingGrams = entry.servingGrams
        self.servingDescription = entry.servingDescription
        self.servingOptionsJSON = entry.servingOptionsJSON
        self.caloriesPer100g = entry.caloriesPer100g
        self.proteinPer100g = entry.proteinPer100g
        self.carbsPer100g = entry.carbsPer100g
        self.fatPer100g = entry.fatPer100g
        self.fiberPer100g = entry.fiberPer100g
        self.notes = entry.notes
    }
}

/// Session clipboard for food entries
/// Cleared automatically on app termination (normal lifecycle)
@MainActor
@Observable
final class FoodClipboardService {
    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "FoodClipboardService"
    )

    /// Current clipboard content (nil if empty)
    private(set) var content: FoodClipboardContent?

    /// Whether clipboard has content
    var hasContent: Bool { content != nil }

    /// Copy all entries from a day
    func copyDay(date: Date, entries: [FoodEntry]) {
        let clipboardEntries = entries.map { ClipboardEntry(from: $0) }
        content = .day(date: date, entries: clipboardEntries)
        Self.logger.info("Copied \(entries.count) entries from day")
    }

    /// Copy all entries from a meal section
    func copyMeal(date: Date, meal: MealSection, entries: [FoodEntry]) {
        let clipboardEntries = entries.map { ClipboardEntry(from: $0) }
        content = .meal(date: date, meal: meal, entries: clipboardEntries)
        Self.logger.info("Copied \(entries.count) entries from \(meal.displayName)")
    }

    /// Clear clipboard content
    func clear() {
        content = nil
        Self.logger.debug("Clipboard cleared")
    }
}
```

### Pattern 2: Context Menu on Section Headers

**What:** Attach `.contextMenu` to meal section headers for "Copy Meal" action.

**When to use:** When users need quick actions on grouped content.

**Example:**
```swift
// Source: SwiftUI contextMenu documentation + project patterns
private func mealSectionHeader(section: MealSection, totals: MealTotals) -> some View {
    HStack {
        // ... existing header content
    }
    .contextMenu {
        let entries = selectedDateEntries.filter { $0.meal == section }
        if !entries.isEmpty {
            Button {
                clipboardService.copyMeal(
                    date: selectedDate,
                    meal: section,
                    entries: entries
                )
            } label: {
                Label("Copy \(section.displayName)", systemImage: "doc.on.doc")
            }
        }
    }
}
```

### Pattern 3: Confirmation Dialog for Paste Action

**What:** Present a confirmation dialog with "Add to existing" or "Replace existing" options when pasting.

**When to use:** When an action has multiple valid outcomes that affect user data.

**Example:**
```swift
// Source: SwiftUI confirmationDialog documentation
.confirmationDialog(
    "Paste Foods",
    isPresented: $showingPasteDialog,
    titleVisibility: .visible
) {
    Button("Add to Existing") {
        Task { await pasteEntries(replacing: false) }
    }
    Button("Replace Existing", role: .destructive) {
        Task { await pasteEntries(replacing: true) }
    }
    Button("Cancel", role: .cancel) {}
} message: {
    if let content = clipboardService.content {
        Text("Paste \(content.entryCount) food items?")
    }
}
```

### Anti-Patterns to Avoid
- **Using UIPasteboard for session-only data:** UIPasteboard persists across app launches and requires Codable encoding. For session-only clipboard (COPY-05), a simple `@Observable` service is cleaner.
- **Storing SwiftData objects directly in clipboard:** SwiftData model objects are tied to their ModelContext. Store lightweight snapshots (ClipboardEntry) instead.
- **Adding context menu to entire List section:** Attach context menu to the header view specifically, not the entire Section, for better UX.
- **Copying by reference:** Always create new UUIDs and timestamps when pasting to avoid data corruption.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Long-press menu | Custom gesture + popover | `.contextMenu` modifier | Built-in haptics, accessibility, consistent iOS UX |
| Action choice modal | Custom bottom sheet | `.confirmationDialog` modifier | Platform-appropriate presentation, automatic cancel button |
| Session state | UserDefaults or singleton with manual lifecycle | `@Observable` service in AppServices | Clean lifecycle, testable, matches project patterns |
| Date filtering | Manual loop/filter | MealLogService.getEntries(for:) | Already implemented, includes proper date boundary handling |

**Key insight:** SwiftUI provides first-class support for context menus and confirmation dialogs. These are well-tested, accessible, and match iOS conventions. Custom implementations would duplicate effort and likely miss edge cases.

## Common Pitfalls

### Pitfall 1: SwiftData Object Lifecycle
**What goes wrong:** Copying FoodEntry objects directly into clipboard, then app crashes when pasting because objects were deallocated with their ModelContext.
**Why it happens:** SwiftData model objects are tied to their ModelContext. When the context changes (e.g., different query), cached objects become invalid.
**How to avoid:** Create lightweight `ClipboardEntry` structs that capture all needed values. Only create new FoodEntry objects during paste operation.
**Warning signs:** EXC_BAD_ACCESS when accessing clipboard content, especially after navigation.

### Pitfall 2: Date Handling on Paste
**What goes wrong:** Pasted entries appear on wrong day or with original timestamps.
**Why it happens:** Copying loggedAt directly instead of updating to target date.
**How to avoid:** When pasting, use the target date for `loggedAt` while preserving meal section. Calculate new date: target day + original meal's time-of-day hint.
**Warning signs:** Entries show on calendar for wrong day, or appear out of order in day view.

### Pitfall 3: Empty Context Menu
**What goes wrong:** Context menu doesn't appear on empty meal sections or days with no entries.
**Why it happens:** No content means nothing to copy, but users might expect paste option.
**How to avoid:** Show "Paste" option in context menu when clipboard has content, even on empty sections. Only hide "Copy" when there's nothing to copy.
**Warning signs:** User confusion about where to find paste action.

### Pitfall 4: Replace Action Data Loss
**What goes wrong:** "Replace" action deletes entries before paste completes, losing data on failure.
**Why it happens:** Performing delete and insert as separate operations without transaction.
**How to avoid:** When replacing, insert new entries first, then delete old entries, all in same save operation. Or wrap in do-catch to rollback on failure.
**Warning signs:** Entries disappear without new ones appearing, especially on poor network (CloudKit sync).

### Pitfall 5: Context Menu on Section vs Header
**What goes wrong:** Long-pressing anywhere in the meal section triggers copy, including on individual food items.
**Why it happens:** Context menu attached to Section view instead of just the header.
**How to avoid:** Extract meal section header into separate view, attach context menu to header only. Food items already have swipe actions.
**Warning signs:** Conflicting gestures, copy menu appearing when trying to swipe an item.

## Code Examples

Verified patterns from official sources and project conventions:

### Creating FoodEntry from Clipboard
```swift
// Source: Existing FoodEntry model pattern + MealLogService
extension MealLogService {
    /// Paste clipboard entries to a target date
    /// - Parameters:
    ///   - entries: Clipboard entries to paste
    ///   - targetDate: Date to log entries on
    ///   - targetMeal: Optional meal section override (for meal-to-meal paste)
    ///   - replacing: Whether to delete existing entries first
    func pasteEntries(
        _ entries: [ClipboardEntry],
        to targetDate: Date,
        targetMeal: MealSection? = nil,
        replacing: Bool
    ) async throws {
        let calendar = Calendar.current

        // If replacing, get existing entries to delete
        var entriesToDelete: [FoodEntry] = []
        if replacing {
            if let meal = targetMeal {
                let existing = try await getEntries(for: targetDate)
                entriesToDelete = existing.filter { $0.meal == meal }
            } else {
                entriesToDelete = try await getEntries(for: targetDate)
            }
        }

        // Create new entries from clipboard
        for clipboardEntry in entries {
            let newEntry = FoodEntry(
                foodId: clipboardEntry.foodId,
                foodName: clipboardEntry.foodName,
                foodBrand: clipboardEntry.foodBrand,
                mealSection: targetMeal ?? clipboardEntry.mealSection,
                loggedAt: targetDate,
                servingGrams: clipboardEntry.servingGrams,
                servingDescription: clipboardEntry.servingDescription,
                servingOptionsJSON: clipboardEntry.servingOptionsJSON,
                caloriesPer100g: clipboardEntry.caloriesPer100g,
                proteinPer100g: clipboardEntry.proteinPer100g,
                carbsPer100g: clipboardEntry.carbsPer100g,
                fatPer100g: clipboardEntry.fatPer100g,
                fiberPer100g: clipboardEntry.fiberPer100g,
                notes: clipboardEntry.notes
            )
            context.insert(newEntry)
        }

        // Delete old entries (after inserts to prevent data loss)
        for entry in entriesToDelete {
            context.delete(entry)
        }

        try context.save()
        notifyDataChanged()

        Self.logger.info(
            "Pasted \(entries.count) entries, deleted \(entriesToDelete.count)"
        )
    }
}
```

### Context Menu with Conditional Items
```swift
// Source: SwiftUI contextMenu documentation
.contextMenu {
    // Copy option (only when there's content)
    if !entries.isEmpty {
        Button {
            clipboardService.copyMeal(
                date: selectedDate,
                meal: section,
                entries: entries
            )
        } label: {
            Label("Copy \(entries.count) Items", systemImage: "doc.on.doc")
        }
    }

    // Paste option (only when clipboard has content)
    if clipboardService.hasContent {
        Button {
            showingPasteDialog = true
        } label: {
            Label("Paste", systemImage: "doc.on.clipboard")
        }
    }
}
```

### Paste State Management in FoodLogView
```swift
// Source: Project patterns from FoodLogView.swift
// State for paste confirmation
@State private var showingPasteDialog = false
@State private var pasteTargetMeal: MealSection?

// Confirmation dialog at view level
.confirmationDialog(
    "Paste Foods",
    isPresented: $showingPasteDialog,
    titleVisibility: .visible
) {
    Button("Add to Existing") {
        Task {
            await performPaste(replacing: false)
        }
    }
    Button("Replace Existing", role: .destructive) {
        Task {
            await performPaste(replacing: true)
        }
    }
    Button("Cancel", role: .cancel) {
        pasteTargetMeal = nil
    }
} message: {
    pasteDialogMessage
}

private var pasteDialogMessage: Text {
    guard let content = clipboardService?.content else {
        return Text("Paste foods")
    }
    let count = content.entryCount
    let target = pasteTargetMeal?.displayName ?? "today"
    return Text("Paste \(count) \(count == 1 ? "item" : "items") to \(target)?")
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` | `@Observable` macro | iOS 17 (2023) | Simpler state management, no @StateObject needed |
| `.actionSheet()` | `.confirmationDialog()` | iOS 15 (2021) | Modern API, better accessibility |
| Custom long-press gesture | `.contextMenu` modifier | iOS 13 (2019) | Consistent platform behavior |

**Deprecated/outdated:**
- `UIPasteboard` for in-app data transfer: Only needed for cross-app clipboard or persistent paste. Session clipboard should use in-memory state.
- `.actionSheet()`: Replaced by `.confirmationDialog()` in iOS 15+.

## Open Questions

Things that couldn't be fully resolved:

1. **Meal section header extraction**
   - What we know: Context menu needs to attach to header specifically, not entire section
   - What's unclear: Should header be separate file or private subview in FoodLogView?
   - Recommendation: Extract as private subview first, can promote to separate file if reused

2. **Paste target when copying day vs meal**
   - What we know: Copying a day includes all meals, copying a meal is one section
   - What's unclear: When pasting a copied day to a day, should meal sections be preserved? When pasting a meal to a day, which meal section?
   - Recommendation: Preserve original meal sections when pasting a day. When pasting a single meal, paste to same meal type on target day (or let user pick via context menu location).

3. **Haptic feedback on copy**
   - What we know: Context menu provides automatic haptic on long-press
   - What's unclear: Should there be additional confirmation haptic after copy completes?
   - Recommendation: Add `.sensoryFeedback(.success)` on successful copy for iOS 17+

## Sources

### Primary (HIGH confidence)
- SwiftUI contextMenu - [Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/contextmenu)
- SwiftUI confirmationDialog - [Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:presenting:actions:)-9ibgk)
- Project CONVENTIONS.md - `@Observable` patterns, service patterns
- Project ARCHITECTURE.md - Service layer design, AppServices pattern
- Existing FoodLogView.swift - Current meal section rendering, swipe actions
- Existing MealLogService.swift - Entry creation and deletion patterns

### Secondary (MEDIUM confidence)
- [Hacking with Swift - Context Menus](https://www.hackingwithswift.com/quick-start/swiftui/how-to-show-a-context-menu) - Usage examples and best practices
- [Swift with Majid - Confirmation Dialogs](https://swiftwithmajid.com/2021/07/28/confirmation-dialogs-in-swiftui/) - Advanced dialog patterns
- [iOS State Management 2025](https://zoewave.medium.com/new-swiftui-state-management-3a6c9b737724) - @Observable best practices

### Tertiary (LOW confidence)
- WebSearch results for food tracking app patterns - Limited specific examples found for meal duplication UX

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Using native SwiftUI components documented by Apple
- Architecture: HIGH - Follows existing project patterns exactly (services, @Observable, CONVENTIONS.md)
- Pitfalls: HIGH - Based on SwiftData documentation and existing codebase patterns
- UX patterns: MEDIUM - Context menu and confirmation dialog are standard, but specific meal copy/paste UX required some inference

**Research date:** 2026-01-17
**Valid until:** 2026-04-17 (90 days - stable patterns, unlikely to change)
