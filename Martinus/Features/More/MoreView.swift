import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import AppIntents

// MARK: - MoreView
struct MoreView: View {
    @Environment(AppState.self) private var appState
    @State private var showFocusSession = false
    @State private var showInsights     = false
    @State private var showSettings     = false
    @State private var showHelp         = false
    @State private var showSiriSetup    = false

    var body: some View {
        NavigationStack {
            ZStack {
                CinematicBackgroundView(variant: 0)
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
            .sheet(isPresented: $showHelp)        { HelpView() }
            .sheet(isPresented: $showSiriSetup)   { SiriSetupView() }
        }
    }

    private var profileSection: some View {
        HStack(spacing: Spacing.base) {
            ProfileAvatarView(profile: appState.userProfile, size: 60)
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.userProfile?.name ?? "Friend")
                    .font(.ffHeadline2)
                    .foregroundColor(.ffTextPrimary)
                Text(profileSubtitle)
                    .font(.ffBody)
                    .foregroundColor(.ffTextSecondary)
            }
            Spacer()
        }
        .padding(.top, Spacing.xl)
        .contentShape(Rectangle())
        .onTapGesture { showInsights = true }
    }

    private var profileSubtitle: String {
        if let note = appState.userProfile?.personalNote, !note.isBlank { return note }
        if let age = appState.userProfile?.age { return "Age \(age) · Your journey, in focus." }
        return "Tap to complete your profile."
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
            menuRow(icon: "person.crop.circle.fill", label: "Profile & Insights", color: .ffSecondary) { showInsights = true }
            menuRow(icon: "bell.badge.fill",       label: "Custom Reminders", color: .ffWarning)   { showSettings = true }
            menuRow(icon: "waveform.circle.fill",  label: "Siri & Shortcuts",  color: .ffPrimary)   { showSiriSetup = true }
            menuRow(icon: "gearshape.fill",        label: "Settings",         color: .ffNeutral)   { showSettings = true }
            menuRow(icon: "questionmark.circle",   label: "Help & Privacy",   color: .ffSuccess)   { showHelp = true }
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

struct SiriSetupView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                CinematicBackgroundView(variant: 1)
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(LinearGradient.ffBrand)
                            Text("Talk to Martinus")
                                .font(.ffHeadline1)
                                .foregroundColor(.ffTextPrimary)
                            Text("Use Siri without opening the app. Start with one of the exact phrases below.")
                                .font(.ffBody)
                                .foregroundColor(.ffTextSecondary)
                        }

                        commandCard(
                            title: "Add a task",
                            phrase: "Hey Siri, add a task to Martinus",
                            detail: "Siri asks what the task is and exactly when it should happen.",
                            icon: "plus.circle.fill"
                        )
                        commandCard(
                            title: "Schedule an event",
                            phrase: "Hey Siri, schedule an event in Martinus",
                            detail: "Siri asks for the event, its start time, and its end time.",
                            icon: "calendar.badge.plus"
                        )
                        commandCard(
                            title: "Hear today's tasks",
                            phrase: "Hey Siri, what are my tasks in Martinus?",
                            detail: "Siri reads your open Martinus tasks for today.",
                            icon: "checklist"
                        )

                        ShortcutsLink()
                            .shortcutsLinkStyle(.automaticOutline)
                    }
                    .padding(Spacing.base)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("Siri & Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.ffPrimary)
                }
            }
        }
    }

    private func commandCard(title: String, phrase: String, detail: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(title, systemImage: icon)
                .font(.ffHeadline3)
                .foregroundColor(.ffTextPrimary)
            Text("“\(phrase)”")
                .font(.ffBodyMed)
                .foregroundColor(.ffPrimary)
            Text(detail)
                .font(.ffCaption)
                .foregroundColor(.ffTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.base)
        .glassCard()
    }
}

// MARK: - FocusSessionView
struct FocusSessionView: View {
    private let task: FocusTask?
    @Environment(AppState.self) private var appState
    @StateObject private var session = FocusSessionService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var plannedMinutes: Int
    @State private var sessionTitle: String
    @State private var showSettings   = false

    private let durationOptions = [15, 20, 25, 30, 45, 60, 90]

    init(task: FocusTask? = nil) {
        self.task = task
        _plannedMinutes = State(initialValue: 25)
        _sessionTitle = State(initialValue: task?.title ?? "Deep Work")
    }

