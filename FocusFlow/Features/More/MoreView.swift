import SwiftUI
import SwiftData

// MARK: - MoreView
struct MoreView: View {
    @Environment(AppState.self) private var appState
    @State private var showFocusSession = false
    @State private var showInsights     = false
    @State private var showSettings     = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ffBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        profileSection
                        statsRow
                        menuSection
                    }
                    .padding(.horizontal, Spacing.base)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showFocusSession) { FocusSessionView() }
            .sheet(isPresented: $showInsights)    { InsightsView() }
            .sheet(isPresented: $showSettings)    { SettingsView() }
        }
    }

    private var profileSection: some View {
        HStack(spacing: Spacing.base) {
            ZStack {
                Circle()
                    .fill(LinearGradient.ffBrand)
                    .frame(width: 60, height: 60)
                Text(String(appState.userProfile?.name.prefix(1) ?? "F"))
                    .font(.ffDisplay2)
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.userProfile?.name ?? "Friend")
                    .font(.ffHeadline2)
                    .foregroundColor(.ffTextPrimary)
                Text("You are on a journey to greatness.")
                    .font(.ffBody)
                    .foregroundColor(.ffTextSecondary)
            }
            Spacer()
        }
        .padding(.top, Spacing.xl)
    }

    private var statsRow: some View {
        HStack(spacing: Spacing.sm) {
            miniStat(label: "Streak",   value: "\(appState.currentStreak)d",     icon: "flame.fill",        color: .ffWarning)
            miniStat(label: "Today",    value: "\(appState.completedToday)/\(appState.todayTaskCount)", icon: "checkmark.circle", color: .ffSuccess)
        }
    }

    private func miniStat(label: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 18))
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.ffHeadline2).foregroundColor(.ffTextPrimary)
                Text(label).font(.ffCaption).foregroundColor(.ffTextSecondary)
            }
            Spacer()
        }
        .padding(Spacing.base)
        .glassCard()
        .frame(maxWidth: .infinity)
    }

    private var menuSection: some View {
        VStack(spacing: Spacing.xs) {
            menuRow(icon: "timer.circle.fill",     label: "Focus Session",    color: .ffPrimary)   { showFocusSession = true }
            menuRow(icon: "chart.bar.fill",        label: "Insights",         color: .ffSecondary) { showInsights = true }
            menuRow(icon: "bell.badge.fill",       label: "Custom Reminders", color: .ffWarning)   {}
            menuRow(icon: "music.note",            label: "Focus Music",      color: Color(hex: "#EC4899")) {}
            menuRow(icon: "gearshape.fill",        label: "Settings",         color: .ffNeutral)   { showSettings = true }
            menuRow(icon: "questionmark.circle",   label: "Help & Feedback",  color: .ffSuccess)   {}
        }
    }

    private func menuRow(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: { HapticManager.light(); action() }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text(label)
                    .font(.ffBodyMed)
                    .foregroundColor(.ffTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.ffTextTertiary)
            }
            .padding(Spacing.base)
            .background(Color.ffSurfaceElevated.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        }
    }
}

