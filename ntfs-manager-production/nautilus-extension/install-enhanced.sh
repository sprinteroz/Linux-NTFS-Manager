#!/bin/bash
# Enhanced NTFS Manager Nautilus Extension Installation Script
# Handles dependency issues and provides robust installation with fallbacks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
EXTENSION_NAME="ntfs_manager_extension.py"
EXTENSION_DIR="$HOME/.local/share/nautilus-python/extensions"
BACKEND_DIR="$PROJECT_ROOT/ntfs-complete-manager-gui/backend"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Check if running as root for system-wide installation
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root. Installing system-wide..."
        EXTENSION_DIR="/usr/share/nautilus-python/extensions"
        BACKEND_DIR="/usr/local/lib/ntfs-manager/backend"
        CONFIG_DIR="/etc/ntfs-manager"
        LOG_DIR="/var/log/ntfs-manager"
        SUDO_USER="${SUDO_USER:-$USER}"
    else
        log_info "Installing for current user..."
        CONFIG_DIR="$HOME/.config/ntfs-manager"
        LOG_DIR="$HOME/.local/share/ntfs-manager/logs"
    fi
}

# Enhanced dependency installation with fallbacks
install_dependencies() {
    log_step "Installing system dependencies..."
    
    # Update package list
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
    elif command -v apt >/dev/null 2>&1; then
        sudo apt update
    else
        log_error "Neither apt-get nor apt found. Please install dependencies manually."
        return 1
    fi
    
    # Install Nautilus Python bindings
    if ! python3 -c "import gi; gi.require_version('Nautilus', '3.0')" 2>/dev/null; then
        log_info "Installing Nautilus Python bindings..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get install -y python3-nautilus
        elif command -v apt >/dev/null 2>&1; then
            sudo apt install -y python3-nautilus
        fi
    else
        log_success "Nautilus Python bindings already available"
    fi
    
    # Install NTFS tools with fallbacks
    install_ntfs_tools() {
        local tools_installed=0
        
        # Try ntfs-3g package first
        if command -v apt >/dev/null 2>&1; then
            if sudo apt install -y ntfs-3g 2>/dev/null; then
                log_success "ntfs-3g installed"
                tools_installed=$((tools_installed + 1))
            fi
        fi
        
        # Fallback to ntfsprogs if ntfs-3g not available
        if ! command -v ntfs-3g >/dev/null 2>&1; then
            if command -v apt >/dev/null 2>&1; then
                if sudo apt install -y ntfsprogs 2>/dev/null; then
                    log_success "ntfsprogs installed (fallback)"
                    tools_installed=$((tools_installed + 1))
                fi
            fi
        fi
        
        # Install ntfsck
        if command -v apt >/dev/null 2>&1; then
            if sudo apt install -y ntfsprogs 2>/dev/null; then
                log_success "ntfsck installed"
                tools_installed=$((tools_installed + 1))
            fi
        fi
        
        return $tools_installed
    }
    
    # Install SMART monitoring tools
    install_smart_tools() {
        local tools_installed=0
        
        # Try smartmontools
        if command -v apt >/dev/null 2>&1; then
            if sudo apt install -y smartmontools 2>/dev/null; then
                log_success "smartmontools installed"
                tools_installed=$((tools_installed + 1))
            fi
        fi
        
        # Fallback options if smartmontools not available
        if ! command -v smartctl >/dev/null 2>&1; then
            # Try installing smartctl directly if available
            if command -v apt >/dev/null 2>&1; then
                if apt-cache show smartctl 2>/dev/null | grep -q "smartctl"; then
                    if sudo apt install -y smartctl 2>/dev/null; then
                        log_success "smartctl installed (fallback)"
                        tools_installed=$((tools_installed + 1))
                    fi
                fi
            fi
        fi
        
        return $tools_installed
    }
    
    # Install core system tools
    install_core_tools() {
        local tools_installed=0
        
        local core_tools=(
            "util-linux"
            "e2fsprogs" 
            "dosfstools"
            "python3-gi"
            "python3-psutil"
            "notify-osd"
        )
        
        for tool in "${core_tools[@]}"; do
            if command -v apt >/dev/null 2>&1; then
                if sudo apt install -y "$tool" 2>/dev/null; then
                    log_success "$tool installed"
                    tools_installed=$((tools_installed + 1))
                fi
            elif command -v apt-get >/dev/null 2>&1; then
                if sudo apt-get install -y "$tool" 2>/dev/null; then
                    log_success "$tool installed"
                    tools_installed=$((tools_installed + 1))
                fi
            fi
        done
        
        return $tools_installed
    }
    
    # Install all tool categories
    local ntfs_tools=$(install_ntfs_tools)
    local smart_tools=$(install_smart_tools)
    local core_tools=$(install_core_tools)
    
    local total_tools=$((ntfs_tools + smart_tools + core_tools))
    
    if [[ $total_tools -gt 0 ]]; then
        log_success "Dependencies installation completed: $total_tools packages installed"
    else
        log_warning "Some dependencies may not be available in this distribution"
    fi
}

