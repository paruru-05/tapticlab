import Foundation
import SwiftUI

/// 保存済みパターンの管理(UserDefaults)。変更は自動で永続化される。
@MainActor
final class PatternStore: ObservableObject {
    @Published var patterns: [HapticPattern] {
        didSet { persist() }
    }

    private let storageKey = "savedPatterns"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([HapticPattern].self, from: data) {
            patterns = decoded
        } else {
            patterns = HapticPresets.all
        }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(patterns) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func add(name: String = "New Pattern") {
        patterns.append(HapticPattern(name: name))
    }

    func delete(_ pattern: HapticPattern) {
        patterns.removeAll { $0.id == pattern.id }
    }

    func importAHAP(json: String, name: String = "Imported") {
        let events = AHAPCodec.parseAHAPEvents(from: json)
        guard !events.isEmpty else { return }
        var pattern = HapticPattern(name: name)
        pattern.events = events
        patterns.append(pattern)
    }
}
