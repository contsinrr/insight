import Foundation

enum AIServiceError: LocalizedError {
    case apiKeyMissing
    case invalidURL
    case networkError(String)
    case apiError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "请先在设置中填写通义千问 API Key"
        case .invalidURL:
            return "API 地址无效"
        case .networkError(let msg):
            return "网络错误：\(msg)"
        case .apiError(let msg):
            return "API 错误：\(msg)"
        case .decodingError:
            return "解析响应数据失败"
        }
    }
}

@Observable
final class AIService {
    private let baseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "apiKey") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "apiKey") }
    }

    var selectedModel: String {
        get { UserDefaults.standard.string(forKey: "selectedModel") ?? "qwen-plus" }
        set { UserDefaults.standard.set(newValue, forKey: "selectedModel") }
    }

    var isApiKeySet: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Stream chat completion from DashScope API
    func streamChat(messages: [ChatRequest.ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard isApiKeySet else {
                        continuation.finish(throwing: AIServiceError.apiKeyMissing)
                        return
                    }

                    guard let url = URL(string: baseURL) else {
                        continuation.finish(throwing: AIServiceError.invalidURL)
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.timeoutInterval = 120

                    let chatRequest = ChatRequest(
                        model: selectedModel,
                        messages: messages,
                        stream: true
                    )
                    request.httpBody = try JSONEncoder().encode(chatRequest)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    // Check HTTP status
                    if let httpResponse = response as? HTTPURLResponse {
                        guard (200...299).contains(httpResponse.statusCode) else {
                            // Try to read error body
                            var errorBody = ""
                            for try await line in bytes.lines {
                                errorBody += line
                            }
                            if let data = errorBody.data(using: .utf8),
                               let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                                continuation.finish(throwing: AIServiceError.apiError(apiError.error.message))
                            } else {
                                continuation.finish(throwing: AIServiceError.apiError("HTTP \(httpResponse.statusCode)"))
                            }
                            return
                        }
                    }

                    // Parse SSE stream line by line
                    for try await line in bytes.lines {
                        // SSE lines start with "data: "
                        guard line.hasPrefix("data: ") else { continue }

                        let jsonString = String(line.dropFirst(6))

                        // Check for stream end
                        if jsonString.trimmingCharacters(in: .whitespaces) == "[DONE]" {
                            break
                        }

                        // Parse the JSON
                        guard let jsonData = jsonString.data(using: .utf8) else { continue }

                        do {
                            let streamResponse = try JSONDecoder().decode(ChatStreamResponse.self, from: jsonData)
                            if let content = streamResponse.choices.first?.delta.content {
                                continuation.yield(content)
                            }
                        } catch {
                            // Skip malformed JSON lines
                            continue
                        }
                    }

                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: AIServiceError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Non-streaming chat (for testing or simple queries)
    func chat(messages: [ChatRequest.ChatMessage]) async throws -> String {
        guard isApiKeySet else {
            throw AIServiceError.apiKeyMissing
        }

        guard let url = URL(string: baseURL) else {
            throw AIServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        let chatRequest = ChatRequest(
            model: selectedModel,
            messages: messages,
            stream: false
        )
        request.httpBody = try JSONEncoder().encode(chatRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw AIServiceError.apiError(apiError.error.message)
            }
            throw AIServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        struct FullResponse: Decodable {
            let choices: [Choice]
            struct Choice: Decodable {
                let message: Message
            }
            struct Message: Decodable {
                let content: String
            }
        }

        let fullResponse = try JSONDecoder().decode(FullResponse.self, from: data)
        guard let content = fullResponse.choices.first?.message.content else {
            throw AIServiceError.decodingError
        }
        return content
    }
}
