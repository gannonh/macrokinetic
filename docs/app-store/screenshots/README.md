# Capture authentic screenshots

The five PNGs in this folder are full-screen captures of real app screens with fictional seeded data. `AppStoreScreenshotUITests` drives each screen, asserts its behavior, and then captures it. Nothing is mocked, composed, or edited. `assets.json` records each file's checksum, source SHA, device, OS, and capture time. [`../evidence/capture-run.json`](../evidence/capture-run.json) records the run.

| Slot | Screen and route | Assertion before capture |
| --- | --- | --- |
| `dashboard` | Dashboard tab | Weekly Nutrition and Today's Nutrition render with seeded entries |
| `food-search` | Food Log → Add food → search "salmon" | The bundled database returns a salmon food |
| `food-log` | Same food → Add | The logged food's row appears in the Food Log |
| `metrics` | Add (+) → Metrics (Log Metrics) | Waist reads exactly 32 in, Health sync off; Save closes the sheet |
| `dose-history` | More → GLP-1 Programs → Analytics → History | Seeded Ozempic doses are listed |

## Recapture

Use an iPhone 17 Pro Max simulator (1320 x 2868, the 6.9-inch size). Do not upscale a smaller device. iPad assets are not needed while `TARGETED_DEVICE_FAMILY` is `1`.

1. Link the production food database into the checkout (it is gitignored):

   ```sh
   ln -s <main-checkout>/JabTracker/Resources/usda_foods.sqlite JabTracker/Resources/
   ```

2. Create and boot a dedicated simulator. Set the clean status bar:

   ```sh
   UDID=$(xcrun simctl create store-capture com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max com.apple.CoreSimulator.SimRuntime.iOS-27-0)
   xcrun simctl boot "$UDID"
   xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 --operatorName ""
   ```

3. Run the capture test in the `ReleaseTestHarness` configuration. It is the optimized Release build with the test seeding controls compiled in, and `ReleasePolicy` turns every unfinished feature off. Without `TEST_RUNNER_APP_STORE_CAPTURE_DIR` the test skips.

   ```sh
   TEST_RUNNER_APP_STORE_CAPTURE_DIR=/tmp/store-capture xcodebuild test -project JabTracker.xcodeproj \
     -scheme JabTrackerReleaseTestHarness -destination "id=$UDID" \
     -only-testing:JabTrackerUITests/AppStoreScreenshotUITests
   ```

4. Simulator PNGs carry an alpha channel that is fully opaque. Confirm it is opaque, then drop the channel without changing any pixel:

   ```sh
   magick identify -format '%[opaque]\n' /tmp/store-capture/dashboard.png   # must print True
   magick /tmp/store-capture/dashboard.png -alpha off PNG24:/tmp/store-capture/dashboard-rgb.png
   ```

5. Clear the old slot in `assets.json` (set `path` to null and `state` to `pending`) and delete the old PNG. Then import each image:

   ```sh
   python3 scripts/app-store.py import-screenshot dashboard /tmp/store-capture/dashboard-rgb.png \
     --candidate-sha <source-sha> --version <version> --build <build> \
     --device "iPhone 17 Pro Max (simulator)" --os-version 27.0 \
     --captured-at "$(cat /tmp/store-capture/dashboard.time)" --scenario "<assertion from the table>" --fictional-data
   ```

6. Inspect each image for enabled features only, fictional records, and a matching caption. Record `reviewed_by`, set `state` to `reviewed`, and link `evidence`.

The script checks PNG decoding, size, opaque 8-bit RGB, checksum, and source identity. It cannot detect invented UI, so a person must review each image.

## Limits

- The captures come from a simulator build of `main`, not from the signed submission archive. KAT-3594 produces that archive and assigns version 1.0.0. Recapture if the archive's screens differ.
- The seeded user name and records are fictional test fixtures (`TestDataSeeding`).
- Captions in `assets.json` are for optional later composition. The raw captures are the submission assets.
