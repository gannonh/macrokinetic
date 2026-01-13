# Issues

Deferred issues discovered during development.

## Open Issues

None.

---

## Resolved Issues

### ISS-001: Search button tap target misaligned in ShortcutsSheet

**Discovered:** Phase 35.1, Task 3 verification
**Resolved:** Phase 38, Plan 01 (2026-01-13)
**Severity:** Low (UX polish)
**Description:** The Search button in the Add shortcuts sheet has a low tap target - tapping directly on the icon often doesn't register, but tapping below the icon works reliably.
**Location:** `JabTracker/Views/Shortcuts/ShortcutButton.swift`
**Fix:** Added `.contentShape(Rectangle())` to VStack inside Button to expand tap target to full button area including label.
**Commit:** `11d058a`
