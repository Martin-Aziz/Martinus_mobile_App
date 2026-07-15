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
    static let ffBackground      = Color(hex: "#0A0A0F")
    static let ffSurface         = Color(hex: "#13131A")
    static let ffSurfaceElevated = Color(hex: "#1C1C28")

    // Glass
    static let ffGlass          = Color.white.opacity(0.06)
    static let ffGlassBorder    = Color.white.opacity(0.12)
    static let ffGlassBorderHover = Color.white.opacity(0.20)

    // Text
    static let ffTextPrimary   = Color.white
    static let ffTextSecondary = Color.white.opacity(0.60)
    static let ffTextTertiary  = Color.white.opacity(0.35)

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

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(backgroundOpacity))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Color.white.opacity(borderOpacity), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = Radius.md, borderOpacity: Double = 0.12) -> some View {
        modifier(GlassmorphismModifier(cornerRadius: cornerRadius, borderOpacity: borderOpacity))
    }
}
