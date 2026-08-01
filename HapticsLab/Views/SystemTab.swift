import SwiftUI
import UIKit

struct SystemTab: View {
    @State private var impactIntensity: Double = 1.0
    @State private var lastFeedback = "—"

    private let notificationTypes: [(UINotificationFeedbackGenerator.FeedbackType, String, String)] = [
        (.success, "success", "checkmark.circle.fill"),
        (.warning, "warning", "exclamationmark.triangle.fill"),
        (.error, "error", "xmark.octagon.fill")
    ]

    private let impactStyles: [(UIImpactFeedbackGenerator.FeedbackStyle, String)] = [
        (.light, "light"),
        (.medium, "medium"),
        (.heavy, "heavy"),
        (.soft, "soft"),
        (.rigid, "rigid")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("通知") {
                    ForEach(notificationTypes, id: \.0) { type, label, icon in
                        Button {
                            lastFeedback = "notification · \(label)"
                            SystemFeedback.notification(type)
                        } label: {
                            Label(label, systemImage: icon)
                        }
                    }
                }

                Section {
                    ForEach(impactStyles, id: \.0) { style, label in
                        Button {
                            lastFeedback = "impact · \(label)"
                            SystemFeedback.impact(style, intensity: impactIntensity)
                        } label: {
                            Label(label, systemImage: "circle.dotted")
                        }
                    }
                } header: {
                    Text("インパクト")
                } footer: {
                    Text("強度は impactOccurred(intensity:) に反映されます")
                }

                Section {
                    HStack {
                        Text("強度")
                        Slider(value: $impactIntensity, in: 0...1)
                        Text(impactIntensity.formatted(.number.precision(.fractionLength(2))))
                            .monospacedDigit()
                            .frame(width: 44)
                    }
                }

                Section("選択") {
                    Button {
                        lastFeedback = "selection"
                        SystemFeedback.selection()
                    } label: {
                        Label("selectionChanged", systemImage: "hand.tap")
                    }
                }
            }
            .navigationTitle("System")
            .safeAreaInset(edge: .bottom) {
                Text("Last: \(lastFeedback)")
                    .font(.caption.monospaced())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
            }
        }
    }
}
