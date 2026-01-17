---
created: 2026-01-17T12:21
title: Fix food log delete button color
area: ui
files:
  - JabTracker/Views/FoodLog/
---

## Problem

On the food log screen, the swipe-to-delete action shows a teal delete button instead of red. Delete actions should use red to signal destructive intent per iOS conventions.

## Solution

Change the delete button background color from teal to red in the swipe action configuration.
