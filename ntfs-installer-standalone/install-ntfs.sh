#!/bin/bash

# Standalone NTFS Installer
# Complete NTFS solution installer - independent of all-in-one installer

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/ntfs-installer.log"
BACKUP_DIR="/var/backups/ntfs-installer"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    log "ERROR: $1"
    exit 1
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "This script must be run as root (use sudo)"
    fi
}

create_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    chmod 755 "$BACKUP_DIR"
}

show_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           Standalone NTFS Installer v2.0                    ${NC}"
    echo -e "${CYAN}           Complete NTFS Solution for Linux                   ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Compiled by: Darryl Bennett${NC}"
    echo -e "${BLUE}Repository: https://github.com/darrylbennett/ntfs-installer${NC}"
    echo ""
}

show_credits() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    CREDITS & ATTRIBUTION                      ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}This NTFS installer combines tools from the following repositories:${NC}"
    echo ""
    echo -e "${GREEN}ntfsprogs-plus${NC} - Enhanced NTFS utilities"
    echo -e "${BLUE}  https://github.com/ntfsprogs-plus/ntfsprogs-plus${NC}"
    echo -e "${YELLOW}  License: GPL-2.0${NC}"
    echo ""
    echo -e "${GREEN}NTFSplus Kernel Driver${NC} - Modern NTFS kernel driver"
    echo -e "${BLUE}  https://github.com/namjaejeon/ntfs-kernel (ntfsplus branch)${NC}"
    echo -e "${YELLOW}  License: GPL-2.0${NC}"
    echo ""
    echo -e "${GREEN}ntfs-3g${NC} - FUSE-based NTFS driver"
    echo -e "${BLUE}  https://github.com/tuxera/ntfs-3g${NC}"
    echo -e "${YELLOW}  License: GPL-2.0, LGPL-2.0${NC}"
    echo ""
    echo -e "${GREEN}GParted${NC} - GNOME Partition Editor"
    echo -e "${BLUE}  https://gparted.org/${NC}"
    echo -e "${YELLOW}  License: GPL-2.0${NC}"
    echo ""
    echo -e "${PURPLE}Compiler: Darryl Bennett${NC}"
    echo -e "${BLUE}  - Collected and integrated these tools${NC}"
    echo -e "${BLUE}  - Added version management and unified interface${NC}"
    echo -e "${BLUE}  - Created automated installation and management${NC}"
    echo ""
}

check_system_requirements() {
    echo -e "${BLUE}Checking system requirements...${NC}"

    # Check kernel version for NTFSplus
    KERNEL_VERSION=$(uname -r | cut -d. -f1,2)
    MAJOR=$(echo $KERNEL_VERSION | cut -d. -f1)
    MINOR=$(echo $KERNEL_VERSION | cut -d. -f2)

    if [ "$MAJOR" -lt 6 ] || ([ "$MAJOR" -eq 6 ] && [ "$MINOR" -lt 2 ]); then
        echo -e "${YELLOW}⚠️  Kernel $KERNEL_VERSION detected${NC}"
        echo -e "${YELLOW}   NTFSplus driver requires kernel 6.2+${NC}"
        echo -e "${BLUE}   You can still install ntfsprogs-plus and ntfs-3g${NC}"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    else
        echo -e "${GREEN}✓ Kernel $KERNEL_VERSION supports NTFSplus${NC}"
    fi

    # Check for required tools
    local REQUIRED_TOOLS=("wget" "git" "make" "gcc" "pkg-config")
    local MISSING_TOOLS=()

    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            MISSING_TOOLS+=("$tool")
        fi
    done

    if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Missing required tools: ${MISSING_TOOLS[*]}${NC}"
        echo -e "${BLUE}   Installing missing tools...${NC}"
        apt-get update
        apt-get install -y "${MISSING_TOOLS[@]}"
        echo -e "${GREEN}✓ Tools installed${NC}"
    else
        echo -e "${GREEN}✓ All required tools available${NC}"
    fi

    echo ""
}

