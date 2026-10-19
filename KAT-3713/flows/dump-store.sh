#!/bin/bash
# usage: dump.sh <sim> ; prints per-table row counts + sha of sorted (identity+values) per table
SIM=$1
C=$(xcrun simctl get_app_container $SIM com.gannonhall.JabTracker data)
DB="$C/Library/Application Support/default.store"
T=$(mktemp -d); cp "$DB"* $T/; sqlite3 $T/default.store "PRAGMA wal_checkpoint(TRUNCATE);" >/dev/null
for t in ZUSER ZDOSE ZMEDICATIONPROFILE ZDOSESCHEDULE ZFOODENTRY ZFOOD ZWEIGHTENTRY ZMETRICSENTRY ZPROGRESSPHOTO ZNUTRITIONGOAL ZNUTRITIONPROGRAM; do
  n=$(sqlite3 $T/default.store "select count(*) from $t")
  h=$(sqlite3 $T/default.store "select * from $t order by 1" | shasum -a 256 | cut -c1-12)
  echo "$t rows=$n sha=$h"
done