    var body: some View {
        ZStack {
            CinematicBackgroundView(variant: 0)
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
        .sheet(isPresented: $showSettings) {
            FocusSessionOptionsView(title: $sessionTitle, minutes: $plannedMinutes)
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
        session.start(minutes: plannedMinutes, title: sessionTitle, taskID: task?.id)
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}

private struct FocusSessionOptionsView: View {
    @Binding var title: String
    @Binding var minutes: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    TextField("Session name", text: $title)
                    Stepper("Duration: \(minutes) minutes", value: $minutes, in: 5...180, step: 5)
                }
                Section {
                    Text("The timer works fully offline. Martinus does not stream or track focus audio.")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Focus Options")
            .toolbar { Button("Done") { dismiss() } }
        }
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
    @State private var showProfileEditor = false

    private let periods = ["Week", "Month"]

    var body: some View {
        NavigationStack {
            ZStack {
                CinematicBackgroundView(variant: 0)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        profileCard
                        periodPicker
                        productivitySection
                        taskCompletionSection
                        moodTrendSection
                    }
                    .padding(.horizontal, Spacing.base)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Profile & Insights")
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
            .sheet(isPresented: $showProfileEditor) {
                ProfileEditorView()
            }
        }
    }

    private var profileCard: some View {
        Button {
            showProfileEditor = true
        } label: {
            HStack(spacing: Spacing.base) {
                ProfileAvatarView(profile: appState.userProfile, size: 72)
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.userProfile?.name ?? "Friend")
                        .font(.ffHeadline2)
                        .foregroundColor(.ffTextPrimary)
                    if let age = appState.userProfile?.age {
                        Text("Age \(age)")
                            .font(.ffBody)
                            .foregroundColor(.ffTextSecondary)
                    }
                    if let note = appState.userProfile?.personalNote, !note.isBlank {
                        Text(note)
                            .font(.ffCaption)
                            .foregroundColor(.ffTextSecondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.ffPrimary)
            }
            .padding(Spacing.base)
            .glassCard(cornerRadius: Radius.md)
        }
        .buttonStyle(.plain)
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

// MARK: - Profile
private struct ProfileAvatarView: View {
    let profile: UserProfile?
    let size: CGFloat
    var imageDataOverride: Data? = nil
    var usesImageOverride = false

    var body: some View {
        Group {
            if let data = usesImageOverride ? imageDataOverride : profile?.profileImageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient.ffBrand
                    Text(String(profile?.name.prefix(1) ?? "F").uppercased())
                        .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
    }
}

private struct ProfileEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var ageText = ""
    @State private var personalNote = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var photoToAdjust: Data?
    @State private var showPhotoAdjuster = false

    var body: some View {
        NavigationStack {
            ZStack {
                CinematicBackgroundView(variant: 0)
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        VStack(spacing: Spacing.sm) {
                            ProfileAvatarView(
                                profile: previewProfile,
                                size: 112,
                                imageDataOverride: imageData,
                                usesImageOverride: true
                            )
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Label(imageData == nil ? "Choose Photo" : "Change Photo", systemImage: "photo")
                                    .font(.ffBodyMed)
                                    .foregroundColor(.ffPrimary)
                            }
                            if imageData != nil {
                                Button("Remove Photo") { imageData = nil }
                                    .font(.ffCaption)
                                    .foregroundColor(.ffDanger)
                            }
                        }

                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("About You")
                                .font(.ffHeadline3)
                                .foregroundColor(.ffTextPrimary)
                            FFTextField("Profile name", text: $name, icon: "person.fill")
                            FFTextField("Age", text: $ageText, icon: "calendar")
                                .keyboardType(.numberPad)
                            FFTextField("A short line about you", text: $personalNote, icon: "quote.bubble", axis: .vertical)
                        }
                    }
                    .padding(Spacing.base)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.ffTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveProfile() }
                        .foregroundColor(.ffPrimary)
                        .disabled(name.isBlank || !ageIsValid)
                }
            }
            .onAppear {
                name = appState.userProfile?.name ?? ""
                ageText = appState.userProfile?.age.map(String.init) ?? ""
                personalNote = appState.userProfile?.personalNote ?? ""
                imageData = appState.userProfile?.profileImageData
            }
            .onChange(of: selectedPhoto) { _, newPhoto in
                guard let newPhoto else { return }
                Task {
                    if let data = try? await newPhoto.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            photoToAdjust = data
                            showPhotoAdjuster = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showPhotoAdjuster) {
                if let photoToAdjust {
                    ProfilePhotoAdjuster(imageData: photoToAdjust) { adjustedData in
                        imageData = adjustedData
                        self.photoToAdjust = nil
                    }
                }
            }
        }
    }

    private var ageIsValid: Bool {
        ageText.isBlank || (Int(ageText).map { (1...120).contains($0) } ?? false)
    }

    private var previewProfile: UserProfile? {
        appState.userProfile
    }

    private func saveProfile() {
        appState.userProfile?.name = name.trimmed
        appState.userProfile?.age = Int(ageText)
        appState.userProfile?.personalNote = personalNote.trimmed
        appState.userProfile?.profileImageData = imageData
        try? appState.profileRepo.save()
        HapticManager.success()
        dismiss()
    }
}

private struct ProfilePhotoAdjuster: View {
    let imageData: Data
    let onUsePhoto: (Data) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var zoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var dragStart: CGSize = .zero

    private let previewSize: CGFloat = 280

