#!/bin/bash
# Hostile-input matrix against ordinary Release build on isolated simulator clone.
U=$(cat /tmp/jab-coord/controls/sim-udid.txt); BID=com.gannonhall.JabTracker
D=/tmp/jab-coord/controls; REL=$D/derived/Build/Products/Release-iphonesimulator/JabTracker.app
DBG=/private/tmp/jabtracker-launch-20260930/derived-test-controls/Build/Products/Debug-iphonesimulator/JabTracker.app
OUT=$D/matrix; rm -rf $OUT; mkdir -p $OUT/retained $OUT/fresh
# name|args|env(space separated K=V)
INPUTS=(
"baseline-none||"
"ui-testing-arg|--ui-testing|"
"ui-testing-env||UI_TESTING=true"
"reset-app-data|--reset-app-data|"
"manual-ui-testing|--manual-ui-testing|"
"bypass-onboarding|--bypass-onboarding|"
"force-onboarding|--force-onboarding|"
"seed-test-7d|--seed-test-7d|"
"seed-test-1y|--seed-test-1y|"
"seed-test-new-user|--seed-test-new-user|"
"seed-check-in-ready|--seed-check-in-ready|"
"seed-calorie-user|--seed-calorie-user|"
"seed-collaborative|--seed-collaborative|"
"seed-3-day-active|--seed-3-day-active|"
"test-titration-data|--test-titration-data|"
"test-data-env||TEST_DATA_SEED=true TEST_DATA_DAYS=7 TEST_DATA_DOSE=0.5 TEST_DATA_DOSE_COUNT=3 TEST_DATA_PROFILES=2"
"mock-active-energy|--mock-active-energy=350|"
"deeplink-url|--deeplink-url=jabtracker://dose|"
"disable-cloudkit|--disable-cloudkit|"
"cloudkit-testing|--cloudkit-testing|"
"inMemory|-inMemory|"
"food-search-fail-once|--food-search-fail-once|"
"storage-fixture|--storage-fixture=11111111-2222-3333-4444-555555555555 --storage-always-fail-open|"
"combined|--ui-testing --reset-app-data --bypass-onboarding --seed-test-1y --seed-calorie-user --mock-active-energy=350 -inMemory --disable-cloudkit --storage-always-fail-open|UI_TESTING=true TEST_DATA_SEED=true TEST_DATA_DAYS=30"
)
snap() { # $1 label dir -> writes counts + hash
  C=$(xcrun simctl get_app_container $U $BID data 2>/dev/null) || { echo "nocontainer"; return; }
  S="$C/Library/Application Support/default.store"
  T=$(mktemp -d); [ -f "$S" ] && cp "$S"* $T/ 2>/dev/null
  if [ -f $T/default.store ]; then
    for t in ZUSER ZDOSE ZFOODENTRY ZWEIGHTENTRY ZMEDICATIONPROFILE ZDOSESCHEDULE ZNUTRITIONGOAL ZMETRICSENTRY; do printf "%s=%s " $t "$(sqlite3 $T/default.store "select count(*) from $t" 2>/dev/null)"; done
    printf "hash=%s" "$(sqlite3 $T/default.store ".dump ZUSER" ".dump ZDOSE" ".dump ZMEDICATIONPROFILE" 2>/dev/null | md5)"
  else printf "NOSTORE"; fi
  rm -rf $T
}
run_one() { # mode name args env
  mode=$1; name=$2; args=$3; envs=$4
  xcrun simctl terminate $U $BID >/dev/null 2>&1
  envp=(); for kv in $envs; do envp+=("SIMCTL_CHILD_$kv"); done
  env "${envp[@]}" xcrun simctl launch $U $BID $args >/dev/null 2>&1
  sleep 7
  xcrun simctl io $U screenshot $OUT/$mode/$name.png >/dev/null 2>&1
  xcrun simctl terminate $U $BID >/dev/null 2>&1
  sleep 1
  echo "$mode|$name|$(md5 -q $OUT/$mode/$name.png)|$(snap)" | tee -a $OUT/results.txt
}
# Part A: retained fictional data from Debug seed
xcrun simctl uninstall $U $BID >/dev/null 2>&1
xcrun simctl install $U $DBG
xcrun simctl launch $U $BID --ui-testing --bypass-onboarding --seed-test-7d >/dev/null; sleep 15; xcrun simctl terminate $U $BID; sleep 1
echo "retained|BEFORE|-|$(snap)" | tee -a $OUT/results.txt
xcrun simctl install $U $REL
for row in "${INPUTS[@]}"; do IFS='|' read -r n a e <<< "$row"; run_one retained "$n" "$a" "$e"; done
echo "retained|AFTER|-|$(snap)" | tee -a $OUT/results.txt
# Part B: fresh install
for row in "${INPUTS[@]}"; do IFS='|' read -r n a e <<< "$row"
  xcrun simctl uninstall $U $BID >/dev/null 2>&1; xcrun simctl install $U $REL
  run_one fresh "$n" "$a" "$e"
done
xcrun simctl uninstall $U $BID >/dev/null 2>&1
echo DONE
