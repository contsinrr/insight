import SwiftUI

struct HomeView: View {
    @Environment(HealthKitManager.self) private var healthKit
    @Environment(AIService.self) private var aiService
    @Environment(ReportGenerator.self) private var reportGenerator
    @State private var showReportSheet = false
    @State private var showSettingsAlert = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.91, blue: 0.98),
                    Color(red: 0.96, green: 0.95, blue: 1.0),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            Group {
                if healthKit.isLoading {
                    LoadingView(message: "正在读取健康数据...")
                } else {
                    scrollContent
                }
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportView()
        }
        .alert("需要设置 API Key", isPresented: $showSettingsAlert) {
            Button("好的") {}
        } message: {
            Text("请先在「设置」页面中填写通义千问 API Key，才能生成健康报告。")
        }
        .task {
            await healthKit.requestAuthorization()
            await healthKit.fetchTodayData()
        }
    }

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                // Report Banner
                reportBanner
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Main Cards
                VStack(spacing: 14) {
                    // Sleep Card (large)
                    sleepCard
                    
                    // Activity Card (large)
                    activityCard

                    // Two column: Heart Rate + Body
                    HStack(spacing: 14) {
                        vitalsCard
                        bodyCard
                    }

                    // Two column: Nutrition + Mindfulness
                    HStack(spacing: 14) {
                        nutritionCard
                        mindfulnessCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .refreshable {
            await healthKit.fetchTodayData()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(greetingText)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
            // Share button style
            Button {
                if aiService.isApiKeySet {
                    showReportSheet = true
                } else {
                    showSettingsAlert = true
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                    Text("分享")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: Date())
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<5: return "夜深了"
        case 5..<8: return "早上好"
        case 8..<11: return "上午好"
        case 11..<13: return "中午好"
        case 13..<17: return "下午好"
        case 17..<21: return "晚上好"
        default: return "夜深了"
        }
    }

    // MARK: - Report Banner

    private var reportBanner: some View {
        Button {
            if aiService.isApiKeySet {
                showReportSheet = true
            } else {
                showSettingsAlert = true
            }
        } label: {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.subheadline)
                    Text("健康日报")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("点击生成 >")
                        .font(.caption)
                        .opacity(0.8)
                }

                HStack {
                    Image(systemName: "brain.head.profile.fill")
                        .font(.caption)
                    Text("AI 智能解读你的健康数据")
                        .font(.caption)
                        .opacity(0.9)
                    Spacer()
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.45, green: 0.40, blue: 0.85),
                        Color(red: 0.55, green: 0.45, blue: 0.90),
                        Color(red: 0.65, green: 0.55, blue: 0.95)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    // MARK: - Sleep Card

    private var sleepCard: some View {
        let s = healthKit.todayData.sleep
        return DataCard {
            VStack(alignment: .leading, spacing: 12) {
                // Title row
                HStack {
                    Text("睡眠")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if s.totalDuration != nil {
                        StatusBadge(text: sleepQualityText(s), color: .indigo)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                if let bedtime = s.bedtime, let wake = s.wakeTime {
                    // Time range
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text(DateFormatters.shortTime.string(from: bedtime))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text(" - ")
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text(DateFormatters.shortTime.string(from: wake))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                    }

                    // Sleep stages
                    HStack(spacing: 16) {
                        if let deep = s.deepMinutes {
                            SleepStageItem(label: "深睡", value: formatMin(deep), color: .indigo)
                        }
                        if let rem = s.remMinutes {
                            SleepStageItem(label: "REM", value: formatMin(rem), color: .purple)
                        }
                        if let core = s.coreMinutes {
                            SleepStageItem(label: "浅睡", value: formatMin(core), color: .blue)
                        }
                        if let awake = s.awakeMinutes {
                            SleepStageItem(label: "清醒", value: formatMin(awake), color: .orange)
                        }
                    }
                    .font(.caption)
                } else {
                    Text("暂无睡眠数据")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - Activity Card

    private var activityCard: some View {
        let a = healthKit.todayData.activity
        return DataCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("运动")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if a.activeCalories != nil {
                        StatusBadge(text: activityStatusText(a), color: .green)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                // Main metrics in two columns
                HStack(spacing: 0) {
                    // Steps
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(a.steps.map { formatNumber($0) } ?? "--")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("步")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("今日步数")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Calories
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(a.activeCalories.map { String(format: "%.0f", $0) } ?? "--")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("kcal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("活动消耗")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Sub metrics
                HStack(spacing: 20) {
                    if let dist = a.distance {
                        MiniMetric(icon: "figure.walk", value: String(format: "%.1f", dist/1000), unit: "km")
                    }
                    if let ex = a.exerciseMinutes {
                        MiniMetric(icon: "flame.fill", value: String(format: "%.0f", ex), unit: "分钟")
                    }
                    if let stand = a.standHours {
                        MiniMetric(icon: "figure.stand", value: String(format: "%.0f", stand), unit: "小时")
                    }
                }
            }
        }
    }

    // MARK: - Vitals Card (Half Width)

    private var vitalsCard: some View {
        let v = healthKit.todayData.vitals
        return DataCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("心率")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    if v.restingHeartRate != nil {
                        StatusBadge(text: heartRateStatus(v.restingHeartRate), color: heartRateColor(v.restingHeartRate))
                    }
                    
                    Spacer()
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(v.restingHeartRate.map { String(format: "%.0f", $0) } ?? "--")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.red)
                    Text("bpm")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let spo2 = v.bloodOxygen {
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text("血氧 \(String(format: "%.0f", spo2))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Body Card (Half Width)

    private var bodyCard: some View {
        let b = healthKit.todayData.body
        return DataCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("身体")
                    .font(.subheadline)
                    .fontWeight(.bold)

                if let weight = b.weight {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", weight))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                        Text("kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("--")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.tertiary)
                }

                if let bmi = b.bmi {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.stand")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text("BMI \(String(format: "%.1f", bmi))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Nutrition Card (Half Width)

    private var nutritionCard: some View {
        let n = healthKit.todayData.nutrition
        return DataCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("营养")
                    .font(.subheadline)
                    .fontWeight(.bold)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(n.water.map { String(format: "%.0f", $0) } ?? "--")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                    Text("mL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                    Text("饮水量")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Mindfulness Card (Half Width)

    private var mindfulnessCard: some View {
        let m = healthKit.todayData.mindfulness
        return DataCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("正念")
                    .font(.subheadline)
                    .fontWeight(.bold)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(m.mindfulMinutes.map { String(format: "%.0f", $0) } ?? "--")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.purple)
                    Text("分钟")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                    Text("冥想时长")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatMin(_ minutes: Double) -> String {
        let total = Int(minutes)
        let h = total / 60
        let m = total % 60
        if h > 0 { return "\(h)h\(m)m" }
        return "\(m)m"
    }

    private func formatNumber(_ value: Double) -> String {
        if value >= 10000 {
            return String(format: "%.1f万", value / 10000)
        }
        return String(format: "%.0f", value)
    }

    private func sleepQualityText(_ s: SleepData) -> String {
        guard let total = s.totalDuration else { return "暂无" }
        let hours = total / 3600
        if hours >= 7 { return "睡眠充足" }
        if hours >= 6 { return "睡眠平稳" }
        return "睡眠不足"
    }

    private func activityStatusText(_ a: ActivityData) -> String {
        guard let cal = a.activeCalories else { return "暂无" }
        if cal >= 400 { return "表现优秀" }
        if cal >= 200 { return "表现达标" }
        return "需要运动"
    }

    private func heartRateStatus(_ hr: Double?) -> String {
        guard let hr = hr else { return "暂无" }
        if hr < 60 { return "偏低" }
        if hr <= 80 { return "正常" }
        return "注意"
    }

    private func heartRateColor(_ hr: Double?) -> Color {
        guard let hr = hr else { return .gray }
        if hr < 60 { return .blue }
        if hr <= 80 { return .green }
        return .orange
    }
}

// MARK: - Reusable Components

struct DataCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct SleepStageItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(label) \(value)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct MiniMetric: View {
    let icon: String
    let value: String
    let unit: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(value) \(unit)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
