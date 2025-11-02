#!/bin/bash
# NTFS Manager Nautilus Extension Installation Script
# Installs the Nautilus extension and all dependencies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if running as root for system-wide installation
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root. Installing system-wide..."
        EXTENSION_DIR="/usr/share/nautilus-python/extensions"
        BACKEND_DIR="/usr/local/lib/ntfs-manager/backend"
    else
        log_info "Installing for current user..."
    fi
}

# Install system dependencies
install_dependencies() {
    log_info "Installing system dependencies..."
    
    # Update package list
    sudo apt update
    
    # Install Nautilus Python bindings
    if ! dpkg -l | grep -q python3-nautilus; then
        log_info "Installing Nautilus Python bindings..."
        sudo apt install -y python3-nautilus
    else
        log_info "Nautilus Python bindings already installed"
    fi
    
    # Install required system tools
    log_info "Installing required system tools..."
    sudo apt install -y \
        ntfs-3g \
        ntfsprogs \
        smartmontools \
        util-linux \
        e2fsprogs \
        dosfstools \
        hddtemp \
        notify-osd \
        python3-gi \
        python3-psutil
    
    log_success "Dependencies installed successfully"
}

# Create extension directory
create_extension_dir() {
    log_info "Creating extension directory..."
    mkdir -p "$EXTENSION_DIR"
    log_success "Extension directory created: $EXTENSION_DIR"
}

# Install the extension
install_extension() {
    log_info "Installing NTFS Manager extension..."
    
    # Copy extension file
    cp "$SCRIPT_DIR/$EXTENSION_NAME" "$EXTENSION_DIR/"
    chmod 644 "$EXTENSION_DIR/$EXTENSION_NAME"
    
    log_success "Extension installed to: $EXTENSION_DIR/$EXTENSION_NAME"
}

