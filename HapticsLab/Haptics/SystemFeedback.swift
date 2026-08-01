import UIKit

/// システム標準のフィードバックジェネレータをまとめたヘルパー。
enum SystemFeedback {
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        UIImpactFeedbackGenerator(style: style).impactOccurred(intensity: intensity)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
