#!/bin/bash

# NTFS Manager - Master Installation Script
# Version 3.0.0
# Installs complete NTFS Manager package with GUI, Nautilus extension, and all dependencies

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/ntfs-manager"
USER_INSTALL_DIR="$HOME/.local/share/ntfs-manager"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"
NAUTILUS_EXT_DIR="$HOME/.local/share/nautilus-python/extensions"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

# Logging
LOG_FILE="/tmp/ntfs-manager-install.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# Helper functions
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

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should be run as regular user, not root"
        log_info "System operations will prompt for sudo when needed"
        exit 1
    fi
}

check_dependencies() {
    log_info "Checking system dependencies..."
    
    local missing_deps=()
    
    # Check essential commands
    for cmd in python3 pip3 apt sudo; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install missing dependencies and try again"
        exit 1
    fi
    
    log_success "All essential dependencies found"
}

install_system_dependencies() {
    log_info "Installing system dependencies..."
    
    local packages=(
        "python3"
        "python3-pip"
        "python3-gi"
        "python3-gi-cairo"
        "gir1.2-gtk-3.0"
        "gir1.2-glib-2.0"
        "python3-nautilus"
        "nautilus"
        "nautilus-data"
        "ntfs-3g"
        "ntfsprogs"
        "dosfstools"
        "exfat-utils"
        "exfat-fuse"
        "gparted"
        "parted"
        "fdisk"
        "util-linux"
        "mount"
        "umount"
        "eject"
        "smartmontools"
        "hddtemp"
        "lm-sensors"
        "usbutils"
        "pciutils"
        "libmagic1"
        "python3-magic"
        "psutil"
        "procps"
        "coreutils"
        "desktop-file-utils"
        "xdg-utils"
        "notify-osd"
        "libnotify-bin"
    )
    
    sudo apt update
    sudo apt install -y "${packages[@]}"
    
    log_success "System dependencies installed"
}

install_python_dependencies() {
    log_info "Installing Python dependencies..."
    
    if [[ -f "$SCRIPT_DIR/requirements.txt" ]]; then
        pip3 install --user -r "$SCRIPT_DIR/requirements.txt"
        log_success "Python dependencies installed"
    else
        log_warning "requirements.txt not found, installing basic dependencies"
        pip3 install --user PyGObject gi psutil python-magic requests
    fi
}

create_directories() {
    log_info "Creating installation directories..."
    
    mkdir -p "$USER_INSTALL_DIR"/{backend,standalone-gui,icons,docs,tests}
    mkdir -p "$DESKTOP_DIR"
    mkdir -p "$ICON_DIR"
    mkdir -p "$NAUTILUS_EXT_DIR"
    mkdir -p "$SYSTEMD_USER_DIR"
    mkdir -p "$HOME/.local/bin"
    
    log_success "Directories created"
}