// MARK: - FocusSessionView
struct FocusSessionView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var session = FocusSessionService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var plannedMinutes = 25
    @State private var sessionTitle   = "Deep Work"
    @State private var showSettings   = false

    private let durationOptions = [15, 20, 25, 30, 45, 60, 90]

    var body: some View {
        ZStack {
            Color.ffBackground.ignoresSafeArea()
            backgroundBlobs

            VStack(spacing: Spacing.xl) {
                navigationBar

                if session.isRunning {
                    activeSessionView
                } else {
                    idleSessionView
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.base)
        }
    }

    // MARK: - Navigation
    private var navigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.ffTextSecondary)
                    .frame(width: 40, height: 40)
                    .background(Color.ffSurfaceElevated)
                    .clipShape(Circle())
            }
            Spacer()
            Text("Focus Session")
                .font(.ffHeadline3)
                .foregroundColor(.ffTextPrimary)
            Spacer()
            CircularIconButton("gear", color: .ffTextSecondary) { showSettings.toggle() }
        }
        .padding(.top, Spacing.xl)
    }

    // MARK: - Idle State
    private var idleSessionView: some View {
        VStack(spacing: Spacing.xxl) {
            VStack(spacing: Spacing.sm) {
                Text(sessionTitle)
                    .font(.ffHeadline1)
                    .foregroundColor(.ffTextPrimary)
                Text("Focus on your goals.\nWe believe in you.")
                    .font(.ffBody)
                    .foregroundColor(.ffTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Large timer display
            Text(formatTime(plannedMinutes * 60))
                .font(.ffMono)
                .foregroundStyle(LinearGradient.ffBrand)

            // Duration picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(durationOptions, id: \.self) { mins in
                        TagChip("\(mins)m", color: .ffPrimary, isSelected: plannedMinutes == mins) {
                            plannedMinutes = mins
                            HapticManager.selection()
                        }
                    }
                }
            }

            // Music selector
            HStack(spacing: Spacing.sm) {
                Image(systemName: "music.note").foregroundColor(.ffTextSecondary)
                Text("Select Music").font(.ffBodyMed).foregroundColor(.ffTextPrimary)
                Spacer()
                Text("Lo-Fi Focus").font(.ffBody).foregroundColor(.ffTextSecondary)
                Image(systemName: "play.fill").foregroundColor(.ffPrimary)
            }
            .padding(Spacing.base)
            .glassCard()

            // Start button
            Button(action: startSession) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.ffBrand)
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.ffPrimary.opacity(0.4), radius: 20, x: 0, y: 8)
                    VStack(spacing: 2) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Start")
                            .font(.ffCaption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
    }

    // MARK: - Active Session
    private var activeSessionView: some View {
        VStack(spacing: Spacing.xxl) {
            VStack(spacing: Spacing.sm) {
                Text(session.sessionTitle)
                    .font(.ffHeadline1)
                    .foregroundColor(.ffTextPrimary)
                Text("Stay focused. You've got this.")
                    .font(.ffBody)
                    .foregroundColor(.ffTextSecondary)
            }

            // Ring + timer
            ZStack {
                ProgressRing(progress: session.progress, size: 200, lineWidth: 12)
                Text(session.formattedRemaining)
                    .font(.ffMono)
                    .foregroundStyle(LinearGradient.ffBrand)
            }

            // Controls
            HStack(spacing: Spacing.xxl) {
                CircularIconButton("stop.fill", color: .ffDanger, size: 56) {
                    _ = session.stop()
                    HapticManager.heavy()
                }
                if session.isPaused {
                    CircularIconButton("play.fill", color: .ffPrimary, size: 72) {
                        session.resume()
                    }
                } else {
                    CircularIconButton("pause.fill", color: .ffPrimary, size: 72) {
                        session.pause()
                    }
                }
                CircularIconButton("checkmark", color: .ffSuccess, size: 56) {
                    _ = session.stop()
                    dismiss()
                }
            }
        }
    }

    private var backgroundBlobs: some View {
        ZStack {
            Circle()
                .fill(Color.ffPrimary.opacity(session.isRunning ? 0.2 : 0.10))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .animation(.easeInOut(duration: 2), value: session.isRunning)
        }
        .ignoresSafeArea()
    }

    private func startSession() {
        HapticManager.heavy()
        session.start(minutes: plannedMinutes, title: sessionTitle)
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}

