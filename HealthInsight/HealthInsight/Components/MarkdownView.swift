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
        VStack(alignment: .leading, spacing: 12) {
            // Split text into blocks by double newlines for better rendering
            let blocks = text.components(separatedBy: "\n\n").filter { !$0.isEmpty }

            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                renderBlock(block)
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

    @ViewBuilder
    private func renderBlock(_ block: String) -> some View {
        if let attributed = try? AttributedString(markdown: block, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attributed)
                .font(.body)
                .lineSpacing(4)
                .textSelection(.enabled)
        } else {
            Text(block)
                .font(.body)
                .lineSpacing(4)
                .textSelection(.enabled)
        }
    }
}
