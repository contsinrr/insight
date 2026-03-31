import SwiftUI
import Charts

struct ReportDetailView: View {
    let report: HealthReport
    
    @Environment(\.dismiss) private var dismiss
    
    private let primaryColor = Color(red: 0.45, green: 0.40, blue: 0.85)
    private let bgGradient = LinearGradient(
        colors: [Color(red: 0.97, green: 0.96, blue: 1.0), Color.white],
        startPoint: .top, endPoint: .bottom
    )
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgGradient.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Score Card
                        scoreCard
                        
                        // Summary Stats Grid
                        summaryStatsGrid
                        
                        // Sleep Stages Chart
                        sleepStagesSection
                        
                        // Heart Rate Section
                        heartRateSection
                        
                        // Detailed Analysis
                        detailedAnalysisSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("报告详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("完成")
                            .fontWeight(.bold)
                            .foregroundStyle(primaryColor)
                    }
                }
            }
        }
    }
    
    // MARK: - Score Card
    
    private var scoreCard: some View {
        VStack(spacing: 12) {
            // Date badge
            HStack {
                Spacer()
                Text(DateFormatters.shortDate.string(from: report.date))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            // Score circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 140, height: 140)
                
                Circle()
                    .trim(from: 0, to: 0.85)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("85")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(primaryColor)
                    Text("健康评分")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            // Score description
            Text("表现优秀！你的睡眠质量和活动量都保持在良好水平。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 16, x: 0, y: 4)
        )
    }
    
    // MARK: - Summary Stats Grid
    
    private var summaryStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                icon: "moon.fill",
                iconColor: .indigo,
                value: "7h 45m",
                label: "总睡眠时长",
                trend: "+12%",
                trendPositive: true
            )
            
            StatCard(
                icon: "bed.double.fill",
                iconColor: .purple,
                value: "00:27",
                label: "入睡时间",
                trend: "正常",
                trendPositive: true
            )
            
            StatCard(
                icon: "eye.fill",
                iconColor: .orange,
                value: "1 次",
                label: "清醒次数",
                trend: "较少",
                trendPositive: true
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Sleep Stages Section
    
    private var sleepStagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("睡眠阶段分析")
                .font(.headline).fontWeight(.bold)
                .foregroundStyle(.primary)
            
            // Sleep stages bar
            VStack(alignment: .leading, spacing: 8) {
                // Segmented bar
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.indigo)
                            .frame(width: geometry.size.width * 0.17)
                        
                        Rectangle()
                            .fill(Color.purple)
                            .frame(width: geometry.size.width * 0.23)
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * 0.55)
                        
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: geometry.size.width * 0.05)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(height: 16)
                
                // Legend
                HStack(spacing: 12) {
                    SleepStageLegendDot(color: .indigo, label: "深睡", percentage: "17%")
                    SleepStageLegendDot(color: .purple, label: "REM", percentage: "23%")
                    SleepStageLegendDot(color: .blue, label: "浅睡", percentage: "55%")
                    SleepStageLegendDot(color: .orange, label: "清醒", percentage: "5%")
                }
            }
            
            // Sleep quality score
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("深度睡眠充足，身体恢复效果好。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Heart Rate Section
    
    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("心率监测")
                    .font(.headline).fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("平均 72 BPM")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            // Heart rate zones (simulated)
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                HeartRateZoneCard(
                    zone: "有氧运动",
                    duration: "2h54m",
                    percentage: "37.3%",
                    color: .orange,
                    description: "中等强度运动，心肺功能提升"
                )
                
                HeartRateZoneCard(
                    zone: "燃脂",
                    duration: "1h30m",
                    percentage: "31.7%",
                    color: .yellow,
                    description: "低强度运动，脂肪燃烧效率高"
                )
                
                HeartRateZoneCard(
                    zone: "热身激活",
                    duration: "20h36m",
                    percentage: "29.3%",
                    color: .blue,
                    description: "日常活动状态，保持身体活跃"
                )
                
                HeartRateZoneCard(
                    zone: "极限运动",
                    duration: "8m",
                    percentage: "1.7%",
                    color: .red,
                    description: "高强度运动，注意适度休息"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Detailed Analysis Section
    
    private var detailedAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("详细解读与建议")
                .font(.headline).fontWeight(.bold)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                AnalysisItem(
                    title: "睡眠质量",
                    icon: "moon.stars.fill",
                    iconColor: .indigo,
                    content: "昨晚你的深度睡眠占比达到 17%，高于平均水平。深度睡眠期间身体进行修复和生长激素分泌，这对身体健康非常重要。",
                    suggestion: "继续保持晚上 10 点开始放松的习惯，避免睡前使用电子设备。"
                )
                
                AnalysisItem(
                    title: "心率健康",
                    icon: "heart.fill",
                    iconColor: .red,
                    content: "静息心率维持在 62-72 BPM 之间，属于健康范围。心率变异性（HRV）为 45ms，显示自主神经系统平衡良好。",
                    suggestion: "可以尝试冥想或深呼吸练习来进一步提升 HRV。"
                )
                
                AnalysisItem(
                    title: "活动建议",
                    icon: "figure.run",
                    iconColor: .orange,
                    content: "今日步数 8,500 步，接近推荐的 10,000 步目标。下午时段活动量较低。",
                    suggestion: "建议在下午 3-4 点进行 10 分钟的快走，有助于提升代谢率和精神状态。"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        )
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let trend: String
    let trendPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            HStack(spacing: 4) {
                Image(systemName: trendPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                    .foregroundStyle(trendPositive ? .green : .orange)
                Text(trend)
                    .font(.caption2)
                    .foregroundStyle(trendPositive ? .green : .orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Sleep Stage Legend Dot

struct SleepStageLegendDot: View {
    let color: Color
    let label: String
    let percentage: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(label) \(percentage)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Heart Rate Zone Card

struct HeartRateZoneCard: View {
    let zone: String
    let duration: String
    let percentage: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(zone)
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()
                Text(percentage)
                    .font(.caption2).fontWeight(.bold)
                    .foregroundStyle(color)
            }
            
            Text(duration)
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            Text(description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Analysis Item

struct AnalysisItem: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: String
    let suggestion: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            
            Text(content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(nil)
            
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                Text(suggestion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 2)
        }
    }
}
