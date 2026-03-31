import SwiftUI
import SwiftData

struct ReportHistoryView: View {
    @Query(sort: \HealthReport.createdAt, order: .reverse)
    private var reports: [HealthReport]

    @Environment(\.modelContext) private var modelContext
    @Environment(AIService.self) private var aiService
    @Environment(ReportGenerator.self) private var reportGenerator

    @State private var showReportSheet = false
    @State private var showSettingsAlert = false

    private let primaryColor = Color(red: 0.45, green: 0.40, blue: 0.85)
    private let bgGradient = LinearGradient(
        colors: [Color(red: 0.93, green: 0.91, blue: 0.96), .white],
        startPoint: .top, endPoint: .bottom
    )

    var body: some View {
        NavigationStack {
            ZStack {
                bgGradient.ignoresSafeArea()

                if reports.isEmpty {
                    emptyState
                } else {
                    reportList
                }
            }
            .navigationTitle("历史报告")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if aiService.isApiKeySet {
                            showReportSheet = true
                        } else {
                            showSettingsAlert = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(primaryColor)
                    }
                }
            }
            .sheet(isPresented: $showReportSheet) {
                ReportView()
            }
            .alert("需要设置 API Key", isPresented: $showSettingsAlert) {
                Button("好的") {}
            } message: {
                Text("请先在「设置」页面中填写通义千问 API Key。")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)

            Text("暂无报告")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("点击右上角 + 生成你的第一份健康分析报告")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Report List

    private var reportList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(reports) { report in
                    NavigationLink {
                        ReportDetailView(report: report)
                    } label: {
                        reportCard(report)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        ShareLink(
                            item: report.content,
                            subject: Text("健康洞察 - \(DateFormatters.shortDate.string(from: report.date))报告"),
                            message: Text("我的健康报告")
                        ) {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive) {
                            withAnimation {
                                modelContext.delete(report)
                            }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Report Card

    private func reportCard(_ report: HealthReport) -> some View {
        let sections = ReportParser.parse(report.content)

        return VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(spacing: 12) {
                // Date badge
                VStack(spacing: 2) {
                    Text(dayString(report.date))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryColor)
                    Text(monthString(report.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(primaryColor.opacity(0.08))
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(DateFormatters.fullDate.string(from: report.date))
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)

                    Text("生成于 \(DateFormatters.reportDate.string(from: report.createdAt))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(16)

            Divider()
                .padding(.horizontal, 16)

            // Section tags
            HStack(spacing: 8) {
                if sections.overallAnalysis != nil {
                    sectionTag(icon: "heart.text.clipboard", title: "整体分析", color: .pink)
                }
                if sections.trendInsights != nil {
                    sectionTag(icon: "chart.line.uptrend.xyaxis", title: "趋势洞察", color: .orange)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Preview snippet
            Text(previewText(from: report.content))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Section Tag

    private func sectionTag(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(title)
                .font(.caption2.bold())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(color.opacity(0.1))
        )
    }

    // MARK: - Helpers

    private func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func monthString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月"
        return formatter.string(from: date)
    }

    private func previewText(from content: String) -> String {
        // Strip markdown headers and formatting for clean preview
        let cleaned = content
            .replacingOccurrences(of: "## 整体分析", with: "")
            .replacingOccurrences(of: "## 趋势洞察", with: "")
            .replacingOccurrences(of: "---", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "**", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.count > 120 {
            return String(cleaned.prefix(120)) + "..."
        }
        return cleaned
    }
}
