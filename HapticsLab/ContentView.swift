import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SystemTab()
                .tabItem { Label("System", systemImage: "iphone.radiowaves.left.and.right") }
            PlaygroundTab()
                .tabItem { Label("Playground", systemImage: "hand.draw") }
            PatternEditorTab()
                .tabItem { Label("Editor", systemImage: "waveform.path.ecg") }
            AdvancedTab()
                .tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }
        }
    }
}
