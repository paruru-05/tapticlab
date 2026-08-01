import Foundation

/// HapticPattern ⇄ AHAP(JSON) 変換ユーティリティ。
/// Apple の AHAP 仕様(Version / Metadata / Pattern)に従う。
enum AHAPCodec {

    static func makeAHAPJSON(from pattern: HapticPattern) throws -> String {
        var elements: [[String: Any]] = []
        for event in pattern.events {
            var parameters: [[String: Any]] = [
                ["EventParameterID": "HapticIntensity", "EventParameterValue": event.intensity],
                ["EventParameterID": "HapticSharpness", "EventParameterValue": event.sharpness]
            ]
            if event.fadeIn {
                parameters.append(["EventParameterID": "AttackTime", "EventParameterValue": 0.05])
            }
            var eventDict: [String: Any] = [
                "EventType": event.kind == .transient ? "HapticTransient" : "HapticContinuous",
                "Time": event.relativeTime,
                "EventParameters": parameters
            ]
            if event.kind == .continuous {
                eventDict["EventDuration"] = event.duration
            }
            elements.append(["Event": eventDict])
        }

        let document: [String: Any] = [
            "Version": 1.0,
            "Metadata": ["Project": pattern.name],
            "Pattern": elements
        ]
        let data = try JSONSerialization.data(withJSONObject: document, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// AHAP JSON のイベント部分だけを HapticEvent 配列として読み取る。
    /// 不明な要素は無視し、解析不能なら空配列を返す。
    static func parseAHAPEvents(from json: String) -> [HapticEvent] {
        guard let data = json.data(using: .utf8),
              let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let patternArray = root["Pattern"] as? [[String: Any]]
        else { return [] }

        var result: [HapticEvent] = []
        for element in patternArray {
            guard let eventDict = element["Event"] as? [String: Any] else { continue }
            let type = (eventDict["EventType"] as? String) ?? ""
            let time = (eventDict["Time"] as? Double) ?? 0
            let duration = (eventDict["EventDuration"] as? Double) ?? 0.2

            var intensity: Double = 0.8
            var sharpness: Double = 0.5
            if let parameters = eventDict["EventParameters"] as? [[String: Any]] {
                for parameter in parameters {
                    guard let id = parameter["EventParameterID"] as? String,
                          let value = parameter["EventParameterValue"] as? Double else { continue }
                    switch id {
                    case "HapticIntensity": intensity = value
                    case "HapticSharpness": sharpness = value
                    default: break
                    }
                }
            }

            result.append(HapticEvent(
                kind: type == "HapticContinuous" ? .continuous : .transient,
                relativeTime: time,
                duration: duration,
                intensity: intensity,
                sharpness: sharpness
            ))
        }
        return result
    }
}
