import SwiftUI
import SwiftData

@main
struct StatSenseApp: App {
    @StateObject private var accessibilityManager = AccessibilityManager()
    @StateObject private var graphAnalyzer = GraphAnalyzer()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(accessibilityManager)
                .environmentObject(graphAnalyzer)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    // Stop speech when app goes to background or inactive
                    if newPhase == .background || newPhase == .inactive {
                        accessibilityManager.stopSpeaking()
                    }
                }
        }
        .modelContainer(for: SavedGraph.self)
    }
}

