---
description: Deploy test build to TestFlight
---

Deploy a new build to TestFlight Internal Testing with the following workflow:

## Step 1: Upload Build

Run the upload script with auto-increment:
```bash
./scripts/upload-testflight.sh --increment-build
```

## Step 2: Generate Release Notes

**1. Generate plain text release notes**

NO EMOJIS - App Store Connect doesn't allow them. Base release notes on:
- Commits since last TestFlight build (find with: `git log --grep="TestFlight Build" --oneline -1`)
- Get all commits since then: `git log <last-build-commit>..HEAD --oneline`
- New features implemented
- Bug fixes
- What testers should focus on

Format the notes as:
```
Build 0.1.0 (X) - [Brief Description]

What's New
- [Feature 1]
- [Feature 2]

Focus Areas for Testing
- [Area 1]: [What to test]
- [Area 2]: [What to test]

Feedback Needed
- [Question 1]
- [Question 2]

Not Yet Implemented
- [Future feature 1]
- [Future feature 2]
```

Output plain text release notes to user (for copy/paste).

**IMPORTANT**: Check the prior build's release notes in `.claude/releases/build-X.txt` to avoid duplication or already annouced features.

**2. Save release notes locally**

Save to `.claude/releases/build-X.txt` (e.g. `.claude/releases/build-0.1.0-5.txt`) for internal reference.

## Step 3: Post-Upload Checklist

After upload completes (10-20 min), provide these instructions to the user:

**Timeline:**
1. Wait 10-30 minutes for Apple to process the build
2. You'll receive email when build is ready

**Required Steps in App Store Connect:**
1. Go to https://appstoreconnect.apple.com/teams/662bb7eb-4802-4b2e-b03e-8943dfa4849c/apps/6755363295/testflight/ios
2. Navigate to: My Apps → Tender App Internal → TestFlight
3. Find the new build (will show as "Processing" until ready)
4. Once ready, click on the build
5. Add the release notes in "What to Test" field (paste generated notes)
6. Answer Export Compliance questions:
   - Uses encryption? **YES**
   - What type? **None of the algorithms mentioned above** (standard Apple encryption only)
7. Click "Save"
8. Build will automatically distribute to "dev" testing group
9. Testers receive email notification

**Export Compliance Answers:**
- App uses standard Apple encryption (CloudKit, HTTPS, Sign in with Apple)
- No custom or proprietary encryption
- Select: "None of the algorithms mentioned above"
- No export documentation required

**Where Testers See Notes:**
- Notes DON'T appear in email notification
- Notes appear in TestFlight app: Open app → Tap build → "What to Test" section
- Remind testers to check TestFlight app for testing instructions

---

## Step 4: Commit Build Number

After successful upload, ask the user for permission tocommit the project.yml file with the updated build number:

```bash
git add project.yml
git commit -m "TestFlight Build [build-number]"
git push
```

**Purpose:**
- Creates a git marker for this build
- Future deployments can analyze commits since last "TestFlight Build X" commit
- Provides accurate commit history for release notes generation

**Example:** If this is build 6, commit message is: `TestFlight Build 6`

---

Present the release notes clearly formatted for easy copy/paste into App Store Connect.
