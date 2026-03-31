import Foundation

// MARK: - Trend Data Point (for charts)
struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct HeartRatePoint: Identifiable {
    let id = UUID()
    let time: Date
    let bpm: Double
}

struct TrendData {
    var sleepTrend: [TrendPoint] = []        // 30天睡眠时长(小时)
    var heartRateSamples: [HeartRatePoint] = []  // 今日心率采样

    var sleepAvgHours: Double? {
        guard !sleepTrend.isEmpty else { return nil }
        return sleepTrend.map(\.value).reduce(0, +) / Double(sleepTrend.count)
    }

    var heartRateMin: Double? {
        heartRateSamples.map(\.bpm).min()
    }

    var heartRateMax: Double? {
        heartRateSamples.map(\.bpm).max()
    }

    var heartRateAvg: Double? {
        guard !heartRateSamples.isEmpty else { return nil }
        return heartRateSamples.map(\.bpm).reduce(0, +) / Double(heartRateSamples.count)
    }

    func toPromptString() -> String {
        var lines: [String] = []

        lines.append("## 近30天睡眠趋势")
        if sleepTrend.isEmpty {
            lines.append("暂无近30天睡眠数据")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            for point in sleepTrend {
                lines.append("- \(formatter.string(from: point.date)): \(String(format: "%.1f", point.value)) 小时")
            }
            if let avg = sleepAvgHours {
                lines.append("- 30天平均睡眠时长: \(String(format: "%.1f", avg)) 小时")
            }
        }
        lines.append("")

        lines.append("## 今日心率趋势")
        if heartRateSamples.isEmpty {
            lines.append("暂无今日心率数据")
        } else {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            // Sample a subset to avoid overly long prompt
            let step = max(1, heartRateSamples.count / 20)
            for i in stride(from: 0, to: heartRateSamples.count, by: step) {
                let s = heartRateSamples[i]
                lines.append("- \(timeFormatter.string(from: s.time)): \(String(format: "%.0f", s.bpm)) bpm")
            }
            if let min = heartRateMin, let max = heartRateMax, let avg = heartRateAvg {
                lines.append("- 今日心率范围: \(String(format: "%.0f", min))-\(String(format: "%.0f", max)) bpm, 平均 \(String(format: "%.0f", avg)) bpm")
            }
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Activity Data
struct ActivityData {
    var steps: Double?
    var distance: Double?           // 米
    var activeCalories: Double?     // 千卡
    var basalCalories: Double?      // 千卡
    var exerciseMinutes: Double?    // 分钟
    var standHours: Double?         // 小时
}

// MARK: - Sleep Data
struct SleepData {
    var totalDuration: TimeInterval?  // 秒
    var awakeMinutes: Double?
    var remMinutes: Double?
    var coreMinutes: Double?          // 浅睡眠
    var deepMinutes: Double?
    var bedtime: Date?
    var wakeTime: Date?
}

// MARK: - Body Data
struct BodyData {
    var weight: Double?              // kg
    var height: Double?              // cm
    var bmi: Double?
    var bodyFatPercentage: Double?   // %
}

// MARK: - Vitals Data
struct VitalsData {
    var restingHeartRate: Double?         // bpm
    var walkingHeartRate: Double?         // bpm
    var heartRateVariability: Double?     // ms
    var bloodPressureSystolic: Double?    // mmHg
    var bloodPressureDiastolic: Double?   // mmHg
    var bloodOxygen: Double?             // %
    var respiratoryRate: Double?         // 次/分钟
    var bodyTemperature: Double?         // °C
}

// MARK: - Nutrition Data
struct NutritionData {
    var water: Double?       // mL
    var caffeine: Double?    // mg
}

// MARK: - Mindfulness Data
struct MindfulnessData {
    var mindfulMinutes: Double?
}

// MARK: - Daily Health Data (Top-level Container)
struct DailyHealthData {
    var date: Date
    var activity: ActivityData
    var sleep: SleepData
    var body: BodyData
    var vitals: VitalsData
    var nutrition: NutritionData
    var mindfulness: MindfulnessData

    static func empty(date: Date = .now) -> DailyHealthData {
        DailyHealthData(
            date: date,
            activity: ActivityData(),
            sleep: SleepData(),
            body: BodyData(),
            vitals: VitalsData(),
            nutrition: NutritionData(),
            mindfulness: MindfulnessData()
        )
    }

    func toPromptString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "yyyy年M月d日 EEEE"
        let dateString = dateFormatter.string(from: date)

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "zh_CN")
        timeFormatter.dateFormat = "HH:mm"

        var lines: [String] = []
        lines.append("以下是我今天（\(dateString)）的 Apple Health 健康数据：")
        lines.append("")

        // Activity
        lines.append("## 活动数据")
        lines.append("- 步数：\(formatOptional(activity.steps, format: "%.0f 步"))")
        lines.append("- 步行+跑步距离：\(formatOptionalDistance(activity.distance))")
        lines.append("- 活动消耗：\(formatOptional(activity.activeCalories, format: "%.0f 千卡"))")
        lines.append("- 基础代谢消耗：\(formatOptional(activity.basalCalories, format: "%.0f 千卡"))")
        lines.append("- 运动时长：\(formatOptional(activity.exerciseMinutes, format: "%.0f 分钟"))")
        lines.append("- 站立小时数：\(formatOptional(activity.standHours, format: "%.0f 小时"))")
        lines.append("")

        // Sleep
        lines.append("## 睡眠数据（昨晚）")
        lines.append("- 总睡眠时长：\(formatOptionalDuration(sleep.totalDuration))")
        lines.append("- 深睡眠：\(formatOptionalMinutesAsDuration(sleep.deepMinutes))")
        lines.append("- REM 睡眠：\(formatOptionalMinutesAsDuration(sleep.remMinutes))")
        lines.append("- 浅睡眠（核心睡眠）：\(formatOptionalMinutesAsDuration(sleep.coreMinutes))")
        lines.append("- 清醒时间：\(formatOptionalMinutesAsDuration(sleep.awakeMinutes))")
        if let bedtime = sleep.bedtime {
            lines.append("- 入睡时间：\(timeFormatter.string(from: bedtime))")
        } else {
            lines.append("- 入睡时间：暂无数据")
        }
        if let wakeTime = sleep.wakeTime {
            lines.append("- 醒来时间：\(timeFormatter.string(from: wakeTime))")
        } else {
            lines.append("- 醒来时间：暂无数据")
        }
        lines.append("")

        // Body
        lines.append("## 身体数据")
        lines.append("- 体重：\(formatOptional(body.weight, format: "%.1f kg"))")
        lines.append("- 身高：\(formatOptional(body.height, format: "%.1f cm"))")
        lines.append("- BMI：\(formatOptional(body.bmi, format: "%.1f"))")
        lines.append("- 体脂率：\(formatOptionalPercentage(body.bodyFatPercentage))")
        lines.append("")

        // Vitals
        lines.append("## 生命体征")
        lines.append("- 静息心率：\(formatOptional(vitals.restingHeartRate, format: "%.0f bpm"))")
        lines.append("- 步行平均心率：\(formatOptional(vitals.walkingHeartRate, format: "%.0f bpm"))")
        lines.append("- 心率变异性：\(formatOptional(vitals.heartRateVariability, format: "%.1f ms"))")
        if vitals.bloodPressureSystolic != nil || vitals.bloodPressureDiastolic != nil {
            let sys = vitals.bloodPressureSystolic.map { String(format: "%.0f", $0) } ?? "?"
            let dia = vitals.bloodPressureDiastolic.map { String(format: "%.0f", $0) } ?? "?"
            lines.append("- 血压：\(sys)/\(dia) mmHg")
        } else {
            lines.append("- 血压：暂无数据")
        }
        lines.append("- 血氧饱和度：\(formatOptionalPercentage(vitals.bloodOxygen))")
        lines.append("- 呼吸频率：\(formatOptional(vitals.respiratoryRate, format: "%.1f 次/分钟"))")
        lines.append("- 体温：\(formatOptional(vitals.bodyTemperature, format: "%.1f °C"))")
        lines.append("")

        // Nutrition
        lines.append("## 营养")
        lines.append("- 饮水量：\(formatOptional(nutrition.water, format: "%.0f mL"))")
        lines.append("- 咖啡因摄入：\(formatOptional(nutrition.caffeine, format: "%.0f mg"))")
        lines.append("")

        // Mindfulness
        lines.append("## 正念")
        lines.append("- 正念冥想：\(formatOptional(mindfulness.mindfulMinutes, format: "%.0f 分钟"))")
        lines.append("")

        lines.append("请根据以上数据生成今日健康分析报告。")

        return lines.joined(separator: "\n")
    }

    // MARK: - Formatting Helpers

    private func formatOptional(_ value: Double?, format: String) -> String {
        guard let value = value else { return "暂无数据" }
        return String(format: format, value)
    }

    private func formatOptionalDistance(_ meters: Double?) -> String {
        guard let meters = meters else { return "暂无数据" }
        let km = meters / 1000.0
        return String(format: "%.2f 公里", km)
    }

    private func formatOptionalDuration(_ seconds: TimeInterval?) -> String {
        guard let seconds = seconds else { return "暂无数据" }
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours) 小时 \(minutes) 分钟"
        }
        return "\(minutes) 分钟"
    }

    private func formatOptionalMinutesAsDuration(_ minutes: Double?) -> String {
        guard let minutes = minutes else { return "暂无数据" }
        let totalMinutes = Int(minutes)
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours > 0 {
            return "\(hours) 小时 \(mins) 分钟"
        }
        return "\(mins) 分钟"
    }

    private func formatOptionalPercentage(_ value: Double?) -> String {
        guard let value = value else { return "暂无数据" }
        return String(format: "%.0f%%", value)
    }
}
