# HealthInsight 设计规范文档

## 📐 设计概览

HealthInsight 是一款基于 Apple Health 数据的 AI 健康分析 iOS 应用，采用现代化卡片式设计语言，提供温暖、专业、直观的用户体验。

---

## 🎨 颜色系统

### 主色调
| 用途 | 色值 | RGB | 使用场景 |
|------|------|-----|----------|
| **Primary Purple** | - | `RGB(0.45, 0.40, 0.85)` | 主按钮、强调元素、Banner |
| **Gradient Start** | - | `RGB(0.93, 0.91, 0.98)` | 背景渐变顶部 |
| **Gradient Middle** | - | `RGB(0.96, 0.95, 1.0)` | 背景渐变中部 |
| **System Background** | `.systemGroupedBackground` | - | 背景渐变底部 |

### 功能色板
| 颜色 | 使用场景 |
|------|----------|
| `.indigo` / `.purple` | 睡眠相关指标、正念冥想 |
| `.green` | 运动数据、BMI 正常状态、体重 |
| `.red` | 心率数据、警告状态 |
| `.orange` | 趋势洞察、清醒状态 |
| `.blue` / `.cyan` | 血氧、饮水、浅睡眠 |
| `.pink` | 整体分析图标背景 |

### 背景渐变配置

#### 首页背景
```swift
LinearGradient(
    colors: [
        Color(red: 0.93, green: 0.91, blue: 0.98),
        Color(red: 0.96, green: 0.95, blue: 1.0),
        Color(.systemGroupedBackground)
    ],
    startPoint: .top,
    endPoint: .center
)
```

#### 报告页背景
```swift
LinearGradient(
    colors: [Color(red: 0.93, green: 0.91, blue: 0.96), .white],
    startPoint: .top, 
    endPoint: .bottom
)
```

#### 健康日报 Banner
```swift
LinearGradient(
    colors: [
        Color(red: 0.45, green: 0.40, blue: 0.85),
        Color(red: 0.55, green: 0.45, blue: 0.90),
        Color(red: 0.65, green: 0.55, blue: 0.95)
    ],
    startPoint: .leading,
    endPoint: .trailing
)
```

---

## 🔲 卡片设计系统

### 通用卡片 (DataCard)
```swift
- 内边距：18pt
- 背景色：纯白 (.white)
- 圆角：20pt
- 阴影：color: .black.opacity(0.04), radius: 8, x: 0, y: 2
- 布局：frame(maxWidth: .infinity, alignment: .leading)
```

### 报告卡片
```swift
- 内边距：16pt（内容区），header 单独 16pt
- 背景色：纯白 (.white)
- 圆角：20pt
- 阴影：color: .black.opacity(0.06), radius: 12, x: 0, y: 4
- 水平边距：左右各留白 (padding .horizontal)
```

### 报告 Banner 卡片
```swift
- 内边距：水平 20pt, 垂直 16pt
- 背景色：紫色渐变（见颜色系统）
- 圆角：20pt
- 文字颜色：白色
```

---

## 📝 字体排印系统

### 字号规范
| 层级 | 字号配置 | 字重 | 使用场景 |
|------|----------|------|----------|
| **Title 2** | `font(.title2)` | Bold | 页面主标题、问候语 |
| **Headline** | `font(.headline)` | Bold/Semibold | 卡片标题 |
| **Subheadline** | `font(.subheadline)` | Bold | 次级标题 |
| **Caption** | `font(.caption)` | Regular | 副标题、说明文字 |
| **Caption 2** | `font(.caption2)` | Medium | 标签、徽章文字 |

### 数字显示规范
| 用途 | 字号配置 | 字重 |
|------|----------|------|
| **主要数值** | `size: 34` | `.bold`, `.rounded` |
| **睡眠时间段** | `size: 32` | `.bold`, `.rounded` |
| **时间段连接符** | `size: 24` | `.medium`, `.rounded` |
| **单位文字** | `font(.caption)` | Regular, `.secondary` |

### 行间距
- 标题与副标题：`spacing: 2` 或 `spacing: 4`
- 卡片内元素：`spacing: 8` / `12` / `16` / `20`
- 卡片之间：`spacing: 14` (同列), `spacing: 16` (报告页)

---

## 🧩 组件设计

