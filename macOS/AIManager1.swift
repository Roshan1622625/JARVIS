import Foundation

struct ChatRequest1: Encodable {
    let message: String
}

struct ChatResponse: Decodable {
    let reply: String
}

final class AIManager1 {
    static let shared = AIManager1()

    private let chatURL = URL(string: "http://127.0.0.1:3000/chat")!

    private init() {}

    func sendMessage(_ message: String) async throws -> String {
        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = try JSONEncoder().encode(ChatRequest1(message: message))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NSError(
                domain: "JARVIS",
                code: httpResponse.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Server error \(httpResponse.statusCode): \(errorText)"
                ]
            )
        }

        let result = try JSONDecoder().decode(ChatResponse.self, from: data)
        return result.reply
    }
}
