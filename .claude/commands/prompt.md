Oh! I didnt realize this was only 5 days  of data. It isnt really a bug then is it?

I've made some changes to our project to support seeding different amopunts of data:

  Changes Made

  1. Updated project.yml

  - Removed --seed-test-data flag
  - Added four new flags: --seed-test-7d, --seed-test-30d, --seed-test-90d, --seed-test-1y
  - Set --seed-test-1y: true as the default for development

  2. Updated AuthenticationManager.swift

  - Modified seedTestDataIfRequested() to check for the new time period flags
  - Kept backward compatibility with environment variable approach for UI tests
  - Each flag sets the appropriate daysOfHistory:
    - --seed-test-7d → 7 days
    - --seed-test-30d → 30 days
    - --seed-test-90d → 90 days
    - --seed-test-1y → 365 days
  - Updated default adherence rate to 95% (more realistic than 100%)
  - Set default variability and skipped doses to true for more realistic data

  3. Regenerated Xcode Project

  - Ran xcodegen generate to apply the new launch arguments

We still have some performance issues but the data is working as expected. Please update the project with this new understanding.