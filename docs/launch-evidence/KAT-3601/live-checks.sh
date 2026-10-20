#!/bin/bash
# KAT-3601 live checks on a dedicated simulator, driven by DoseReminderLiveCheckUITests.
#
# iOS keeps pending notification requests in usernotificationsd's memory, so Debug builds launched with
# --dump-pending-notifications write the app's own pendingNotificationRequests() to Documents after every
# queue refresh. This script joins that list to the ScheduledDose rows in the store.
#
# Usage: live-checks.sh <udid> <derivedData> <out-dir> [check]   check: 1 | 1-main | 2 | 3 | 4 | all (default)
#   <derivedData>  derivedDataPath of `xcodebuild build-for-testing -scheme JabTracker` (Debug)
#   1-main         run against a main build that has this test file and the same dump block added
set -uo pipefail
U=$1 DD=$2 OUT=$3 CHECK=${4:-all}
B=com.gannonhall.JabTracker APP="$DD/Build/Products/Debug-iphonesimulator/JabTracker.app"
RUN=$(ls "$DD"/Build/Products/*.xctestrun | head -1)
mkdir -p "$OUT"

fresh() { # reinstall (resets notification permission) and seed a liraglutide (Victoza) 0.6 mg profile
  xcrun simctl terminate "$U" $B 2>/dev/null; xcrun simctl uninstall "$U" $B; xcrun simctl install "$U" "$APP"
  SIMCTL_CHILD_TEST_DATA_SEED=true SIMCTL_CHILD_TEST_DATA_DAYS=1 SIMCTL_CHILD_TEST_DATA_MEDICATION=liraglutide \
    SIMCTL_CHILD_TEST_DATA_BRAND=Victoza SIMCTL_CHILD_TEST_DATA_DOSE=0.6 \
    xcrun simctl launch "$U" $B --ui-testing --reset-app-data >/dev/null
  sleep 15; xcrun simctl terminate "$U" $B
}

ui() { # <name> <method> [extra env]
  local name=$1 method=$2; shift 2
  rm -rf "$OUT/$name.xcresult"
  env TEST_RUNNER_KAT3601_LIVE=1 "$@" perl -e 'alarm shift; exec @ARGV' 400 \
    xcodebuild test-without-building -xctestrun "$RUN" -destination "platform=iOS Simulator,id=$U" \
    -parallel-testing-enabled NO -only-testing:JabTrackerUITests/DoseReminderLiveCheckUITests/$method \
    -resultBundlePath "$OUT/$name.xcresult" > "$OUT/$name.log" 2>&1
  xcrun xcresulttool export attachments --path "$OUT/$name.xcresult" --output-path "$OUT/$name-attachments" >/dev/null 2>&1
  if grep -q "Test Case.*$method.*passed" "$OUT/$name.log"; then echo "$name: PASS"; else
    echo "$name: FAIL"; grep -E "error:" "$OUT/$name.log" | head -3; fi
  grep -h "KAT3601" "$OUT/$name.log" | grep -v "Test Case" | head -3
}

pending() { # <label>: pending requests joined to ScheduledDose rows, plus counts
  local data; data=$(xcrun simctl get_app_container "$U" $B data)
  local file="$data/Documents/pending-notifications.tsv"
  echo "[$1] now $(date '+%Y-%m-%d %H:%M %Z'); list written $(stat -f '%Sm' -t '%H:%M:%S' "$file" 2>/dev/null || echo never)"
  [ -f "$file" ] || { echo "[$1] no pending list"; return; }
  python3 - "$file" "$data/Library/Application Support/default.store" "$OUT/pending-$1.tsv" "$1" <<'PY'
import sys, sqlite3, uuid
src, db, out, label = sys.argv[1:]
rows = {str(uuid.UUID(bytes=zid)).upper(): (amt, t) for zid, amt, t in sqlite3.connect(db).execute(
    "select ZID, ZDOSEAMOUNT, datetime(ZSCHEDULEDTIME+978307200,'unixepoch','localtime') from ZSCHEDULEDDOSE")}
lines = [l.split('\t') for l in open(src).read().splitlines() if l]
with open(out, 'w') as o:
    o.write("fire_time\tcategory\tidentifier\ttitle\tdose_amount_mg\tdose_time\n")
    for l in lines:
        o.write('\t'.join(l + [str(x) for x in rows.get(l[2], ('', ''))]) + '\n')
dose = [l for l in lines if l[1] == 'DOSE_REMINDER']
renewal = [l[0] for l in lines if l[2] == 'dose-reminders-renewal']
amounts = sorted({str(rows.get(l[2], ('no row',))[0]) for l in dose})
span = f"first {dose[0][0]}, last {dose[-1][0]}" if dose else "none"
print(f"[{label}] total {len(lines)}, dose reminders {len(dose)} ({span}), renewal {renewal or 'none'}, "
      f"amounts {amounts}, ScheduledDose rows {len(rows)}")
PY
}

refresh_log() { # NotificationService refreshes in the last <minutes>
  xcrun simctl spawn "$U" log show --last "${1}m" --info --predicate \
    'subsystem == "com.gannonhall.JabTracker" AND category == "NotificationService" AND (eventMessage CONTAINS "Refreshing notification queue" OR eventMessage CONTAINS "state loaded")' \
    2>/dev/null | awk 'NR>1 {print $2, substr($0, index($0, "NotificationService]") + 21)}'
}

tap() { # <name>: deliver a DOSE_REMINDER for the first pending dose ~25 s in, then tap its banner
  local id token
  id=$(awk -F'\t' '$2=="DOSE_REMINDER"{print $3; exit}' "$(ls -t "$OUT"/pending-*.tsv | head -1)")
  token="Live check $(date +%H%M%S)"
  printf '{"Simulator Target Bundle":"%s","aps":{"alert":{"title":"Time for your dose","body":"%s"},"category":"DOSE_REMINDER"},"scheduledDoseId":"%s"}' \
    $B "$token" "$id" > "$OUT/$1.apns"
  echo "[$1] reminder for dose $id; app running: $(xcrun simctl spawn "$U" launchctl list | grep -c "UIKitApplication:$B")"
  (sleep 25; xcrun simctl push "$U" $B "$OUT/$1.apns" >/dev/null) &
  ui "$1" testTapDeliveredReminderOpensItsDose TEST_RUNNER_KAT3601_PUSH_TOKEN="$token"; wait
  xcrun simctl spawn "$U" log show --last 2m --info --predicate \
    'subsystem == "com.gannonhall.JabTracker" AND (eventMessage CONTAINS "notification response" OR eventMessage CONTAINS "QuickDoseSheet for dose")' \
    2>/dev/null | awk 'NR>1 {print "  " $2, substr($0, index($0, "] ") + 2)}'
}

case $CHECK in 1|1-main|all)
  fresh; ui c1-enable testCreateDailyScheduleAndAllowReminders; pending c1-enable
  ui c1-relaunch testTurnRemindersOffAndOn; pending c1-relaunch ;;
esac
case $CHECK in 2|all)
  ui c2-pause testPauseScheduleForAWeek; pending c2-paused
  ui c2-resume testResumeSchedule; pending c2-resumed
  ui c2-foreground testBackgroundAndForeground; pending c2-foreground; refresh_log 1 ;;
esac
case $CHECK in 3|all)
  xcrun simctl launch "$U" $B --dump-pending-notifications >/dev/null; sleep 8
  pending c3-before
  xcrun simctl launch "$U" com.apple.Preferences >/dev/null; sleep 2; tap c3-warm
  xcrun simctl terminate "$U" $B; xcrun simctl terminate "$U" com.apple.Preferences 2>/dev/null; tap c3-cold ;;
esac
case $CHECK in 4|all)
  fresh; ui c4-denied testDeniedPermissionRecoversFromSettings; pending c4-recovered ;;
esac
