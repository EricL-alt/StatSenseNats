import Foundation
import SwiftUI

enum AccessibilityMode: String, CaseIterable, Identifiable, Codable {
    case audio = "Audio"
    case visual = "Visual"
    case haptic = "Haptic"
    case combined = "Combined"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .audio: return "speaker.wave.3.fill"
        case .visual: return "eye.fill"
        case .haptic: return "hand.tap.fill"
        case .combined: return "square.stack.3d.up.fill"
        }
    }

    var description: String {
        switch self {
        case .audio: return "Voice descriptions of graphs"
        case .visual: return "High-contrast visual display"
        case .haptic: return "Vibration patterns for trends"
        case .combined: return "All accessibility modes together"
        }
    }
}

enum Language: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case spanish = "es"
    case german = "de"
    case french = "fr"
    case dutch = "nl"
    case italian = "it"
    case japanese = "ja"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .german: return "Deutsch"
        case .french: return "Français"
        case .dutch: return "Nederlands"
        case .italian: return "Italiano"
        case .japanese: return "日本語"
        }
    }
    
    var nativeDisplayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .german: return "German"
        case .french: return "French"
        case .dutch: return "Dutch"
        case .italian: return "Italian"
        case .japanese: return "Japanese"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .german: return "🇩🇪"
        case .french: return "🇫🇷"
        case .dutch: return "🇳🇱"
        case .italian: return "🇮🇹"
        case .japanese: return "🇯🇵"
        }
    }
    
    /// Returns the appropriate Deepgram TTS model for this language
    var deepgramModel: String {
        switch self {
        case .english: return "aura-2-asteria-en"
        case .spanish: return "aura-2-celeste-es"
        case .german: return "aura-2-julius-de"
        case .french: return "aura-2-agathe-fr"
        case .dutch: return "aura-2-rhea-nl"
        case .italian: return "aura-2-livia-it"
        case .japanese: return "aura-2-fujin-ja"
        }
    }
    
    /// Returns ISO locale identifier for voice synthesis
    var localeIdentifier: String {
        switch self {
        case .english: return "en-US"
        case .spanish: return "es-ES"
        case .german: return "de-DE"
        case .french: return "fr-FR"
        case .dutch: return "nl-NL"
        case .italian: return "it-IT"
        case .japanese: return "ja-JP"
        }
    }
}

struct SpeechSettings: Equatable, Codable {
    var rate: Float = 0.5
    var pitch: Float = 1.0
    var volume: Float = 1.0
    var voice: String = "en-US"
    var autoPlay: Bool = true

    var rateDescription: String {
        switch rate {
        case 0.0..<0.3: return "Slow"
        case 0.3..<0.6: return "Normal"
        case 0.6..<0.8: return "Fast"
        default: return "Very Fast"
        }
    }
}

struct VisualSettings: Equatable, Codable {
    var fontSize: CGFloat = 24
    var useHighContrast: Bool = true
    var colorBlindMode: ColorBlindMode = .none
    var showTrendIcons: Bool = true
    var showConfidenceIndicator: Bool = true
    var animationsEnabled: Bool = true

    var dynamicTypeSize: DynamicTypeSize {
        switch fontSize {
        case 16..<20: return .medium
        case 20..<24: return .large
        case 24..<28: return .xxLarge
        case 28..<32: return .accessibility1
        case 32..<36: return .accessibility3
        case 36...: return .accessibility5
        default: return .medium
        }
    }

    enum ColorBlindMode: String, CaseIterable, Identifiable, Codable {
        case none = "Standard"
        case protanopia = "Protanopia"
        case deuteranopia = "Deuteranopia"
        case tritanopia = "Tritanopia"
        case monochrome = "Monochrome"

        var id: String { rawValue }
    }
}

struct HapticSettings: Equatable, Codable {
    var intensity: Float = 0.8
    var enabled: Bool = true
    var patternDuration: Double = 0.5
    var feedbackOnTap: Bool = true

    var intensityDescription: String {
        switch intensity {
        case 0.0..<0.3: return "Gentle"
        case 0.3..<0.7: return "Medium"
        default: return "Strong"
        }
    }
}

struct UserPreferences: Equatable, Codable {
    var primaryMode: AccessibilityMode = .combined
    var language: Language = .english
    var speechSettings: SpeechSettings = SpeechSettings()
    var visualSettings: VisualSettings = VisualSettings()
    var hapticSettings: HapticSettings = HapticSettings()
    var showOnboarding: Bool = true
    var isDemoMode: Bool = false
    var autoCapture: Bool = false
    var saveHistory: Bool = true
}

struct AccessibleColors {

    static let primary = Color(red: 0.0, green: 0.45, blue: 0.7)
    static let secondary = Color(red: 0.9, green: 0.6, blue: 0.0)
    static let tertiary = Color(red: 0.0, green: 0.6, blue: 0.5)
    static let quaternary = Color(red: 0.8, green: 0.4, blue: 0.0)

    private static var standardSuccess: Color { Color(red: 0.15, green: 0.6, blue: 0.15) }
    private static var standardWarning: Color { Color(red: 0.95, green: 0.6, blue: 0.1) }
    private static var standardError: Color { Color(red: 0.85, green: 0.2, blue: 0.2) }

    static var success: Color { standardSuccess }
    static var warning: Color { standardWarning }
    static var error: Color { standardError }

    static func success(mode: VisualSettings.ColorBlindMode) -> Color {
        trendColor(for: .increasing, mode: mode)
    }

    static func warning(mode: VisualSettings.ColorBlindMode) -> Color {
        trendColor(for: .fluctuating, mode: mode)
    }

    static func error(mode: VisualSettings.ColorBlindMode) -> Color {
        trendColor(for: .decreasing, mode: mode)
    }

    static let highContrastBackground = Color.black
    static let highContrastText = Color.white
    static let highContrastAccent = Color.yellow

    static func trendColor(for trend: TrendType, mode: VisualSettings.ColorBlindMode = .none) -> Color {
        switch mode {
        case .monochrome:
            return monochromeTrendColor(for: trend)
        case .protanopia, .deuteranopia:
            return blueYellowTrendColor(for: trend)
        case .tritanopia:
            return redCyanTrendColor(for: trend)
        case .none:
            switch trend {
            case .increasing: return standardSuccess
            case .decreasing: return standardError
            case .constant: return primary
            case .fluctuating: return standardWarning
            case .exponential: return tertiary
            case .logarithmic: return secondary
            }
        }
    }

    private static func monochromeTrendColor(for trend: TrendType) -> Color {
        switch trend {
        case .increasing, .exponential: return .white
        case .decreasing, .logarithmic: return .gray
        default: return .secondary
        }
    }

    private static func blueYellowTrendColor(for trend: TrendType) -> Color {

        switch trend {
        case .increasing, .exponential: return Color(red: 0.0, green: 0.27, blue: 0.67)
        case .decreasing, .logarithmic: return Color(red: 0.9, green: 0.7, blue: 0.0)
        default: return .primary
        }
    }

    private static func redCyanTrendColor(for trend: TrendType) -> Color {

        switch trend {
        case .increasing, .exponential: return Color(red: 0.0, green: 0.6, blue: 0.6)
        case .decreasing, .logarithmic: return Color(red: 0.8, green: 0.0, blue: 0.0)
        default: return .primary
        }
    }
}

