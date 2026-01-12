# Issues

Deferred issues discovered during development.

## Open Issues

### ISS-001: Search button tap target misaligned in ShortcutsSheet

**Discovered:** Phase 35.1, Task 3 verification
**Severity:** Low (UX polish)
**Description:** The Search button in the Add shortcuts sheet has a low tap target - tapping directly on the icon often doesn't register, but tapping below the icon works reliably.
**Location:** `JabTracker/Views/Shortcuts/ShortcutsSheet.swift`
**Fix approach:** Adjust contentShape or button frame to center tap target on visible icon

---

## Resolved Issues

None yet.
