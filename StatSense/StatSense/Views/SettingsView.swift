import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var accessibilityManager: AccessibilityManager

    var body: some View {
        NavigationStack {
            Form {
                
                Section("Language") {
                    Picker("Language", selection: $accessibilityManager.preferences.language) {
                        ForEach(Language.allCases) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.displayName)
                            }
                            .tag(language)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    Text("This affects both graph analysis and voice output")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Accessibility Mode") {
                    Picker("Primary Mode", selection: $accessibilityManager.preferences.primaryMode) {
                        ForEach(AccessibilityMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.icon)
                                .tag(mode)
                        }
                    }
                }

                Section("Audio Settings") {
                    Toggle("Auto-play descriptions", isOn: $accessibilityManager.preferences.speechSettings.autoPlay)

                    VStack(alignment: .leading) {
                        Text("Speech Rate: \(accessibilityManager.preferences.speechSettings.rateDescription)")
                        Slider(value: $accessibilityManager.preferences.speechSettings.rate, in: 0.1...1.0)
                    }

                    VStack(alignment: .leading) {
                        Text("Volume")
                        Slider(value: $accessibilityManager.preferences.speechSettings.volume, in: 0...1)
                    }

                    Button("Test Speech") {
                        accessibilityManager.speak("This is a sample of the speech settings.", priority: true)
                    }
                }

                Section("Visual Settings") {
                    Toggle("High Contrast Mode", isOn: $accessibilityManager.preferences.visualSettings.useHighContrast)

                    Toggle("Show Trend Icons", isOn: $accessibilityManager.preferences.visualSettings.showTrendIcons)

                    Toggle("Show Confidence Indicator", isOn: $accessibilityManager.preferences.visualSettings.showConfidenceIndicator)

                    Picker("Color Blind Mode", selection: $accessibilityManager.preferences.visualSettings.colorBlindMode) {
                        ForEach(VisualSettings.ColorBlindMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Font Size: \(Int(accessibilityManager.preferences.visualSettings.fontSize))")
                        Slider(value: $accessibilityManager.preferences.visualSettings.fontSize, in: 16...36, step: 2)
                    }
                }

                Section("Haptic Settings") {
                    Toggle("Enable Haptics", isOn: $accessibilityManager.preferences.hapticSettings.enabled)

                    if accessibilityManager.preferences.hapticSettings.enabled {
                        VStack(alignment: .leading) {
                            Text("Intensity: \(accessibilityManager.preferences.hapticSettings.intensityDescription)")
                            Slider(value: $accessibilityManager.preferences.hapticSettings.intensity, in: 0.1...1.0)
                        }

                        Toggle("Feedback on Tap", isOn: $accessibilityManager.preferences.hapticSettings.feedbackOnTap)

                        Button("Test Rising Pattern") {
                            accessibilityManager.playHaptic(.rising)
                        }

                        Button("Test Falling Pattern") {
                            accessibilityManager.playHaptic(.falling)
                        }

                        Button("Test Intersection Pattern") {
                            accessibilityManager.playHaptic(.intersection)
                        }
                    }
                }

                Section("General") {
                    Toggle("Auto-capture Mode", isOn: $accessibilityManager.preferences.autoCapture)
                    Toggle("Save Analysis History", isOn: $accessibilityManager.preferences.saveHistory)
                    Toggle("Show Onboarding", isOn: $accessibilityManager.preferences.showOnboarding)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink("Accessibility Statement") {
                        AccessibilityStatementView()
                    }

                    NavigationLink("Privacy Policy") {
                        PrivacyPolicyView()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct AccessibilityStatementView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Accessibility Statement")
                    .font(.title)
                    .fontWeight(.bold)

                Text("""
                StatSense is designed from the ground up with accessibility as a core principle, not an afterthought.

                Our Commitment:
                • Full VoiceOver compatibility
                • Multiple output modes for different needs
                • No reliance on any single sense
                • Large, clear interface elements
                • Color-blind safe color palette
                • Haptic feedback that works without screen

                We believe STEM education should be accessible to everyone, regardless of ability. If you encounter any accessibility barriers, please contact us.
                """)
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)

                Text("""
                StatSense respects your privacy.

                Data Processing:
                • All image analysis happens on your device
                • No images are sent to external servers
                • No cloud processing required
                • No account or login needed

                Data Storage:
                • Analysis history is stored locally only
                • You can delete history at any time
                • No personal data is collected

                Permissions:
                • Camera: Required to capture graphs
                • No other permissions needed
                """)
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AccessibilityManager())
}

