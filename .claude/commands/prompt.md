Thanks. I changed it and rebuilt. When I go to analytics, it correctly loads the 30 day data, but when I navigate to 7d, that chart is empty and
  navigating back to 30 and it's still empty. Logs:

✅ Test data seeding complete:
   - Doses created: 5
   - Skipped doses: 0
   - Adherence: 100.0%
   - Seeding time: 28.7ms
🔍 OnboardingCoordinator: UI testing mode detected - bypassing onboarding
🔍 OnboardingCoordinator: UI testing mode detected - bypassing onboarding
🔍 ContentView: Tab changed from home to history
🔍 ContentView: Tab changed from history to analytics
🔄 Refreshing chart dataset for time period: last30Days
📈 Generating chart dataset - medicationProfiles count: 1
  🔍 DEBUG: Total doses in DB: 5
    - Dose 2025-10-01 00:11:23 +0000: medication=semaglutide, medicationID=457E9102
    - Dose 2025-09-24 00:11:23 +0000: medication=semaglutide, medicationID=457E9102
    - Dose 2025-09-17 00:11:23 +0000: medication=semaglutide, medicationID=457E9102
  🔍 DEBUG: Querying for profileID=457E9102, genericName=semaglutide
  📦 Profile semaglutide: 5 doses in last30Days
  ✅ Total profiles with doses: 1
📊 Chart dataset updated: Last Month
fopen failed for data file: errno = 2 (No such file or directory)
Errors found! Invalidating cache...
fopen failed for data file: errno = 2 (No such file or directory)
Errors found! Invalidating cache...
🔄 Refreshing chart dataset for time period: last7Days
📈 Generating chart dataset - medicationProfiles count: 1
  🔍 DEBUG: Total doses in DB: 5
    - Dose 2025-10-01 00:11:23 +0000: medication=semaglutide, medicationID=457E9102
    - Dose 2025-09-24 00:11:23 +0000: medication=semaglutide, medicationID=457E9102
    - Dose 2025-09-17 00:11:23 +0000: medication=semaglutide, medicationID=457E9102
  🔍 DEBUG: Querying for profileID=457E9102, genericName=semaglutide
  📦 Profile semaglutide: 1 doses in last7Days
  ✅ Total profiles with doses: 1
📊 Chart dataset updated: Last Week
🔄 Refreshing chart dataset for time period: last30Days
📈 Generating chart dataset - medicationProfiles count: 1
  🔍 DEBUG: Total doses in DB: 5
    - Dose 2025-10-01 00:11:23 +0000: medication=semaglutide, medicationID=457E9102
    - Dose 2025-09-24 00:11:23 +0000: medication=nil, medicationID=nil
    - Dose 2025-09-17 00:11:23 +0000: medication=nil, medicationID=nil
  🔍 DEBUG: Querying for profileID=457E9102, genericName=semaglutide
  📦 Profile semaglutide: 1 doses in last30Days
  ✅ Total profiles with doses: 1
📊 Chart dataset updated: Last Month

This is strange:
    - Dose 2025-09-24 00:11:23 +0000: medication=nil, medicationID=nil
    - Dose 2025-09-17 00:11:23 +0000: medication=nil, medicationID=nil