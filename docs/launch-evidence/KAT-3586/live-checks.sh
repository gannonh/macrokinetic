#!/bin/bash
# KAT-3586 live upgrade checks on a dedicated simulator.
#
# Seeds a real on-disk store with the `main` build, then upgrades to the branch build in each user state
# (signed in, signed out, Apple ID erased) and drives the branch with NoSignInLiveCheckUITests.
# Usage: live-checks.sh <udid> <main.app> <branch-derivedData> <output-dir> [all|lock]   (lock reruns 7 and 8 only)
#   <main.app>            Debug-iphonesimulator JabTracker.app built from main
#   <branch-derivedData>  derivedDataPath of `xcodebuild build-for-testing` on the branch
set -uo pipefail

UDID=$1 MAIN_APP=$2 BRANCH_DD=$3 OUT=$4 PHASE=${5:-all}
BUNDLE=com.gannonhall.JabTracker
mkdir -p "$OUT/shots" "$OUT/state"
RESULTS="$OUT/results.md"
: > "${RESULTS}.$PHASE" ; RESULTS="${RESULTS}.$PHASE"

log() { echo "$*" | tee -a "$RESULTS"; }
store() { echo "$(xcrun simctl get_app_container "$UDID" $BUNDLE data)/Library/Application Support"; }
counts() {
  local db="$(store)/default.store"
  for t in ZUSER ZDOSE ZMEDICATIONPROFILE ZNUTRITIONGOAL ZWEIGHTENTRY ZFOODENTRY; do
    printf '%s=%s ' "${t#Z}" "$(sqlite3 "$db" "select count(*) from $t")"
  done
}
user_row() { sqlite3 "$(store)/default.store" "select ZNAME, coalesce(ZAPPLEUSERID,'NULL'), ZHASCOMPLETEDONBOARDING from ZUSER" ; }
stop() { xcrun simctl terminate "$UDID" $BUNDLE 2>/dev/null; sleep 1; }
save_base() { rm -rf "$OUT/state/base"; mkdir -p "$OUT/state/base"; cp "$(store)"/default.store* "$OUT/state/base/"; }
restore_base() { stop; cp "$OUT/state/base"/default.store* "$(store)/"; }
shot() { xcrun simctl io "$UDID" screenshot "$OUT/shots/$1.png" >/dev/null 2>&1; }

run_ui() { # <name> <TestMethod> [env KEY=VAL...]
  local name=$1 method=$2; shift 2
  rm -rf "$OUT/$name.xcresult"
  env TEST_RUNNER_KAT3586_LIVE=1 "$@" xcodebuild test-without-building -scheme JabTracker \
    -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$BRANCH_DD" CODE_SIGNING_ALLOWED=NO \
    -disable-concurrent-destination-testing -parallel-testing-enabled NO \
    -only-testing:JabTrackerUITests/NoSignInLiveCheckUITests/$method \
    -resultBundlePath "$OUT/$name.xcresult" > "$OUT/$name.log" 2>&1
  local rc=$?
  xcrun xcresulttool export attachments --path "$OUT/$name.xcresult" --output-path "$OUT/shots/$name" >/dev/null 2>&1
  return $rc
}

verdict() { if [ "$1" = 0 ]; then echo PASS; else echo FAIL; fi; }

if [ "$PHASE" = all ]; then
# ---- Seed with main ------------------------------------------------------------------------------
xcrun simctl uninstall "$UDID" $BUNDLE 2>/dev/null
xcrun simctl install "$UDID" "$MAIN_APP"
xcrun simctl launch "$UDID" $BUNDLE --ui-testing --disable-cloudkit --seed-1-month-active >/dev/null
sleep 25; stop
save_base
log "## Seed (main build, --ui-testing --seed-1-month-active)"
log "counts: $(counts)"
log "user (name|appleUserId|onboarded): $(user_row)"
BASE_COUNTS="$(counts)"

# ---- Scenario 1: same flow on main and on the branch ------------------------------------------------
restore_base
sqlite3 "$(store)/default.store" "update ZUSER set ZAPPLEUSERID='001234.live-check'"
cp "$(store)"/default.store* "$OUT/state/" 2>/dev/null
xcrun simctl launch "$UDID" $BUNDLE --disable-cloudkit >/dev/null; sleep 8
shot "s01-main-existing-install"; stop
log ""; log "## 1. main, existing install (signed-in, no --ui-testing)"
log "main after launch: user row = $(user_row) (appleUserId erased by main's credential check; sign-in screen: see shots/s01-main-existing-install.png)"

