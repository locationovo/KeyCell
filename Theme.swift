import SwiftUI
import UIKit

enum Theme {
    static let bg = Color(UIColor.systemGroupedBackground)
    static let card = Color(UIColor.secondarySystemGroupedBackground)
    static let text = Color(UIColor.label)
    static let subText = Color(UIColor.secondaryLabel)
    static let accent = Color(UIColor.systemBlue)
    static let success = Color(UIColor.systemGreen)
    static let danger = Color(UIColor.systemRed)
    static let border = Color(UIColor.separator)
    static let radius: CGFloat = 16
    
    static func mono(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func text(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

@MainActor class Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}
