import SwiftUI

struct TabVisualTheme {
    let background: Color
    let accent: Color
    let card: Color
    var gradient: LinearGradient { LinearGradient(colors: [background, card, background.opacity(0.94)], startPoint: .topLeading, endPoint: .bottomTrailing) }
    var heroGradient: LinearGradient { LinearGradient(colors: [accent.opacity(0.50), card, background], startPoint: .topLeading, endPoint: .bottomTrailing) }
    var accentGradient: LinearGradient { LinearGradient(colors: [accent, accent.opacity(0.62)], startPoint: .topLeading, endPoint: .bottomTrailing) }
}

enum TwentyOneTab {
    case profile, dailies, market, bosses, history, achievements, assistant
    var theme: TabVisualTheme {
        switch self {
        case .profile: return TabVisualTheme(background: Color(red: 0.06, green: 0.07, blue: 0.18), accent: Color(red: 0.48, green: 0.44, blue: 1.00), card: Color(red: 0.15, green: 0.14, blue: 0.32))
        case .dailies: return TabVisualTheme(background: Color(red: 0.03, green: 0.13, blue: 0.10), accent: Color(red: 0.16, green: 0.85, blue: 0.58), card: Color(red: 0.07, green: 0.24, blue: 0.18))
        case .market: return TabVisualTheme(background: Color(red: 0.14, green: 0.10, blue: 0.04), accent: Color(red: 1.00, green: 0.68, blue: 0.16), card: Color(red: 0.26, green: 0.19, blue: 0.09))
        case .bosses: return TabVisualTheme(background: Color(red: 0.15, green: 0.04, blue: 0.06), accent: Color(red: 1.00, green: 0.32, blue: 0.30), card: Color(red: 0.27, green: 0.09, blue: 0.12))
        case .history: return TabVisualTheme(background: Color(red: 0.03, green: 0.12, blue: 0.14), accent: Color(red: 0.16, green: 0.83, blue: 0.72), card: Color(red: 0.08, green: 0.25, blue: 0.26))
        case .achievements: return TabVisualTheme(background: Color(red: 0.09, green: 0.06, blue: 0.18), accent: Color(red: 0.74, green: 0.40, blue: 1.00), card: Color(red: 0.18, green: 0.13, blue: 0.30))
        case .assistant: return TabVisualTheme(background: Color(red: 0.04, green: 0.09, blue: 0.19), accent: Color(red: 0.30, green: 0.58, blue: 1.00), card: Color(red: 0.11, green: 0.18, blue: 0.32))
        }
    }
}

enum AppPalette {
    static let ink = Color(red: 0.21, green: 0.11, blue: 0.05)
    static let parchment = Color(red: 0.91, green: 0.89, blue: 0.68)
    static let cream = Color(red: 0.96, green: 0.93, blue: 0.82)
    static let gold = Color(red: 0.85, green: 0.72, blue: 0.29)
    static let goldDeep = Color(red: 0.60, green: 0.42, blue: 0.09)
}

enum RankPalette {
    static func color(for rank: String) -> Color {
        switch rank {
        case "R": return Color(red: 1.00, green: 0.30, blue: 0.42)
        case "SSS", "SS": return Color(red: 0.98, green: 0.55, blue: 0.20)
        case "S": return AppPalette.gold
        case "A": return Color(red: 0.74, green: 0.40, blue: 1.00)
        case "B": return Color(red: 0.30, green: 0.58, blue: 1.00)
        case "C": return Color(red: 0.16, green: 0.83, blue: 0.72)
        case "D": return Color(red: 0.16, green: 0.85, blue: 0.58)
        case "E": return Color(red: 0.62, green: 0.78, blue: 0.38)
        default: return Color(red: 0.72, green: 0.66, blue: 0.58)
        }
    }
    static func gradient(for rank: String) -> LinearGradient { LinearGradient(colors: [color(for: rank), color(for: rank).opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing) }
}

struct TwentyCardModifier: ViewModifier {
    let fill: Color
    var radius: CGFloat = 20
    func body(content: Content) -> some View {
        content.padding(16).background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill.opacity(0.92))).overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Color.white.opacity(0.10), lineWidth: 1)).shadow(color: Color.black.opacity(0.28), radius: 14, x: 0, y: 8)
    }
}

extension View {
    func twentyCard(_ fill: Color, radius: CGFloat = 20) -> some View { modifier(TwentyCardModifier(fill: fill, radius: radius)) }
}

struct TwentyPrimaryButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(.white).padding(.horizontal, 16).padding(.vertical, 9).background(Capsule().fill(LinearGradient(colors: [color, color.opacity(0.62)], startPoint: .topLeading, endPoint: .bottomTrailing))).overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1)).shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4).opacity(configuration.isPressed ? 0.75 : 1).scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct TwentySecondaryButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(color).padding(.horizontal, 14).padding(.vertical, 8).background(Capsule().fill(color.opacity(0.14))).overlay(Capsule().strokeBorder(color.opacity(0.45), lineWidth: 1)).opacity(configuration.isPressed ? 0.7 : 1).scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct RankBadge: View {
    let rank: String
    var body: some View {
        Text(rank).font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(.white).padding(.horizontal, 7).padding(.vertical, 3).background(Capsule().fill(RankPalette.gradient(for: rank))).overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
    }
}

struct GradientProgressBar: View {
    let value: Double
    let total: Double
    let color: Color
    var height: CGFloat = 10
    private var fraction: Double { total > 0 ? min(max(value / total, 0), 1) : 0 }
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.14))
                Capsule().fill(LinearGradient(colors: [color, color.opacity(0.6)], startPoint: .leading, endPoint: .trailing)).frame(width: geo.size.width * fraction)
            }
        }.frame(height: height)
    }
}

struct ItemArtwork: View {
    let imageName: String
    var fallbackIcon: String = "star.fill"
    var size: CGFloat = 56
    var body: some View {
        Group {
            if UIImage(named: imageName) != nil {
                Image(imageName).resizable().interpolation(.none).scaledToFit()
            } else {
                Image(systemName: fallbackIcon).font(.system(size: size * 0.42, weight: .semibold)).foregroundStyle(AppPalette.gold)
            }
        }
        .frame(width: size, height: size)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }
}

struct StatPill: View {
    let icon: String
    let text: String
    let color: Color
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold))
            Text(text).font(.system(size: 12, weight: .semibold)).lineLimit(1)
        }.foregroundStyle(color).padding(.horizontal, 9).padding(.vertical, 5).background(Capsule().fill(color.opacity(0.16)))
    }
}
