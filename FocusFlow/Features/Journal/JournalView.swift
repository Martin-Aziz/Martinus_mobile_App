import SwiftUI
import SwiftData

// MARK: - JournalViewModel
@MainActor
@Observable
final class JournalViewModel {
    var entries:     [JournalEntry] = []
    var selectedDate = Date()
    var todayEntry:  JournalEntry?  = nil
    var isLoaded     = false
    var showAdd      = false
    var showEdit     = false

    private var journalRepo: JournalRepository?

    func load(journalRepo: JournalRepository) async {
        self.journalRepo = journalRepo
        await refresh()
    }

    func refresh() async {
        entries    = (try? journalRepo?.fetchAll()) ?? []
        todayEntry = entries.first(where: { $0.date.isToday })
        isLoaded   = true
    }

    func delete(_ entry: JournalEntry) {
        journalRepo?.delete(entry)
        Task { await refresh() }
    }

    var entriesByMonth: [String: [JournalEntry]] {
        Dictionary(grouping: entries) { entry in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: entry.date)
        }
    }
}

// MARK: - JournalView
struct JournalView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = JournalViewModel()
    @State private var showAdd   = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ffBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    headerBar
                    weekMoodBar
                    FFDivider()

                    if viewModel.entries.isEmpty {
                        emptyState
                    } else {
                        entriesList
                    }
                }
            }
            .task { await viewModel.load(journalRepo: appState.journalRepo) }
            .sheet(isPresented: $showAdd, onDismiss: { Task { await viewModel.refresh() } }) {
                AddJournalEntryView()
            }
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Journal")
                    .font(.ffDisplay2)
                    .foregroundColor(.ffTextPrimary)
                Text("\(viewModel.entries.count) entries")
                    .font(.ffBody)
                    .foregroundColor(.ffTextSecondary)
            }
            Spacer()
            CircularIconButton("plus", action: { showAdd = true })
        }
        .padding(.horizontal, Spacing.base)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.sm)
    }

    private var weekMoodBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xl) {
                ForEach(last7Days, id: \.self) { date in
                    let entry = viewModel.entries.first(where: { $0.date.isSameDay(as: date) })
                    VStack(spacing: 4) {
                        Text(date.weekdayShort)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.ffTextSecondary)
                        ZStack {
                            Circle()
                                .fill(entry != nil ? Color.ffPrimary.opacity(0.2) : Color.ffSurfaceElevated)
                                .frame(width: 36, height: 36)
                            if let entry {
                                Text(entry.mood.emoji)
                                    .font(.system(size: 18))
                            } else {
                                Text("·")
                                    .font(.system(size: 20))
                                    .foregroundColor(.ffTextTertiary)
                            }
                        }
                        if date.isToday {
                            Circle().fill(Color.ffPrimary).frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.base)
        }
        .padding(.vertical, Spacing.sm)
    }

    private var entriesList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Spacing.md) {
                ForEach(viewModel.entries) { entry in
                    NavigationLink {
                        JournalEntryDetailView(entry: entry, onDelete: { viewModel.delete(entry) })
                    } label: {
                        JournalEntryCard(entry: entry)
                    }
                }
            }
            .padding(.horizontal, Spacing.base)
            .padding(.bottom, 100)
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon:        "book",
            title:       "No journal entries",
            subtitle:    "Write your first reflection. It takes less than 2 minutes.",
            actionLabel: "Write Today's Entry",
            onAction:    { showAdd = true }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var last7Days: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Date().startOfDay) }.reversed()
    }
}

// MARK: - JournalEntryCard
struct JournalEntryCard: View {
    var entry: JournalEntry
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                HStack(spacing: Spacing.xs) {
                    Text(entry.mood.emoji)
                    Text(entry.date.relativeString)
                        .font(.ffCaption)
                        .foregroundColor(.ffTextSecondary)
                }
                Spacer()
                HStack(spacing: Spacing.xs) {
                    moodStat(label: "Energy", value: entry.energy.rawValue, total: 5)
                    moodStat(label: "Focus",  value: entry.focus,           total: 10)
                }
            }

            if !entry.body.isEmpty {
                Text(entry.body)
                    .font(.ffBody)
                    .foregroundColor(.ffTextPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            if !entry.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(entry.tags, id: \.self) { tag in
                            TagChip("#\(tag)", color: .ffSecondary)
                        }
                    }
                }
            }
        }
        .padding(Spacing.base)
        .glassCard()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func moodStat(label: String, value: Int, total: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)/\(total)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.ffTextPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.ffTextSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.ffSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - JournalEntryDetailView
