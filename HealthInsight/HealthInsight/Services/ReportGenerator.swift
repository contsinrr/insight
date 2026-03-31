import Foundation
import SwiftData

@Observable
final class ReportGenerator {
    let healthKitManager: HealthKitManager
    let aiService: AIService

    var isGeneratingOverall = false
    var isGeneratingTrend = false
    var overallAnalysis = ""
    var trendInsights = ""
    var error: String?

    var sleepTrendData: [TrendPoint] = []
    var heartRateData: [HeartRatePoint] = []

    var isGenerating: Bool {
        isGeneratingOverall || isGeneratingTrend
    }

    init(healthKitManager: HealthKitManager, aiService: AIService) {
        self.healthKitManager = healthKitManager
        self.aiService = aiService
    }

    var fullReportText: String {
        var parts: [String] = []
        if !overallAnalysis.isEmpty {
            parts.append("## 整体分析\n\n\(overallAnalysis)")
        }
        if !trendInsights.isEmpty {
            parts.append("## 趋势洞察\n\n\(trendInsights)")
        }
        return parts.joined(separator: "\n\n---\n\n")
    }

    // MARK: - Prompts

    private let overallSystemPrompt = """
    你是一位专业的健康数据分析师和私人健康顾问，名叫"健康洞察AI"。

    ## 分析原则
    1. 基于数据说话，不编造不存在的数据
    2. 提供具体、可操作的建议
    3. 语气温暖友好，像一位关心你的私人医生
    4. 对于缺失的数据类别，不做推测，可以建议用户开始记录
    5. 不做医学诊断，必要时建议咨询专业医生

    ## 输出要求
    请根据用户提供的今日健康数据进行 **整体分析**：

    1. **睡眠分析**：分析昨晚睡眠时长、各阶段比例，给出评价和建议
    2. **运动分析**：分析今日步数、运动量、卡路里消耗，给出评价和建议
    3. 结尾给一个综合健康评分(1-100分)和简短理由

    使用 Markdown 格式，直接输出分析内容，不需要加"整体分析"标题。
    对于没有数据的部分，简短说明"暂无该项数据"即可。
    """

    private let trendSystemPrompt = """
    你是一位专业的健康数据分析师和私人健康顾问，名叫"健康洞察AI"。

    ## 分析原则
    1. 基于数据说话，不编造不存在的数据
    2. 关注数据趋势和异常值
    3. 提供具体、可操作的建议
    4. 语气温暖友好，像一位关心你的私人医生
    5. 不做医学诊断，必要时建议咨询专业医生

    ## 输出要求
    请根据用户提供的趋势数据进行 **趋势洞察** 分析：

    1. **睡眠趋势解读**：分析近30天的睡眠时长趋势，找出规律、异常和变化，给出改善建议
    2. **心率趋势解读**：分析今天全天心率的变化趋势，找出静息/运动/异常时段

    使用 Markdown 格式，直接输出分析内容，不需要加"趋势洞察"标题。
    对于没有数据的部分，简短说明"暂无该项数据"即可。
    """

    // MARK: - Generate Report (Two Parallel Streams)

    @MainActor
    func generateReport(modelContext: ModelContext) async {
        guard !isGenerating else { return }

        guard aiService.isApiKeySet else {
            error = "请先在设置中填写通义千问 API Key"
            return
        }

        isGeneratingOverall = true
        isGeneratingTrend = true
        overallAnalysis = ""
        trendInsights = ""
        error = nil

        // Fetch latest health data + trend data in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.healthKitManager.fetchTodayData() }
            group.addTask { await self.healthKitManager.fetchTrendData() }
        }

        let healthData = healthKitManager.todayData
        let trendData = healthKitManager.trendData

        sleepTrendData = trendData.sleepTrend
        heartRateData = trendData.heartRateSamples

        // Build separate message lists
        let overallMessages: [ChatRequest.ChatMessage] = [
            .init(role: "system", content: overallSystemPrompt),
            .init(role: "user", content: healthData.toPromptString())
        ]

        let trendPrompt = """
        \(trendData.toPromptString())

        补充：今日活动数据 - 步数 \(healthData.activity.steps.map { String(format: "%.0f", $0) } ?? "暂无"), \
        静息心率 \(healthData.vitals.restingHeartRate.map { String(format: "%.0f bpm", $0) } ?? "暂无")
        """

        let trendMessages: [ChatRequest.ChatMessage] = [
            .init(role: "system", content: trendSystemPrompt),
            .init(role: "user", content: trendPrompt)
        ]

        let aiService = self.aiService

        // Launch two parallel streaming tasks
        let overallTask = Task { @MainActor in
            do {
                let stream = aiService.streamChat(messages: overallMessages)
                for try await chunk in stream {
                    self.overallAnalysis += chunk
                }
            } catch {
                if self.error == nil {
                    self.error = "整体分析生成失败: \(error.localizedDescription)"
                }
            }
            self.isGeneratingOverall = false
        }

        let trendTask = Task { @MainActor in
            do {
                let stream = aiService.streamChat(messages: trendMessages)
                for try await chunk in stream {
                    self.trendInsights += chunk
                }
            } catch {
                if self.error == nil {
                    self.error = "趋势洞察生成失败: \(error.localizedDescription)"
                }
            }
            self.isGeneratingTrend = false
        }

        // Wait for both to finish
        await overallTask.value
        await trendTask.value

        // Save report to SwiftData
        if !fullReportText.isEmpty {
            let report = HealthReport(
                date: healthData.date,
                content: fullReportText,
                healthSummary: healthData.toPromptString()
            )
            modelContext.insert(report)
            try? modelContext.save()
        }
    }
}
