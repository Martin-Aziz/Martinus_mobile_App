import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget Timeline Entry
struct FocusFlowEntry: TimelineEntry {
    var date:        Date
    var focusTitle:  String
    var taskCount:   Int
    var completedCount: Int
    var streakDays:  Int
    var quoteText:   String
    var quoteAuthor: String
}

// MARK: - Widget Provider
struct FocusFlowProvider: TimelineProvider {
    typealias Entry = FocusFlowEntry

    func placeholder(in context: Context) -> FocusFlowEntry {
        FocusFlowEntry(
            date:           Date(),
            focusTitle:     "Finish startup pitch deck",
            taskCount:      5,
            completedCount: 2,
            streakDays:     7,
            quoteText:      "Discipline is the bridge between goals and accomplishment.",
            quoteAuthor:    "Jim Rohn"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusFlowEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusFlowEntry>) -> Void) {
        // In a full production implementation, this reads from an App Group shared UserDefaults
        // that the main app writes to whenever data changes.
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> FocusFlowEntry {
        let defaults    = UserDefaults(suiteName: "group.com.focusflow.app")
        let focusTitle  = defaults?.string(forKey: "widget.focusTitle")  ?? "Set your focus"
        let taskCount   = defaults?.integer(forKey: "widget.taskCount")  ?? 0
        let completed   = defaults?.integer(forKey: "widget.completed")  ?? 0
        let streak      = defaults?.integer(forKey: "widget.streak")     ?? 0
        let quoteText   = defaults?.string(forKey: "widget.quoteText")   ?? "Small steps. Big results."
        let quoteAuthor = defaults?.string(forKey: "widget.quoteAuthor") ?? "FocusFlow"

        return FocusFlowEntry(
            date:           Date(),
            focusTitle:     focusTitle,
            taskCount:      taskCount,
            completedCount: completed,
            streakDays:     streak,
            quoteText:      quoteText,
            quoteAuthor:    quoteAuthor
        )
    }
}

// MARK: - Small Widget View (2×2)
struct SmallWidgetView: View {
    var entry: FocusFlowEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0A0A0F"), Color(hex: "#13131A")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "scope")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(LinearGradient.ffBrand)
                    Text("Focus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                    Spacer()
                    Text("\(entry.completedCount)/\(entry.taskCount)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.5))
                }

                Spacer()

                Text(entry.focusTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#F59E0B"))
                    Text("\(entry.streakDays)d streak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Medium Widget View (4×2)
struct MediumWidgetView: View {
    var entry: FocusFlowEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0A0A0F"), Color(hex: "#13131A")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            HStack(spacing: 12) {
                // Left: Today's Focus
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "scope")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(LinearGradient.ffBrand)
                        Text("Today's Focus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.6))
                    }

                    Text(entry.focusTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#F59E0B"))
                        Text("\(entry.streakDays)d")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1)

                // Right: Progress
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))

                    Text("\(entry.completedCount)/\(entry.taskCount)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(LinearGradient.ffBrand)

                    Text("tasks done")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.5))

                    Spacer()

                    let progress: Double = entry.taskCount > 0
                        ? Double(entry.completedCount) / Double(entry.taskCount)
                        : 0
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient.ffBrand)
                                .frame(width: geo.size.width * progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                .frame(maxWidth: 100, alignment: .leading)
            }
            .padding(14)
        }
    }
}

// MARK: - Lock Screen Widget (accessoryRectangular)
struct LockScreenWidgetView: View {
    var entry: FocusFlowEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "scope")
                .font(.system(size: 12, weight: .bold))
            Text(entry.focusTitle)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
        }
    }
}

// MARK: - Widget Bundle
@main
struct FocusFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusFlowHomeWidget()
        FocusFlowLockScreenWidget()
    }
}

// MARK: - Home Screen Widget
struct FocusFlowHomeWidget: Widget {
    let kind = "FocusFlowHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusFlowProvider()) { entry in
            FocusFlowHomeWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("FocusFlow")
        .description("See your focus and today's progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Home Screen Widget Entry View
struct FocusFlowHomeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: FocusFlowEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Lock Screen Widget
struct FocusFlowLockScreenWidget: Widget {
    let kind = "FocusFlowLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusFlowProvider()) { entry in
            LockScreenWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("FocusFlow Focus")
        .description("See your main focus on the Lock Screen.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Color extension (widget target doesn't import AppTheme)
private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b)
    }
}

private extension LinearGradient {
    static let ffBrand = LinearGradient(
        colors: [Color(hex: "#8C65FF"), Color(hex: "#00D4FF")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}
