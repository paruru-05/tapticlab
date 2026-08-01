import CoreHaptics
import Foundation

/// CHHapticEngine を一元管理するシングルトン。
/// resetHandler / stoppedHandler で自動復帰し、アプリ全体で再利用できる。
final class HapticEngineManager: ObservableObject {
    static let shared = HapticEngineManager()

    @Published private(set) var isRunning = false
    @Published private(set) var lastEvent = "—"

    private(set) var engine: CHHapticEngine?
    private var activePlayer: CHHapticAdvancedPatternPlayer?
    private var continuousPlayer: CHHapticAdvancedPatternPlayer?

    private init() {
        setupEngine()
    }

    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            lastEvent = "この端末はハプティクス非対応"
            return
        }
        do {
            engine = try CHHapticEngine()
        } catch {
            lastEvent = "エンジン作成失敗: \(error.localizedDescription)"
            return
        }
        engine?.isAutoShutdownEnabled = true

        engine?.resetHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.lastEvent = "エンジンがリセットされました"
                self?.isRunning = false
                _ = try? self?.start()
            }
        }
        engine?.stoppedHandler = { [weak self] reason in
            DispatchQueue.main.async {
                self?.lastEvent = "エンジン停止: \(reason.rawValue)"
                self?.isRunning = false
                self?.continuousPlayer = nil
            }
        }
    }

    @discardableResult
    func start() throws -> Bool {
        guard let engine else { return false }
        try engine.start()
        isRunning = true
        lastEvent = "エンジン実行中"
        return true
    }

    func stop() {
        try? activePlayer?.stop(atTime: CHHapticTimeImmediate)
        try? continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
        activePlayer = nil
        continuousPlayer = nil
        engine?.stop()
        isRunning = false
        lastEvent = "エンジン停止"
    }

    func stopCurrent() {
        try? activePlayer?.stop(atTime: CHHapticTimeImmediate)
        try? continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
        activePlayer = nil
        continuousPlayer = nil
    }

    /// パターンを再生する。再生前のパターンは停止される。
    func play(_ pattern: CHHapticPattern,
              loop: Bool = false,
              playbackRate: Float = 1.0,
              completion: ((Error?) -> Void)? = nil) {
        stopCurrent()
        do {
            try start()
            let player = try engine?.makeAdvancedPlayer(with: pattern)
            activePlayer = player
            player?.loopEnabled = loop
            player?.playbackRate = playbackRate
            try player?.start(atTime: CHHapticTimeImmediate)
            lastEvent = loop ? "パターン再生中 (ループ)" : "パターン再生中"
            completion?(nil)
        } catch {
            lastEvent = "再生エラー: \(error.localizedDescription)"
            completion?(error)
        }
    }

    func playTransient(intensity: Float, sharpness: Float) {
        do {
            let pattern = try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient,
                              parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                              ],
                              relativeTime: 0)
            ], parameters: [])
            play(pattern)
        } catch {
            lastEvent = "パターン生成エラー: \(error.localizedDescription)"
        }
    }

    func startContinuousIfNeeded(intensity: Float, sharpness: Float) {
        guard continuousPlayer == nil else { return }
        startContinuous(intensity: intensity, sharpness: sharpness)
    }

    func startContinuous(intensity: Float, sharpness: Float) {
        stopCurrent()
        do {
            try start()
            let pattern = try CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticContinuous,
                              parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                              ],
                              relativeTime: 0,
                              duration: 60)
            ], parameters: [])
            let player = try engine?.makeAdvancedPlayer(with: pattern)
            continuousPlayer = player
            try player?.start(atTime: CHHapticTimeImmediate)
            lastEvent = "連続再生中"
        } catch {
            lastEvent = "連続再生エラー: \(error.localizedDescription)"
        }
    }

    /// 再生中の連続パターンに動的パラメータを送る。
    func updateContinuous(intensity: Float, sharpness: Float) {
        do {
            try continuousPlayer?.sendParameters([
                CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0),
                CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: sharpness, relativeTime: 0)
            ], atTime: 0)
        } catch {
            lastEvent = "パラメータ送信エラー: \(error.localizedDescription)"
        }
    }

    func stopContinuous() {
        try? continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
        continuousPlayer = nil
        lastEvent = "連続再生停止"
    }
}