install_ntfs_solution() {
    echo -e "${BLUE}Installing Complete NTFS Solution...${NC}"

    # Use the NTFS manager from the ntfs-manager directory
    if [ -f "$SCRIPT_DIR/ntfs-manager/ntfs-complete-manager-v2.sh" ]; then
        log "Running NTFS Complete Manager v2.0 installation"
        bash "$SCRIPT_DIR/ntfs-manager/ntfs-complete-manager-v2.sh" --install
        echo -e "${GREEN}✓ NTFS Complete Manager installation completed${NC}"
    else
        error_exit "NTFS manager not found in $SCRIPT_DIR/ntfs-manager/"
    fi

    echo ""
}

create_desktop_shortcuts() {
    echo -e "${BLUE}Creating desktop shortcuts...${NC}"

    # NTFS Manager shortcut
    cat > "/home/$SUDO_USER/Desktop/NTFS-Manager.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=NTFS Manager
Comment=Manage NTFS drivers and tools
Exec=gnome-terminal -- bash -c "echo 'NTFS Manager - Complete NTFS Solution'; echo '===================================='; echo ''; echo 'Available commands:'; echo '  sudo ntfs-complete-manager-v2.sh --scan     # Check status'; echo '  sudo ntfs-complete-manager-v2.sh --update   # Update components'; echo '  sudo ntfs-complete-manager-v2.sh --install  # Reinstall'; echo ''; echo 'Press Enter to close...'; read"
Icon=drive-harddisk
Terminal=false
Categories=System;Utility;
EOF

    chmod +x "/home/$SUDO_USER/Desktop/NTFS-Manager.desktop"
    chown "$SUDO_USER:$SUDO_USER" "/home/$SUDO_USER/Desktop/NTFS-Manager.desktop"

    echo -e "${GREEN}✓ Desktop shortcuts created${NC}"
}

show_installation_summary() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║               NTFS INSTALLATION COMPLETE!                     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Installed Components:${NC}"
    echo -e "  ${GREEN}✓${NC} ntfsprogs-plus utilities (ntfsck, ntfsclone, etc.)"
    echo -e "  ${GREEN}✓${NC} NTFSplus kernel driver (if kernel >= 6.2)"
    echo -e "  ${GREEN}✓${NC} ntfs-3g additional tools (resize, undelete, etc.)"
    echo -e "  ${GREEN}✓${NC} GParted GUI partition manager"
    echo ""
    echo -e "${CYAN}Quick Start:${NC}"
    echo -e "  ${YELLOW}Check status:${NC} sudo ntfs-complete-manager-v2.sh --scan"
    echo -e "  ${YELLOW}Update tools:${NC} sudo ntfs-complete-manager-v2.sh --update"
    echo -e "  ${YELLOW}Desktop shortcut:${NC} Check your desktop for NTFS Manager"
    echo ""
    echo -e "${CYAN}Mount NTFS drives:${NC}"
    echo -e "  ${YELLOW}Automatic:${NC} Drives are auto-detected and mounted"
    echo -e "  ${YELLOW}Manual:${NC} sudo mount -t ntfsplus /dev/sdXn /mnt/point"
    echo ""
    echo -e "${BLUE}Documentation: Check the docs/ directory for detailed guides${NC}"
    echo ""
}

main() {
    show_header
    show_credits

    check_root
    create_backup_dir

    echo -e "${YELLOW}This will install the complete NTFS solution for Linux.${NC}"
    echo -e "${CYAN}Components: ntfsprogs-plus, NTFSplus driver, ntfs-3g, GParted${NC}"
    echo ""

    read -p "Continue with installation? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi

    log "Starting standalone NTFS installer"

    check_system_requirements
    install_ntfs_solution
    create_desktop_shortcuts
    show_installation_summary

    log "Standalone NTFS installer completed successfully"
}

main "$@"
