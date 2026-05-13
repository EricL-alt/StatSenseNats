import Foundation
import UIKit

class DeepSeekService {
    private var apiKey: String {
        guard let key = Bundle.main.infoDictionary?["DeepSeekAPIKey"] as? String, !key.isEmpty else {
            print("WARNING: DeepSeekAPIKey not found in Info.plist!")
            return ""
        }
        let masked = key.prefix(3) + "..." + key.suffix(4)
        print("DEBUG: Using DeepSeekAPIKey: \(masked)")
        return key
    }
    private let url = URL(string: "https://api.deepseek.com/chat/completions")!

    func analyzeGraphData(textFromImage: String, axisX: String, axisY: String, detectedContours: String, language: Language) async throws -> InterpretationResult {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Language-specific instruction
        let languageInstruction: String
        switch language {
        case .english:
            languageInstruction = "Provide all text output in English."
        case .spanish:
            languageInstruction = "Proporciona toda la salida de texto en español."
        case .german:
            languageInstruction = "Gib alle Textausgaben auf Deutsch aus."
        case .french:
            languageInstruction = "Fournissez toute la sortie de texte en français."
        case .dutch:
            languageInstruction = "Geef alle tekstuitvoer in het Nederlands."
        case .italian:
            languageInstruction = "Fornisci tutto il testo di output in italiano."
        case .japanese:
            languageInstruction = "すべてのテキスト出力を日本語で提供してください。"
        }

        let prompt = """
        ACT AS: A world-class Accessibility Graph Interpreter for blind users.
        TASK: Convert messy OCR and Vision contour data into a structured InterpretationResult JSON.
        
        LANGUAGE: \(languageInstruction)
        IMPORTANT: All "title", "label", "description", and text fields must be in \(language.displayName). Only field names and enum values remain in English.

        INPUT DATA:
        - OCR Text: "\(textFromImage)"
        - X-Axis: "\(axisX)"
        - Y-Axis: "\(axisY)"
        - Vision Segments: "\(detectedContours)"

        OUTPUT REQUIREMENT: Return a valid JSON object matching our schema. Do NOT include any markdown formatting like ```json.
        Return ONLY the raw JSON.

        CRITICAL FORMATTING RULES:
        1. NUMBERS MUST NOT BE IN QUOTES (e.g., "confidence": 0.9, NOT "0.9").
        2. MISSING DATA: If no lines are found, return an empty array [] for "dataLines", DO NOT RETURN null.
        3. AXIS: If axis labels are missing, provide a generic label like "Value" (translated to \(language.displayName)) and default range [0, 100].
        4. ALL DESCRIPTIVE TEXT (title, labels, descriptions) MUST BE IN \(language.displayName).

        JSON SCHEMA & ALLOWED VALUES:
        {
          "graphType": "Line Graph" | "Bar Chart" | "Scatter Plot" | "Pie Chart" | "Diagram" | "Whiteboard" | "Unknown",
          "title": "A descriptive title based on OCR titles/context [IN \(language.displayName.uppercased())]",
          "xAxis": { "label": "string [IN \(language.displayName.uppercased())]", "minValue": number, "maxValue": number, "scale": "linear" },
          "yAxis": { "label": "string [IN \(language.displayName.uppercased())]", "minValue": number, "maxValue": number, "scale": "linear" },
          "dataLines": [{
            "label": "string [IN \(language.displayName.uppercased())]",
            "points": [{ "x": number, "y": number }],
            "segments": [{
               "startPoint": {"x": number, "y": number},
               "endPoint": {"x": number, "y": number},
               "trend": "Increasing" | "Decreasing" | "Constant" | "Fluctuating" | "Exponential" | "Logarithmic",
               "slope": "Steep Positive" | "Moderate Positive" | "Gentle Positive" | "Flat" | "Gentle Negative" | "Moderate Negative" | "Steep Negative"
            }],
            "trend": "Increasing" | "Decreasing" | "Constant" | "Fluctuating" | "Exponential" | "Logarithmic",
            "averageSlope": "Steep Positive" | "Moderate Positive" | "Gentle Positive" | "Flat" | "Gentle Negative" | "Moderate Negative" | "Steep Negative"
          }],
          "intersections": [],
          "overallTrend": "Increasing" | "Decreasing" | "Constant" | "Fluctuating" | "Exponential" | "Logarithmic",
          "confidence": 0.0 to 1.0 (float),
          "warnings": ["string [IN \(language.displayName.uppercased())]"],
          "explanations": [{
            "order": number,
            "title": "string [IN \(language.displayName.uppercased())]",
            "description": "Short, clear description for ScreenReader and Haptics [IN \(language.displayName.uppercased())]",
            "trend": "Increasing" | "Decreasing" | "Constant" | "Fluctuating" | "Exponential" | "Logarithmic",
            "hapticPattern": "none" | "rising" | "falling" | "steady" | "intersection" | "attention" | "success"
          }]
        }

        CRITICAL:
        1. "explanations" must be a narrative for a blind user IN \(language.displayName).
        2. Ensure "hapticPattern" values are lowercase and match EXACTLY: "none", "rising", "falling", "steady", "intersection", "attention", "success".
        3. All trend and slope values must be EXACT capitalized strings as shown above (in English, do not translate these enum values).
        4. All user-facing text (title, labels, descriptions, warnings) must be in \(language.displayName).
        """

        let parameters: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": "You are a specialized JSON-only data analysis engine. You output raw, parsable JSON matching the requested schema. No conversational filler. You can communicate in multiple languages."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "response_format": ["type": "json_object"]
        ]

        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 {
            throw NSError(domain: "DeepSeek", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid API Key. Please check your Info.plist."])
        }

        if httpResponse.statusCode == 402 {
            throw NSError(domain: "DeepSeek", code: 402, userInfo: [NSLocalizedDescriptionKey: "Insufficient Balance or Unpaid API Key."])
        }

        if httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            print("DEEPSEEK API ERROR (\(httpResponse.statusCode)): \(errorBody)")
            throw URLError(.badServerResponse)
        }

