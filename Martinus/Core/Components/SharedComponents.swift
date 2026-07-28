import SwiftUI
import UIKit

struct CinematicBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    var variant: Int? = nil

    private var imageName: String {
        let names = ["CinematicRoman", "CinematicGreek", "CinematicArena"]
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return names[(variant ?? day) % names.count]
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                Color.ffBackground
                    .opacity(colorScheme == .dark ? 0.38 : 0.60)

                LinearGradient(
                    colors: [
                        Color.ffBackground.opacity(0.70),
                        Color.ffBackground.opacity(0.18),
                        Color.ffBackground.opacity(0.60)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct UserAvatarView: View {
    let profile: UserProfile?
    var size: CGFloat = 52

    var body: some View {
        Group {
            if let data = profile?.profileImageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient.ffBrand
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.42, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.55), lineWidth: 2))
        .shadow(color: Color.black.opacity(0.28), radius: 8, y: 4)
        .accessibilityLabel("Profile")
    }
}

struct CompactCountdownLabel: View {
    let target: Date
    var prefix: String? = nil

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let interval = target.timeIntervalSince(context.date)
            HStack(spacing: 4) {
                Image(systemName: interval <= 0 ? "exclamationmark.circle.fill" : "hourglass")
                Text([prefix, countdownText(interval)].compactMap { $0 }.joined(separator: " · "))
            }
            .font(.ffCaption2)
            .foregroundColor(countdownColor(interval))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(countdownColor(interval).opacity(0.13))
            .clipShape(Capsule())
        }
    }

    private func countdownText(_ interval: TimeInterval) -> String {
        guard interval > 0 else { return "Past due" }
        let totalMinutes = Int(interval) / 60
        let days = totalMinutes / 1_440
        let hours = (totalMinutes % 1_440) / 60
        let minutes = totalMinutes % 60
        if days > 0 { return "\(days)d \(hours)h remaining" }
        if hours > 0 { return "\(hours)h \(minutes)m remaining" }
        return "\(max(1, minutes))m remaining"
    }

    private func countdownColor(_ interval: TimeInterval) -> Color {
        if interval <= 0 || interval <= 3 * 3_600 { return .ffDanger }
        if interval <= 24 * 3_600 { return .ffWarning }
        return .ffSecondary
    }
}

// MARK: - GlassCard
/// Glassmorphism container card matching the design system.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat
    var padding: CGFloat
    var borderOpacity: Double
    var content: () -> Content

    init(
        cornerRadius:  CGFloat = Radius.md,
        padding:       CGFloat = Spacing.base,
        borderOpacity: Double  = 0.12,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius  = cornerRadius
        self.padding       = padding
        self.borderOpacity = borderOpacity
        self.content       = content
    }

    var body: some View {
        content()
            .padding(padding)
            .glassCard(cornerRadius: cornerRadius, borderOpacity: borderOpacity)
    }
}

// MARK: - FFButton (Primary / Secondary / Ghost)
struct FFButton: View {
    enum Style { case primary, secondary, ghost, danger }

    var label:   String
    var style:   Style
    var icon:    String?
    var isLoading: Bool
    var action:  () -> Void

    init(
        _ label:     String,
        style:       Style  = .primary,
        icon:        String? = nil,
        isLoading:   Bool   = false,
        action:      @escaping () -> Void
    ) {
        self.label     = label
        self.style     = style
        self.icon      = icon
        self.isLoading = isLoading
        self.action    = action
    }

    var body: some View {
        Button(action: {
            HapticManager.medium()
            action()
        }) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(labelColor)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(label)
                    .font(.ffBodySemi)
            }
            .foregroundColor(labelColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, Spacing.xl)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .strokeBorder(borderColor, lineWidth: style == .ghost ? 1 : 0)
            )
        }
        .disabled(isLoading)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient.ffBrand
        case .secondary:
            Color.ffSurfaceElevated
        case .ghost:
            Color.clear
        case .danger:
            Color.ffDanger.opacity(0.15)
        }
    }

    private var labelColor: Color {
        switch style {
        case .primary:   return .white
        case .secondary: return .ffTextPrimary
        case .ghost:     return .ffPrimary
        case .danger:    return .ffDanger
        }
    }

    private var borderColor: Color {
        switch style {
        case .ghost: return .ffGlassBorder
        default:     return .clear
        }
    }
}

// MARK: - ProgressRing
struct ProgressRing: View {
    var progress: Double       // 0.0 – 1.0
    var size: CGFloat
    var lineWidth: CGFloat
    var gradient: LinearGradient

