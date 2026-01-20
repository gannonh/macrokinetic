# Requirements: MacroKinetic v0.10.0

**Defined:** 2026-01-17
**Core Value:** Reduce repetitive food logging through copy/paste and scheduled meals

## v1 Requirements

Requirements for v0.10.0 release. Each maps to roadmap phases.

### Copy/Paste

- [x] **COPY-01**: User can copy all foods from a day to clipboard
- [x] **COPY-02**: User can copy all foods from a single meal to clipboard
- [x] **COPY-03**: User can paste clipboard contents to current day/meal
- [x] **COPY-04**: On paste, user is prompted to add to existing or replace existing foods
- [x] **COPY-05**: Clipboard persists during session (until app terminates or new copy)

### Food Scheduling

- [x] **SCHED-01**: User can schedule a food from Food Library (swipe action)
- [x] **SCHED-02**: User can schedule a food from search results (swipe action)
- [x] **SCHED-03**: User can schedule a food from Food Detail view (action button)
- [x] **SCHED-04**: Non-custom foods are auto-converted to custom when scheduling
- [x] **SCHED-05**: Schedule configuration includes: days of week, meal types, quantity
- [x] **SCHED-06**: Schedule configuration includes optional start/end dates
- [x] **SCHED-07**: One schedule per food, supporting multiple day/meal combinations
- [x] **SCHED-08**: Schedule displays on Food Detail view and can be edited/stopped there
- [x] **SCHED-09**: Food Library has "Scheduled" filter showing all scheduled foods
- [ ] **SCHED-10**: Scheduled foods auto-populate at midnight for applicable days
- [ ] **SCHED-11**: User can delete auto-populated scheduled entries like normal food entries

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Multi-day paste picker | Simplicity — navigate then paste is cleaner |
| Skip/snooze scheduled meals | Complexity — just delete if unwanted |
| Meal templates library | Scheduling covers this use case |
| Cross-device clipboard sync | Session-only clipboard is sufficient for v1 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| COPY-01 | Phase 44 | Complete |
| COPY-02 | Phase 44 | Complete |
| COPY-03 | Phase 44 | Complete |
| COPY-04 | Phase 44 | Complete |
| COPY-05 | Phase 44 | Complete |
| SCHED-01 | Phase 46 | Complete |
| SCHED-02 | Phase 46 | Complete |
| SCHED-03 | Phase 46 | Complete |
| SCHED-04 | Phase 45 | Complete |
| SCHED-05 | Phase 45 | Complete |
| SCHED-06 | Phase 45 | Complete |
| SCHED-07 | Phase 45 | Complete |
| SCHED-08 | Phase 46 | Complete |
| SCHED-09 | Phase 46 | Complete |
| SCHED-10 | Phase 47 | Pending |
| SCHED-11 | Phase 47 | Pending |

**Coverage:**
- v1 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-01-17*
*Last updated: 2026-01-18 after Phase 46 completion*
