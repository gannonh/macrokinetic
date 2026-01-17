---
created: 2026-01-17T12:24
title: Add clear day to food log context menu
area: ui
files:
  - JabTracker/Views/FoodLog/
---

## Problem

Users need a quick way to clear all food entries for a day. Currently there's no bulk delete option, requiring manual deletion of each entry.

## Solution

Add "Clear Day" option to the long-press context menu on the food log. Include a confirmation dialog before deleting to prevent accidental data loss.
