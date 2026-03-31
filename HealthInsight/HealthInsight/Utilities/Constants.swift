import Foundation

enum Constants {
    static let apiBaseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"

    static let availableModels = [
        "qwen-plus",
        "qwen-turbo",
        "qwen-max"
    ]

    static let modelDisplayNames: [String: String] = [
        "qwen-plus": "通义千问 Plus（推荐）",
        "qwen-turbo": "通义千问 Turbo（快速）",
        "qwen-max": "通义千问 Max（最强）"
    ]
}
