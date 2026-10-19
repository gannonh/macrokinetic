## Seed (main build, --ui-testing --seed-1-month-active)
counts: USER=1 DOSE=4 MEDICATIONPROFILE=1 NUTRITIONGOAL=1 WEIGHTENTRY=30 FOODENTRY=97 
user (name|appleUserId|onboarded): UI Test User|NULL|1

## 1. main, existing install (signed-in, no --ui-testing)
main after launch: user row = UI Test User|NULL|1 (appleUserId erased by main's credential check; sign-in screen: see shots/s01-main-existing-install.png)

## 3. upgrade, signed in: PASS
before: USER=1 DOSE=4 MEDICATIONPROFILE=1 NUTRITIONGOAL=1 WEIGHTENTRY=30 FOODENTRY=97 
after:  USER=1 DOSE=4 MEDICATIONPROFILE=1 NUTRITIONGOAL=1 WEIGHTENTRY=30 FOODENTRY=97 
user: UI Test User|001234.live-check|1
counts identical: PASS

## 5. upgrade, Apple ID erased: PASS
before: USER=1 DOSE=4 MEDICATIONPROFILE=1 NUTRITIONGOAL=1 WEIGHTENTRY=30 FOODENTRY=97 
after:  USER=1 DOSE=4 MEDICATIONPROFILE=1 NUTRITIONGOAL=1 WEIGHTENTRY=30 FOODENTRY=97 
user: UI Test User|NULL|1
counts identical: PASS

## 4. upgrade, signed out: PASS
before: USER=0 DOSE=0 MEDICATIONPROFILE=0 NUTRITIONGOAL=0 WEIGHTENTRY=30 FOODENTRY=97 
after:  USER=1 DOSE=0 MEDICATIONPROFILE=0 NUTRITIONGOAL=0 WEIGHTENTRY=30 FOODENTRY=97 
user: |NULL|1

## 2. fresh install reaches onboarding: PASS

## 7a. lock on, relaunch requires biometrics: FAIL
## 7b. non-matching biometrics / cancel keeps it locked: FAIL
## 7c. match unlocks, background relocks: FAIL
## 8. lock off, relaunch opens directly: PASS

Final counts: USER=1 DOSE=4 MEDICATIONPROFILE=1 NUTRITIONGOAL=1 WEIGHTENTRY=30 FOODENTRY=97 
