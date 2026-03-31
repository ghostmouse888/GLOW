import Foundation

final class ClaudeService {

    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model   = "claude-sonnet-4-6"

    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key  = dict["ANTHROPIC_API_KEY"] as? String, !key.isEmpty
        else { assertionFailure("⚠️ Add ANTHROPIC_API_KEY to Secrets.plist"); return "" }
        return key
    }

    /// General multi-turn chat (512 tokens)
    func send(userMessage: String, history: [Message], systemPrompt: String) async throws -> String {
        try await call(system: systemPrompt, messages: buildMessages(history: history, userMessage: userMessage), maxTokens: 512)
    }

    /// Short single-turn response (256 tokens) — for wins, body check, focus intro etc.
    func quick(prompt: String, system: String) async throws -> String {
        try await call(system: system, messages: [["role": "user", "content": prompt]], maxTokens: 256)
    }

    // MARK: — Private

    private func buildMessages(history: [Message], userMessage: String) -> [[String: Any]] {
        history.map { ["role": $0.role.rawValue, "content": $0.content] }
             + [["role": "user", "content": userMessage]]
    }

    private func call(system: String, messages: [[String: Any]], maxTokens: Int) async throws -> String {
        let body: [String: Any] = [
            "model": model, "max_tokens": maxTokens,
            "system": system, "messages": messages
        ]
        var request        = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.httpBody   = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey,             forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",       forHTTPHeaderField: "anthropic-version")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw ClaudeError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        guard let json    = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text    = content.first?["text"] as? String
        else { throw ClaudeError.invalidResponse }
        return text
    }
}

enum ClaudeError: LocalizedError {
    case httpError(Int, String), invalidResponse
    var errorDescription: String? {
        switch self {
        case .httpError(let c, let b): return "API error \(c): \(b)"
        case .invalidResponse:         return "Unexpected response from Claude API."
        }
    }
}
