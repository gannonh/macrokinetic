# Roadmap: MacroKinetic v0.10.0

**Project:** MacroKinetic
**Milestone:** v0.10.0 Food Log Enhancements
**Created:** 2026-01-17
**Phases:** 4

## Overview

This roadmap delivers two complementary features to reduce repetitive food logging: copy/paste for duplicating existing meals, and food scheduling for recurring items. Copy/paste is a self-contained feature delivered in one phase. Food scheduling has natural dependencies requiring three phases: data model, user interface, and the auto-population engine.

## Phases

### Phase 44: Copy/Paste

**Goal:** Users can duplicate entire days or individual meals to save food logging time.
**Depends on:** Nothing (first phase)
**Requirements:** COPY-01, COPY-02, COPY-03, COPY-04, COPY-05

**Success Criteria:**
1. User can long-press a day header and copy all foods from that day
2. User can long-press a meal section and copy all foods from that meal
3. User can paste clipboard contents to current day with add/replace choice
4. Clipboard contents persist across navigation until app termination or new copy

**Plans:** 2 plans

Plans:
- [x] 44-01-PLAN.md — Clipboard service and data model
- [x] 44-02-PLAN.md — Context menus and paste dialog in FoodLogView

---

### Phase 45: Schedule Model

**Goal:** Data foundation exists for food scheduling with proper CloudKit sync.
**Depends on:** Nothing (can run parallel to Phase 44)
**Requirements:** SCHED-04, SCHED-05, SCHED-06, SCHED-07

**Success Criteria:**
1. FoodSchedule model persists schedule configuration (days, meals, quantity, dates)
2. Non-custom foods are automatically converted to custom foods when scheduling
3. One schedule per food enforced at data layer (update existing if schedule exists)
4. Schedule data syncs across devices via CloudKit

**Plans:** 2 plans

Plans:
- [x] 45-01-PLAN.md — FoodSchedule model and ScheduleConfiguration value types
- [x] 45-02-PLAN.md — FoodScheduleService CRUD and DataController registration

---

### Phase 46: Schedule UX

**Goal:** Users can create and manage food schedules from natural entry points.
**Depends on:** Phase 45 (schedule model)
**Requirements:** SCHED-01, SCHED-02, SCHED-03, SCHED-08, SCHED-09

**Success Criteria:**
1. User can swipe a food in Food Library to open schedule configuration
2. User can swipe a food in search results to open schedule configuration
3. User can tap "Schedule" action button in Food Detail view
4. Food Detail view shows current schedule status and allows edit/stop
5. Food Library "Scheduled" filter shows all foods with active schedules

**Plans:** 3 plans

Plans:
- [ ] 46-01-PLAN.md — Register FoodScheduleService, create ScheduleConfigSheet and ScheduleDayMealGrid
- [ ] 46-02-PLAN.md — Add Schedule swipe actions and button to entry points
- [ ] 46-03-PLAN.md — Add Scheduled tab to Food Library

---

### Phase 47: Auto-Population

**Goal:** Scheduled foods automatically appear in the daily food log.
**Depends on:** Phase 46 (schedule UX)
**Requirements:** SCHED-10, SCHED-11

**Success Criteria:**
1. At midnight, scheduled foods auto-populate for applicable day/meal combinations
2. Auto-populated entries appear in food log like normal entries
3. User can delete auto-populated entries (deletes entry, not schedule)
4. Missed days (app not opened) backfill when app launches

**Plans:** (created by /gsd:plan-phase)

---

## Progress

| Phase | Status | Completed |
|-------|--------|-----------|
| 44 - Copy/Paste | ✓ Complete | 2026-01-17 |
| 45 - Schedule Model | ✓ Complete | 2026-01-18 |
| 46 - Schedule UX | Planned | — |
| 47 - Auto-Population | Not started | — |

---

*Roadmap for milestone: v0.10.0 Food Log Enhancements*
*Created: 2026-01-17*
