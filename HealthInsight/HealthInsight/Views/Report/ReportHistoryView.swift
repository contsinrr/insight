import SwiftUI
import SwiftData
import Charts

struct ReportHistoryView: View {
    @Query(sort: \HealthReport.createdAt, order: .reverse)
    private var reports: [HealthReport]

    @Environment(\.modelContext) private var modelContext
    @Environment(AIService.self) private var aiService
    @Environment(ReportGenerator.self) private var reportGenerator
    @Environment(HealthKitManager.self) private var healthKit

    @State private var showReportSheet = false
    @State private var showSettingsAlert = false

    private let primaryColor = Color(red: 0.45, green: 0.40, blue: 0.85)
    private let bgGradient = LinearGradient(
        colors: [Color(red: 0.97, green: 0.96, blue: 1.0), Color.white],
        startPoint: .top, endPoint: .bottom
    )

    var body: some View {
        NavigationStack {
            ZStack {
                bgGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        headerSection

                        // Weekly Insights Card
                        weeklyInsightsCard

                        // Trend Analysis Card (Heart Rate)
                        trendAnalysisCard

                        // 30 Day Sleep Card
                        sleepDurationCard

                        // Report Archive Section
                        reportArchiveSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(primaryColor)
                        Text("健康洞察")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
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
            .task {
                await healthKit.fetchTodayData()
                await healthKit.fetchTrendData()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Smart Analysis System tag
            Text("智能分析系统")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(primaryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(primaryColor.opacity(0.1))
                .clipShape(Capsule())

            // Main title
            Text("健康报告")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.primary)

            // Subtitle
            Text("详细分析您的生理趋势并提供 AI 驱动的健康优化方案。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Weekly Insights Card

    private var weeklyInsightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Card header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text("AI 洞察")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .clipShape(Capsule())

                Spacer()

                Text(dateRangeText)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Title
            Text("每周洞察 \(DateFormatters.mediumDate.string(from: Date()))")
                .font(.headline)
                .foregroundStyle(.primary)

            // Sleep insight
            InsightRow(
                icon: "moon.fill",
                iconColor: .indigo,
                category: "睡眠",
                status: "已改善",
                statusColor: .green,
                description: "本周您的深度睡眠周期增加了 14%。保持晚上 10 点开始放松休息的习惯稳定了您的昼夜节律。"
            )

            // Exercise insight
            InsightRow(
                icon: "figure.run",
                iconColor: .orange,
                category: "运动",
                status: "平稳",
                statusColor: .gray,
                description: "每日步数稳定在 8,500 步。考虑在下午增加运动强度以提升代谢率。"
            )

            // View full analysis button
            Button {
                if aiService.isApiKeySet {
                    showReportSheet = true
                } else {
                    showSettingsAlert = true
                }
            } label: {
                HStack {
                    Text("查看完整分析")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline.bold())
                .foregroundStyle(primaryColor)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(primaryColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Trend Analysis Card (Heart Rate)

    private var trendAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("趋势分析")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("心率波动（今日）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Average BPM
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(averageBPM)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(primaryColor)
                    Text("平均 BPM")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Heart rate chart
            if !reportGenerator.heartRateData.isEmpty {
                heartRateChart
                    .frame(height: 160)
            } else {
                emptyChartPlaceholder("暂无心率数据", height: 160)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - 30 Day Sleep Duration Card

    private var sleepDurationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("30 天睡眠时长")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }

            // Sleep stats visualization
            HStack(spacing: 20) {
                // Progress bars
                VStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(sleepBarColor(for: index))
                            .frame(width: CGFloat(60 + index * 12), height: 8)
                    }
                }

                Spacer()

                // Average hours
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(sleepAvgHours, specifier: "%.1f")")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.primary)
                    HStack(spacing: 2) {
                        Text("小时")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text("目标：8 小时")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.93, green: 0.91, blue: 0.96), Color.white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Report Archive Section

    private var reportArchiveSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("报告存档")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Spacer()

                Button(role: .none) {
                    // Navigate to full archive
                } label: {
                    Text("查看全部")
                        .font(.subheadline.bold())
                        .foregroundStyle(primaryColor)
                }
            }

            // Report list
            VStack(spacing: 12) {
                ForEach(reports.prefix(3)) { report in
                    ArchiveReportRow(report: report)
                }

                if reports.isEmpty {
                    emptyArchivePlaceholder
                }
            }
        }
    }

    // MARK: - Helpers

    private var dateRangeText: String {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            return DateFormatters.shortDate.string(from: now)
        }
        return "\(DateFormatters.shortDate.string(from: startOfWeek)) - \(DateFormatters.shortDate.string(from: endOfWeek))"
    }

    private var averageBPM: Int {
        guard !reportGenerator.heartRateData.isEmpty else { return 0 }
        let avg = reportGenerator.heartRateData.map(\.bpm).reduce(0, +) / Double(reportGenerator.heartRateData.count)
        return Int(avg)
    }

    private var sleepAvgHours: Double {
        let values = reportGenerator.sleepTrendData.map(\.value)
        guard !values.isEmpty else { return 0.0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func sleepBarColor(for index: Int) -> Color {
        let colors: [Color] = [
            Color.blue.opacity(0.3),
            Color.blue.opacity(0.5),
            Color.blue.opacity(0.7),
            Color.blue.opacity(0.85),
            Color.blue.opacity(1.0)
        ]
        return colors[min(index, colors.count - 1)]
    }

    private var heartRateChart: some View {
        let data = reportGenerator.heartRateData
        let minBPM = (data.map(\.bpm).min() ?? 50) - 10
        let maxBPM = (data.map(\.bpm).max() ?? 120) + 10

        return Chart {
            ForEach(data) { point in
                BarMark(
                    x: .value("时间", point.time, unit: .hour),
                    y: .value("BPM", point.bpm)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [primaryColor.opacity(0.7), primaryColor.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(3)
            }
        }
        .chartYScale(domain: minBPM...maxBPM)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 4)) { value in
                AxisValueLabel(format: .dateTime.hour())
                    .font(.caption2)
            }
        }
    }

    private func emptyChartPlaceholder(_ text: String, height: CGFloat) -> some View {
        HStack {
            Image(systemName: "chart.bar.xaxis")
                .foregroundStyle(.tertiary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: height)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.06))
        )
    }

    private var emptyArchivePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 36))
                .foregroundStyle(.quaternary)
            Text("暂无历史报告")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Text("点击右上角 + 生成你的第一份报告")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.04))
        )
    }
}

// MARK: - Insight Row Component

struct InsightRow: View {
    let icon: String
    let iconColor: Color
    let category: String
    let status: String
    let statusColor: Color
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(category)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)

                    Text(status)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.1))
                        .clipShape(Capsule())
                }

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

// MARK: - Archive Report Row Component

struct ArchiveReportRow: View {
    let report: HealthReport

    private let primaryColor = Color(red: 0.45, green: 0.40, blue: 0.85)

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(primaryColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: "doc.richtext")
                    .font(.system(size: 20))
                    .foregroundStyle(primaryColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("\(DateFormatters.mediumDate.string(from: report.date))深度分析报告")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("生成于 \(DateFormatters.reportDate.string(from: report.createdAt))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                HStack(spacing: 12) {
                    Label("\(estimateSize(report))", systemImage: "cylinder.split.2x1")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }

    private func estimateSize(_ report: HealthReport) -> String {
        // Estimate based on content length
        let chars = report.content.count
        if chars < 1000 { return "Small" }
        if chars < 3000 { return "Medium" }
        return "Large"
    }
}
