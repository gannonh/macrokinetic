#!/bin/bash
# KAT-3613 live checks: dose reminder fire times across daylight-saving changes, on a dedicated simulator
# in America/Los_Angeles. Reuses DoseReminderLiveCheckUITests and the --dump-pending-notifications list
# from KAT-3601, joined to the ScheduledDose rows in the store.
#
# Usage: live-checks.sh <udid> <derivedData> <out-dir> <split|weekly>
#   <derivedData>  derivedDataPath of `xcodebuild build-for-testing -scheme JabTracker` (Debug)
#   For main, build main with this branch's DoseReminderLiveCheckUITests.swift applied.
set -uo pipefail
U=$1 DD=$2 OUT=$3 PATTERN=$4
B=com.gannonhall.JabTracker APP="$DD/Build/Products/Debug-iphonesimulator/JabTracker.app"
RUN=$(ls "$DD"/Build/Products/*.xctestrun | head -1)
mkdir -p "$OUT"

# Reinstall (resets notification permission) and seed a semaglutide (Ozempic) 1 mg weekly profile with an
# existing split (0.5 mg x 2) or weekly schedule
SPLIT=$([ "$PATTERN" = split ] && echo true || echo false)
xcrun simctl terminate "$U" $B 2>/dev/null; xcrun simctl uninstall "$U" $B; xcrun simctl install "$U" "$APP"
SIMCTL_CHILD_TEST_DATA_SEED=true SIMCTL_CHILD_TEST_DATA_DAYS=8 SIMCTL_CHILD_TEST_DATA_MEDICATION=semaglutide \
  SIMCTL_CHILD_TEST_DATA_BRAND=Ozempic SIMCTL_CHILD_TEST_DATA_DOSE=1.0 SIMCTL_CHILD_TEST_DATA_SPLIT_SCHEDULE=$SPLIT \
  xcrun simctl launch "$U" $B --ui-testing --reset-app-data >/dev/null
sleep 15; xcrun simctl terminate "$U" $B

ui() { # <name> <method>
  rm -rf "$OUT/$1.xcresult"
  env TEST_RUNNER_KAT3601_LIVE=1 perl -e 'alarm shift; exec @ARGV' 300 \
    xcodebuild test-without-building -xctestrun "$RUN" -destination "platform=iOS Simulator,id=$U" \
    -parallel-testing-enabled NO -only-testing:JabTrackerUITests/DoseReminderLiveCheckUITests/$2 \
    -resultBundlePath "$OUT/$1.xcresult" > "$OUT/$1.log" 2>&1
  xcrun xcresulttool export attachments --path "$OUT/$1.xcresult" --output-path "$OUT/$1-attachments" >/dev/null 2>&1
  if grep -q "Test Case.*$2.*passed" "$OUT/$1.log"; then echo "$1: PASS"; else echo "$1: FAIL"; fi
}

pending() { # <label>: pending list joined to ScheduledDose rows, then reminder counts per local weekday and time
  local data; data=$(xcrun simctl get_app_container "$U" $B data)
  python3 - "$data/Documents/pending-notifications.tsv" "$data/Library/Application Support/default.store" \
    "$OUT/pending-$1.tsv" "$1" <<'PY'
import sys, sqlite3, uuid, collections, datetime, zoneinfo
src, db, out, label = sys.argv[1:]
la = zoneinfo.ZoneInfo("America/Los_Angeles")
rows = {str(uuid.UUID(bytes=zid)).upper(): (amt, t) for zid, amt, t in sqlite3.connect(db).execute(
    "select ZID, ZDOSEAMOUNT, ZSCHEDULEDTIME from ZSCHEDULEDDOSE")}
local = lambda t: datetime.datetime.fromtimestamp(t + 978307200, la).strftime("%Y-%m-%d %a %H:%M %Z")
lines = [l.split('\t') for l in open(src).read().splitlines() if l]
dose = [l for l in lines if l[1] == 'DOSE_REMINDER']
with open(out, 'w') as o:
    o.write("fire_time\tcategory\tidentifier\tdose_amount_mg\tdose_time\n")
    for l in lines:
        amt, t = rows.get(l[2], ('', None))
        o.write('\t'.join([l[0], l[1], l[2], str(amt), local(t) if t else '']) + '\n')
if not dose:
    sys.exit(print(f"[{label}] total {len(lines)}, no dose reminders"))
times = collections.Counter()
for l in dose:
    stamp = datetime.datetime.strptime(l[0], "%Y-%m-%d %H:%M").replace(tzinfo=la)
    times[(stamp.strftime("%Z"), stamp.strftime("%a %H:%M"))] += 1
print(f"[{label}] total {len(lines)}, dose reminders {len(dose)} ({dose[0][0]} -> {dose[-1][0]}), "
      f"amounts {sorted({str(rows.get(l[2], ('no row',))[0]) for l in dose})}")
for (zone, slot), n in sorted(times.items()):
    print(f"[{label}]   {zone} {slot}: {n} reminders")
PY
}

ui allow testAllowRemindersForSeededSchedule; pending "$PATTERN-allow"
ui relaunch testBackgroundAndForeground; pending "$PATTERN-relaunch"
[ -s "$OUT/pending-$PATTERN-allow.tsv" ] && cmp -s <(cut -f1,3 "$OUT/pending-$PATTERN-allow.tsv") <(cut -f1,3 "$OUT/pending-$PATTERN-relaunch.tsv") \
  && echo "relaunch: identifiers and fire times identical" || echo "relaunch: lists differ"