# Install backend modules
install_backend() {
    log_info "Installing backend modules..."
    
    # Create backend directory
    mkdir -p "$BACKEND_DIR"
    
    # Copy backend files
    cp "$PROJECT_ROOT/ntfs-complete-manager-gui/backend"/*.py "$BACKEND_DIR/"
    chmod 644 "$BACKEND_DIR"/*.py
    
    # Make backend executable
    chmod +x "$BACKEND_DIR"/*.py
    
    log_success "Backend modules installed to: $BACKEND_DIR"
}

# Create configuration
create_config() {
    log_info "Creating configuration..."
    
    CONFIG_DIR="$HOME/.config/ntfs-manager"
    mkdir -p "$CONFIG_DIR"
    
    # Create default configuration
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
EOF
    
    log_success "Configuration created: $CONFIG_DIR/config.ini"
}

# Create log directory
create_log_dir() {
    log_info "Creating log directory..."
    
    LOG_DIR="/var/log/ntfs-manager"
    
    # Create log directory
    if [[ $EUID -eq 0 ]]; then
        mkdir -p "$LOG_DIR"
        chmod 755 "$LOG_DIR"
        
        # Set ownership for user access
        if [[ -n "$SUDO_USER" ]]; then
            chown "$SUDO_USER:$SUDO_USER" "$LOG_DIR"
        fi
    else
        mkdir -p "$HOME/.local/share/ntfs-manager/logs"
        LOG_DIR="$HOME/.local/share/ntfs-manager/logs"
    fi
    
    log_success "Log directory created: $LOG_DIR"
}

# Install desktop integration
install_desktop_integration() {
    log_info "Installing desktop integration..."
    
    # Create desktop file for standalone application
    DESKTOP_DIR="$HOME/.local/share/applications"
    mkdir -p "$DESKTOP_DIR"
    
    cat > "$DESKTOP_DIR/ntfs-manager.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=NTFS Manager
Comment=Manage NTFS drives and partitions
Exec=python3 $PROJECT_ROOT/ntfs-complete-manager-gui/main.py
Icon=drive-harddisk
Terminal=false
Categories=System;FileTools;GTK;
Keywords=drive;ntfs;partition;mount;format;
StartupNotify=true
EOF
    
    # Make desktop file executable
    chmod +x "$DESKTOP_DIR/ntfs-manager.desktop"
    
    log_success "Desktop integration installed"
}

# Install icons
install_icons() {
    log_info "Installing icons..."
    
    ICON_DIR="$HOME/.local/share/icons/hicolor"
    
    # Copy icons from existing project
    if [[ -d "$PROJECT_ROOT/ntfs-complete-manager-gui/icons" ]]; then
        cp -r "$PROJECT_ROOT/ntfs-complete-manager-gui/icons"/* "$ICON_DIR/" 2>/dev/null || true
        log_success "Icons installed from project"
    else
        # Create simple fallback icon
        mkdir -p "$ICON_DIR/scalable/apps"
        cat > "$ICON_DIR/scalable/apps/ntfs-manager.svg" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="48" height="48" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="8" y="12" width="32" height="24" rx="2" fill="#2196F3" stroke="#1976D2" stroke-width="2"/>
  <rect x="12" y="16" width="24" height="16" rx="1" fill="#E3F2FD"/>
  <circle cx="24" cy="24" r="3" fill="#1976D2"/>
  <text x="24" y="28" text-anchor="middle" fill="white" font-family="sans-serif" font-size="4" font-weight="bold">NTFS</text>
</svg>
EOF
        log_success "Fallback icon created"
    fi
    
    # Update icon cache
    gtk-update-icon-cache -f -t "$ICON_DIR" 2>/dev/null || true
}

# Restart Nautilus
restart_nautilus() {
    log_info "Restarting Nautilus to load extension..."
    
    # Kill existing Nautilus processes
    pkill -f nautilus 2>/dev/null || true
    
    # Wait a moment
    sleep 2
    
    # Start Nautilus
    nohup nautilus --no-default-window &>/dev/null &
    
    log_success "Nautilus restarted"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check if extension file exists
    if [[ -f "$EXTENSION_DIR/$EXTENSION_NAME" ]]; then
        log_success "Extension file installed"
    else
        log_error "Extension file not found"
        return 1
    fi
    
    # Check if backend modules exist
    if [[ -f "$BACKEND_DIR/drive_manager.py" ]]; then
        log_success "Backend modules installed"
    else
        log_error "Backend modules not found"
        return 1
    fi
    
    # Check configuration
    if [[ -f "$HOME/.config/ntfs-manager/config.ini" ]]; then
        log_success "Configuration created"
    else
        log_error "Configuration not found"
        return 1
    fi
    
    log_success "Installation verified successfully"
}

# Show usage information
show_usage_info() {
    log_info "Installation completed successfully!"
    echo
    echo "=== NTFS Manager Nautilus Extension ==="
    echo
    echo "Usage:"
    echo "1. Right-click on any drive or mount point in Nautilus"
    echo "2. Select 'NTFS Management' from the context menu"
    echo "3. Choose the desired operation:"
    echo "   - Mount/Unmount Drive"
    echo "   - Drive Properties (Windows-style information)"
    echo "   - Health Check (SMART and filesystem status)"
    echo "   - Repair Drive (fix filesystem errors)"
    echo "   - Format Drive (DANGEROUS - erases all data)"
    echo "   - Safe Eject (for removable drives)"
    echo
    echo "Features:"
    echo "- Real-time drive monitoring"
    echo "- Windows-style NTFS properties"
    echo "- Health monitoring and SMART status"
    echo "- Desktop notifications"
    echo "- Comprehensive logging"
    echo
    echo "Configuration: $HOME/.config/ntfs-manager/config.ini"
    echo "Logs: $(if [[ $EUID -eq 0 ]]; then echo "/var/log/ntfs-manager"; else echo "$HOME/.local/share/ntfs-manager/logs"; fi)"
    echo
    echo "To uninstall, run: $SCRIPT_DIR/uninstall.sh"
}

# Main installation function
main() {
    echo "=== NTFS Manager Nautilus Extension Installer ==="
    echo
    
    check_permissions
    install_dependencies
    create_extension_dir
    install_extension
    install_backend
    create_config
    create_log_dir
    install_desktop_integration
    install_icons
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
        log_info "Uninstall not implemented yet. Please remove files manually."
        ;;
    --help|-h)
        echo "Usage: $0 [install|uninstall|--help]"
        echo "  install   - Install the extension (default)"
        echo "  uninstall - Uninstall the extension"
        echo "  --help    - Show this help message"
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
EOF