// MARK: - InsightsView
struct InsightsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var taskRepo:    TaskRepository?
    @State private var journalRepo: JournalRepository?
    @State private var weeklyTasks: [FocusTask] = []
    @State private var recentEntries: [JournalEntry] = []
    @State private var selectedPeriod = "Week"

    private let periods = ["Week", "Month"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ffBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        periodPicker
                        productivitySection
                        taskCompletionSection
                        moodTrendSection
                    }
                    .padding(.horizontal, Spacing.base)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.ffPrimary)
                }
            }
            .task {
                taskRepo    = TaskRepository(modelContext: modelContext)
                journalRepo = JournalRepository(modelContext: modelContext)
                weeklyTasks = (try? taskRepo?.fetchAll()) ?? []
                recentEntries = (try? journalRepo?.fetchRecent(limit: 14)) ?? []
            }
        }
    }

    private var periodPicker: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(periods, id: \.self) { p in
                TagChip(p, color: .ffPrimary, isSelected: selectedPeriod == p) { selectedPeriod = p }
            }
        }
    }

    private var productivityPercent: Int {
        let total     = weeklyTasks.count
        let completed = weeklyTasks.filter { $0.isCompleted }.count
        guard total > 0 else { return 0 }
        return Int(Double(completed) / Double(total) * 100)
    }

    private var productivitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Productivity")
            HStack(spacing: Spacing.base) {
                StatTile(
                    label: "Rate",
                    value: "\(productivityPercent)%",
                    icon:  "chart.line.uptrend.xyaxis",
                    color: .ffPrimary
                )
                StatTile(
                    label: "Completed",
                    value: "\(weeklyTasks.filter { $0.isCompleted }.count)",
                    icon:  "checkmark.circle",
                    color: .ffSuccess
                )
                StatTile(
                    label: "Total",
                    value: "\(weeklyTasks.count)",
                    icon:  "list.bullet",
                    color: .ffSecondary
                )
            }
        }
    }

    private var taskCompletionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Streak")
            HStack(spacing: Spacing.base) {
                StatTile(
                    label: "Current Streak",
                    value: "\(appState.currentStreak)d",
                    icon:  "flame.fill",
                    color: .ffWarning
                )
            }
        }
    }

    private var moodTrendSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Mood This Week")
            HStack(spacing: Spacing.sm) {
                ForEach(recentEntries.prefix(7)) { entry in
                    VStack(spacing: 4) {
                        Text(entry.mood.emoji).font(.system(size: 22))
                        Text(entry.date.weekdayShort)
                            .font(.system(size: 10))
                            .foregroundColor(.ffTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(Spacing.base)
            .glassCard()
        }
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var name               = ""
    @State private var morningHour        = 8
    @State private var eveningHour        = 21
    @State private var morningEnabled     = true
    @State private var eveningEnabled     = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ffBackground.ignoresSafeArea()
                List {
                    profileSection
                    notificationsSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveSettings(); dismiss() }.foregroundColor(.ffPrimary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.ffTextSecondary)
                }
            }
            .onAppear { loadSettings() }
        }
    }

    private var profileSection: some View {
        Section("Profile") {
            HStack {
                Text("Name")
                Spacer()
                TextField("Your name", text: $name)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.ffPrimary)
            }
        }
        .listRowBackground(Color.ffSurfaceElevated)
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Morning Briefing", isOn: $morningEnabled)
                .tint(.ffPrimary)
            if morningEnabled {
                Stepper("Hour: \(morningHour):00", value: $morningHour, in: 5...11)
            }
            Toggle("Evening Review", isOn: $eveningEnabled)
                .tint(.ffPrimary)
            if eveningEnabled {
                Stepper("Hour: \(eveningHour):00", value: $eveningHour, in: 18...23)
            }
        }
        .listRowBackground(Color.ffSurfaceElevated)
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0").foregroundColor(.ffTextSecondary)
            }
            HStack {
                Text("Build")
                Spacer()
                Text("100").foregroundColor(.ffTextSecondary)
            }
        }
        .listRowBackground(Color.ffSurfaceElevated)
    }

    private func loadSettings() {
        name           = appState.userProfile?.name ?? ""
        morningHour    = appState.userProfile?.morningReminderHour ?? 8
        eveningHour    = appState.userProfile?.eveningReviewHour ?? 21
        morningEnabled = appState.userProfile?.morningReminderEnabled ?? true
        eveningEnabled = appState.userProfile?.eveningReviewEnabled ?? true
    }

    private func saveSettings() {
        appState.userProfile?.name                   = name
        appState.userProfile?.morningReminderHour    = morningHour
        appState.userProfile?.eveningReviewHour      = eveningHour
        appState.userProfile?.morningReminderEnabled = morningEnabled
        appState.userProfile?.eveningReviewEnabled   = eveningEnabled

        if morningEnabled {
            Task { await NotificationService.shared.scheduleMorningBriefing(hour: morningHour, minute: 0) }
        }
        if eveningEnabled {
            Task { await NotificationService.shared.scheduleEveningReview(hour: eveningHour, minute: 0) }
        }
    }
}
