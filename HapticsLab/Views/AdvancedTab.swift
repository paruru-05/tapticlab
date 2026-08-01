import SwiftUI

struct AdvancedTab: View {
    @EnvironmentObject var engine: HapticEngineManager
    @State private var liveIntensity: Double = 0.7
    @State private var liveSharpness: Double = 0.5
    @State private var livePlaying = false
    @State private var speed: Double = 1.0
    @State private var loopEnabled = false
    @State private var ahapText = AdvancedTab.sampleAHAP
    @State private var status = ""

    private static let sampleAHAP = """
    {
      "Version": 1.0,
      "Pattern": [
        {
          "Event": {
            "Time": 0.0,
            "EventType": "HapticTransient",
            "EventParameters": [
              { "EventParameterID": "HapticIntensity", "EventParameterValue": 1.0 },
              { "EventParameterID": "HapticSharpness", "EventParameterValue": 0.9 }
            ]
          }
        },
        {
          "Event": {
            "Time": 0.2,
            "EventType": "HapticContinuous",
            "EventDuration": 0.4,
            "EventParameters": [
              { "EventParameterID": "HapticIntensity", "EventParameterValue": 0.6 },
              { "EventParameterID": "HapticSharpness", "EventParameterValue": 0.3 }
            ]
          }
        }
      ]
    }
    """

    var body: some View {
        NavigationStack {
            List {
                Section("Engine") {
                    LabeledContent("状態") {
                        Text(engine.isRunning ? "実行中" : "停止")
                            .foregroundStyle(engine.isRunning ? .green : .secondary)
                    }
                    Button {
                        try? engine.start()
                    } label: {
                        Label("Start", systemImage: "play.fill")
                    }
                    Button {
                        engine.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                }

                Section("ライブ調整 (連続再生)") {
                    HStack {
                        Text("強さ")
                        Slider(value: $liveIntensity, in: 0...1)
                        Text(liveIntensity.formatted(.number.precision(.fractionLength(2))))
                            .monospacedDigit()
                            .frame(width: 44)
                    }
                    HStack {
                        Text("鋭さ")
                        Slider(value: $liveSharpness, in: 0...1)
                        Text(liveSharpness.formatted(.number.precision(.fractionLength(2))))
                            .monospacedDigit()
                            .frame(width: 44)
                    }
                    Button {
                        toggleContinuous()
                    } label: {
                        Label(livePlaying ? "連続再生を停止" : "連続再生を開始", systemImage: livePlaying ? "stop.circle" : "play.circle")
                    }
                }
                .onChange(of: liveIntensity) { _, newValue in
                    if livePlaying { engine.updateContinuous(intensity: Float(newValue), sharpness: Float(liveSharpness)) }
                }
                .onChange(of: liveSharpness) { _, newValue in
                    if livePlaying { engine.updateContinuous(intensity: Float(liveIntensity), sharpness: Float(newValue)) }
                }

                Section("再生速度 / ループ") {
                    HStack {
                        Text("速度")
                        Slider(value: $speed, in: 0.25...2, step: 0.05)
                        Text(speed.formatted(.number.precision(.fractionLength(2))))
                            .monospacedDigit()
                            .frame(width: 44)
                    }
                    Toggle("ループ", isOn: $loopEnabled)
                    Button {
                        playPreset()
                    } label: {
                        Label("プリセット (Tap) で再生", systemImage: "waveform")
                    }
                }

                Section("生 AHAP") {
                    TextEditor(text: $ahapText)
                        .font(.system(.caption, design: .monospaced))
                        .autocorrectionDisabled()
                        .frame(minHeight: 180)
                    Button {
                        playAHAP()
                    } label: {
                        Label("AHAPを再生", systemImage: "play.fill")
                    }
                }

                if !status.isEmpty {
                    Section("ステータス") {
                        Text(status)
                            .font(.caption.monospaced())
                    }
                }

                Section("Engine イベント") {
                    Text(engine.lastEvent)
                        .font(.caption.monospaced())
                }
            }
            .navigationTitle("Advanced")
            .onDisappear {
                if livePlaying { toggleContinuous() }
            }
        }
    }

    private func toggleContinuous() {
        livePlaying.toggle()
        if livePlaying {
            engine.startContinuous(intensity: Float(liveIntensity), sharpness: Float(liveSharpness))
        } else {
            engine.stopContinuous()
        }
    }

    private func playPreset() {
        guard let preset = HapticPresets.all.first else { return }
        do {
            let chPattern = try preset.makeCHPattern()
            engine.play(chPattern, loop: loopEnabled, playbackRate: Float(speed)) { error in
                status = error.map { "エラー: \($0.localizedDescription)" } ?? "再生中"
            }
        } catch {
            status = "エラー: \(error.localizedDescription)"
        }
    }

    private func playAHAP() {
        let events = AHAPCodec.parseAHAPEvents(from: ahapText)
        guard !events.isEmpty else {
            status = "AHAPを解析できませんでした"
            return
        }
        var pattern = HapticPattern(name: "AHAP")
        pattern.events = events
        do {
            let chPattern = try pattern.makeCHPattern()
            engine.play(chPattern, loop: loopEnabled, playbackRate: Float(speed)) { error in
                status = error.map { "エラー: \($0.localizedDescription)" } ?? "\(events.count) イベントを再生中"
            }
        } catch {
            status = "エラー: \(error.localizedDescription)"
        }
    }
}
