import SwiftUI

struct ReportDetailView: View {
    let report: HealthReport

    @State private var overallExpanded = true
    @State private var trendExpanded = true

    private let primaryColor = Color(red: 0.45, green: 0.40, blue: 0.85)
    private let bgGradient = LinearGradient(
        colors: [Color(red: 0.93, green: 0.91, blue: 0.96), .white],
        startPoint: .top, endPoint: .bottom
    )

    private var sections: ReportParser.Sections {
        ReportParser.parse(report.content)
    }

    var body: some View {
        ZStack {
            bgGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Date header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(DateFormatters.fullDate.string(from: report.date))
                                .font(.title3.bold())
                            Text("生成于 \(DateFormatters.reportDate.string(from: report.createdAt))")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)

                    // Card 1: 整体分析
                    if let overall = sections.overallAnalysis, !overall.isEmpty {
                        detailCard(
                            title: "整体分析",
                            subtitle: "睡眠与运动综合评估",
                            icon: "heart.text.clipboard",
                            iconColor: .pink,
                            isExpanded: $overallExpanded
                        ) {
                            StreamingMarkdownView(text: overall, isStreaming: false)
                        }
                    }

                    // Card 2: 趋势洞察
                    if let trend = sections.trendInsights, !trend.isEmpty {
                        detailCard(
                            title: "趋势洞察",
                            subtitle: "睡眠趋势 · 心率趋势",
                            icon: "chart.line.uptrend.xyaxis",
                            iconColor: .orange,
                            isExpanded: $trendExpanded
                        ) {
                            StreamingMarkdownView(text: trend, isStreaming: false)
                        }
                    }

                    // Fallback: if no sections parsed, show raw
                    if sections.overallAnalysis == nil && sections.trendInsights == nil {
                        detailCard(
                            title: "健康报告",
                            subtitle: "AI 分析",
                            icon: "doc.richtext",
                            iconColor: primaryColor,
                            isExpanded: $overallExpanded
                        ) {
                            StreamingMarkdownView(text: report.content, isStreaming: false)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
        }
        .navigationTitle("报告详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: report.content,
                    subject: Text("健康洞察 - \(DateFormatters.shortDate.string(from: report.date))报告"),
                    message: Text("我的健康报告")
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(primaryColor)
                }
            }
        }
    }

    // MARK: - Card Template

    private func detailCard<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            // Header
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

                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 0 : -90))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

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
}
