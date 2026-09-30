# Prepare the App Store packet

This is the draft submission packet for [KAT-3591](https://linear.app/kata-sh/issue/KAT-3591), under [KAT-3185](https://linear.app/kata-sh/issue/KAT-3185). It is **IN PROGRESS**. No authentic candidate screenshots or signed icon output have been supplied. Public identity, contact, domain, and health-sync policy remain unresolved.

The current app displays **MacroKinetic**. The repository and stable bundle identifier retain JabTracker. Copy uses MacroKinetic pending the owner's branding decision. `metadata.json` proposes 1.0.0; it does not change `project.yml` or assign a build number.

The [launch readiness plan](../launch-readiness.md) records ticket order, gate conditions, existing-ticket disposition, dated PR states, verified evidence, and the owner/candidate blockers. Refresh its status snapshot when work advances.

## Validate the draft

Run these commands from the repository root:

```sh
python3 scripts/app-store.py validate
python3 -m unittest scripts.tests.test_app_store
```

Draft validation checks copy lengths, required files, manifest shape, existing asset properties, and the Icon Composer source. It prints outstanding readiness inputs. A valid draft does not prove launch behavior, legal compliance, or App Store readiness.

After all inputs and authentic assets are recorded, run the strict gate:

```sh
python3 scripts/app-store.py validate --ready
```

The strict gate exits nonzero while candidate evidence, image review, or owner inputs are absent. A successful strict check proves packet consistency. A human still reviews image content, legal facts, and the signed candidate.

## Complete the packet

1. Review [the launch audit](launch-audit.md) and the linked Linear issues.
2. Resolve [owner inputs](owner-inputs.json) and the [data-flow worksheet](privacy-data-flow.md).
3. Confirm the [age and medical-status worksheet](age-and-medical-status.md).
4. Finalize the [public drafts](public/README.md) after the health-sync decision. Test their real URLs separately.
5. Record the exact candidate SHA, version, build, and release-scope evidence in `assets.json`.
6. Exercise each advertised claim. Save reviewable results under `evidence/`, and link them from `metadata.json`.
7. Follow [the capture plan](screenshots/README.md). Import real full-resolution PNGs with the script. Review each image and record its reviewer.
8. Export the compiled icon from the same candidate archive. Record its file, checksum, candidate SHA, review, and evidence in `assets.json`.
9. Replace unresolved reviewer instructions, remove draft markers from finalized resources, and set packet states to `ready`.
10. Run the strict gate and preserve its output with the candidate evidence.

Do not publish these pages, upload screenshots, or submit a build as part of this workflow. KAT-3592 owns public resources and app links; KAT-3594 owns the submission-eligible archive; KAT-3595 records independent readiness evidence.

## Copy and asset limits

`metadata.json` contains English copy only. Advertised behavior is conditional on the claim evidence. It makes no concentration-accuracy, dosage-guidance, weight-loss-outcome, subscription-price, food-count, or cloud-security claim.

Apple allows a 30-character name and subtitle, 170-character promotional text, a 4,000-character description, and 100 bytes of keywords. [Apple platform fields](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).

The screenshot plan uses portrait RGB PNGs at accepted large-iPhone sizes. iPad assets are unnecessary while `TARGETED_DEVICE_FAMILY` remains `1`. [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).

An optional App Store preview is 15 to 30 seconds. The project's Human Review video is 30 to 60 seconds, so use separate exports. No preview is required by this packet. [Apple preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications/).
