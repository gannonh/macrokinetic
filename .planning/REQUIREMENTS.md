# Requirements: MacroKinetic v0.10.0

**Defined:** 2026-01-17
**Core Value:** Reduce repetitive food logging through copy/paste and scheduled meals

## v1 Requirements

Requirements for v0.10.0 release. Each maps to roadmap phases.

### Copy/Paste

- [ ] **COPY-01**: User can copy all foods from a day to clipboard
- [ ] **COPY-02**: User can copy all foods from a single meal to clipboard
- [ ] **COPY-03**: User can paste clipboard contents to current day/meal
- [ ] **COPY-04**: On paste, user is prompted to add to existing or replace existing foods
- [ ] **COPY-05**: Clipboard persists during session (until app terminates or new copy)

### Food Scheduling

- [ ] **SCHED-01**: User can schedule a food from Food Library (swipe action)
- [ ] **SCHED-02**: User can schedule a food from search results (swipe action)
- [ ] **SCHED-03**: User can schedule a food from Food Detail view (action button)
- [ ] **SCHED-04**: Non-custom foods are auto-converted to custom when scheduling
- [ ] **SCHED-05**: Schedule configuration includes: days of week, meal types, quantity
- [ ] **SCHED-06**: Schedule configuration includes optional start/end dates
- [ ] **SCHED-07**: One schedule per food, supporting multiple day/meal combinations
- [ ] **SCHED-08**: Schedule displays on Food Detail view and can be edited/stopped there
- [ ] **SCHED-09**: Food Library has "Scheduled" filter showing all scheduled foods
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
| COPY-01 | Phase 44 | Pending |
| COPY-02 | Phase 44 | Pending |
| COPY-03 | Phase 44 | Pending |
| COPY-04 | Phase 44 | Pending |
| COPY-05 | Phase 44 | Pending |
| SCHED-01 | Phase 46 | Pending |
| SCHED-02 | Phase 46 | Pending |
| SCHED-03 | Phase 46 | Pending |
| SCHED-04 | Phase 45 | Pending |
| SCHED-05 | Phase 45 | Pending |
| SCHED-06 | Phase 45 | Pending |
| SCHED-07 | Phase 45 | Pending |
| SCHED-08 | Phase 46 | Pending |
| SCHED-09 | Phase 46 | Pending |
| SCHED-10 | Phase 47 | Pending |
| SCHED-11 | Phase 47 | Pending |

**Coverage:**
- v1 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-01-17*
*Last updated: 2026-01-17 after roadmap creation*
