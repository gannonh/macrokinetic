# UAT Issues: Phase 35 Plan 01

**Tested:** 2026-01-12
**Source:** .planning/phases/35-search-performance-ux/35-01-SUMMARY.md
**Tester:** User via /gsd:verify-work

## Open Issues

[None]

## Resolved Issues

### UAT-001: Search UI freezes/blocks during typing - appears synchronous

**Discovered:** 2026-01-12
**Phase/Plan:** 35-01
**Severity:** Blocker
**Feature:** Search debouncing
**Description:** When typing in the search field, spinners appear immediately on each keystroke and the entire UI blocks until the search completes. Typing feels like it's single-threaded synchronous - user types a letter, everything freezes until spinner completes, then can type next letter.
**Expected:** Fast, responsive typing with no UI blocking. Given the 1.7M+ food database is local SQLite FTS5, searches should be nearly instantaneous with no visible spinner needed.
**Actual:** UI freezes on each keystroke, spinner appears immediately, blocks all interaction until search completes.

**Resolved:** 2026-01-12 - Fixed in 35-01-FIX.md
**Root Cause:** Both FoodService and LocalFoodDatabase were @MainActor, forcing synchronous SQLite FTS5 queries on main thread
**Fix:** Moved database queries to background thread via Task.detached, removed unnecessary spinner
**Commits:** 924b344e (perf: move queries off main thread), a09b6fb7 (fix: remove spinner)

---

*Phase: 35-search-performance-ux*
*Plan: 01*
*Tested: 2026-01-12*
