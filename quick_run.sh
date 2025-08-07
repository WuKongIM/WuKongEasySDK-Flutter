#!/bin/bash

# Quick Flutter Example Runner
# Simple script to run the WuKong Easy SDK example with device selection

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE} WuKong Easy SDK - Quick Run${NC}"
    echo -e "${BLUE}================================================${NC}\n"
}

# Quick device selection menu
show_device_menu() {
    echo "请选择运行设备 / Please select a device:"
    echo ""
    echo "  1. 🖥️  macOS Desktop (推荐用于开发测试)"
    echo "  2. 🌐 Chrome Browser (Web版本)"
    echo "  3. 📱 iOS Simulator (需要Xcode)"
    echo "  4. 📲 Physical iOS Device (物理设备)"
    echo "  5. 🤖 Auto Select (自动选择)"
    echo ""
    read -p "请输入选项 (1-5) / Enter option (1-5): " -n 1 -r
    echo ""
    
    case $REPLY in
        1)
            DEVICE="macos"
            print_success "选择: macOS Desktop"
            ;;
        2)
            DEVICE="chrome"
            print_success "选择: Chrome Browser"
            ;;
        3)
            DEVICE="ios"
            print_success "选择: iOS Simulator"
            ;;
        4)
            DEVICE=""
            print_success "选择: Physical iOS Device (自动检测)"
            ;;
        5)
            DEVICE=""
            print_success "选择: Auto Select"
            ;;
        *)
            print_error "无效选择，使用自动选择"
            DEVICE=""
            ;;
    esac
}

# Run the application
run_app() {
    print_status "正在启动应用程序..."
    
    # Navigate to example directory
    if [ ! -d "example" ]; then
        print_error "找不到 example 目录"
        print_error "请确保在 WuKong Easy SDK 根目录运行此脚本"
        exit 1
    fi
    
    cd example
    
    # Install dependencies if needed
    if [ ! -d ".dart_tool" ]; then
        print_status "正在安装依赖..."
        flutter pub get
    fi
    
    # Build run command
    if [ -n "$DEVICE" ]; then
        CMD="flutter run -d $DEVICE"
    else
        CMD="flutter run"
    fi
    
    print_status "执行命令: $CMD"
    print_status "按 Ctrl+C 停止应用程序"
    echo ""
    
    # Run the app
    if $CMD; then
        print_success "应用程序启动成功!"
    else
        print_error "应用程序启动失败"
        echo ""
        print_status "故障排除建议:"
        echo "  1. 检查设备连接状态: flutter devices"
        echo "  2. 尝试其他设备: flutter run -d chrome"
        echo "  3. 清理项目: flutter clean && flutter pub get"
        echo "  4. 检查Flutter环境: flutter doctor"
        echo ""
        
        # Offer Chrome fallback
        read -p "是否尝试在Chrome中运行? Try Chrome? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "正在Chrome中启动..."
            flutter run -d chrome
        fi
    fi
}

# Main execution
main() {
    print_header
    
    # Check if Flutter is available
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter 未安装或不在 PATH 中"
        print_error "请安装 Flutter: https://flutter.dev/docs/get-started/install"
        exit 1
    fi
    
    # Show device menu
    show_device_menu
    
    echo ""
    print_status "准备启动 WuKong Easy SDK 测试应用程序"
    read -p "按 Enter 继续 / Press Enter to continue..."
    
    # Run the app
    run_app
}

# Handle interruption
trap 'echo -e "\n${YELLOW}[WARNING]${NC} 用户中断 / User interrupted"; exit 130' INT

# Run main function
main "$@"
