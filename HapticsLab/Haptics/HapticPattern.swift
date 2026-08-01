import CoreHaptics
import Foundation

enum HapticEventKind: String, Codable, CaseIterable, Identifiable {
    case transient
    case continuous
    var id: String { rawValue }
}

struct HapticEvent: Codable, Identifiable, Hashable {
    var id = UUID()
    var kind: HapticEventKind = .transient
    var relativeTime: Double = 0
    var duration: Double = 0.2
    var intensity: Double = 0.8
    var sharpness: Double = 0.5
    var fadeIn: Bool = false
    var fadeOut: Bool = false
}

struct HapticPattern: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String = "New Pattern"
    var events: [HapticEvent] = []
    var loopEnabled: Bool = false
    var playbackRate: Double = 1.0

    /// モデルを CoreHaptics の CHHapticPattern に変換する。
    func makeCHPattern() throws -> CHHapticPattern {
        var chEvents: [CHHapticEvent] = []
        var curves: [CHHapticParameterCurve] = []

        for event in events {
            let parameters = [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(event.intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(event.sharpness))
            ]
            switch event.kind {
            case .transient:
                chEvents.append(
                    CHHapticEvent(eventType: .hapticTransient,
                                  parameters: parameters,
                                  relativeTime: event.relativeTime)
                )
            case .continuous:
                chEvents.append(
                    CHHapticEvent(eventType: .hapticContinuous,
                                  parameters: parameters,
                                  relativeTime: event.relativeTime,
                                  duration: event.duration)
                )
                if event.fadeIn, event.duration > 0 {
                    curves.append(
                        CHHapticParameterCurve(
                            parameterID: .hapticIntensityControl,
                            controlPoints: [
                                CHHapticParameterCurve.ControlPoint(relativeTime: event.relativeTime, value: 0),
                                CHHapticParameterCurve.ControlPoint(relativeTime: event.relativeTime + event.duration * 0.3, value: Float(event.intensity))
                            ],
                            relativeTime: 0
                        )
                    )
                }
                if event.fadeOut, event.duration > 0 {
                    curves.append(
                        CHHapticParameterCurve(
                            parameterID: .hapticIntensityControl,
                            controlPoints: [
                                CHHapticParameterCurve.ControlPoint(relativeTime: event.relativeTime + event.duration * 0.7, value: Float(event.intensity)),
                                CHHapticParameterCurve.ControlPoint(relativeTime: event.relativeTime + event.duration, value: 0)
                            ],
                            relativeTime: 0
                        )
                    )
                }
            }
        }
        return try CHHapticPattern(events: chEvents, parameterCurves: curves)
    }
}
