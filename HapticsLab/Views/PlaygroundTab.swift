import CoreHaptics
import SwiftUI

struct PlaygroundTab: View {
    @EnvironmentObject var engine: HapticEngineManager
    @State private var mode: PlayMode = .transient
    @State private var touchLocation: CGPoint?
    @State private var paletteSize: CGSize = .zero
    @State private var lastTransientAt = Date.distantPast

    enum PlayMode: String, CaseIterable, Identifiable {
        case transient
        case continuous
        var id: String { rawValue }
    }

    private var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    private var intensity: Double {
        guard paletteSize.height > 0, let location = touchLocation else { return 0.5 }
        return max(0, min(1, 1 - location.y / paletteSize.height))
    }

    private var sharpness: Double {
        guard paletteSize.width > 0, let location = touchLocation else { return 0.5 }
        return max(0, min(1, location.x / paletteSize.width))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if !supportsHaptics {
                    Label("この端末ではハプティクスをサポートしていません", systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }

                Picker("Mode", selection: $mode) {
                    ForEach(PlayMode.allCases) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                palette
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.horizontal)

                VStack(spacing: 6) {
                    Text("強さ \(intensity.formatted(.number.precision(.fractionLength(2))))")
                    Text("鋭さ \(sharpness.formatted(.number.precision(.fractionLength(2))))")
                }
                .font(.body.monospaced())
            }
            .navigationTitle("Playground")
            .onDisappear {
                if mode == .continuous {
                    engine.stopContinuous()
                }
            }
        }
    }

    private var palette: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .blue.opacity(0.25), location: 0),
                                .init(color: .purple, location: 0.5),
                                .init(color: .pink, location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(gridLines)

                if let location = touchLocation {
                    Circle()
                        .fill(.white)
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(.black.opacity(0.35), lineWidth: 2))
                        .shadow(radius: 4)
                        .position(location)
                }
            }
            .overlay(alignment: .topLeading) {
                Text("鋭さ →")
                    .font(.caption2.bold())
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(10)
            }
            .overlay(alignment: .bottomTrailing) {
                Text("強さ ↑")
                    .font(.caption2.bold())
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .gesture(dragGesture(in: geo.size))
            .onAppear { paletteSize = geo.size }
            .onChange(of: geo.size) { _, newSize in paletteSize = newSize }
        }
    }

    private var gridLines: some View {
        GeometryReader { geo in
            Path { path in
                for i in 1..<5 {
                    let x = geo.size.width * CGFloat(i) / 5
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))

                    let y = geo.size.height * CGFloat(i) / 5
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(.white.opacity(0.25), lineWidth: 0.5)
        }
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let location = CGPoint(
                    x: max(0, min(size.width, value.location.x)),
                    y: max(0, min(size.height, value.location.y))
                )
                touchLocation = location
                switch mode {
                case .transient:
                    if Date().timeIntervalSince(lastTransientAt) > 0.12 {
                        lastTransientAt = Date()
                        engine.playTransient(intensity: Float(intensity), sharpness: Float(sharpness))
                    }
                case .continuous:
                    engine.startContinuousIfNeeded(intensity: Float(intensity), sharpness: Float(sharpness))
                    engine.updateContinuous(intensity: Float(intensity), sharpness: Float(sharpness))
                }
            }
            .onEnded { _ in
                touchLocation = nil
                if mode == .continuous {
                    engine.stopContinuous()
                }
            }
    }
}