struct JournalEntryDetailView: View {
    var entry:    JournalEntry
    var onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Color.ffBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date.relativeString)
                                .font(.ffDisplay2)
                                .foregroundColor(.ffTextPrimary)
                            Text(entry.date.shortDateString)
                                .font(.ffBody)
                                .foregroundColor(.ffTextSecondary)
                        }
                        Spacer()
                        Text(entry.mood.emoji).font(.system(size: 40))
                    }

                    // Mood stats
                    HStack(spacing: Spacing.base) {
                        statCard(label: "Mood",   value: entry.mood.label,             color: .ffPrimary)
                        statCard(label: "Energy", value: "\(entry.energy.rawValue)/5", color: .ffSecondary)
                        statCard(label: "Focus",  value: "\(entry.focus)/10",          color: .ffSuccess)
                    }

                    if !entry.body.isEmpty {
                        sectionBlock(title: "Today's Entry", content: entry.body)
                    }
                    if !entry.wins.isEmpty {
                        sectionBlock(title: "Wins", content: entry.wins)
                    }
                    if !entry.gratitude.isEmpty {
                        sectionBlock(title: "Grateful for", content: entry.gratitude)
                    }
                    if !entry.intentions.isEmpty {
                        sectionBlock(title: "Tomorrow I want to", content: entry.intentions)
                    }

                    FFButton("Delete Entry", style: .danger, icon: "trash") {
                        showDeleteConfirm = true
                    }
                    .padding(.bottom, Spacing.xxl)
                }
                .padding(Spacing.base)
            }
        }
        .navigationTitle("Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Entry?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { onDelete(); dismiss() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func sectionBlock(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.ffCaption)
                .foregroundColor(.ffTextSecondary)
                .textCase(.uppercase)
                .tracking(1)
            Text(content)
                .font(.ffBody)
                .foregroundColor(.ffTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.base)
        .glassCard()
    }

    private func statCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.ffHeadline3).foregroundColor(color)
            Text(label).font(.ffCaption).foregroundColor(.ffTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .glassCard(cornerRadius: Radius.sm)
    }
}

// MARK: - AddJournalEntryView
struct AddJournalEntryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var body_      = ""
    @State private var wins       = ""
    @State private var gratitude  = ""
    @State private var intentions = ""
    @State private var mood       = Mood.neutral
    @State private var energy     = EnergyLevel.medium
    @State private var focus      = 5
    @State private var tagInput   = ""
    @State private var tags:      [String] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ffBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        moodSection
                        journalBodySection
                        winsSection
                        gratitudeSection
                        intentionsSection
                        tagsSection
                        FFButton("Save Entry", icon: "checkmark.circle.fill") { saveEntry() }
                            .padding(.bottom, Spacing.xxl)
                    }
                    .padding(.horizontal, Spacing.base)
                    .padding(.top, Spacing.base)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.ffTextSecondary)
                }
            }
        }
    }

    private var moodSection: some View {
        VStack(spacing: Spacing.base) {
            // Mood picker
            VStack(spacing: Spacing.sm) {
                Text("How are you feeling?")
                    .font(.ffHeadline3)
                    .foregroundColor(.ffTextPrimary)
                HStack(spacing: Spacing.xl) {
                    ForEach(Mood.allCases) { m in
                        Button(action: { mood = m; HapticManager.light() }) {
                            VStack(spacing: 4) {
                                Text(m.emoji).font(.system(size: 28))
                                    .scaleEffect(mood == m ? 1.2 : 1.0)
                                    .animation(.spring(duration: 0.2), value: mood)
                                Text(m.label).font(.system(size: 10)).foregroundColor(mood == m ? .ffPrimary : .ffTextTertiary)
                            }
                        }
                    }
                }
            }

            // Energy slider
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Energy").font(.ffCaption).foregroundColor(.ffTextSecondary)
                    Spacer()
                    Text(energy.label).font(.ffCaption).foregroundColor(.ffPrimary)
                }
                Slider(value: Binding(
                    get: { Double(energy.rawValue - 1) },
                    set: { energy = EnergyLevel(rawValue: Int($0) + 1) ?? .medium }
                ), in: 0...4, step: 1)
                .tint(.ffSecondary)
            }

            // Focus slider
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Focus level").font(.ffCaption).foregroundColor(.ffTextSecondary)
                    Spacer()
                    Text("\(focus)/10").font(.ffCaption).foregroundColor(.ffSuccess)
                }
                Slider(value: Binding(
                    get: { Double(focus) },
                    set: { focus = Int($0) }
                ), in: 1...10, step: 1)
                .tint(.ffSuccess)
            }
        }
        .padding(Spacing.base)
        .glassCard()
    }

    private var journalBodySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Today's Entry").font(.ffHeadline3).foregroundColor(.ffTextPrimary)
            FFTextField("What happened today? How are you really?", text: $body_, axis: .vertical)
        }
    }

    private var winsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Today's Wins 🏆").font(.ffHeadline3).foregroundColor(.ffTextPrimary)
            FFTextField("What went well?", text: $wins, axis: .vertical)
        }
    }

    private var gratitudeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Grateful for ❤️").font(.ffHeadline3).foregroundColor(.ffTextPrimary)
            FFTextField("Something I appreciate today...", text: $gratitude, axis: .vertical)
        }
    }

    private var intentionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Tomorrow I want to 🎯").font(.ffHeadline3).foregroundColor(.ffTextPrimary)
            FFTextField("My intention for tomorrow...", text: $intentions, axis: .vertical)
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Tags").font(.ffHeadline3).foregroundColor(.ffTextPrimary)
            HStack(spacing: Spacing.sm) {
                FFTextField("Add tag...", text: $tagInput)
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(.ffPrimary)
                }
            }
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(tags, id: \.self) { tag in
                            TagChip("#\(tag)", color: .ffSecondary, onTap: { tags.removeAll { $0 == tag } })
                        }
                    }
                }
            }
        }
    }

    private func addTag() {
        let t = tagInput.trimmed.lowercased()
        guard !t.isEmpty, !tags.contains(t) else { return }
        tags.append(t)
        tagInput = ""
    }

    private func saveEntry() {
        let entry = JournalEntry(
            body:       body_,
            mood:       mood,
            energy:     energy,
            focus:      focus,
            wins:       wins,
            intentions: intentions,
            gratitude:  gratitude,
            tags:       tags
        )
        appState.journalRepo.insert(entry)
        try? appState.journalRepo.save()
        HapticManager.success()
        dismiss()
    }
}
