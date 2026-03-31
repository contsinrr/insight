import SwiftUI

struct HealthMetricRow: View {
    let label: String
    let value: String?
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            if let value {
                HStack(spacing: 2) {
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(.vertical, 2)
    }
}
