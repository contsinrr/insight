import SwiftUI
import SwiftData
import Charts

struct ReportHistoryView: View {
    @Query(sort: \HealthReport.createdAt, order: .reverse)
    private var allReports: [HealthReport]

    @Environment(\.modelContext) private var modelContext
    @Environment(AIService.self) private var aiService
    @Environment(ReportGenerator.self) private var reportGenerator
    @Environment(HealthKitManager.self) private var healthKit

    @State private var showReportSheet = false
    @State private var showSettingsAlert = false
    @State private var showAllReports = false
    @State private var showSleepTrendSheet = false

    private let primaryColor = Color(red: 0.45, green: 0.40, blue: 0.85)
    private let bgGradient = LinearGradient(
        colors: [Color(red: 0.97, green: 0.96, blue: 1.0), Color.white],
        startPoint: .top, endPoint: .bottom
    )

    // Limit to 7 reports by default
    private var displayedReports: [HealthReport] {
        if showAllReports {
            return Array(allReports)
        } else {
            return Array(allReports.prefix(7))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                bgGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
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
                            .font(.title2).fontWeight(.bold)
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
            .sheet(isPresented: $showSleepTrendSheet) {
                sleepTrendSheet
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
            Text("智能分析系统")
                .font(.caption2).fontWeight(.medium)
                .foregroundStyle(primaryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(primaryColor.opacity(0.1))
                .clipShape(Capsule())

            Text("健康报告")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.primary)

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
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text("AI 洞察")
                        .font(.caption).fontWeight(.bold)
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

            Text("每周洞察 \(DateFormatters.shortDate.string(from: Date()))")
                .font(.headline).fontWeight(.bold)
                .foregroundStyle(.primary)

            InsightRow(
                icon: "moon.fill",
                iconColor: .indigo,
                category: "睡眠",
                status: "已改善",
                statusColor: .green,
                description: "本周您的深度睡眠周期增加了 14%。保持晚上 10 点开始放松休息的习惯稳定了您的昼夜节律。"
            )

            InsightRow(
                icon: "figure.run",
                iconColor: .orange,
                category: "运动",
                status: "平稳",
                statusColor: .gray,
                description: "每日步数稳定在 8,500 步。考虑在下午增加运动强度以提升代谢率。"
            )

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
                .font(.subheadline).fontWeight(.bold)
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
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("趋势分析")
                        .font(.headline).fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Text("心率波动（今日）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(averageBPM)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(primaryColor)
                    Text("平均 BPM")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

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
        Button {
            showSleepTrendSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("30 天睡眠时长")
                        .font(.headline).fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "ellipsis")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 20) {
                    VStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(sleepBarColor(for: index))
                                .frame(width: CGFloat(60 + index * 12), height: 8)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%.1f", sleepAvgHours))
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
        .buttonStyle(.plain)
    }

    // MARK: - Sleep Trend Sheet

    private var sleepTrendSheet: some View {
        NavigationStack {
            ZStack {
                bgGradient.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Summary card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("近 30 天平均睡眠")
                            .font(.headline).fontWeight(.bold)

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(sleepAvgHours, specifier: "%.1f")")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(primaryColor)
                            Text("小时")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 16) {
                            StatBadge(label: "最佳", value: String(format: "%.1f", bestSleepNight) + "h", icon: "star.fill", color: .yellow)
                            StatBadge(label: "最差", value: String(format: "%.1f", worstSleepNight) + "h", icon: "moon.zzz.fill", color: .gray)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("每日睡眠趋势")
                            .font(.headline).fontWeight(.bold)

                        if !reportGenerator.sleepTrendData.isEmpty {
                            sleepTrendChart
                                .frame(height: 240)
                        } else {
                            emptyChartPlaceholder("暂无睡眠数据", height: 240)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
                    )
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        showSleepTrendSheet = false
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(primaryColor)
                }
            }
        }
    }

    // MARK: - Report Archive Section

    private var reportArchiveSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("报告存档")
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    withAnimation {
                        showAllReports.toggle()
                    }
                } label: {
                    Text(showAllReports ? "收起" : "查看全部")
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundStyle(primaryColor)
                }
            }

            if displayedReports.isEmpty {
                emptyArchivePlaceholder
            } else {
                VStack(spacing: 12) {
                    ForEach(displayedReports) { report in
                        NavigationLink {
                            ReportDetailView(report: report)
                        } label: {
                            ArchiveReportRow(report: report)
                        }
                        .buttonStyle(.plain)
                    }
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
        let values = reportGenerator.sleepTrendData.filter { $0.value > 0 }.map(\.value)
        guard !values.isEmpty else { return 0.0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private var bestSleepNight: Double {
        let values = reportGenerator.sleepTrendData.filter { $0.value > 0 }.map(\.value)
        return values.max() ?? 0.0
    }

    private var worstSleepNight: Double {
        let values = reportGenerator.sleepTrendData.filter { $0.value > 0 }.map(\.value)
        return values.min() ?? 0.0
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

    private var sleepTrendChart: some View {
        let data = reportGenerator.sleepTrendData

        return Chart {
            ForEach(data) { point in
                BarMark(
                    x: .value("日期", point.date, unit: .day),
                    y: .value("小时", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.7), Color.indigo.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }

            RuleMark(y: .value("平均", sleepAvgHours))
                .foregroundStyle(.indigo.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let h = value.as(Double.self) {
                        Text("\(String(format: "%.0f", h))h")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 5)) { value in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
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
            Circle()
                .fill(iconColor.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(iconColor)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(category)
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(status)
                        .font(.caption2).fontWeight(.medium)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(primaryColor.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 20))
                        .foregroundStyle(primaryColor)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(DateFormatters.mediumDate.string(from: report.date)) 深度分析报告")
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("生成于 \(DateFormatters.reportDate.string(from: report.createdAt))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption).fontWeight(.bold)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption2).fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
        )
    }
}