        let jsonResponse = try JSONDecoder().decode(DeepSeekResponse.self, from: data)
        let jsonContent = jsonResponse.choices.first?.message.content ?? "{}"

        var cleanedJSON = jsonContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedJSON.hasPrefix("```") {
            let lines = cleanedJSON.components(separatedBy: .newlines)
            if lines.count > 2 {
                cleanedJSON = lines.dropFirst().dropLast().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        let regex = try? NSRegularExpression(pattern: ",\\s*([\\}\\]])", options: [])
        cleanedJSON = regex?.stringByReplacingMatches(in: cleanedJSON, options: [], range: NSRange(location: 0, length: cleanedJSON.utf16.count), withTemplate: "$1") ?? cleanedJSON

        guard let resultData = cleanedJSON.data(using: .utf8) else {
            throw AnalysisError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let result = try decoder.decode(InterpretationResult.self, from: resultData)
            return result
        } catch let decodingError as DecodingError {
            var errorDetail = ""
            switch decodingError {
            case .typeMismatch(let type, let context):
                errorDetail = "Type mismatch for \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Expected \(type)."
            case .valueNotFound(let value, let context):
                errorDetail = "Value \(value) not found at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))."
            case .keyNotFound(let key, let context):
                errorDetail = "Key '\(key.stringValue)' not found at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))."
            case .dataCorrupted(let context):
                errorDetail = "Data corrupted at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))."
            @unknown default:
                errorDetail = decodingError.localizedDescription
            }
            print("❌ JSON DECODING FAILED: \(errorDetail)")
            print("FAILED JSON BLOCK BEGIN:\n\(cleanedJSON)\nFAILED JSON BLOCK END")
            throw NSError(domain: "DeepSeek", code: -1, userInfo: [NSLocalizedDescriptionKey: "AI Response Format Error: \(errorDetail)"])
        } catch {
            print("❌ UNKNOWN ERROR: \(error)")
            throw error
        }
    }
}

struct DeepSeekResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }
}
