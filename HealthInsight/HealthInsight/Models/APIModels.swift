import Foundation

// MARK: - Chat Request (OpenAI-compatible format)
struct ChatRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let stream: Bool

    struct ChatMessage: Encodable {
        let role: String
        let content: String
    }
}

// MARK: - Chat Stream Response
struct ChatStreamResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let delta: Delta
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case delta
            case finishReason = "finish_reason"
        }
    }

    struct Delta: Decodable {
        let content: String?
        let role: String?
    }
}

// MARK: - API Error Response
struct APIErrorResponse: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
        let type: String?
        let code: String?
    }
}
