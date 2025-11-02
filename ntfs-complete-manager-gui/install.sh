#!/bin/bash

# NTFS Complete Manager Installation Script
# Installs the NTFS Manager GUI with proper permissions and system integration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="NTFS Complete Manager"
APP_DIR="/opt/ntfs-manager"
DESKTOP_FILE="/usr/share/applications/ntfs-manager.desktop"
EXECUTABLE="/usr/local/bin/ntfs-manager"
LOG_DIR="/var/log/ntfs-manager"

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_dependencies() {
    print_status "Checking dependencies..."
    
    local missing_deps=()
    
    # Check Python 3
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    # Check GTK3
    if ! python3 -c "import gi; gi.require_version('Gtk', '3.0')" 2>/dev/null; then
        missing_deps+=("python3-gi")
    fi
    
    # Check system packages
    local sys_deps=("lsblk" "ntfs-3g" "ntfsprogs" "smartctl" "mount" "umount" "eject")
    for dep in "${sys_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_status "Install with: sudo apt install ${missing_deps[*]}"
        exit 1
    fi
    
    print_status "All dependencies found"
}

install_python_deps() {
    print_status "Installing Python dependencies..."
    
    if [[ -f "requirements.txt" ]]; then
        pip3 install -r requirements.txt
        print_status "Python dependencies installed"
    else
        print_warning "requirements.txt not found, skipping Python dependencies"
    fi
}

create_directories() {
    print_status "Creating directories..."
    
    # Create application directory
    mkdir -p "$APP_DIR"
    cp -r . "$APP_DIR/"
    chown -R root:root "$APP_DIR"
    chmod -R 755 "$APP_DIR"
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    chmod 755 "$LOG_DIR"
    
    # Create executable symlink
    ln -sf "$APP_DIR/main.py" "$EXECUTABLE"
    chmod 755 "$EXECUTABLE"
    
    print_status "Directories created and permissions set"
}

install_desktop_file() {
    print_status "Installing desktop entry..."
    
    # Update desktop file with correct paths
    sed "s|%K|$APP_DIR|g" ntfs-manager.desktop > /tmp/ntfs-manager.desktop
    
    # Install to system
    cp /tmp/ntfs-manager.desktop "$DESKTOP_FILE"
    chmod 644 "$DESKTOP_FILE"
    
    # Update desktop database
    update-desktop-database &> /dev/null || true
    
    print_status "Desktop entry installed"
}

install_system_integration() {
    print_status "Installing system integration..."
    
    # Create udev rules for drive monitoring (optional)
    if [[ -f "modules/08-drive-management/core/udev-monitor.sh" ]]; then
        print_status "Drive monitoring scripts found - can be installed separately"
    fi
    
    # Create systemd service for logging (optional)
    cat > /tmp/ntfs-manager-log.service << EOF
[Unit]
Description=NTFS Manager Log Cleanup
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/find $LOG_DIR -name "*.log.*" -mtime +30 -delete
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
    
    # Install log cleanup service
    cp /tmp/ntfs-manager-log.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable ntfs-manager-log.service &> /dev/null || true
    
    print_status "System integration installed"
}

create_launcher_script() {
    print_status "Creating launcher script..."
    
    cat > "$EXECUTABLE" << 'EOF'
#!/bin/bash
# NTFS Complete Manager Launcher
cd "$APP_DIR"
python3 main.py "$@"
EOF
    
    chmod 755 "$EXECUTABLE"
    print_status "Launcher script created"
}

test_installation() {
    print_status "Testing installation..."
    
    # Test executable
    if "$EXECUTABLE" --help &> /dev/null; then
        print_status "Installation test passed"
    else
        print_error "Installation test failed"
        return 1
    fi
}

show_post_install_info() {
    print_status "Installation completed successfully!"
    echo ""
    echo -e "${BLUE}=== Post-Installation Information ===${NC}"
    echo ""
    echo "Application installed to: $APP_DIR"
    echo "Executable: $EXECUTABLE"
    echo "Desktop entry: $DESKTOP_FILE"
    echo "Log directory: $LOG_DIR"
    echo ""
    echo -e "${GREEN}Usage:${NC}"
    echo "  Run from terminal: $EXECUTABLE"
    echo "  Run from applications menu: NTFS Complete Manager"
    echo ""
    echo -e "${YELLOW}Note:${NC} You may need to log out and log back in to see the application in your menu."
    echo ""
    echo -e "${BLUE}=== Optional Components ===${NC}"
    echo ""
    echo "For enhanced functionality, consider installing:"
    echo "  • GParted: sudo apt install gparted"
    echo "  • HDDtemp: sudo apt install hddtemp"
    echo "  • Drive monitoring scripts: modules/08-drive-management/core/udev-monitor.sh"
    echo ""
}

uninstall() {
    print_status "Uninstalling NTFS Complete Manager..."
    
    # Remove application files
    if [[ -d "$APP_DIR" ]]; then
        rm -rf "$APP_DIR"
        print_status "Application files removed"
    fi
    
    # Remove executable
    if [[ -f "$EXECUTABLE" ]]; then
        rm -f "$EXECUTABLE"
        print_status "Executable removed"
    fi
    
    # Remove desktop entry
    if [[ -f "$DESKTOP_FILE" ]]; then
        rm -f "$DESKTOP_FILE"
        print_status "Desktop entry removed"
    fi
    
    # Remove systemd service
    if [[ -f "/etc/systemd/system/ntfs-manager-log.service" ]]; then
        systemctl disable ntfs-manager-log.service &> /dev/null || true
        rm -f /etc/systemd/system/ntfs-manager-log.service
        systemctl daemon-reload
        print_status "System service removed"
    fi
    
    # Ask about log directory
    echo -e "${YELLOW}Keep log directory $LOG_DIR? (y/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        rm -rf "$LOG_DIR"
        print_status "Log directory removed"
    else
        print_status "Log directory preserved"
    fi
    
    print_status "Uninstallation completed"
}

# Main installation logic
main() {
    echo -e "${BLUE}=== NTFS Complete Manager Installation ===${NC}"
    echo ""
    
    check_root
    
    case "${1:-install}" in
        "install")
            check_dependencies
            install_python_deps
            create_directories
            create_launcher_script
            install_desktop_file
            install_system_integration
            test_installation
            show_post_install_info
            ;;
        "uninstall")
            uninstall
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [install|uninstall|help]"
            echo ""
            echo "Commands:"
            echo "  install    - Install NTFS Complete Manager (default)"
            echo "  uninstall  - Remove NTFS Complete Manager"
            echo "  help       - Show this help message"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
