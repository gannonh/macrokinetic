# Capture authentic candidate screenshots

No candidate screenshots are present yet. `assets.json` contains the storyboard and pending slots. Each caption describes intended launch behavior and needs evidence before use.

Use the final Release configuration and fictional demonstration records. Capture complete screens at 1320x2868, 1290x2796, or 1260x2736 portrait pixels. Choose one device size consistently. Do not enlarge an iPhone Pro capture to a Pro Max size, stretch a screenshot, use mocks, or generate UI.

## Body-measurement recording slot

The pending `metrics` slot advertises **Record your body measurements** and uses the `metrics_recording` claim. Its source route is Add (+) → Metrics → Log Metrics. [ContentView](../../../JabTracker/ContentView.swift) presents [QuickMetricsSheet](../../../JabTracker/Views/Metrics/QuickMetricsSheet.swift) from [ShortcutsSheet](../../../JabTracker/Views/Shortcuts/ShortcutsSheet.swift). Save calls [MetricsService.logMetrics](../../../JabTracker/Services/MetricsService.swift), which inserts a MetricsEntry and saves the context. The release-flags branch retains this route. Source inspection establishes that the flow exists; candidate acceptance remains pending.

If the fictional user's waist measurement is disabled, enable it through More → Metrics before recording. That More route configures measurement visibility; it is not the recording screen. On the candidate, enter a fictional waist value such as 80 cm, confirm the exact saved record/value and relaunch retention, then reopen Log Metrics and capture the recording form. Save this acceptance result separately from the image. Confirm the displayed fields, unit, date, and permission behavior before accepting the caption. Do not advertise a measurement-history screen or fabricate a chart. If recording is absent or fails on the final candidate, remove its copy, claim, and slot.

## Record the capture

1. Confirm the candidate SHA, version/build, flags, and production food-database manifest.
2. Use an isolated simulator or test device with fictional records. Do not reset a real user's data.
3. Exercise and verify the screen's behavior, then capture the full device screen as an opaque RGB PNG. Record device, OS, capture time, scenario, and the literal result.
4. Import the unmodified PNG. This command only validates and copies the image; it does not run the app or capture a simulator.

For a simulator that is already running the approved candidate, the capture operator can use `xcrun simctl io <simulator-udid> screenshot --type=png /absolute/path/candidate-food-log.png`. Use the tested device's native size. Do not boot or reset a device merely to satisfy this packet.

```sh
python3 scripts/app-store.py import-screenshot food-log /absolute/path/candidate-food-log.png \
	--candidate-sha <full-40-character-sha> --version 1.0.0 --build <candidate-build> \
	--device "iPhone 17 Pro Max" --os-version <tested-os> \
	--captured-at <ISO-8601-time-with-zone> --scenario "Recorded and verified meal totals" \
	--fictional-data
```

5. Review the image for enabled features, fictional records, legibility, and matching caption. Record `reviewed_by` and set the slot to `reviewed`. The import command leaves every image `captured_unreviewed`.
6. Save the exercised result under `evidence/`. Link the file from the screenshot's `evidence` and its advertised claim in `metadata.json`.

Imported images are the submission assets. Captions remain in the manifest for optional later composition. Do not cover controls, alter displayed totals, or add unsupported claims. If you later add overlays, preserve the raw capture and record composition provenance separately.

The script checks PNG decoding, dimensions, RGB/opacity, checksums, candidate association, and review/evidence fields. It cannot detect invented UI or confirm the human attestation. Inspect every image before submission.