### StatusBadge (状态徽章)
```swift
struct StatusBadge {
    - 字体：font(.caption2), fontWeight(.medium)
    - 前景色：对应状态颜色
    - 内边距：水平 8pt, 垂直 3pt
    - 背景：color.opacity(0.12)
    - 形状：Capsule (完全圆角)
}
```

### SleepStageItem (睡眠阶段项)
```swift
- 圆点：width: 6, height: 6, 填充对应颜色
- 文字：font(.caption), .secondary
- 间距：4pt
- 布局：HStack(spacing: 4)
```

### MiniMetric (迷你指标)
```swift
- 图标：font(.caption2), .secondary
- 文字：font(.caption), .secondary
- 间距：4pt
```

### 图标规范
| 位置 | 尺寸 | 样式 |
|------|------|------|
| 报告卡片图标容器 | 40×40pt | 圆角 10pt 背景 + 18pt 图标 |
| 小图标 | font(.caption2) | SF Symbols |
| 中等图标 | font(.subheadline) | SF Symbols |
| 装饰图标 | font(.body) | SF Symbols |

---

## 📊 图表样式

### 睡眠趋势图 (Bar Chart)
```swift
- 图表类型：柱状图 (BarMark)
- 高度：160pt
- 柱体样式:
  - 渐变：LinearGradient [.indigo.opacity(0.7) → .indigo.opacity(0.3)]
  - 方向：top → bottom
  - 圆角：3pt
- 平均线:
  - 样式：虚线 StrokeStyle(lineWidth: 1, dash: [4, 3])
  - 颜色：.indigo.opacity(0.5)
  - 标注：font(.caption2), .indigo
- Y 轴：左侧 (position: .leading), font(.caption2)
- X 轴：每 7 天一个刻度，格式 "月.日"
```

### 心率趋势图 (Line + Area Chart)
```swift
- 图表类型：折线图 + 面积图组合
- 高度：160pt
- 线条样式:
  - 颜色：Color.red.opacity(0.8)
  - 线宽：1.5pt
  - 插值：.catmullRom (平滑曲线)
- 面积样式:
  - 渐变：LinearGradient [.red.opacity(0.2) → .red.opacity(0.02)]
  - 插值：.catmullRom
- Y 轴：左侧，动态范围 (min-10 ~ max+10)
- X 轴：每 3 小时一个刻度
```

### 空状态图表
```swift
- 背景：RoundedRectangle(cornerRadius: 12)
- 填充：Color.gray.opacity(0.06)
- 最小高度：80pt
- 图标：chart.bar.xaxis, .tertiary
- 文字：font(.caption), .secondary
```

---

## 🎭 交互设计

### 展开/折叠动画
```swift
// 弹簧动画
withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
    isExpanded.wrappedValue.toggle()
}

// 箭头旋转
.rotationEffect(.degrees(isExpanded ? 0 : -90))

// 内容过渡
.transition(.opacity.combined(with: .move(edge: .top)))
```

### 按钮样式
| 类型 | 样式 |
|------|------|
| **主要按钮** | `.buttonStyle(.borderedProminent)`, tint(primaryColor) |
| **卡片触发器** | `.buttonStyle(.plain)`, 全区域点击 |
| **分享按钮** | 无边框，.secondary 前景色 |

### 加载状态
```swift
// 骨架屏式加载
ProgressView()
    .scaleEffect(0.7)  // 缩小进度环

// 加载文案
Text("正在分析...")
    .font(.caption)
    .foregroundStyle(.secondary)
```

### 错误提示
```swift
// 错误 Banner
- 背景：RoundedRectangle(cornerRadius: 12)
- 填充：.red.opacity(0.1)
- 图标：exclamationmark.triangle.fill, .red
- 文字：font(.caption)
```

---

## 📐 布局系统

### 首页网格布局
```
┌─────────────────────────────────────┐
│         Header (日期 + 问候)          │
├─────────────────────────────────────┤
│      Report Banner (全宽卡片)        │
├─────────────────────────────────────┤
│                                     │
│        Sleep Card (全宽)            │
│                                     │
├─────────────────────────────────────┤
│                                     │
│       Activity Card (全宽)          │
│                                     │
├───────────────┬─────────────────────┤
│               │                     │
│  Vitals Card  │    Body Card        │
│   (50% 宽)     │    (50% 宽)         │
│               │                     │
├───────────────┼─────────────────────┤
│               │                     │
│Nutrition Card │ Mindfulness Card    │
│   (50% 宽)     │    (50% 宽)         │
│               │                     │
└───────────────┴─────────────────────┘
```