# ---- Scenario 3: signed in -------------------------------------------------------------------------
restore_base
sqlite3 "$(store)/default.store" "update ZUSER set ZAPPLEUSERID='001234.live-check'"
BEFORE="$(counts)"
run_ui s03-signed-in testUpgradeOpensStraightIntoApp KAT3586_EXPECT_NAME="UI Test User"; RC=$?
AFTER="$(counts)"
log ""; log "## 3. upgrade, signed in: $(verdict $RC)"
log "before: $BEFORE"; log "after:  $AFTER"; log "user: $(user_row)"
[ "$BEFORE" = "$AFTER" ] && log "counts identical: PASS" || log "counts identical: FAIL"

# ---- Scenario 5: Apple ID already erased -----------------------------------------------------------
restore_base
sqlite3 "$(store)/default.store" "update ZUSER set ZAPPLEUSERID=NULL"
BEFORE="$(counts)"
run_ui s05-apple-id-erased testUpgradeOpensStraightIntoApp KAT3586_EXPECT_NAME="UI Test User"; RC=$?
AFTER="$(counts)"
log ""; log "## 5. upgrade, Apple ID erased: $(verdict $RC)"
log "before: $BEFORE"; log "after:  $AFTER"; log "user: $(user_row)"
[ "$BEFORE" = "$AFTER" ] && log "counts identical: PASS" || log "counts identical: FAIL"

# ---- Scenario 4: signed out (old logout deleted the User and cascaded doses/profiles/goals) ---------
restore_base
sqlite3 "$(store)/default.store" "delete from ZDOSE; delete from ZMEDICATIONPROFILE; delete from ZNUTRITIONGOAL; delete from ZUSER;"
BEFORE="$(counts)"
run_ui s04-signed-out testUpgradeOpensStraightIntoApp KAT3586_EXPECT_NAME="Not set"; RC=$?
AFTER="$(counts)"
log ""; log "## 4. upgrade, signed out: $(verdict $RC)"
log "before: $BEFORE"; log "after:  $AFTER"; log "user: $(user_row)"

# ---- Scenario 2: fresh install ---------------------------------------------------------------------
stop; xcrun simctl uninstall "$UDID" $BUNDLE
run_ui s02-fresh-install testFreshInstallReachesOnboarding; RC=$?
log ""; log "## 2. fresh install reaches onboarding: $(verdict $RC)"

fi

# ---- Scenarios 7 and 8: Face ID lock (signed-in data, lock toggled by the stored setting) -------------
xcrun simctl spawn "$UDID" notifyutil -s com.apple.BiometricKit.enrollmentChanged 1 >/dev/null 2>&1
xcrun simctl spawn "$UDID" notifyutil -p com.apple.BiometricKit.enrollmentChanged >/dev/null 2>&1
restore_base 2>/dev/null || { xcrun simctl install "$UDID" "$MAIN_APP"; restore_base; }
run_ui s07a-lock-on-relaunch testLockOnRelaunchIsLocked; RC=$?
log ""; log "## 7a. lock on, relaunch requires biometrics: $(verdict $RC)"

(while true; do xcrun simctl spawn "$UDID" notifyutil -p com.apple.BiometricKit_Sim.pearl.nomatch >/dev/null 2>&1; sleep 1; done) & NM=$!
run_ui s07b-lock-cancel testLockStaysLockedWhenBiometricsFail; RC=$?
kill $NM 2>/dev/null; wait $NM 2>/dev/null
log "## 7b. non-matching biometrics / cancel keeps it locked: $(verdict $RC)"

(while true; do xcrun simctl spawn "$UDID" notifyutil -p com.apple.BiometricKit_Sim.pearl.match >/dev/null 2>&1; sleep 1; done) & M=$!
run_ui s07c-lock-match testLockUnlocksOnMatchAndRelocksFromBackground; RC=$?
kill $M 2>/dev/null; wait $M 2>/dev/null
log "## 7c. match unlocks, background relocks: $(verdict $RC)"

run_ui s08-lock-off testLockOffRelaunchOpensDirectly; RC=$?
log "## 8. lock off, relaunch opens directly: $(verdict $RC)"

log ""; log "Final counts: $(counts)"
