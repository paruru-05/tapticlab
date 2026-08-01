import SwiftUI
import UIKit

struct PatternEditorTab: View {
    @EnvironmentObject var engine: HapticEngineManager
    @StateObject private var store = PatternStore()
    @State private var editing: HapticPattern?
    @State private var showingImport = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.patterns) { pattern in
                    Button {
                        editing = pattern
                    } label: {
                        HStack {
                            Text(pattern.name)
                            Spacer()
                            Text("\(pattern.events.count) イベント")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { store.delete(store.patterns[$0]) }
                }
            }
            .navigationTitle("Editor")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        store.add()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("パターン追加")

                    Button {
                        showingImport = true
                    } label: {
                        Image(systemName: "doc.badge.plus")
                    }
                    .accessibilityLabel("AHAPをインポート")
                }
            }
            .sheet(item: $editing) { pattern in
                if let index = store.patterns.firstIndex(where: { $0.id == pattern.id }) {
                    PatternEditorView(pattern: $store.patterns[index])
                        .environmentObject(engine)
                }
            }
            .sheet(isPresented: $showingImport) {
                AHAPImportView { events, name in
                    var pattern = HapticPattern(name: name ?? "Imported")
                    pattern.events = events
                    store.patterns.append(pattern)
                    showingImport = false
                }
            }
        }
    }
}

struct PatternEditorView: View {
    @Binding var pattern: HapticPattern
    @EnvironmentObject var engine: HapticEngineManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAHAP = false
    @State private var status = ""

    var body: some View {
        NavigationStack {
            List {
                Section("パターン") {
                    TextField("名前", text: $pattern.name)
                    Toggle("ループ再生", isOn: $pattern.loopEnabled)
                    HStack {
                        Text("再生速度")
                        Slider(value: $pattern.playbackRate, in: 0.25...2, step: 0.05)
                        Text(pattern.playbackRate.formatted(.number.precision(.fractionLength(2))))
                            .monospacedDigit()
                            .frame(width: 44)
                    }
                }

                Section("イベント") {
                    ForEach($pattern.events) { $event in
                        EventRow(event: $event)
                    }
                    .onDelete { pattern.events.remove(atOffsets: $0) }

                    Button {
                        pattern.events.append(HapticEvent())
                    } label: {
                        Label("イベント追加", systemImage: "plus.circle")
                    }
                }

                if !status.isEmpty {
                    Section("ステータス") {
                        Text(status)
                            .font(.caption.monospaced())
                    }
                }
            }
            .navigationTitle("エディタ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("AHAP") { showingAHAP = true }
                    Button("再生") { play() }
                    Button("閉じる") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAHAP) {
                AHAPExportView(pattern: pattern)
            }
        }
    }

    private func play() {
        do {
            let chPattern = try pattern.makeCHPattern()
            engine.play(chPattern,
                        loop: pattern.loopEnabled,
                        playbackRate: Float(pattern.playbackRate)) { error in
                if let error {
                    status = "エラー: \(error.localizedDescription)"
                } else {
                    status = "再生中"
                }
            }
        } catch {
            status = "エラー: \(error.localizedDescription)"
        }
    }
}

struct EventRow: View {
    @Binding var event: HapticEvent
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack {
                    Text(event.kind == .transient ? "Transient" : "Continuous")
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor.opacity(0.2)))
                    Spacer()
                    Text(String(format: "t: %.2fs", event.relativeTime))
                        .font(.caption.monospaced())
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
            }

            if expanded {
                Picker("種別", selection: $event.kind) {
                    ForEach(HapticEventKind.allCases) { kind in
                        Text(kind == .transient ? "Transient" : "Continuous").tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                slider("開始 t", value: $event.relativeTime, range: 0...3)
                if event.kind == .continuous {
                    slider("持続 dur", value: $event.duration, range: 0.05...2)
                }
                slider("強さ", value: $event.intensity, range: 0...1)
                slider("鋭さ", value: $event.sharpness, range: 0...1)

                if event.kind == .continuous {
                    Toggle("フェードイン", isOn: $event.fadeIn)
                    Toggle("フェードアウト", isOn: $event.fadeOut)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title)
                .font(.footnote)
                .frame(width: 64, alignment: .leading)
            Slider(value: value, in: range)
            Text(value.wrappedValue.formatted(.number.precision(.fractionLength(2))))
                .font(.caption.monospacedDigit())
                .frame(width: 44)
        }
    }
}

struct AHAPExportView: View {
    let pattern: HapticPattern
    @State private var ahapText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TextEditor(text: $ahapText)
                .font(.system(.caption, design: .monospaced))
                .autocorrectionDisabled()
                .padding(8)
                .navigationTitle("AHAP (JSON)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button("コピー") {
                            UIPasteboard.general.string = ahapText
                        }
                        Button("閉じる") { dismiss() }
                    }
                }
                .onAppear {
                    ahapText = (try? AHAPCodec.makeAHAPJSON(from: pattern)) ?? ""
                }
        }
    }
}

struct AHAPImportView: View {
    var onImport: ([HapticEvent], String?) -> Void
    @State private var ahapText = ""
    @State private var name = "Imported"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextField("パターン名", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                TextEditor(text: $ahapText)
                    .font(.system(.caption, design: .monospaced))
                    .autocorrectionDisabled()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.secondary.opacity(0.3))
                    )
                    .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("AHAPをインポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("インポート") {
                        let events = AHAPCodec.parseAHAPEvents(from: ahapText)
                        guard !events.isEmpty else { return }
                        onImport(events, name)
                    }
                    .disabled(AHAPCodec.parseAHAPEvents(from: ahapText).isEmpty)

                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}
