import SwiftUI

// MARK: - Color Palette (from design spec)
extension Color {
    // Primary brand
    static let ffPrimary   = Color(hex: "#8C65FF") // purple
    static let ffSecondary = Color(hex: "#00D4FF") // cyan
    static let ffSuccess   = Color(hex: "#22C55E")
    static let ffWarning   = Color(hex: "#F59E0B")
    static let ffDanger    = Color(hex: "#EF4444")
    static let ffNeutral   = Color(hex: "#6B7280")

    // Backgrounds
    static let ffBackground      = Color.dynamic(light: "#F6F5FA", dark: "#0A0A0F")
    static let ffSurface         = Color.dynamic(light: "#FFFFFF", dark: "#13131A")
    static let ffSurfaceElevated = Color.dynamic(light: "#EEEAF6", dark: "#1C1C28")

    // Glass
    static let ffGlass          = Color.dynamic(light: "#FFFFFF", dark: "#FFFFFF").opacity(0.10)
    static let ffGlassBorder    = Color.dynamic(light: "#4B3F72", dark: "#FFFFFF").opacity(0.14)
    static let ffGlassBorderHover = Color.dynamic(light: "#4B3F72", dark: "#FFFFFF").opacity(0.22)

    // Text
    static let ffTextPrimary   = Color.dynamic(light: "#18151F", dark: "#FFFFFF")
    static let ffTextSecondary = Color.dynamic(light: "#5F586B", dark: "#FFFFFF").opacity(0.68)
    static let ffTextTertiary  = Color.dynamic(light: "#81798D", dark: "#FFFFFF").opacity(0.48)

    // Priority colors
    static let ffPriorityHigh   = Color(hex: "#EF4444")
    static let ffPriorityMedium = Color(hex: "#F59E0B")
    static let ffPriorityLow    = Color(hex: "#22C55E")

    // Gradient stops
    static let ffGradientStart = Color(hex: "#8C65FF")
    static let ffGradientEnd   = Color(hex: "#00D4FF")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }

    static func dynamic(light: String, dark: String) -> Color {
        Color(UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}

// MARK: - Gradient Presets
extension LinearGradient {
    static let ffBrand = LinearGradient(
        colors: [.ffGradientStart, .ffGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let ffPurpleDeep = LinearGradient(
        colors: [Color(hex: "#6B46FF"), Color(hex: "#8C65FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let ffCyan = LinearGradient(
        colors: [Color(hex: "#00D4FF"), Color(hex: "#0095FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let ffSuccess = LinearGradient(
        colors: [Color(hex: "#22C55E"), Color(hex: "#16A34A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let ffWarning = LinearGradient(
        colors: [Color(hex: "#F59E0B"), Color(hex: "#D97706")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Spacing System (base 8)
enum Spacing {
    static let xs:   CGFloat = 4
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 12
    static let base: CGFloat = 16
    static let lg:   CGFloat = 20
    static let xl:   CGFloat = 24
    static let xxl:  CGFloat = 32
    static let xxxl: CGFloat = 40
    static let huge: CGFloat = 48
    static let giant: CGFloat = 64
}

// MARK: - Corner Radius
enum Radius {
    static let xs:  CGFloat = 8
    static let sm:  CGFloat = 12
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 20
    static let xl:  CGFloat = 24
    static let full: CGFloat = 999
}

// MARK: - Shadow Presets
struct AppShadow {
    static let glow = Color.ffPrimary.opacity(0.32)
    static let soft = Color.black.opacity(0.25)

    static func purpleGlow(radius: CGFloat = 20) -> some View {
        RoundedRectangle(cornerRadius: Radius.md)
            .fill(Color.ffPrimary.opacity(0.15))
            .blur(radius: radius)
    }
}

// MARK: - Glassmorphism Style
struct GlassmorphismModifier: ViewModifier {
    var cornerRadius: CGFloat = Radius.md
    var borderOpacity: Double = 0.12
    var backgroundOpacity: Double = 0.06
    var blurRadius: CGFloat = 20

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(Color.ffGlass.opacity(max(backgroundOpacity, 0.04)))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(Color.ffGlassBorder.opacity(max(borderOpacity, 0.12)), lineWidth: 1)
                        )
                )
        }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = Radius.md, borderOpacity: Double = 0.12) -> some View {
        modifier(GlassmorphismModifier(cornerRadius: cornerRadius, borderOpacity: borderOpacity))
    }
}
