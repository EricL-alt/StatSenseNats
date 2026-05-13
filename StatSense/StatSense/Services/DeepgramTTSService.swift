import Foundation
import AVFoundation

@MainActor
class DeepgramTTSService: NSObject, ObservableObject {
    @Published var isSpeaking = false
    @Published var currentText = ""
    
    private var apiKey: String {
        guard let key = Bundle.main.infoDictionary?["DeepgramTTSAPIKey"] as? String, !key.isEmpty else {
            print("WARNING: DeepgramTTSAPIKey not found in Info.plist!")
            return ""
        }
        return key
    }
    
    private var audioPlayer: AVAudioPlayer?
    private var audioPlayerDelegate: AudioPlayerDelegate?
    private let baseURL = "https://api.deepgram.com/v1/speak"
    
    // Queue for managing sequential speech requests
    private var speechQueue: [String] = []
    private var isProcessing = false
    
    override init() {
        super.init()
        audioPlayerDelegate = AudioPlayerDelegate(service: self)
    }
    
    /// Speaks text using Deepgram's Aura-2 TTS API
    /// - Parameters:
    ///   - text: The text to convert to speech
    ///   - model: The voice model (auto-selected based on language if not specified)
    ///   - language: The language to use (will auto-select appropriate model)
    ///   - speed: Speaking rate 0.7-1.5 (default: 1.0)
    ///   - priority: If true, stops current speech and speaks immediately
    func speak(
        text: String,
        model: String? = nil,
        language: Language,
        speed: Float = 1.0,
        priority: Bool = false
    ) async throws {
        guard !text.isEmpty else { return }
        
        // Use provided model or auto-select based on language
        let selectedModel = model ?? language.deepgramModel
        
        if priority {
            await stopSpeaking()
            speechQueue.removeAll()
        }
        
        // Add to queue
        speechQueue.append(text)
        
        // Process queue if not already processing
        if !isProcessing {
            await processQueue(model: selectedModel, speed: speed)
        }
    }
    
    private func processQueue(model: String, speed: Float) async {
        isProcessing = true
        
        while !speechQueue.isEmpty {
            let text = speechQueue.removeFirst()
            currentText = text
            
            do {
                try await generateAndPlaySpeech(text: text, model: model, speed: speed)
            } catch {
                print("❌ Deepgram TTS Error: \(error.localizedDescription)")
                // Continue with next item even if this one fails
            }
        }
        
        isProcessing = false
        currentText = ""
    }
    
    private func generateAndPlaySpeech(text: String, model: String, speed: Float) async throws {
        // Build URL with parameters
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "model", value: model),
            URLQueryItem(name: "encoding", value: "mp3"),
            URLQueryItem(name: "bitrate", value: "48000")
            // No sample_rate, no container
        ]
        
        // Add speed if not default
        if speed != 1.0 {
            components.queryItems?.append(URLQueryItem(name: "speed", value: String(speed)))
        }
        
        guard let url = components.url else {
            throw TTSError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TTSError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw TTSError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Deepgram TTS API Error (\(httpResponse.statusCode)): \(errorBody)")
            throw TTSError.apiError(statusCode: httpResponse.statusCode)
        }
        
        // Play the audio
        try await playAudio(data: data)
    }
    
    private func playAudio(data: Data) async throws {
        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try session.setActive(true)
        
        // Create and configure audio player
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.delegate = audioPlayerDelegate
        audioPlayer?.prepareToPlay()
        
        isSpeaking = true
        
        // Play audio
        audioPlayer?.play()
        
        // Wait for playback to complete
        await waitForPlaybackCompletion()
    }
    
    private func waitForPlaybackCompletion() async {
        // Wait while audio is playing
        while audioPlayer?.isPlaying == true {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        isSpeaking = false
    }
    
    func stopSpeaking() async {
        speechQueue.removeAll()
        audioPlayer?.stop()
        isSpeaking = false
        currentText = ""
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    func pauseSpeaking() {
        audioPlayer?.pause()
    }
    
    func continueSpeaking() {
        audioPlayer?.play()
    }
    
    // MARK: - Audio Player Delegate Helper
    private class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
        weak var service: DeepgramTTSService?
        
        init(service: DeepgramTTSService) {
            self.service = service
        }
        
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            Task { @MainActor in
                service?.isSpeaking = false
            }
        }
        
        func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
            print("Audio Player Error: \(error?.localizedDescription ?? "Unknown")")
            Task { @MainActor in
                service?.isSpeaking = false
            }
        }
    }
}

// MARK: - Errors
enum TTSError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case apiError(statusCode: Int)
    case playbackError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid TTS API URL"
        case .invalidResponse:
            return "Invalid response from TTS service"
        case .unauthorized:
            return "Unauthorized: Check your Deepgram TTS API key in Info.plist"
        case .apiError(let code):
            return "TTS API error (status code: \(code))"
        case .playbackError:
            return "Audio playback error"
        }
    }
}
