import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AIService.self) private var aiService
    @Environment(\.modelContext) private var modelContext

    @State private var apiKeyInput = ""
    @State private var selectedModel = "qwen-plus"
    @State private var showClearAlert = false
    @State private var showSavedToast = false

    @Query private var reports: [HealthReport]

    var body: some View {
        NavigationStack {
            Form {
                // API Key Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("通义千问 API Key")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        SecureField("请输入 API Key", text: $apiKeyInput)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        Button {
                            aiService.apiKey = apiKeyInput
                            showSavedToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSavedToast = false
                            }
                        } label: {
                            HStack {
                                Text("保存")
                                if showSavedToast {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } header: {
                    Text("AI 服务配置")
                } footer: {
                    Text("请从阿里云百炼平台获取 API Key。该 Key 仅保存在本地设备中。")
                }

                // Model Selection
                Section {
                    Picker("AI 模型", selection: $selectedModel) {
                        ForEach(Constants.availableModels, id: \.self) { model in
                            Text(Constants.modelDisplayNames[model] ?? model)
                                .tag(model)
                        }
                    }
                    .onChange(of: selectedModel) {
                        aiService.selectedModel = selectedModel
                    }
                } footer: {
                    Text("Plus 模型分析能力更强，Turbo 模型速度更快，Max 模型质量最佳但价格更高。")
                }

                // Health Data
                Section {
                    Button {
                        if let url = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                            Text("打开「健康」App")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(.blue)
                            Text("管理健康数据权限")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                } header: {
                    Text("健康数据")
                } footer: {
                    Text("如果某些数据显示「暂无数据」，请确认已在「设置 > 隐私 > 健康」中授权本 App 读取相应数据。")
                }

                // Report Management
                Section {
                    HStack {
                        Text("已保存报告数量")
                        Spacer()
                        Text("\(reports.count) 份")
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("清除所有历史报告")
                        }
                    }
                    .disabled(reports.isEmpty)
                } header: {
                    Text("报告管理")
                }

                // About
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("开发者")
                        Spacer()
                        Text("个人项目")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("关于")
                } footer: {
                    Text("HealthInsight 是一个个人使用的健康数据分析工具。所有健康数据仅在本地处理，仅将数据摘要发送到 AI 服务生成分析报告。")
                }
            }
            .navigationTitle("设置")
            .onAppear {
                apiKeyInput = aiService.apiKey
                selectedModel = aiService.selectedModel
            }
            .alert("确认清除", isPresented: $showClearAlert) {
                Button("取消", role: .cancel) {}
                Button("清除", role: .destructive) {
                    clearAllReports()
                }
            } message: {
                Text("确定要删除所有历史报告吗？此操作不可恢复。")
            }
        }
    }

    private func clearAllReports() {
        for report in reports {
            modelContext.delete(report)
        }
        try? modelContext.save()
    }
}