    init(
        progress:  Double,
        size:      CGFloat = 64,
        lineWidth: CGFloat = 6,
        gradient:  LinearGradient = .ffBrand
    ) {
        self.progress  = progress.clampedProgress
        self.size      = size
        self.lineWidth = lineWidth
        self.gradient  = gradient
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.ffGlassBorder.opacity(0.65), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)
            Text(progress.percentString)
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundColor(.ffTextPrimary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - PriorityBadge
struct PriorityBadge: View {
    var priority: Priority
    var compact: Bool

    init(_ priority: Priority, compact: Bool = false) {
        self.priority = priority
        self.compact  = compact
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            if !compact {
                Text(priority.label)
                    .font(.ffCaption2)
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    private var color: Color {
        switch priority {
        case .high:   return .ffPriorityHigh
        case .medium: return .ffPriorityMedium
        case .low:    return .ffPriorityLow
        }
    }
}

// MARK: - TagChip
struct TagChip: View {
    var label: String
    var color: Color
    var isSelected: Bool
    var onTap: (() -> Void)?

    init(_ label: String, color: Color = .ffPrimary, isSelected: Bool = false, onTap: (() -> Void)? = nil) {
        self.label      = label
        self.color      = color
        self.isSelected = isSelected
        self.onTap      = onTap
    }

    var body: some View {
        Text(label)
            .font(.ffCaption)
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 6)
            .background(isSelected ? color : color.opacity(0.15))
            .clipShape(Capsule())
            .onTapGesture {
                if let onTap { HapticManager.light(); onTap() }
            }
    }
}

// MARK: - EmptyStateView
struct EmptyStateView: View {
    var icon:     String
    var title:    String
    var subtitle: String
    var actionLabel: String?
    var onAction: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.base) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(LinearGradient.ffBrand)
                .padding(.bottom, Spacing.sm)

            Text(title)
                .font(.ffHeadline3)
                .foregroundColor(.ffTextPrimary)

            Text(subtitle)
                .font(.ffBody)
                .foregroundColor(.ffTextSecondary)
                .multilineTextAlignment(.center)

            if let label = actionLabel, let action = onAction {
                FFButton(label, icon: "plus", action: action)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - SectionHeader
struct SectionHeader: View {
    var title:  String
    var trailingLabel: String?
    var onTap:  (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.ffHeadline3)
                .foregroundColor(.ffTextPrimary)
            Spacer()
            if let label = trailingLabel {
                Button(action: { onTap?() }) {
                    Text(label)
                        .font(.ffCaption)
                        .foregroundColor(.ffPrimary)
                }
            }
        }
    }
}

// MARK: - FFTextField
struct FFTextField: View {
    var placeholder: String
    var icon:        String?
    @Binding var text: String
    var axis: Axis

    init(_ placeholder: String, text: Binding<String>, icon: String? = nil, axis: Axis = .horizontal) {
        self.placeholder = placeholder
        self._text       = text
        self.icon        = icon
        self.axis        = axis
    }

    var body: some View {
        HStack(alignment: axis == .vertical ? .top : .center, spacing: Spacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.ffTextSecondary)
                    .padding(.top, axis == .vertical ? 2 : 0)
            }
            TextField(placeholder, text: $text, axis: axis)
                .font(.ffBody)
                .foregroundColor(.ffTextPrimary)
                .tint(.ffPrimary)
        }
        .padding(Spacing.base)
        .background(Color.ffSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.sm)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

// MARK: - CircularIconButton
struct CircularIconButton: View {
    var icon:  String
    var color: Color
    var size:  CGFloat
    var action: () -> Void

    init(_ icon: String, color: Color = .ffPrimary, size: CGFloat = 44, action: @escaping () -> Void) {
        self.icon   = icon
        self.color  = color
        self.size   = size
        self.action = action
    }

    var body: some View {
        Button(action: { HapticManager.light(); action() }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(color.opacity(0.15))
                .clipShape(Circle())
        }
    }
}

// MARK: - Checkmark Button
struct CheckmarkButton: View {
    var isChecked: Bool
    var color: Color
    var onToggle: () -> Void

    init(isChecked: Bool, color: Color = .ffPrimary, onToggle: @escaping () -> Void) {
        self.isChecked = isChecked
        self.color     = color
        self.onToggle  = onToggle
    }

    var body: some View {
        Button(action: { HapticManager.success(); onToggle() }) {
            ZStack {
                Circle()
                    .stroke(isChecked ? color : Color.white.opacity(0.25), lineWidth: 2)
                    .frame(width: 24, height: 24)
                if isChecked {
                    Circle()
                        .fill(color)
                        .frame(width: 24, height: 24)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .animation(.spring(duration: 0.25), value: isChecked)
        }
    }
}

// MARK: - StatTile
struct StatTile: View {
    var label:  String
    var value:  String
    var icon:   String
    var color:  Color
    var trend:  String?   // e.g. "+20%"

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Spacer()
                if let trend {
                    Text(trend)
                        .font(.ffCaption2)
                        .foregroundColor(.ffSuccess)
                }
            }
            Text(value)
                .font(.ffDisplay2)
                .foregroundColor(.ffTextPrimary)
            Text(label)
                .font(.ffCaption)
                .foregroundColor(.ffTextSecondary)
        }
        .padding(Spacing.base)
        .glassCard(cornerRadius: Radius.sm)
    }
}

// MARK: - Divider
struct FFDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
    }
}
