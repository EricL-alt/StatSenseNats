import Foundation
import SwiftUI
import AVFoundation
import CoreHaptics

@MainActor
class AccessibilityManager: ObservableObject {
    @Published var preferences = UserPreferences() {
        didSet {
            savePreferences()
        }
    }
    @Published var isSpeaking = false
    @Published var currentSpeechText = ""
    @Published var hapticEngine: CHHapticEngine?

    private let preferencesKey = "com.statsense.preferences"

    private var speechSynthesizer = AVSpeechSynthesizer()
    private var speechDelegate: SpeechDelegate?
    
    // Deepgram TTS Service
    private let deepgramTTS = DeepgramTTSService()
    private var useDeepgram = true // Set to false to fallback to native TTS

    init() {
        loadPreferences()
        setupHapticEngine()
        speechDelegate = SpeechDelegate(manager: self)
        speechSynthesizer.delegate = speechDelegate
    }

    private func savePreferences() {
        do {
            let data = try JSONEncoder().encode(preferences)
            UserDefaults.standard.set(data, forKey: preferencesKey)
        } catch {
            print("Failed to save preferences: \(error)")
        }
    }

    private func loadPreferences() {
        guard let data = UserDefaults.standard.data(forKey: preferencesKey) else { return }
        do {
            preferences = try JSONDecoder().decode(UserPreferences.self, from: data)
        } catch {
            print("Failed to load preferences: \(error)")
        }
    }

    func setMode(_ mode: AccessibilityMode) {
        preferences.primaryMode = mode
        announceMode(mode)
    }

    private func announceMode(_ mode: AccessibilityMode) {
        if preferences.primaryMode == .audio || preferences.primaryMode == .combined {
            speak("Switched to \(mode.rawValue) mode")
        }
        if preferences.hapticSettings.enabled {
            playHaptic(.success)
        }
    }

    func speak(_ text: String, priority: Bool = false) {
        guard preferences.primaryMode == .audio || preferences.primaryMode == .combined else { return }

        if useDeepgram {
            // Use Deepgram TTS
            print("🎙️ Using Deepgram TTS for: '\(text.prefix(50))...'")
            Task {
                do {
                    let speed = mapRateToDeepgramSpeed(preferences.speechSettings.rate)
                    let language = preferences.language
                    
                    print("📡 Deepgram language: \(language.displayName) (\(language.rawValue)), model: \(language.deepgramModel), speed: \(speed)")
                    
                    currentSpeechText = text
                    isSpeaking = true
                    
                    try await deepgramTTS.speak(
                        text: text,
                        language: language,
                        speed: speed,
                        priority: priority
                    )
                    
                    // Update isSpeaking based on Deepgram's state
                    isSpeaking = deepgramTTS.isSpeaking
                    print("✅ Deepgram TTS completed successfully")
                } catch {
                    print("⚠️ Deepgram TTS failed, falling back to native: \(error)")
                    // Fallback to native TTS
                    speakWithNativeTTS(text, priority: priority)
                }
            }
        } else {
            // Use native TTS
            print("🔊 Using native TTS (Deepgram disabled)")
            speakWithNativeTTS(text, priority: priority)
        }
    }
    
    private func speakWithNativeTTS(_ text: String, priority: Bool) {
        if priority {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = preferences.speechSettings.rate
        utterance.pitchMultiplier = preferences.speechSettings.pitch
        utterance.volume = preferences.speechSettings.volume

        // Use language-appropriate voice
        let localeIdentifier = preferences.language.localeIdentifier
        if let voice = AVSpeechSynthesisVoice(language: localeIdentifier) {
            utterance.voice = voice
        }

        currentSpeechText = text
        isSpeaking = true
        speechSynthesizer.speak(utterance)
    }
    
    /// Maps iOS speech rate (0.0-1.0) to Deepgram speed (0.7-1.5)
    private func mapRateToDeepgramSpeed(_ rate: Float) -> Float {
        // iOS default rate is 0.5 (maps to 1.0 Deepgram speed)
        // Scale: 0.0 -> 0.7, 0.5 -> 1.0, 1.0 -> 1.5
        return 0.7 + (rate * 0.8)
    }

    func stopSpeaking() {
        if useDeepgram {
            Task {
                await deepgramTTS.stopSpeaking()
                isSpeaking = false
            }
        } else {
            speechSynthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
    }

    func pauseSpeaking() {
        if useDeepgram {
            deepgramTTS.pauseSpeaking()
        } else {
            speechSynthesizer.pauseSpeaking(at: .word)
        }
    }

    func continueSpeaking() {
        if useDeepgram {
            deepgramTTS.continueSpeaking()
        } else {
            speechSynthesizer.continueSpeaking()
        }
    }

    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()

            hapticEngine?.resetHandler = { [weak self] in
                do {
                    try self?.hapticEngine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }

    func playHaptic(_ pattern: ExplanationStep.HapticPattern) {
        guard preferences.hapticSettings.enabled,
              let engine = hapticEngine else { return }

        do {
            let events = createHapticEvents(for: pattern)
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic: \(error)")
        }
    }

    private func createHapticEvents(for pattern: ExplanationStep.HapticPattern) -> [CHHapticEvent] {
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity,
                                                value: preferences.hapticSettings.intensity)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)

        switch pattern {
        case .rising:
            return (0..<5).map { i in
                CHHapticEvent(eventType: .hapticTransient,
                             parameters: [CHHapticEventParameter(parameterID: .hapticIntensity,
                                                                  value: Float(i + 1) * 0.2),
                                         sharpness],
                             relativeTime: Double(i) * 0.15)
            }
        case .falling:
            return (0..<5).map { i in
                CHHapticEvent(eventType: .hapticTransient,
                             parameters: [CHHapticEventParameter(parameterID: .hapticIntensity,
                                                                  value: Float(5 - i) * 0.2),
                                         sharpness],
                             relativeTime: Double(i) * 0.15)
            }
        case .steady:
            return (0..<3).map { i in
                CHHapticEvent(eventType: .hapticTransient,
                             parameters: [intensity, sharpness],
                             relativeTime: Double(i) * 0.2)
            }
        case .intersection:
            return [
                CHHapticEvent(eventType: .hapticTransient,
                             parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                                         CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)],
                             relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient,
                             parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                                         CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)],
                             relativeTime: 0.1)
            ]
        case .attention:
            return (0..<3).map { i in
                CHHapticEvent(eventType: .hapticTransient,
                             parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                                         CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)],
                             relativeTime: Double(i) * 0.1)
            }
        case .success:
            return [
                CHHapticEvent(eventType: .hapticContinuous,
                             parameters: [intensity, sharpness],
                             relativeTime: 0,
                             duration: 0.3)
            ]
        case .none:
            return []
        }
    }
}

