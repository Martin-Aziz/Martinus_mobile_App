import SwiftUI

// MARK: - Typography System
extension Font {
    private static var preferredDesign: Font.Design { AppFontStyle.saved.design }
    // Display (SF Pro Display)
    static var ffDisplay1: Font { .system(size: 34, weight: .bold, design: preferredDesign) }
    static var ffDisplay2: Font { .system(size: 28, weight: .bold, design: preferredDesign) }

    // Headlines (SF Pro Display)
    static var ffHeadline1: Font { .system(size: 22, weight: .semibold, design: preferredDesign) }
    static var ffHeadline2: Font { .system(size: 20, weight: .semibold, design: preferredDesign) }
    static var ffHeadline3: Font { .system(size: 18, weight: .semibold, design: preferredDesign) }

    // Body (SF Pro Text)
    static var ffBody: Font { .system(size: 16, weight: .regular, design: preferredDesign) }
    static var ffBodyMed: Font { .system(size: 16, weight: .medium, design: preferredDesign) }
    static var ffBodySemi: Font { .system(size: 16, weight: .semibold, design: preferredDesign) }

    // Subheadline
    static var ffSubhead: Font { .system(size: 15, weight: .regular, design: preferredDesign) }
    static var ffSubheadMed: Font { .system(size: 15, weight: .medium, design: preferredDesign) }

    // Caption (SF Pro Text)
    static var ffCaption: Font { .system(size: 13, weight: .medium, design: preferredDesign) }
    static var ffCaption2: Font { .system(size: 12, weight: .regular, design: preferredDesign) }

    // Monospaced (for timer)
    static var ffMono: Font { .system(size: 48, weight: .thin, design: .monospaced) }
    static var ffMonoSm: Font { .system(size: 24, weight: .light, design: .monospaced) }

    // Quote
    static var ffQuote: Font { .system(size: 20, weight: .semibold, design: preferredDesign == .default ? .serif : preferredDesign) }
}

// MARK: - View Extensions
extension View {
    // Typography shortcuts
    func ffDisplay()   -> some View { self.font(.ffDisplay1).foregroundColor(.ffTextPrimary) }
    func ffHeadline()  -> some View { self.font(.ffHeadline1).foregroundColor(.ffTextPrimary) }
    func ffBody()      -> some View { self.font(.ffBody).foregroundColor(.ffTextPrimary) }
    func ffCaption()   -> some View { self.font(.ffCaption).foregroundColor(.ffTextSecondary) }

    // Haptics
    func hapticLight()   -> some View { self }
    func hapticMedium()  -> some View { self }
    func hapticHeavy()   -> some View { self }

    // Card styling
    func ffCard(padding: CGFloat = Spacing.base) -> some View {
        self
            .padding(padding)
            .glassCard()
    }

    // Conditional modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Haptic Utilities
struct HapticManager {
    static func light()    { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium()   { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func heavy()    { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func success()  { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning()  { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func error()    { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}

// MARK: - Date Extensions
extension Date {
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isTomorrow: Bool { Calendar.current.isDateInTomorrow(self) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(self) }
    var isPast: Bool { self < Date() }

    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    var relativeString: String {
        if isToday     { return "Today" }
        if isTomorrow  { return "Tomorrow" }
        if isYesterday { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    var weekdayShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self).uppercased()
    }

    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    func daysUntil(_ other: Date) -> Int {
        Calendar.current.dateComponents([.day], from: startOfDay, to: other.startOfDay).day ?? 0
    }
}

// MARK: - String Extensions
extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

// MARK: - Double Extensions
extension Double {
    var percentString: String { String(format: "%.0f%%", self * 100) }
    var clampedProgress: Double { min(max(self, 0), 1) }
}
