import Foundation
import SwiftData

@Model
final class HealthReport {
    var id: UUID
    var date: Date
    var content: String
    var healthSummary: String
    var createdAt: Date

    init(date: Date, content: String, healthSummary: String) {
        self.id = UUID()
        self.date = date
        self.content = content
        self.healthSummary = healthSummary
        self.createdAt = .now
    }
}
