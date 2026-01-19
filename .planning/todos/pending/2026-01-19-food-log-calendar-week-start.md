---
created: 2026-01-19T12:30
title: Change Food Log calendar week start to Monday
area: ui
files:
  - JabTracker/Views/FoodLog/FoodLogView.swift
---

## Problem

The Food Log weekly calendar uses Sunday-Saturday as its week boundary, but the rest of the app is normalized around Monday-Sunday (e.g., the Weekly Nutrition Hero). This inconsistency creates a confusing user experience where different parts of the app show different week boundaries.

## Solution

Update the Food Log calendar component to start weeks on Monday instead of Sunday, aligning with the Weekly Nutrition Hero and other weekly views in the app.
