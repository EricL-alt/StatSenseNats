import SwiftUI

struct ContentView: View {
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @EnvironmentObject var graphAnalyzer: GraphAnalyzer
    @State private var selectedTab: Tab = .capture

    enum Tab: String, CaseIterable {
        case capture = "Capture"
        case history = "History"
        case settings = "Settings"
        case info = "Info"

        var icon: String {
            switch self {
            case .capture: return "camera.fill"
            case .history: return "clock.fill"
            case .settings: return "gearshape.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            CaptureView()
                .tabItem {
                    Label(Tab.capture.rawValue, systemImage: Tab.capture.icon)
                }
                .tag(Tab.capture)

            HistoryView()
                .tabItem {
                    Label(Tab.history.rawValue, systemImage: Tab.history.icon)
                }
                .tag(Tab.history)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)

            InfoView()
                .tabItem {
                    Label(Tab.info.rawValue, systemImage: Tab.info.icon)
                }
                .tag(Tab.info)
        }
        .tint(AccessibleColors.primary)
        .preferredColorScheme(accessibilityManager.preferences.visualSettings.useHighContrast ? .dark : nil)
        .fullScreenCover(isPresented: $accessibilityManager.preferences.showOnboarding) {
            OnboardingView(isPresented: $accessibilityManager.preferences.showOnboarding)
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            // Stop speech when user switches tabs
            if oldTab != newTab {
                accessibilityManager.stopSpeaking()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AccessibilityManager())
        .environmentObject(GraphAnalyzer())
}

