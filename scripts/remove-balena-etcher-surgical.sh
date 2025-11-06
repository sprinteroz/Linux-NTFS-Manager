#!/bin/bash

# Surgical Balena Etcher Removal Script
# ONLY removes balena Etcher files - preserves Node.js and all other programs
# Version 1.0.0

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/tmp/balena-removal-surgical-$(date +%Y%m%d-%H%M%S).log"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     Surgical Balena Etcher Removal (Node.js Safe)           ║${NC}"
    echo -e "${CYAN}║     Only removes balena Etcher - keeps everything else      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

scan_balena_only() {
    log_info "Scanning for balena Etcher installations (ONLY)..."
    echo ""
    
    local found_items=()
    
    # Check exact installation directory from the install script
    if [[ -d "$HOME/.local/share/balena-etcher" ]]; then
        found_items+=("Installation: $HOME/.local/share/balena-etcher")
    fi
    
    # Check desktop entry
    if [[ -f "$HOME/.local/share/applications/balena-etcher.desktop" ]]; then
        found_items+=("Application entry: $HOME/.local/share/applications/balena-etcher.desktop")
    fi
    
    # Check desktop shortcut
    if [[ -f "$HOME/Desktop/balena-etcher.desktop" ]]; then
        found_items+=("Desktop shortcut: $HOME/Desktop/balena-etcher.desktop")
    fi
    
    # Check install script location
    if [[ -f "/home/darryl/Downloads/old files for setup /install-balena-etcher.sh" ]]; then
        found_items+=("Install script: /home/darryl/Downloads/old files for setup /install-balena-etcher.sh")
    fi
    
    # Check for any balenaEtcher AppImage files
    local appimages=$(find "$HOME" -maxdepth 3 -name "balenaEtcher*.AppImage" 2>/dev/null)
    if [[ -n "$appimages" ]]; then
        while IFS= read -r file; do
            found_items+=("AppImage: $file")
        done <<< "$appimages"
    fi
    
    echo -e "${YELLOW}Items to be removed:${NC}"
    if [[ ${#found_items[@]} -eq 0 ]]; then
        log_success "No balena Etcher installations found"
        echo -e "${GREEN}✓ Your system is clean - balena Etcher not installed${NC}"
        return 1
    else
        for item in "${found_items[@]}"; do
            echo -e "  ${RED}•${NC} $item"
        done
        echo ""
        echo -e "${GREEN}What will NOT be touched:${NC}"
        echo -e "  ${GREEN}✓${NC} Node.js installations (v20, v23, etc.)"
        echo -e "  ${GREEN}✓${NC} npm and npm modules"
        echo -e "  ${GREEN}✓${NC} Any other programs or files"
        echo ""
        return 0
    fi
}

remove_balena_installation() {
    log_info "Removing balena Etcher installation directory..."
    
    if [[ -d "$HOME/.local/share/balena-etcher" ]]; then
        rm -rf "$HOME/.local/share/balena-etcher"
        log_success "Removed: $HOME/.local/share/balena-etcher"
    else
        log_info "Installation directory not found"
    fi
}

remove_desktop_files() {
    log_info "Removing desktop entries and shortcuts..."
    
    local removed=0
    
    # Remove application entry
    if [[ -f "$HOME/.local/share/applications/balena-etcher.desktop" ]]; then
        rm -f "$HOME/.local/share/applications/balena-etcher.desktop"
        log_success "Removed application entry"
        ((removed++))
    fi
    
    # Remove desktop shortcut
    if [[ -f "$HOME/Desktop/balena-etcher.desktop" ]]; then
        rm -f "$HOME/Desktop/balena-etcher.desktop"
        log_success "Removed desktop shortcut"
        ((removed++))
    fi
    
    if [[ $removed -eq 0 ]]; then
        log_info "No desktop files found"
    else
        # Update desktop database
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
        log_success "Desktop database updated"
    fi
}

remove_install_script() {
    log_info "Removing installation script..."
    
    if [[ -f "/home/darryl/Downloads/old files for setup /install-balena-etcher.sh" ]]; then
        rm -f "/home/darryl/Downloads/old files for setup /install-balena-etcher.sh"
        log_success "Removed installation script"
    else
        log_info "Installation script not found"
    fi
}

remove_appimages() {
    log_info "Scanning for balena Etcher AppImage files..."
    
    local removed=0
    while IFS= read -r file; do
        if [[ -f "$file" ]] && [[ "$file" == *"balenaEtcher"* ]]; then
            rm -f "$file"
            log_success "Removed AppImage: $file"
            ((removed++))
        fi
    done < <(find "$HOME" -maxdepth 3 -name "balenaEtcher*.AppImage" 2>/dev/null)
    
    if [[ $removed -eq 0 ]]; then
        log_info "No AppImage files found"
    fi
}

clean_balena_udev_rules() {
    log_info "Checking for balena-specific udev rules..."
    
    # Only check and remove if we're running with sudo
    if [[ $EUID -eq 0 ]]; then
        if grep -r "balena\|etcher" /etc/udev/rules.d/ 2>/dev/null | grep -q .; then
            # Backup first
            mkdir -p /var/backups/udev-rules-backup
            cp -r /etc/udev/rules.d/ /var/backups/udev-rules-backup/$(date +%Y%m%d-%H%M%S)/ 2>/dev/null || true
            
            # Remove problematic lines
            for file in /etc/udev/rules.d/*; do
                if [[ -f "$file" ]]; then
                    sed -i '/balena/d' "$file"
                    sed -i '/etcher/d' "$file"
                fi
            done
            
            udevadm control --reload-rules 2>/dev/null || true
            udevadm trigger 2>/dev/null || true
            
            log_success "Udev rules cleaned"
        else
            log_info "No balena-specific udev rules found"
        fi
    else
        log_warning "Skipping udev rules (requires sudo)"
        log_info "Run with sudo to clean udev rules"
    fi
}

verify_node_safe() {
    log_info "Verifying Node.js installations are intact..."
    
    # Check Node.js v20
    if [[ -d "$HOME/.nvm/versions/node/v20.19.5" ]]; then
        log_success "✓ Node.js v20.19.5 - intact"
    fi
    
    # Check Node.js v23
    if [[ -d "$HOME/.nvm/versions/node/v23.11.1" ]]; then
        log_success "✓ Node.js v23.11.1 - intact"
    fi
    
    # Test if node command works
    if command -v node &> /dev/null; then
        local node_version=$(node --version 2>/dev/null || echo "unknown")
        log_success "✓ Node.js is working: $node_version"
    else
        log_info "Node command not in current PATH (this is OK)"
    fi
    
    # Test if npm works
    if command -v npm &> /dev/null; then
        local npm_version=$(npm --version 2>/dev/null || echo "unknown")
        log_success "✓ npm is working: v$npm_version"
    else
        log_info "npm command not in current PATH (this is OK)"
    fi
}

show_summary() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        Surgical Balena Etcher Removal Complete              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}What was removed:${NC}"
    echo -e "  ${GREEN}✓${NC} Balena Etcher installation directory"
    echo -e "  ${GREEN}✓${NC} Desktop entries and shortcuts"
    echo -e "  ${GREEN}✓${NC} Installation script"
    echo -e "  ${GREEN}✓${NC} Any AppImage files"
    echo ""
    echo -e "${GREEN}What was preserved:${NC}"
    echo -e "  ${GREEN}✓${NC} Node.js installations (all versions)"
    echo -e "  ${GREEN}✓${NC} npm and all npm modules"
    echo -e "  ${GREEN}✓${NC} All other programs and files"
    echo ""
    echo -e "${YELLOW}⚠️  NEXT STEP - Fix NTFS Functionality:${NC}"
    echo -e "  Run the recovery script to restore NTFS functionality:"
    echo -e "  ${CYAN}sudo ./scripts/balena-etcher-recovery.sh${NC}"
    echo ""
    echo -e "${BLUE}Log file: $LOG_FILE${NC}"
    echo ""
}

main() {
    show_header
    
    # Scan first
    if ! scan_balena_only; then
        exit 0
    fi
    
    echo ""
    read -p "Proceed with surgical removal? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Removal cancelled"
        exit 0
    fi
    
    echo ""
    log_info "Starting surgical removal (Node.js will NOT be touched)..."
    echo ""
    
    # Remove only balena Etcher files
    remove_balena_installation
    remove_desktop_files
    remove_install_script
    remove_appimages
    clean_balena_udev_rules
    
    # Verify Node.js is safe
    echo ""
    verify_node_safe
    
    # Show summary
    show_summary
    
    echo -e "${CYAN}Would you like to run the NTFS recovery script now? (y/N):${NC} "
    read -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        if [[ $EUID -eq 0 ]]; then
            ./scripts/balena-etcher-recovery.sh
        else
            sudo ./scripts/balena-etcher-recovery.sh
        fi
    else
        echo ""
        echo -e "${YELLOW}Remember to run the recovery script later:${NC}"
        echo -e "  ${CYAN}sudo ./scripts/balena-etcher-recovery.sh${NC}"
    fi
}

main "$@"
