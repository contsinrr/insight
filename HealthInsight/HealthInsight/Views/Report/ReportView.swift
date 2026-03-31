import SwiftUI
import SwiftData
import Charts

struct ReportView: View {
    @Environment(ReportGenerator.self) private var generator
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var overallExpanded = true
    @State private var trendExpanded = true

    private let primaryColor = Color(red: 0.45, green: 0.40, blue: 0.85)
    private let bgGradient = LinearGradient(
        colors: [Color(red: 0.93, green: 0.91, blue: 0.96), .white],
        startPoint: .top, endPoint: .bottom
    )

    var body: some View {
        NavigationStack {
            ZStack {
                // Use solid color background only - no gradient to avoid transparency issues
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Date header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("健康报告")
                                    .font(.title2).bold()
                                Text(DateFormatters.fullDate.string(from: Date()))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if !generator.fullReportText.isEmpty && !generator.isGenerating {
                                ShareLink(
                                    item: generator.fullReportText,
                                    subject: Text("健康洞察 - 今日报告"),
                                    message: Text("我的今日健康报告")
                                ) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.body)
                                        .foregroundStyle(primaryColor)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Status / Generate Button
                        if generator.overallAnalysis.isEmpty && generator.trendInsights.isEmpty && !generator.isGenerating {
                            generateButton
                        }

                        // Card 1: 整体分析
                        reportCard(
                            title: "整体分析",
                            subtitle: "睡眠与运动综合评估",
                            icon: "heart.text.clipboard",
                            iconColor: .pink,
                            isLoading: generator.isGeneratingOverall,
                            isExpanded: $overallExpanded
                        ) {
                            overallAnalysisContent
                        }

                        // Card 2: 趋势洞察
                        reportCard(
                            title: "趋势洞察",
                            subtitle: "30天睡眠趋势 · 今日心率",
                            icon: "chart.line.uptrend.xyaxis",
                            iconColor: .orange,
                            isLoading: generator.isGeneratingTrend,
                            isExpanded: $trendExpanded
                        ) {
                            trendInsightsContent
                        }

                        // Error display
                        if let error = generator.error {
                            errorBanner(error)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
            .task {
                if generator.overallAnalysis.isEmpty && generator.trendInsights.isEmpty && !generator.isGenerating {
                    await generator.generateReport(modelContext: modelContext)
                }
            }
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundStyle(primaryColor)

            Text("准备生成健康报告")
                .font(.headline)

            Text("将读取您的健康数据，由 AI 生成分析报告")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await generator.generateReport(modelContext: modelContext)
                }
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("开始生成")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(primaryColor)
            .padding(.horizontal, 48)
        }
        .padding(.vertical, 32)
    }

    // MARK: - Card Template

    private func reportCard<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        isLoading: Bool,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            // Card Header (always visible)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(iconColor.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundStyle(iconColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 0 : -90))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded.wrappedValue {
                Divider()
                    .padding(.horizontal)

                content()
                    .padding(16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal)
    }

    // MARK: - Overall Analysis Content

    @ViewBuilder
    private var overallAnalysisContent: some View {
        if generator.overallAnalysis.isEmpty && generator.isGeneratingOverall {
            VStack(spacing: 8) {
                ProgressView()
                Text("正在分析睡眠与运动数据...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } else if !generator.overallAnalysis.isEmpty {
            StreamingMarkdownView(
                text: generator.overallAnalysis,
                isStreaming: generator.isGeneratingOverall
            )
        }
    }

    // MARK: - Trend Insights Content

    @ViewBuilder
    private var trendInsightsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Sleep Trend Chart
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bed.double.fill")
                        .foregroundStyle(.indigo)
                    Text("近30天睡眠时长")
                        .font(.subheadline.bold())
                }

                if generator.sleepTrendData.isEmpty && !generator.isGeneratingTrend {
                    emptyChartPlaceholder("暂无近30天睡眠数据")
                } else if !generator.sleepTrendData.isEmpty {
                    sleepTrendChart
                }
            }

            Divider()

            // Heart Rate Chart
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text("今日心率趋势")
                        .font(.subheadline.bold())
                }

                if generator.heartRateData.isEmpty && !generator.isGeneratingTrend {
                    emptyChartPlaceholder("暂无今日心率数据")
                } else if !generator.heartRateData.isEmpty {
                    heartRateChart
                }
            }

            if !generator.trendInsights.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.orange)
                        Text("AI 趋势解读")
                            .font(.subheadline.bold())
                    }

                    StreamingMarkdownView(
                        text: generator.trendInsights,
                        isStreaming: generator.isGeneratingTrend
                    )
                }
            } else if generator.isGeneratingTrend {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("正在分析趋势数据...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Sleep Trend Chart

    private var sleepTrendChart: some View {
        let data = generator.sleepTrendData
        let avgHours = data.map(\.value).reduce(0, +) / max(Double(data.count), 1)

        return Chart {
            ForEach(data) { point in
                BarMark(
                    x: .value("日期", point.date, unit: .day),
                    y: .value("小时", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.7), Color.indigo.opacity(0.3)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .cornerRadius(3)
            }

            RuleMark(y: .value("平均", avgHours))
                .foregroundStyle(.indigo.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .annotation(position: .top, alignment: .leading) {
                    Text("平均 \(String(format: "%.1f", avgHours))h")
                        .font(.caption2)
                        .foregroundStyle(.indigo)
                }
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
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.caption2)
            }
        }
        .frame(height: 160)
    }

    // MARK: - Heart Rate Chart

    private var heartRateChart: some View {
        let data = generator.heartRateData
        let minBPM = (data.map(\.bpm).min() ?? 50) - 10
        let maxBPM = (data.map(\.bpm).max() ?? 120) + 10

        return Chart {
            ForEach(data) { point in
                LineMark(
                    x: .value("时间", point.time),
                    y: .value("BPM", point.bpm)
                )
                .foregroundStyle(Color.red.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("时间", point.time),
                    y: .value("BPM", point.bpm)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.red.opacity(0.2), Color.red.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYScale(domain: minBPM...maxBPM)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let bpm = value.as(Double.self) {
                        Text("\(String(format: "%.0f", bpm))")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                AxisValueLabel(format: .dateTime.hour())
                    .font(.caption2)
            }
        }
        .frame(height: 160)
    }

    // MARK: - Helpers

    private func emptyChartPlaceholder(_ text: String) -> some View {
        HStack {
            Image(systemName: "chart.bar.xaxis")
                .foregroundStyle(.tertiary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.06))
        )
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.red.opacity(0.1))
        )
        .padding(.horizontal)
    }
}
