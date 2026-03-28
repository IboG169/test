import SwiftUI

enum Theme {
    static let accentBlue = Color(red: 0, green: 122.0/255.0, blue: 255.0/255.0)
    static let gold = Color(red: 210.0/255.0, green: 175.0/255.0, blue: 36.0/255.0)
    static let background = Color(UIColor.systemBackground)
    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)

    static let moodEmojis = ["\u{1F61E}", "\u{1F610}", "\u{1F642}", "\u{1F4AA}", "\u{1F525}"]

    static func progressColor(for percentage: Double) -> Color {
        if percentage >= 1.0 { return .green }
        if percentage >= 0.7 { return accentBlue }
        if percentage >= 0.4 { return gold }
        return .orange
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(16)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