    var body: some View {
        NavigationStack {
            ZStack {
                CinematicBackgroundView(variant: 0)
                VStack(spacing: Spacing.xl) {
                    Spacer()
                    Text("Move and scale your photo")
                        .font(.ffHeadline2)
                        .foregroundColor(.ffTextPrimary)
                    Text("Drag to reposition. Use the slider to zoom in or out.")
                        .font(.ffBody)
                        .foregroundColor(.ffTextSecondary)
                        .multilineTextAlignment(.center)

                    photoPreview

                    HStack(spacing: Spacing.md) {
                        Image(systemName: "photo").foregroundColor(.ffTextSecondary)
                        Slider(value: $zoom, in: 1...3)
                            .tint(.ffPrimary)
                        Image(systemName: "photo.fill").foregroundColor(.ffPrimary)
                    }
                    .padding(.horizontal, Spacing.xl)

                    Button("Reset") {
                        withAnimation(.spring) {
                            zoom = 1
                            offset = .zero
                            dragStart = .zero
                        }
                    }
                    .font(.ffBodyMed)
                    .foregroundColor(.ffTextSecondary)

                    FFButton("Use This Photo", icon: "checkmark.circle.fill") {
                        guard let data = croppedImageData else { return }
                        onUsePhoto(data)
                        dismiss()
                    }
                    .padding(.horizontal, Spacing.base)
                    Spacer()
                }
            }
            .navigationTitle("Adjust Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.ffTextSecondary)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var photoPreview: some View {
        ZStack {
            Color.black.opacity(0.25)
            if let image = sourceImage {
                let baseScale = max(previewSize / image.size.width, previewSize / image.size.height)
                Image(uiImage: image)
                    .resizable()
                    .frame(width: image.size.width * baseScale * zoom, height: image.size.height * baseScale * zoom)
                    .offset(offset)
            }
        }
        .frame(width: previewSize, height: previewSize)
        .clipShape(Circle())
        .overlay(Circle().stroke(LinearGradient.ffBrand, lineWidth: 3))
        .shadow(color: Color.ffPrimary.opacity(0.25), radius: 24)
        .contentShape(Circle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = CGSize(width: dragStart.width + value.translation.width, height: dragStart.height + value.translation.height)
                }
                .onEnded { _ in dragStart = offset }
        )
    }

    private var sourceImage: UIImage? { UIImage(data: imageData) }

    private var croppedImageData: Data? {
        guard let image = sourceImage else { return nil }
        let outputSize = CGSize(width: 600, height: 600)
        let renderer = UIGraphicsImageRenderer(size: outputSize)
        let rendered = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: outputSize))
            let baseScale = max(outputSize.width / image.size.width, outputSize.height / image.size.height)
            let scale = baseScale * zoom
            let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let offsetScale = outputSize.width / previewSize
            let origin = CGPoint(
                x: (outputSize.width - drawSize.width) / 2 + offset.width * offsetScale,
                y: (outputSize.height - drawSize.height) / 2 + offset.height * offsetScale
            )
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }
        return rendered.jpegData(compressionQuality: 0.86)
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
    @State private var fontStyle          = AppFontStyle.system
    @State private var appearance         = AppAppearance.system

    var body: some View {
        NavigationStack {
            ZStack {
                CinematicBackgroundView(variant: 0)
                List {
                    profileSection
                    appearanceSection
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

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $appearance) {
                ForEach(AppAppearance.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            Picker("Font", selection: $fontStyle) {
                ForEach(AppFontStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            Text("Choose System, Rounded, Serif, or Monospaced. The selection stays on this device.")
                .font(.caption)
                .foregroundColor(.ffTextSecondary)
        }
        .listRowBackground(Color.ffSurfaceElevated)
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
            HStack {
                Text("Storage")
                Spacer()
                Text("On this device").foregroundColor(.ffTextSecondary)
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
        fontStyle      = appState.fontStyle
        appearance     = appState.appearance
    }

    private func saveSettings() {
        appState.userProfile?.name                   = name
        appState.userProfile?.morningReminderHour    = morningHour
        appState.userProfile?.eveningReviewHour      = eveningHour
        appState.userProfile?.morningReminderEnabled = morningEnabled
        appState.userProfile?.eveningReviewEnabled   = eveningEnabled
        appState.fontStyle                            = fontStyle
        appState.appearance                           = appearance
        try? appState.profileRepo.save()

        if morningEnabled {
            Task { await NotificationService.shared.scheduleMorningBriefing(hour: morningHour, minute: 0) }
        } else {
            NotificationService.shared.removeNotifications(withPrefix: "morning-briefing")
        }
        if eveningEnabled {
            Task { await NotificationService.shared.scheduleEveningReview(hour: eveningHour, minute: 0) }
        } else {
            NotificationService.shared.removeNotifications(withPrefix: "evening-review")
        }
    }
}

private struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Martinus") {
                    Label("Plan tasks in Today", systemImage: "calendar")
                    Label("Track goals and milestones", systemImage: "target")
                    Label("Write private journal entries", systemImage: "book.fill")
                    Label("Save favorite quotes", systemImage: "quote.bubble.fill")
                    Label("Run offline focus sessions", systemImage: "timer")
                }
                Section("Privacy") {
                    Text("No account is required. Your tasks, goals, journal, and preferences remain locally on this device. Martinus has no backend, advertising, analytics upload, or subscription.")
                }
                Section("Permissions") {
                    Text("Calendar access is read-only and optional. Notifications are optional and can be changed in iPhone Settings at any time.")
                }
            }
            .navigationTitle("Help & Privacy")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
