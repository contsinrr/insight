import SwiftUI

struct HealthCategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    let metrics: [(label: String, value: String?, unit: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(color)
            }

            Divider()

            // Metrics
            ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                HealthMetricRow(
                    label: metric.label,
                    value: metric.value,
                    unit: metric.unit
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}
