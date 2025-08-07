#!/bin/bash

# WuKong Easy SDK Flutter Example Runner
# This script sets up and runs the Flutter example application

set -e  # Exit on any error

# Global variable to store selected device
SELECTED_DEVICE=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE} WuKong Easy SDK Flutter Example Runner${NC}"
    echo -e "${BLUE}================================================${NC}\n"
}

# Function to check if Flutter is installed
check_flutter() {
    print_status "Checking Flutter installation..."
    
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        print_error "Please install Flutter from: https://flutter.dev/docs/get-started/install"
        exit 1
    fi
    
    # Check Flutter version
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    print_success "Flutter found: $FLUTTER_VERSION"
    
    # Run flutter doctor to check setup
    print_status "Running Flutter doctor to check setup..."
    flutter doctor --android-licenses > /dev/null 2>&1 || true
    flutter doctor
}

# Function to check project structure
check_project_structure() {
    print_status "Checking project structure..."
    
    if [ ! -f "pubspec.yaml" ]; then
        print_error "pubspec.yaml not found in current directory"
        print_error "Please run this script from the WuKong Easy SDK root directory"
        exit 1
    fi
    
    if [ ! -d "example" ]; then
        print_error "Example directory not found"
        print_error "Please ensure the example directory exists"
        exit 1
    fi
    
    if [ ! -f "example/pubspec.yaml" ]; then
        print_error "Example pubspec.yaml not found"
        print_error "Please ensure the example project is properly set up"
        exit 1
    fi
    
    print_success "Project structure verified"
}

# Function to install dependencies for main package
install_main_dependencies() {
    print_status "Installing dependencies for main WuKong Easy SDK package..."
    
    if flutter pub get; then
        print_success "Main package dependencies installed successfully"
    else
        print_error "Failed to install main package dependencies"
        exit 1
    fi
}

# Function to install dependencies for example
install_example_dependencies() {
    print_status "Navigating to example directory..."
    cd example
    
    print_status "Installing dependencies for example application..."
    
    if flutter pub get; then
        print_success "Example dependencies installed successfully"
    else
        print_error "Failed to install example dependencies"
        exit 1
    fi
}

# Function to check for available devices and let user choose
check_devices() {
    print_status "Checking for available devices..."

    # Get device list and show to user
    print_status "Available devices:"
    flutter devices

    echo ""
    print_status "Device Selection Options:"
    echo "  1. 📱 iOS Simulator (recommended for testing)"
    echo "  2. 🖥️  macOS Desktop (native macOS app)"
    echo "  3. 🌐 Chrome Web Browser (web app)"
    echo "  4. 📲 Physical iOS Device (if connected)"
    echo "  5. 🤖 Let Flutter choose automatically"
    echo ""

    read -p "Please select an option (1-5): " -n 1 -r
    echo ""

    case $REPLY in
        1)
            SELECTED_DEVICE="ios"
            print_success "Selected: iOS Simulator"
            ;;
        2)
            SELECTED_DEVICE="macos"
            print_success "Selected: macOS Desktop"
            ;;
        3)
            SELECTED_DEVICE="chrome"
            print_success "Selected: Chrome Web Browser"
            ;;
        4)
            # Try to find a physical iOS device
            IOS_DEVICE=$(flutter devices | grep "ios" | grep -v "simulator" | head -n 1 | awk '{print $NF}' | tr -d '()')
            if [ -n "$IOS_DEVICE" ]; then
                SELECTED_DEVICE="$IOS_DEVICE"
                print_success "Selected: Physical iOS Device ($IOS_DEVICE)"
            else
                print_warning "No physical iOS device found. Falling back to iOS Simulator."
                SELECTED_DEVICE="ios"
            fi
            ;;
        5)
            SELECTED_DEVICE=""
            print_success "Selected: Automatic device selection"
            ;;
        *)
            print_warning "Invalid selection. Using automatic device selection."
            SELECTED_DEVICE=""
            ;;
    esac
}

# Function to run the Flutter application
run_flutter_app() {
    print_status "Starting Flutter application..."
    print_status "This will launch the WuKong Easy SDK Test Example"
    print_status "Press Ctrl+C to stop the application"
    echo ""

    # Build the flutter run command based on device selection
    if [ -n "$SELECTED_DEVICE" ]; then
        FLUTTER_CMD="flutter run --hot -d $SELECTED_DEVICE"
        print_status "Running: $FLUTTER_CMD"
    else
        FLUTTER_CMD="flutter run --hot"
        print_status "Running: $FLUTTER_CMD (automatic device selection)"
    fi

    # Try to run the application
    if $FLUTTER_CMD; then
        print_success "Application started successfully"
    else
        print_error "Failed to start Flutter application"
        print_error ""
        print_error "Common issues and solutions:"
        print_error "  1. 📱 iOS Device Issues:"
        print_error "     - Ensure device is unlocked and trusted"
        print_error "     - Check Developer settings are enabled"
        print_error "     - Try: flutter run -d ios (for simulator)"
        print_error ""
        print_error "  2. 🌐 Network Issues (wireless devices):"
        print_error "     - Ensure Mac and device are on same WiFi"
        print_error "     - Try USB connection instead"
        print_error "     - Try: flutter run -d chrome (for web testing)"
        print_error ""
        print_error "  3. 🖥️  Alternative Options:"
        print_error "     - macOS Desktop: flutter run -d macos"
        print_error "     - Web Browser: flutter run -d chrome"
        print_error "     - iOS Simulator: flutter run -d ios"
        print_error ""
        print_status "You can also run the app manually with:"
        print_status "  cd example && flutter run -d <device-id>"

        # Offer to try alternative devices
        echo ""
        read -p "Would you like to try running on Chrome (web) instead? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Trying Chrome web browser..."
            if flutter run --hot -d chrome; then
                print_success "Application started successfully on Chrome"
            else
                print_error "Failed to start on Chrome as well"
                exit 1
            fi
        else
            exit 1
        fi
    fi
}

# Function to provide usage instructions
show_usage_instructions() {
    echo ""
    print_success "Flutter Example Application Setup Complete!"
    echo ""
    print_status "The WuKong Easy SDK Test Example should now be running."
    print_status "You can test the following features:"
    echo ""
    echo "  1. Connection Settings:"
    echo "     - Server URL: ws://your-wukongim-server.com:5200"
    echo "     - User ID: Your unique user identifier"
    echo "     - Token: Your authentication token"
    echo ""
    echo "  2. Message Sending:"
    echo "     - Target User ID: ID of the user to send messages to"
    echo "     - Message JSON: Custom message payload"
    echo ""
    echo "  3. Real-time Logs:"
    echo "     - View connection events, message events, and errors"
    echo "     - Clear logs as needed"
    echo ""
    print_warning "Note: You'll need a running WuKongIM server to test full functionality"
    print_status "For development, you can use the default settings and observe connection attempts"
}

# Main execution
main() {
    print_header
    
    # Check prerequisites
    check_flutter
    check_project_structure
    
    # Install dependencies
    install_main_dependencies
    install_example_dependencies
    
    # Check devices
    check_devices
    
    # Show usage instructions before running
    show_usage_instructions
    
    echo ""
    read -p "Press Enter to start the Flutter application..."
    
    # Run the application
    run_flutter_app
}

# Handle script interruption
trap 'print_warning "\nScript interrupted by user"; exit 130' INT

# Run main function
main "$@"
