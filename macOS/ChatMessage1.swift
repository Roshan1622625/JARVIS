import Foundation

struct ChatMessage1: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}
