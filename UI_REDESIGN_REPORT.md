# Home UI Incremental Improvement Report

## 1. Cluster

`Home` route; files: `Martinus/Features/Home/HomeView.swift`, `Martinus/Features/Home/HomeViewModel.swift`, `UI_REDESIGN_REPORT.md`.

## 2. Findings addressed

- Unloaded and genuinely empty data previously shared one presentation. Home now gates its data-dependent sections on `isLoaded` and renders the existing `ProgressView` with project spacing and card tokens while loading (`Martinus/Features/Home/HomeView.swift:18-46`; load completion remains at `Martinus/Features/Home/HomeViewModel.swift:39-59`).
- The existing change-focus state now drives a confirmation dialog populated from open, relevant tasks (`Martinus/Features/Home/HomeView.swift:65-74`; `Martinus/Features/Home/HomeViewModel.swift:78-80`).
- The existing See All state now sends the user to the existing Today destination and resets itself (`Martinus/Features/Home/HomeView.swift:75-79`, trigger at `Martinus/Features/Home/HomeView.swift:107-113`).
- Focus progress is no longer a literal zero. The card receives a status-derived value of 0%, 50%, or 100% (`Martinus/Features/Home/HomeView.swift:19-24`, `Martinus/Features/Home/HomeView.swift:185-205`; mapping at `Martinus/Features/Home/HomeViewModel.swift:82-88`).
- The feature-local focus material stack was replaced with the existing `.glassCard(cornerRadius:)` primitive (`Martinus/Features/Home/HomeView.swift:222-225`; primitive source at `Martinus/Core/Design/AppTheme.swift:127-160`).
- Reminder and Promise no longer contain feature-local hex values; both reference the existing primary token (`Martinus/Features/Home/HomeView.swift:135-146`; token at `Martinus/Core/Design/AppTheme.swift:6`).

## 3. Findings deferred

- Root tab navigation values and motion remain deferred because `ContentView` is a routing surface requiring separate approval (`Martinus/ContentView.swift:3-216`).
- Shared `ProgressRing`, `CheckmarkButton`, and `TagChip` motion/semantics remain deferred because changing them affects every feature cluster (`Martinus/Core/Components/SharedComponents.swift:220-318`, `Martinus/Core/Components/SharedComponents.swift:441-470`).
- The Home screen's existing 100-point bottom inset remains deferred to the root-navigation cluster because it compensates for the root overlay (`Martinus/Features/Home/HomeView.swift:47-50`, `Martinus/ContentView.swift:40-65`).

## 4. New components

None. Loading uses SwiftUI `ProgressView`; focus selection uses SwiftUI `confirmationDialog`; navigation uses the existing Today destination; card rendering uses the existing `.glassCard()` primitive (`Martinus/Features/Home/HomeView.swift:40-45`, `Martinus/Features/Home/HomeView.swift:65-79`, `Martinus/Features/Home/HomeView.swift:222-225`).

## 5. New dependencies

None. The project continues to use SwiftUI and its project-owned primitives (`Martinus/Features/Home/HomeView.swift:1-2`).

## 6. Microcopy added

- `Change Today's Focus` repeats the existing focus-button label (`Martinus/Features/Home/HomeView.swift:65-73`, precedent at `Martinus/Features/Home/HomeView.swift:222`).
- `Cancel` follows existing modal-action precedent (`Martinus/Features/Home/HomeView.swift:73`; precedent at `Martinus/Features/Today/AddTaskView.swift:70`).
- Task-choice labels come directly from `FocusTask.title` (`Martinus/Features/Home/HomeView.swift:70-72`; model field at `Martinus/Models/Models.swift:213-216`).

## 7. Verification Block

```text
Tests:          DEVELOPER_DIR=/Users/martin/Desktop/Xcode-beta.app/Contents/Developer xcodebuild test -project Martinus.xcodeproj -scheme Martinus -destination 'platform=iOS Simulator,id=82D964A1-1FFE-4CB6-815F-7821A99DCAD8' -derivedDataPath /tmp/MartinusHomeAuditDerivedData -> 56 passed, 0 failed
Typecheck:      DEVELOPER_DIR=/Users/martin/Desktop/Xcode-beta.app/Contents/Developer xcodebuild build -project Martinus.xcodeproj -scheme Martinus -destination 'platform=iOS Simulator,id=82D964A1-1FFE-4CB6-815F-7821A99DCAD8' -derivedDataPath /tmp/MartinusHomeAuditDerivedData -> 0 errors
Lint:           rg -n 'swiftlint|SwiftLint' . -g '!*.xcuserstate' -> no configured SwiftLint build phase or config; 0 measured lint errors, 0 new warnings
Contrast:       ffTextPrimary/#F6F5FA = 16.61:1; #FFFFFF/#0A0A0F = 19.75:1; ffPrimary/#F6F5FA = 3.57:1; ffPrimary/#0A0A0F = 5.10:1; ffPrimary on its 15% light tint = 3.01:1; ffPrimary on its 15% dark tint = 4.39:1. Native Liquid Glass is sampled dynamically, so it has no single fixed RGB background to measure.
Focus-visible:  N/A for this touch-first iOS cluster; no hardware-keyboard UI-test target exists and no focus-indicator code was changed.
Keyboard path:  N/A for the native confirmation dialog and tab action in the current touch-only test harness; VoiceOver/Full Keyboard Access automation is deferred.
Reduced motion: no animation was added; N/A.
Target size:    44 pt minimum for system confirmation-dialog actions; existing FFButton computes to at least 52 pt from a 24 pt body line plus 14 pt top and bottom padding (`Martinus/Core/Components/SharedComponents.swift:163-180`).
Reformat split: no - no formatter was run.
Rollback:       git apply -R /tmp/martinus-home-session.patch && rm UI_REDESIGN_REPORT.md
Preservation:   session-scoped changes to ASK-BEFORE-TOUCH paths = 0 files. HEAD-relative git diff is not 0 because ten protected paths already had pre-existing changes before Phase 1; none were edited in this session.
```

## 8. Untouched surfaces

This session did not edit `Martinus/ContentView.swift`, `Martinus/Core/AppState.swift`, `Martinus/MartinusApp.swift`, `Martinus/Models/Models.swift`, `Martinus/Repositories/Repositories.swift`, `Martinus/Services/**`, `MartinusTests/**`, `Martinus.xcodeproj/project.pbxproj`, either Info.plist, or `MartinusWidget/**`. The Phase 1 baseline already showed HEAD-relative modifications in ten protected paths, so their repository-wide `git diff --stat` is nonzero; session-scoped comparison is zero.

## 9. Rollback command

`git apply -R /tmp/martinus-home-session.patch && rm UI_REDESIGN_REPORT.md`

A commit-level rollback was intentionally not claimed because the two Home files already contained pre-existing uncommitted changes at Phase 1. Committing their complete HEAD-relative diff would mix earlier work into this cluster.

## 10. Recommended next cluster

Root navigation readability and reduced-motion behavior in `Martinus/ContentView.swift` plus this report: estimated 2 files. This requires explicit approval because `ContentView` owns the routing table; do not start it automatically.
