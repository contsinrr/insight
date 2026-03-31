import SwiftUI

struct MarkdownView: View {
    let text: String

    var body: some View {
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attributed)
                .font(.body)
                .textSelection(.enabled)
        } else {
            // Fallback: render as plain text
            Text(text)
                .font(.body)
                .textSelection(.enabled)
        }
    }
}

/// A streaming-friendly Markdown view that handles partial markdown gracefully
struct StreamingMarkdownView: View {
    let text: String
    let isStreaming: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Render the entire text as a single block to avoid overlapping
            if let attributed = try? AttributedString(
                markdown: text,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            ) {
                Text(attributed)
                    .font(.body)
                    .lineSpacing(4)
                    .textSelection(.enabled)
            } else {
                // Fallback: render as plain text with line breaks
                Text(text)
                    .font(.body)
                    .lineSpacing(4)
                    .textSelection(.enabled)
            }

            if isStreaming {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                        .opacity(0.8)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isStreaming)
                    Text("正在生成...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }
}
