#!/bin/bash
# HealthInsight 项目生成脚本
# 安装好 Xcode 后运行此脚本即可生成 .xcodeproj 项目文件

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "================================================"
echo "  HealthInsight (健康洞察) 项目生成器"
echo "================================================"
echo ""

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "[错误] 未检测到 Xcode，请先从 Mac App Store 安装 Xcode。"
    exit 1
fi

echo "[1/3] 检查 Xcode..."
xcodebuild -version
echo ""

# Install xcodegen if needed
if ! command -v xcodegen &> /dev/null; then
    echo "[2/3] 安装 XcodeGen (项目生成工具)..."
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo "[错误] 需要 Homebrew 来安装 XcodeGen。"
        echo "请先安装 Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
else
    echo "[2/3] XcodeGen 已安装。"
fi
echo ""

# Generate Xcode project
echo "[3/3] 生成 Xcode 项目..."
xcodegen generate
echo ""

echo "================================================"
echo "  项目生成完成！"
echo "================================================"
echo ""
echo "接下来请执行以下步骤："
echo ""
echo "  1. 双击打开: HealthInsight.xcodeproj"
echo ""
echo "  2. 在 Xcode 中配置签名:"
echo "     - 点击左侧 HealthInsight 项目"
echo "     - 选择 Signing & Capabilities 标签"
echo "     - 勾选 Automatically manage signing"
echo "     - Team 选择你的 Apple ID (Personal Team)"
echo ""
echo "  3. 连接 iPhone，选择你的手机作为运行目标"
echo ""
echo "  4. 点击 ▶️ 运行按钮 (或按 Cmd+R)"
echo ""
echo "  5. iPhone 上首次运行需要信任开发者:"
echo "     设置 > 通用 > VPN与设备管理 > 信任开发者证书"
echo ""
echo "  6. 打开 App，在「设置」中填写通义千问 API Key"
echo ""
echo "祝你使用愉快！🎉"
