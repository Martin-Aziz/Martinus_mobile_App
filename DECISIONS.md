# DECISIONS.md — Martinus Architecture & Assumption Log

## ADR-001: SwiftData over Core Data

**Status:** Accepted  
**Date:** 2026-07-15

**Context:** The app requires local persistence for tasks, goals, journal entries, quotes, and user profile. The persistence layer must be simple to maintain, type-safe, and compatible with CloudKit for a future sync feature.

**Decision:** Use SwiftData (iOS 17+).

**Rationale:**
- SwiftData uses `@Model` macros and type-safe predicates — far less boilerplate than Core Data
- Native CloudKit integration via `ModelConfiguration` when the entitlement is added
- Works seamlessly with `@Environment(\.modelContext)` in SwiftUI
- Compile-time type checking of queries

**Alternatives considered:**
- Core Data: battle-tested, but NSManagedObject boilerplate is significant
- SQLite + GRDB: excellent performance, but more setup and no native CloudKit path
- Realm: third-party dependency, not worth introducing for a solo-user app

**Trade-offs:** SwiftData is newer (iOS 17+) and has fewer third-party resources. Chosen because deployment target is iOS 17.0.

---

## ADR-002: @Observable + Environment over ObservableObject

**Status:** Accepted  
**Date:** 2026-07-15

**Context:** ViewModels need to be observable by SwiftUI views. Two patterns are available: the legacy `ObservableObject` + `@Published` and the new `@Observable` macro.

**Decision:** Use `@Observable` for ViewModels and `@Environment` for the global `AppState`.

**Rationale:**
- `@Observable` requires fewer annotations — no `@Published` on every property
- Fine-grained observation: SwiftUI only re-renders views that read a changed property
- Cleaner code, less cognitive overhead
- `AppState` passed via `@Environment` allows any view to access global services without prop-drilling

**Alternatives considered:**
- `ObservableObject`: still works, but generates more renders
- Redux/TCA: powerful but introduces significant complexity for a single-user local app

---

## ADR-003: MVVM + Repository Pattern

**Status:** Accepted  
**Date:** 2026-07-15

**Context:** The architecture must allow unit testing of business logic without SwiftUI dependencies.

**Decision:** MVVM where Views own ViewModels (via `@State private var viewModel`), and ViewModels depend on Repository abstractions, not SwiftData ModelContext directly.

**Rationale:**
- ViewModels can be tested with in-memory ModelContext
- Repository pattern hides SwiftData details — easy to swap persistence layer
- Services (Notification, Calendar, FocusSession) are singletons injected via AppState
- Views remain thin — no business logic in SwiftUI body

**Alternatives considered:**
- Fat Views (MVC): fast initially, untestable, unmaintainable
- Clean Architecture with UseCases: appropriate for teams, over-engineered for this scope

---

## ADR-004: QuotesSeed — Manual curation, no AI generation

**Status:** Accepted  
**Date:** 2026-07-15

**Context:** The spec explicitly states: "The application must not invent quotes or incorrectly attribute them." Quotes are displayed with author name and are used for motivation.

**Decision:** Ship a curated, manually verified seed of 60 quotes. FocusFlow-original guidance is clearly labeled as "FocusFlow Guidance" with no external attribution.

**Rationale:**
- Misattributed quotes (extremely common in apps/internet) damage credibility
- Each quote includes an explanation in plain language
- All quotes verified against primary sources or well-documented secondary sources

**Alternatives considered:**
- AI-generated quotes: high misattribution risk, explicitly disallowed in spec
- Scraping API: attribution unreliable, license unclear

---

## ADR-005: FocusSessionService as a Singleton

**Status:** Accepted  
**Date:** 2026-07-15

**Context:** The focus timer needs to survive tab switches and sheet dismissals. Multiple views access it (More tab, Home quick action, task detail).

**Decision:** `FocusSessionService.shared` singleton, `@MainActor` annotated, accessed via `@StateObject` at the call site or directly via `shared`.