install_standalone_gui() {
    log_info "Installing standalone GUI application..."
    
    # Copy backend modules
    cp -r "$SCRIPT_DIR/backend"/* "$USER_INSTALL_DIR/backend/"
    
    # Copy GUI files
    cp "$SCRIPT_DIR/standalone-gui/main.py" "$USER_INSTALL_DIR/"
    cp "$SCRIPT_DIR/standalone-gui/ntfs-manager.desktop" "$DESKTOP_DIR/"
    
    # Copy icons
    cp -r "$SCRIPT_DIR/icons"/* "$ICON_DIR/"
    
    # Create launcher script
    cat > "$HOME/.local/bin/ntfs-manager" << 'EOF'
#!/bin/bash
cd "$USER_INSTALL_DIR"
python3 main.py "$@"
EOF
    chmod +x "$HOME/.local/bin/ntfs-manager"
    
    log_success "Standalone GUI installed"
}

install_nautilus_extension() {
    log_info "Installing Nautilus extension..."
    
    # Copy extension files
    cp "$SCRIPT_DIR/nautilus-extension/ntfs_manager_extension.py" "$NAUTILUS_EXT_DIR/"
    cp "$SCRIPT_DIR/nautilus-extension/install.sh" "$USER_INSTALL_DIR/nautilus-install.sh"
    cp "$SCRIPT_DIR/nautilus-extension/test_integration.py" "$USER_INSTALL_DIR/"
    
    # Make extension executable
    chmod +x "$NAUTILUS_EXT_DIR/ntfs_manager_extension.py"
    
    log_success "Nautilus extension installed"
    log_warning "You may need to restart Nautilus: nautilus -q"
}

install_desktop_integration() {
    log_info "Installing desktop integration..."
    
    # Update desktop file with correct paths
    sed -i "s|Exec=.*|Exec=$HOME/.local/bin/ntfs-manager|g" "$DESKTOP_DIR/ntfs-manager.desktop"
    sed -i "s|Icon=.*|Icon=ntfs-manager|g" "$DESKTOP_DIR/ntfs-manager.desktop"
    
    # Update desktop database
    update-desktop-database "$HOME/.local/share/applications"
    
    log_success "Desktop integration installed"
}

create_user_services() {
    log_info "Setting up user services..."
    
    # Create update service (optional)
    if [[ -f "$SCRIPT_DIR/nautilus-extension/install-enhanced.sh" ]]; then
        cp "$SCRIPT_DIR/nautilus-extension/install-enhanced.sh" "$USER_INSTALL_DIR/"
        chmod +x "$USER_INSTALL_DIR/install-enhanced.sh"
        log_success "Enhanced installation script available"
    fi
}

setup_permissions() {
    log_info "Setting up permissions..."
    
    # Add user to disk group if not already member
    if ! groups "$USER" | grep -q "\bdisk\b"; then
        log_warning "Adding user to disk group (requires sudo)"
        sudo usermod -aG disk "$USER"
        log_warning "You may need to log out and log back in for group changes to take effect"
    fi
    
    # Set executable permissions
    find "$USER_INSTALL_DIR" -name "*.py" -exec chmod +x {} \;
    chmod +x "$HOME/.local/bin/ntfs-manager"
    
    log_success "Permissions configured"
}

verify_installation() {
    log_info "Verifying installation..."
    
    local errors=0
    
    # Check if main executable exists
    if [[ ! -x "$HOME/.local/bin/ntfs-manager" ]]; then
        log_error "Main executable not found"
        ((errors++))
    fi
    
    # Check if desktop file exists
    if [[ ! -f "$DESKTOP_DIR/ntfs-manager.desktop" ]]; then
        log_error "Desktop file not found"
        ((errors++))
    fi
    
    # Check if Nautilus extension exists
    if [[ ! -f "$NAUTILUS_EXT_DIR/ntfs_manager_extension.py" ]]; then
        log_error "Nautilus extension not found"
        ((errors++))
    fi
    
    # Check Python dependencies
    if ! python3 -c "import gi, psutil" 2>/dev/null; then
        log_error "Python dependencies not properly installed"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "Installation verified successfully"
        return 0
    else
        log_error "Installation verification failed with $errors errors"
        return 1
    fi
}

show_post_install_info() {
    log_info "Installation completed!"
    echo
    echo -e "${GREEN}=== NTFS Manager Installation Complete ===${NC}"
    echo
    echo -e "${BLUE}Standalone GUI:${NC}"
    echo "  Launch from terminal: ntfs-manager"
    echo "  Or from applications menu"
    echo
    echo -e "${BLUE}Nautilus Extension:${NC}"
    echo "  Right-click NTFS drives in Nautilus"
    echo "  Restart Nautilus if needed: nautilus -q"
    echo
    echo -e "${BLUE}Documentation:${NC}"
    echo "  README: $SCRIPT_DIR/README.md"
    echo "  CHANGELOG: $SCRIPT_DIR/CHANGELOG.md"
    echo "  Requirements: $SCRIPT_DIR/requirements.txt"
    echo
    echo -e "${YELLOW}Important Notes:${NC}"
    echo "  - You may need to log out/in for disk group permissions"
    echo "  - Restart Nautilus for extension to load"
    echo "  - Check $LOG_FILE for installation details"
    echo
}

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -f /tmp/ntfs-manager-*
    log_success "Cleanup completed"
}

# Main installation flow
main() {
    echo -e "${BLUE}=== NTFS Manager v3.0.0 Installation ===${NC}"
    echo
    
    check_root
    check_dependencies
    
    # Ask for installation type
    echo "Select installation type:"
    echo "1) Full installation (recommended)"
    echo "2) GUI only"
    echo "3) Nautilus extension only"
    echo "4) Dependencies only"
    echo
    read -p "Enter choice [1-4]: " -n 1 -r
    echo
    
    case $REPLY in
        1)
            log_info "Starting full installation..."
            install_system_dependencies
            install_python_dependencies
            create_directories
            install_standalone_gui
            install_nautilus_extension
            install_desktop_integration
            create_user_services
            setup_permissions
            ;;
        2)
            log_info "Starting GUI-only installation..."
            install_python_dependencies
            create_directories
            install_standalone_gui
            install_desktop_integration
            setup_permissions
            ;;
        3)
            log_info "Starting Nautilus extension installation..."
            install_system_dependencies
            install_python_dependencies
            create_directories
            install_nautilus_extension
            setup_permissions
            ;;
        4)
            log_info "Installing dependencies only..."
            install_system_dependencies
            install_python_dependencies
            ;;
        *)
            log_error "Invalid choice"
            exit 1
            ;;
    esac
    
    if verify_installation; then
        show_post_install_info
        cleanup
        log_success "Installation completed successfully!"
    else
        log_error "Installation failed. Check $LOG_FILE for details."
        exit 1
    fi
}

# Handle script interruption
trap cleanup EXIT

# Run main function
main "$@"
