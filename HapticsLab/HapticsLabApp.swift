import SwiftUI

@main
struct HapticsLabApp: App {
    @StateObject private var engine = HapticEngineManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .preferredColorScheme(.dark)
                .task {
                    _ = try? engine.start()
                }
        }
    }
}
