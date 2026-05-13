import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @Environment(\.dismiss) private var dismiss

    let result: InterpretationResult
    @State private var currentStepIndex = 0
    @State private var isExploring = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if accessibilityManager.preferences.visualSettings.useHighContrast {
                        HighContrastResultCard(result: result)
                    } else {
                        if let image = result.capturedImage {
                            ImagePreviewCard(image: image)
                        }

                        headerSection

                        SummaryCard(result: result)

                        explanationSection
                    }

                    if isExploring {
                        StepByStepExplorer(
                            steps: result.explanations,
                            currentIndex: $currentStepIndex
                        )
                    }

                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Analysis Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        // Stop any ongoing speech when user dismisses
                        accessibilityManager.stopSpeaking()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: shareResult) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .onAppear {
            if accessibilityManager.preferences.speechSettings.autoPlay {
                accessibilityManager.speak(result.summary, priority: true)
            }
        }
        .onDisappear {
            // Stop speech when view disappears (swiped away, navigated away, etc.)
            accessibilityManager.stopSpeaking()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {

                Label(result.graphType.rawValue, systemImage: result.graphType.icon)
                    .font(.body.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AccessibleColors.primary.opacity(0.2))
                    .clipShape(Capsule())

                Spacer()

                ConfidenceIndicator(confidence: result.confidence)
            }

            if !result.warnings.isEmpty {
                WarningsCard(warnings: result.warnings)
            }
        }
    }

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Detailed Explanation")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                    isExploring.toggle()
                    if isExploring {
                        accessibilityManager.speak("Step by step mode activated. Tap next to explore each part.")
                    }
                }) {
                    Label(isExploring ? "Exit Explore" : "Step-by-Step",
                          systemImage: isExploring ? "xmark.circle" : "hand.tap")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
            }

            ForEach(result.explanations) { step in
                ExplanationStepCard(step: step)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {

            Button(action: readAloud) {
                Label(
                    accessibilityManager.isSpeaking ? "Stop Reading" : "Read Aloud",
                    systemImage: accessibilityManager.isSpeaking ? "stop.fill" : "speaker.wave.3.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AccessibleColors.primary)

            Button(action: playHapticSummary) {
                Label("Feel Trend Pattern", systemImage: "hand.tap.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top)
    }

    private func readAloud() {
        if accessibilityManager.isSpeaking {
            accessibilityManager.stopSpeaking()
        } else {
            let fullText = result.explanations.map { $0.description }.joined(separator: ". ")
            accessibilityManager.speak(fullText, priority: true)
        }
    }

    private func playHapticSummary() {
        let pattern: ExplanationStep.HapticPattern = {
            switch result.overallTrend {
            case .increasing, .exponential: return .rising
            case .decreasing, .logarithmic: return .falling
            default: return .steady
            }
        }()
        accessibilityManager.playHaptic(pattern)
    }

    private func shareResult() {

        let text = result.summary
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct ImagePreviewCard: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: 200)
            .cornerRadius(12)
            .shadow(radius: 5)
    }
}

struct SummaryCard: View {
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    let result: InterpretationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Summary")
                    .font(.title2.bold())
                Spacer()
                TrendIconView(trend: result.overallTrend, size: 32)
            }

            Text(result.summary)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

