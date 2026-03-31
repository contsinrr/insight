import SwiftUI
import SwiftData

@main
struct HealthInsightApp: App {
    @State private var healthKitManager = HealthKitManager()
    @State private var aiService = AIService()
    @State private var reportGenerator: ReportGenerator

    init() {
        let hkm = HealthKitManager()
        let ai = AIService()
        _healthKitManager = State(initialValue: hkm)
        _aiService = State(initialValue: ai)
        _reportGenerator = State(initialValue: ReportGenerator(healthKitManager: hkm, aiService: ai))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(healthKitManager)
                .environment(aiService)
                .environment(reportGenerator)
        }
        .modelContainer(for: HealthReport.self)
    }
}