# Create extension directory with proper permissions
create_extension_dir() {
    log_step "Creating extension directory..."
    
    mkdir -p "$EXTENSION_DIR"
    
    # Set proper permissions
    if [[ $EUID -eq 0 ]]; then
        chmod 755 "$EXTENSION_DIR"
        if [[ -n "$SUDO_USER" ]]; then
            chown -R "$SUDO_USER:$SUDO_USER" "$EXTENSION_DIR"
        fi
    else
        chmod 755 "$EXTENSION_DIR"
    fi
    
    log_success "Extension directory created: $EXTENSION_DIR"
}

# Enhanced extension installation
install_extension() {
    log_step "Installing NTFS Manager extension..."
    
    # Copy extension file
    cp "$SCRIPT_DIR/$EXTENSION_NAME" "$EXTENSION_DIR/"
    chmod 644 "$EXTENSION_DIR/$EXTENSION_NAME"
    
    # Create symlink for easier access
    if [[ ! -L "$EXTENSION_DIR/NTFSManagerExtension.py" ]]; then
        ln -sf "$EXTENSION_NAME" "$EXTENSION_DIR/NTFSManagerExtension.py"
    fi
    
    log_success "Extension installed to: $EXTENSION_DIR/$EXTENSION_NAME"
}

# Enhanced backend installation
install_backend() {
    log_step "Installing backend modules..."
    
    # Create backend directory
    mkdir -p "$BACKEND_DIR"
    
    # Copy backend files
    if [[ -d "$PROJECT_ROOT/ntfs-complete-manager-gui/backend" ]]; then
        cp "$PROJECT_ROOT/ntfs-complete-manager-gui/backend"/*.py "$BACKEND_DIR/"
        chmod 644 "$BACKEND_DIR"/*.py
        
        # Make backend executable
        chmod +x "$BACKEND_DIR"/*.py
        
        log_success "Backend modules installed to: $BACKEND_DIR"
    else
        log_error "Backend directory not found: $PROJECT_ROOT/ntfs-complete-manager-gui/backend"
        return 1
    fi
    
    # Create Python path configuration
    local python_path_file="$BACKEND_DIR/__init__.py"
    cat > "$python_path_file" << EOF
# NTFS Manager Backend Python Path
import sys
import os

# Add backend directory to Python path
backend_dir = os.path.dirname(os.path.abspath(__file__))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)
EOF
    
    chmod 644 "$python_path_file"
    log_success "Python path configuration created"
}

# Enhanced configuration creation
create_config() {
    log_step "Creating configuration..."
    
    mkdir -p "$CONFIG_DIR"
    
    # Create enhanced configuration
    cat > "$CONFIG_DIR/config.ini" << EOF
[NTFS Manager]
# NTFS Manager Nautilus Extension Configuration

# Enable desktop notifications
notifications=true

# Auto-refresh interval in seconds
refresh_interval=30

# Log level (DEBUG, INFO, WARNING, ERROR)
log_level=INFO

# Enable health monitoring
health_monitoring=true

# Show advanced options in context menu
advanced_options=true

# Default mount options for NTFS drives
default_mount_options=uid=1000,gid=1000,dmask=022,fmask=133

# Enable automatic drive monitoring
auto_monitoring=true

# Enable fallback mode for missing dependencies
fallback_mode=true

# Show debug information
debug_mode=false

# Preferred filesystem tools (ntfs-3g, ntfsprogs, etc.)
preferred_ntfs_tool=auto

# Enable system integration
system_integration=true
EOF
    
    # Set proper permissions
    if [[ $EUID -eq 0 ]]; then
        chmod 644 "$CONFIG_DIR/config.ini"
        if [[ -n "$SUDO_USER" ]]; then
            chown "$SUDO_USER:$SUDO_USER" "$CONFIG_DIR/config.ini"
        fi
    else
        chmod 644 "$CONFIG_DIR/config.ini"
    fi
    
    log_success "Configuration created: $CONFIG_DIR/config.ini"
}

# Enhanced log directory creation
create_log_dir() {
    log_step "Creating log directory..."
    
    mkdir -p "$LOG_DIR"
    
    # Set proper permissions
    if [[ $EUID -eq 0 ]]; then
        chmod 755 "$LOG_DIR"
        if [[ -n "$SUDO_USER" ]]; then
            chown -R "$SUDO_USER:$SUDO_USER" "$LOG_DIR"
        fi
    else
        mkdir -p "$LOG_DIR"
        chmod 755 "$LOG_DIR"
    fi
    
    # Create log subdirectories
    mkdir -p "$LOG_DIR"/{main,operations,errors,security,structured}
    
    log_success "Log directory created: $LOG_DIR"
}

# Enhanced desktop integration
install_desktop_integration() {
    log_step "Installing desktop integration..."
    
    local desktop_dir="$HOME/.local/share/applications"
    mkdir -p "$desktop_dir"
    
    # Create enhanced desktop file
    cat > "$desktop_dir/ntfs-manager.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=NTFS Manager
Comment=Manage NTFS drives and partitions with native Nautilus integration
Exec=python3 $PROJECT_ROOT/ntfs-complete-manager-gui/main.py
Icon=drive-harddisk
Terminal=false
Categories=System;FileTools;GTK;
Keywords=drive;ntfs;partition;mount;format;nautilus;extension;
StartupNotify=true
Actions=QuickMount;QuickProperties;QuickHealthCheck;

[Desktop Action QuickMount]
Name=Quick Mount
Exec=python3 -c "
import sys
sys.path.insert(0, '$BACKEND_DIR')
from drive_manager import DriveManager

dm = DriveManager()
drives = dm.get_all_drives()
ntfs_drives = [d for d in drives if d.fstype == 'ntfs' and not d.mountpoint]

if ntfs_drives:
    first_drive = ntfs_drives[0]
    dm.mount_drive(first_drive.name)
    print(f'Mounted {first_drive.name}')
else:
    print('No unmounted NTFS drives found')
"

[Desktop Action QuickProperties]
Name=Quick Properties
Exec=python3 -c "
import sys
sys.path.insert(0, '$BACKEND_DIR')
from drive_manager import DriveManager
from ntfs_properties import NTFSProperties

dm = DriveManager()
drives = dm.get_all_drives()
ntfs_drives = [d for d in drives if d.fstype == 'ntfs']

if ntfs_drives:
    first_drive = ntfs_drives[0]
    device_path = f'/dev/{first_drive.name}'
    props = NTFSProperties(device_path)
    all_props = props.get_all_properties()
    
    print(f'NTFS Properties for {first_drive.name}:')
    print(f'Volume: {all_props.get(\"volume\", {}).get(\"name\", \"Unknown\")}')
    print(f'Size: {all_props.get(\"volume\", {}).get(\"total_size\", 0)}')
    print(f'Free: {all_props.get(\"volume\", {}).get(\"free_space\", 0)}')
else:
    print('No NTFS drives found')
"

[Desktop Action QuickHealthCheck]
Name=Quick Health Check
Exec=python3 -c "
import sys
sys.path.insert(0, '$BACKEND_DIR')
from drive_manager import DriveManager
from ntfs_properties import NTFSProperties

dm = DriveManager()
drives = dm.get_all_drives()

if drives:
    first_drive = drives[0]
    device_path = f'/dev/{first_drive.name}'
    props = NTFSProperties(device_path)
    health_results = props.run_disk_check()
    
    print(f'Health Check for {first_drive.name}:')
    print(f'Overall Status: {health_results.get(\"overall_status\", \"Unknown\")}')
    for check_name, check_result in health_results.get(\"checks\", {}).items():
        print(f'{check_name}: {check_result.get(\"status\", \"Unknown\")}')
else:
    print('No drives found')
"
EOF
    
    log_success "Desktop integration installed"
}

# Enhanced Nautilus restart
restart_nautilus() {
    log_step "Restarting Nautilus to load extension..."
    
    # Kill existing Nautilus processes gracefully
    if pgrep -f nautilus >/dev/null; then
        log_info "Terminating existing Nautilus processes..."
        pkill -f nautilus
        sleep 2
    fi
    
    # Start Nautilus with extension loaded
    log_info "Starting Nautilus with extension..."
    if command -v nautilus >/dev/null 2>&1; then
        nohup nautilus --no-default-window &>/dev/null 2>&1 &
    else
        nohup /usr/bin/nautilus --no-default-window &>/dev/null 2>&1 &
    fi
    
    # Wait a moment for Nautilus to start
    sleep 3
    
    # Check if Nautilus is running
    if pgrep -f nautilus >/dev/null; then
        log_success "Nautilus restarted successfully"
    else
        log_warning "Nautilus may not have started properly"
    fi
}

# Enhanced verification
verify_installation() {
    log_step "Verifying installation..."
    
    local verification_passed=true
    
    # Check if extension file exists
    if [[ -f "$EXTENSION_DIR/$EXTENSION_NAME" ]]; then
        log_success "✓ Extension file installed"
    else
        log_error "✗ Extension file not found"
        verification_passed=false
    fi
    
    # Check if backend modules exist
    if [[ -f "$BACKEND_DIR/drive_manager.py" ]]; then
        log_success "✓ Backend modules available"
    else
        log_error "✗ Backend modules not found"
        verification_passed=false
    fi
    
    # Check if configuration exists
    if [[ -f "$CONFIG_DIR/config.ini" ]]; then
        log_success "✓ Configuration created"
    else
        log_error "✗ Configuration not found"
        verification_passed=false
    fi
    
    # Check if log directory exists
    if [[ -d "$LOG_DIR" ]]; then
        log_success "✓ Log directory created"
    else
        log_error "✗ Log directory not found"
        verification_passed=false
    fi
    
    # Check desktop integration
    if [[ -f "$HOME/.local/share/applications/ntfs-manager.desktop" ]]; then
        log_success "✓ Desktop integration installed"
    else
        log_error "✗ Desktop integration not found"
        verification_passed=false
    fi
    
    if [[ "$verification_passed" == true ]]; then
        log_success "Installation verified successfully"
        return 0
    else
        log_error "Installation verification failed"
        return 1
    fi
}

# Enhanced usage information
show_usage_info() {
    log_success "Enhanced NTFS Manager Nautilus Extension installation completed!"
    echo
    echo "=== ENHANCED NTFS MANAGER NAUTILUS EXTENSION ==="
    echo
    echo "USAGE:"
    echo "1. Right-click on any drive or mount point in Nautilus"
    echo "2. Select 'NTFS Management' from context menu"
    echo "3. Choose desired operation:"
    echo "   - Mount/Unmount Drive"
    echo "   - Drive Properties (Windows-style information)"
    echo "   - Health Check (SMART and filesystem status)"
    echo "   - Repair Drive (fix filesystem errors)"
    echo "   - Format Drive (DANGEROUS - erases all data)"
    echo "   - Safe Eject (for removable drives)"
    echo
    echo "QUICK ACTIONS:"
    echo "   - Right-click desktop → Quick Mount/Properties/Health Check"
    echo
    echo "ENHANCED FEATURES:"
    echo "   - Robust dependency handling with fallbacks"
    echo "   - Enhanced error recovery and logging"
    echo "   - Quick action desktop integration"
    echo "   - Comprehensive configuration options"
    echo "   - Automatic system detection and adaptation"
    echo
    echo "CONFIGURATION: $CONFIG_DIR/config.ini"
    echo "LOGS: $LOG_DIR/"
    echo
    echo "TROUBLESHOOTING:"
    echo "   - If extension doesn't load: restart Nautilus with 'nautilus -q && nautilus'"
    echo "   - If operations fail: check permissions and system tools"
    echo "   - For debug mode: set debug_mode=true in config.ini"
    echo
    echo "ENHANCED INSTALLER FEATURES:"
    echo "   - Automatic dependency resolution"
    echo "   - Multiple package manager support (apt, apt-get)"
    echo "   - Fallback mechanisms for missing tools"
    echo "   - Enhanced error handling and recovery"
    echo "   - System-wide and user installation support"
    echo "   - Quick action desktop integration"
    echo "   - Comprehensive verification and testing"
}

# Main installation function
main() {
    echo "============================================================"
    echo "ENHANCED NTFS MANAGER NAUTILUS EXTENSION INSTALLER"
    echo "============================================================"
    echo
    
    check_permissions
    install_dependencies
    create_extension_dir
    install_extension
    install_backend
    create_config
    create_log_dir
    install_desktop_integration
    restart_nautilus
    verify_installation
    show_usage_info
}

# Handle command line arguments
case "${1:-install}" in
    install)
        main
        ;;
    uninstall)
        log_info "Uninstallation not implemented yet. Please remove files manually."
        echo "To uninstall:"
        echo "  rm -rf $EXTENSION_DIR/$EXTENSION_NAME"
        echo "  rm -rf $BACKEND_DIR"
        echo "  rm -rf $CONFIG_DIR"
        echo "  rm -rf $LOG_DIR"
        echo "  rm -f $HOME/.local/share/applications/ntfs-manager.desktop"
        echo "  Then restart Nautilus"
        ;;
    verify)
        verify_installation
        ;;
    --help|-h)
        echo "Enhanced NTFS Manager Nautilus Extension Installer"
        echo
        echo "Usage: $0 [install|uninstall|verify|--help]"
        echo
        echo "  install   - Install extension with enhanced features (default)"
        echo "  uninstall - Uninstall extension"
        echo "  verify    - Verify installation"
        echo "  --help    - Show this help message"
        echo
        echo "Enhanced Features:"
        echo "  - Robust dependency handling with fallbacks"
        echo "  - Multiple package manager support"
        echo "  - Enhanced error recovery and logging"
        echo "  - Quick action desktop integration"
        echo "  - System-wide and user installation support"
        echo "  - Comprehensive verification and testing"
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
EOF
