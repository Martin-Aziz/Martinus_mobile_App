# FocusFlow

**Your personal assistant for goals, reflection, and motivation.**

Plan your day. Achieve your goals. Reflect with intention. Stay motivated.

---

## The Idea

FocusFlow is a private, native iPhone application that helps busy people reduce mental burden. It remembers commitments, organizes goals, plans the day, surfaces what matters most right now, and helps the user understand personal progress — all without requiring an account, backend, or subscription.

The application feels calm, intelligent, personal, and supportive. It never feels judgmental, noisy, or stressful.

---

## Technical Architecture

```
FocusFlow/
├── FocusFlowApp.swift          # @main entry, ModelContainer
├── ContentView.swift           # Root TabView, sheet coordinator
├── Core/
│   ├── Design/
│   │   └── AppTheme.swift      # Color, Gradient, Spacing, Radius, Glass modifier
│   ├── Extensions/
│   │   └── Extensions.swift    # Date, String, Double, View helpers
│   └── Components/
│       └── SharedComponents.swift  # GlassCard, FFButton, ProgressRing, etc.
├── Models/
│   └── Models.swift            # SwiftData @Model classes + Codable value types
├── Repositories/
│   └── Repositories.swift      # TaskRepository, GoalRepository, JournalRepository,
│                               # QuoteRepository, UserProfileRepository
├── Services/
│   ├── NotificationService.swift  # UNUserNotificationCenter wrapper
│   ├── CalendarService.swift      # EventKit wrapper
│   ├── FocusSessionService.swift  # Pomodoro timer
│   └── AssistantService.swift     # Context-aware insight generator (pure logic)
├── Features/
│   ├── Home/                   # Dashboard — greeting, focus card, assistant, quotes
│   ├── Today/                  # Planner — week selector, timeline, add task
│   ├── Goals/                  # Goal list, detail, add, milestones
│   ├── Journal/                # Journal list, entry detail, add entry
│   ├── Quotes/                 # Quote library, daily hero card, favorites
│   ├── More/                   # Focus timer, insights, settings
│   └── Onboarding/             # 5-page walkthrough + name + notifications
└── Seeds/
    └── QuotesSeed.swift        # 60 verified, attributed quotes

FocusFlowWidget/
└── FocusFlowWidget.swift       # Small, Medium (systemSmall/Medium) + Lock Screen widgets

FocusFlowTests/
├── AssistantServiceTests.swift
├── ModelTests.swift
└── ViewModelTests.swift
```

### Design System

| Token | Value |
|-------|-------|
| Primary | `#8C65FF` (purple) |
| Secondary | `#00D4FF` (cyan) |
| Success | `#22C55E` |
| Warning | `#F59E0B` |
| Danger | `#EF4444` |
| Background | `#0A0A0F` |
| Surface | `#13131A` |
| Surface Elevated | `#1C1C28` |
| Typography | SF Pro Display / SF Pro Text |
| Spacing | Base-8 system (4, 8, 12, 16, 20, 24, 32, 40, 48, 64) |
| Corners | 8, 12, 16, 20, 24 |
| Style | iOS glassmorphism — `.ultraThinMaterial` + gradient overlay + subtle border |

### Data Flow

```
User Action → SwiftUI View → ViewModel (Observable) → Repository → SwiftData
                           ↓
                    Service (Notification / Calendar / Focus)
```

---

## Quick Start

### Prerequisites

- Xcode 15.3+
- iOS 17.0+ device or simulator
- macOS Sonoma or later

### Steps

1. Clone the repository
   ```bash
   git clone <repo-url>
   cd Focusflow
   ```

2. Open the project
   ```bash
   open FocusFlow.xcodeproj
   ```

3. Select your development team in **Signing & Capabilities** for both `FocusFlow` and `FocusFlowWidget` targets

4. Run on Simulator or Device
   ```
   Cmd + R
   ```

No additional dependencies. No package manager required. The app is self-contained.

---

## Running Tests

```bash
# In Xcode
Cmd + U

# Via xcodebuild (simulator)
xcodebuild test \
  -project FocusFlow.xcodeproj \
  -scheme FocusFlow \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

## Key Features

### MVP Features
| Feature | Description |
|---------|-------------|
| **Home Dashboard** | Greeting, Today's Focus card, assistant nudge, upcoming items, daily motivation |
| **Today Planner** | Week navigator, chronological timeline, calendar events, unscheduled section |
| **Goals** | Category-filtered goals, progress rings, milestones, deadline tracking |
| **Journal** | Mood/energy/focus tracking, structured entry (wins, gratitude, intentions), weekly mood calendar |
| **Quotes** | 60 verified curated quotes, daily hero, category filter, favorites |
| **Focus Timer** | Pomodoro-style timer with progress ring, pause/resume, music label |
| **Insights** | Productivity rate, streak, mood trend for last 7 days |
| **Onboarding** | 5-step walkthrough, name capture, notification permission request |

### Bonus Features (beyond spec)
| Feature | Rationale |
|---------|-----------|
| **Smart Assistant Card** | Analyzes overdue tasks, neglected goals, self-promises, and celebrations — surfaces only the most relevant nudge |
| **Evening Review** | Structured end-of-day reflection card with completions, what didn't get done, tomorrow's setup |
| **Promise System** | First-class "promise to yourself / to another person" concept with reschedule tracking |
| **WidgetKit (Home + Lock Screen)** | Small and medium home widgets showing focus + progress; lock screen accessory widget |
| **End-of-day review prompt** | Appears automatically after 20:00 on the Today screen |
| **Goal Milestones** | Inline milestone checklist per goal, stored as compressed JSON in SwiftData |
| **Streak tracking** | Daily streak counter shown in home and More tabs |

---

## Architecture Decisions

See [DECISIONS.md](DECISIONS.md) for full rationale.

| Decision | Choice | Alternatives |
|----------|--------|-------------|
| Persistence | SwiftData | Core Data (more complex), SQLite (no ORM), CloudKit (requires account) |
| State management | `@Observable` + `@Environment` | ObservableObject (older), Redux (overkill) |
| UI framework | SwiftUI | UIKit (more control, more boilerplate) |
| Architecture | MVVM + Repository | MVC (no separation), Clean Architecture (over-engineered for solo app) |
| Quote attribution | Manual curation + FocusFlow Guidance label | AI generation (inaccurate, risky) |
| Calendar access | EventKit read-only | No calendar (reduced value) |
| Local notifications | UNUserNotificationCenter | Background fetch only (less timely) |

---

## Security

- All data is stored locally on-device via SwiftData
- No network requests, no analytics, no telemetry
- Calendar access is read-only (no write operations on user calendar)
- Notification permission is requested in onboarding with clear explanation
- No secrets, API keys, or credentials in any source file

---

## Known Limitations & Future Work

| Area | Note |
|------|------|
| CloudKit sync | Architecture is CloudKit-ready (SwiftData supports it natively) but disabled until iCloud entitlement is added |
| App Intents / Siri | `AppIntents` framework is imported but Siri integration shortcut actions are not yet wired |
| Habit tracking | Model supports recurring tasks (`isRecurring`, `recurrenceRule`) but UI for habit streaks is not built |
| Focus music | Music selection label is present in UI; actual AVAudioPlayer integration is a future step |
| HealthKit integration | UserProfile model has hooks; HealthKit read/write not yet implemented |
| App Group for Widget | Widget reads from `UserDefaults(suiteName:)` — the main app must write data to this suite on state changes |
| iPad support | Layout is optimized for iPhone portrait; iPad adaptive layout is future work |