**Rationale:**
- Timer state must be global — a new instance per view would reset the timer on navigation
- `@MainActor` ensures all UI updates happen on the main thread
- Simple, predictable, easy to test

**Trade-offs:** Singleton state can be harder to isolate in tests. Mitigated by always stopping the session in `tearDown()`.

---

## ADR-006: One-File-Per-Feature vs One-File-Per-Concern

**Status:** Accepted  
**Date:** 2026-07-15

**Context:** Large features like Goals and Journal have multiple sub-views (list, detail, add). Choosing between one file per subview or one file per feature.

**Decision:** For the initial build, all subviews within a feature live in one file (e.g., `GoalsView.swift` contains `GoalsView`, `GoalCard`, `GoalDetailView`, `AddGoalView`). ViewModels are in a separate file.

**Rationale:**
- Reduces cognitive overhead when navigating — one file per feature to find
- Easy to split later when files grow beyond ~600 lines
- Consistent with standard SwiftUI sample patterns from Apple

**Trade-offs:** Large files when a feature grows. Acceptable for initial MVP; split into subdirectories when any file exceeds 400 lines in practice.

---

## ADR-007: Goal Milestones Stored as JSON in SwiftData

**Status:** Accepted  
**Date:** 2026-07-15

**Context:** Goals have an ordered list of milestones. SwiftData 1.0 relationship handling (especially ordered arrays of simple structs) has known edge cases with schema migrations.

**Decision:** Milestones are encoded as `Data` (`milestonesData: Data?`) containing JSON-encoded `[GoalMilestone]`. A computed property `milestones` handles encode/decode.

**Rationale:**
- Avoids SwiftData ordered relationship complexity and migration pitfalls
- `GoalMilestone` is a simple `Codable` struct, not a `@Model`
- Simple schema — one column, no join table

**Trade-offs:** Cannot query milestones from SwiftData predicates. Acceptable because milestones are always accessed through their parent `Goal` and never queried independently.

---

## ADR-008: Widget Data via App Group UserDefaults

**Status:** Accepted (pending App Group entitlement)  
**Date:** 2026-07-15

**Context:** WidgetKit extensions cannot access the main app's SwiftData store directly. They need a lightweight shared data channel.

**Decision:** Use `UserDefaults(suiteName: "group.com.focusflow.app")` as the data bridge. The main app writes `widget.focusTitle`, `widget.taskCount`, `widget.completed`, `widget.streak`, and `widget.quoteText` whenever these values change.

**Rationale:**
- Standard Apple pattern for widget data sharing
- No additional dependencies, no file coordination
- Lightweight for the small amount of data widgets need

**Implementation note:** The main app must add "App Groups" entitlement with group ID `group.com.focusflow.app` and write to UserDefaults after every state mutation. This integration point is architecturally complete but requires the entitlement to be configured in Xcode before the widget can read live data.

---

## Assumptions Made

| # | Assumption | Rationale |
|---|-----------|-----------|
| 1 | User name defaults to "Martin" in HomeViewModel greeting until profile is loaded | Spec mentions the name "Martin" as an example; replaced by real name after onboarding |
| 2 | Focus session music is UI-only label; no AVAudioPlayer integration in v1 | Scoped out of MVP; architecture hook is present |
| 3 | Calendar access is read-only | Writing to calendar is not in the spec and would require additional permission text |
| 4 | Morning briefing default: 08:00, Evening review default: 21:00 | Reasonable defaults for a working professional; user can change in Settings |
| 5 | Streak logic increments when any task is completed on a given day | Simplified; production version should require journal entry + ≥1 task completion |
| 6 | iOS 17.0 minimum deployment target | Enables SwiftData, `@Observable`, and new `containerBackground` widget API |
| 7 | Dark mode is default; light mode respects system | Design spec shows both; app-level `preferredColorScheme(.dark)` with per-user override in Settings |
| 8 | Bundle ID is `com.focusflow.app` | Placeholder; must be replaced with a registered Apple Developer account Bundle ID before submission |