### 边距系统
| 位置 | 数值 |
|------|------|
| 页面水平边距 | 20pt |
| 卡片间距 (垂直) | 14pt |
| 卡片间距 (水平) | 14pt |
| 顶部安全区后 | 8pt (header), 16pt (banner) |
| 底部留白 | 32pt |

### 报告页布局
```
┌─────────────────────────────────────┐
│ 标题 "健康报告"                      │
│ 日期 (右对齐分享按钮)                │
─────────────────────────────────────┤
│                                     │
│  [Generate Button - 空状态时显示]    │
│                                     │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ ○ 整体分析                    ▼│  │
│  │   睡眠与运动综合评估           │  │
│  ├───────────────────────────────┤  │
│  │                               │  │
│  │      (展开内容区)             │  │
│  │                               │  │
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  ───────────────────────────────┐  │
│  │ ○ 趋势洞察                    ▼│  │
│  │   30 天睡眠趋势 · 今日心率      │  │
│  ├───────────────────────────────┤  │
│  │  [睡眠趋势图表]                │  │
│  │  ───────────────────────────  │  │
│  │  [心率图表]                    │  │
│  │  ───────────────────────────  │  │
│  │  [AI 趋势解读]                 │  │
│  └───────────────────────────────┘  │
─────────────────────────────────────┘
```

---

## 🎯 响应式行为

### 下拉刷新
```swift
.refreshable {
    await healthKit.fetchTodayData()
}
```

### Sheet 弹窗
- 报告页以 Sheet 形式从底部弹出
- 包含自定义导航栏（关闭按钮）
- 自动根据内容滚动

### 条件渲染
- 空数据时显示占位符
- 加载中显示 ProgressView
- 错误时显示错误 Banner

---

## 💡 设计原则

1. **层次感**：通过阴影深度、圆角大小建立视觉层次
2. **一致性**：统一的圆角 (20pt)、间距系统
3. **呼吸感**：充足的留白，避免信息过载
4. **色彩语义**：功能色与内容强关联（睡眠=紫色，心率=红色）
5. **微交互**：弹簧动画、渐变过渡提升体验
6. **渐进披露**：可展开卡片减少初始认知负担

---

## 📁 文件结构

```
HealthInsight/
├── App/
│   ├── HealthInsightApp.swift      # 应用入口
│   └── ContentView.swift           # 主 Tab 结构
├── Models/
│   ├── HealthData.swift            # 健康数据模型
│   ├── HealthReport.swift          # 报告数据模型
│   └── APIModels.swift             # API 请求模型
├── Services/
│   ├── HealthKitManager.swift      # HealthKit 数据管理
│   ├── AIService.swift             # AI 服务
│   └── ReportGenerator.swift       # 报告生成器
├── Views/
│   ├── Home/
│   │   └── HomeView.swift          # 首页视图
│   ├── Report/
│   │   ├── ReportView.swift        # 报告生成页
│   │   ├── ReportHistoryView.swift # 历史报告列表
│   │   └── ReportDetailView.swift  # 报告详情页
│   └── Settings/
│       └── SettingsView.swift      # 设置页
├── Components/
│   ├── DataCard.swift              # 通用卡片组件
│   ├── StatusBadge.swift           # 状态徽章
│   ├── SleepStageItem.swift        # 睡眠阶段项
│   ├── MiniMetric.swift            # 迷你指标
│   ├── MarkdownView.swift          # Markdown 渲染
│   └── EmptyStateView.swift        # 空状态视图
└── Utilities/
    ├── Constants.swift             # 常量定义
    ├── DateFormatters.swift        # 日期格式化
    └── ReportParser.swift          # 报告解析工具
```

---

## 🚀 技术栈

- **UI 框架**: SwiftUI (iOS 17+)
- **状态管理**: @Observable macro
- **数据持久化**: SwiftData
- **健康数据**: HealthKit
- **AI 服务**: DashScope API (通义千问)
- **图表库**: Swift Charts
- **零第三方依赖**: 全部使用 Apple 原生框架

---

*最后更新：2026-03-31*
*版本：v1.0*
