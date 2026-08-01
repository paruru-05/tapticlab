import Foundation

/// サンプルパターン集。
enum HapticPresets {
    static let all: [HapticPattern] = [tap, doubleTap, pulse, heartbeat, rampUp, alarm]

    static let tap = HapticPattern(name: "Tap", events: [
        HapticEvent(kind: .transient, relativeTime: 0, intensity: 0.8, sharpness: 0.9)
    ])

    static let doubleTap = HapticPattern(name: "Double Tap", events: [
        HapticEvent(kind: .transient, relativeTime: 0, intensity: 0.7, sharpness: 0.8),
        HapticEvent(kind: .transient, relativeTime: 0.12, intensity: 0.7, sharpness: 0.8)
    ])

    static let pulse = HapticPattern(name: "Pulse", events: [
        HapticEvent(kind: .transient, relativeTime: 0, intensity: 1.0, sharpness: 0.5),
        HapticEvent(kind: .transient, relativeTime: 0.15, intensity: 0.5, sharpness: 0.5)
    ])

    static let heartbeat = HapticPattern(name: "Heartbeat", events: [
        HapticEvent(kind: .continuous, relativeTime: 0, duration: 0.18, intensity: 1.0, sharpness: 0.7),
        HapticEvent(kind: .transient, relativeTime: 0.22, intensity: 0.6, sharpness: 0.5),
        HapticEvent(kind: .transient, relativeTime: 0.34, intensity: 0.5, sharpness: 0.5)
    ])

    static let rampUp = HapticPattern(name: "Ramp Up", events: (0..<10).map { index in
        HapticEvent(kind: .transient,
                    relativeTime: Double(index) * 0.08,
                    intensity: 0.1 + Double(index) * 0.09,
                    sharpness: 0.4)
    })

    static let alarm = HapticPattern(name: "Alarm", events: (0..<6).map { index in
        HapticEvent(kind: .continuous,
                    relativeTime: Double(index) * 0.3,
                    duration: 0.15,
                    intensity: 1.0,
                    sharpness: 0.9)
    })
}
