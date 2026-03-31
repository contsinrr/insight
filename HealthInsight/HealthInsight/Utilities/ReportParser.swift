import Foundation

/// Parses saved report content into structured sections
enum ReportParser {
    struct Sections {
        var overallAnalysis: String?
        var trendInsights: String?
    }

    static func parse(_ content: String) -> Sections {
        var sections = Sections()

        // Split by the separator used in ReportGenerator.fullReportText
        let parts = content.components(separatedBy: "\n\n---\n\n")

        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("## 整体分析") {
                sections.overallAnalysis = trimmed
                    .replacingOccurrences(of: "## 整体分析", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("## 趋势洞察") {
                sections.trendInsights = trimmed
                    .replacingOccurrences(of: "## 趋势洞察", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else if sections.overallAnalysis == nil {
                // Fallback: treat entire content as overall analysis
                sections.overallAnalysis = trimmed
            }
        }

        return sections
    }
}
