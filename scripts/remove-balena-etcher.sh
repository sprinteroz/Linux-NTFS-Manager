#!/bin/bash

# Complete Balena Etcher Removal Script
# Removes balena Etcher from all possible locations and cleans up icons
# Version 1.0.0

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Log file
LOG_FILE="/tmp/balena-etcher-removal-$(date +%Y%m%d-%H%M%S).log"

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
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║        Complete Balena Etcher Removal Tool                  ║${NC}"
    echo -e "${RED}║        Removes ALL traces of balena Etcher                  ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}This script will completely remove balena Etcher from your system${NC}"
    echo -e "${YELLOW}including all desktop icons and configuration files.${NC}"
    echo ""
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

scan_system() {
    log_info "Scanning system for balena Etcher installations..."
    echo ""
    
    local found_items=()
    
    # Check executables
    if command -v balena-etcher-electron &> /dev/null; then
        found_items+=("Executable: $(command -v balena-etcher-electron)")
    fi
    
    if command -v balenaEtcher &> /dev/null; then
        found_items+=("Executable: $(command -v balenaEtcher)")
    fi
    
    if command -v etcher &> /dev/null; then
        found_items+=("Executable: $(command -v etcher)")
    fi
    
    # Check snap packages
    if snap list 2>/dev/null | grep -q "etcher"; then
        found_items+=("Snap package: etcher")
    fi
    
    # Check AppImage files
    local appimages=$(find /home -name "*balena*etcher*.AppImage" 2>/dev/null)
    if [[ -n "$appimages" ]]; then
        while IFS= read -r file; do
            found_items+=("AppImage: $file")
        done <<< "$appimages"
    fi
    
    # Check desktop files
    local desktop_files=$(find /home -name "*balena*.desktop" -o -name "*etcher*.desktop" 2>/dev/null)
    if [[ -n "$desktop_files" ]]; then
        while IFS= read -r file; do
            found_items+=("Desktop file: $file")
        done <<< "$desktop_files"
    fi
    
    # Check system-wide desktop files
    if ls /usr/share/applications/*etcher*.desktop 2>/dev/null | grep -q .; then
        found_items+=("System desktop files: /usr/share/applications/*etcher*.desktop")
    fi
    
    # Check /opt directory
    if [[ -d /opt/balena-etcher ]] || [[ -d /opt/etcher ]]; then
        found_items+=("Installation directory: /opt/balena-etcher or /opt/etcher")
    fi
    
    # Check user local installations
    local user_apps=$(find /home -type d -name "*balena*" -o -name "*etcher*" 2>/dev/null | head -20)
    if [[ -n "$user_apps" ]]; then
        while IFS= read -r dir; do
            if [[ "$dir" != *".cache"* ]] && [[ "$dir" != *".git"* ]]; then
                found_items+=("User directory: $dir")
            fi
        done <<< "$user_apps"
    fi
    
    if [[ ${#found_items[@]} -eq 0 ]]; then
        log_success "No balena Etcher installations found"
        return 1
    else
        log_warning "Found ${#found_items[@]} balena Etcher related items:"
        for item in "${found_items[@]}"; do
            echo -e "  ${RED}•${NC} $item"
        done
        echo ""
        return 0
    fi
}

remove_snap_package() {
    log_info "Removing snap packages..."
    
    if snap list 2>/dev/null | grep -q "etcher"; then
        snap remove etcher 2>/dev/null || true
        snap remove balena-etcher 2>/dev/null || true
        log_success "Snap packages removed"
    else
        log_info "No snap packages found"
    fi
}

remove_apt_packages() {
    log_info "Checking for apt packages..."
    
    if dpkg -l | grep -q "etcher\|balena"; then
        apt-get remove --purge -y *etcher* *balena* 2>/dev/null || true
        apt-get autoremove -y
        log_success "APT packages removed"
    else
        log_info "No apt packages found"
    fi
}

remove_appimages() {
    log_info "Removing AppImage files..."
    
    local removed=0
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log_success "Removed: $file"
            ((removed++))
        fi
    done < <(find /home -name "*balena*etcher*.AppImage" 2>/dev/null)
    
    if [[ $removed -eq 0 ]]; then
        log_info "No AppImage files found"
    else
        log_success "Removed $removed AppImage file(s)"
    fi
}

remove_desktop_icons() {
    log_info "Removing desktop icons and shortcuts..."
    
    local removed=0
    
    # Remove from user desktops
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log_success "Removed desktop icon: $file"
            ((removed++))
        fi
    done < <(find /home -path "*/Desktop/*etcher*" -o -path "*/Desktop/*balena*" 2>/dev/null)
    
    # Remove desktop files from home directories
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log_success "Removed desktop file: $file"
            ((removed++))
        fi
    done < <(find /home -name "*balena*.desktop" -o -name "*etcher*.desktop" 2>/dev/null)
    
    # Remove system-wide desktop files
    rm -f /usr/share/applications/*etcher*.desktop 2>/dev/null || true
    rm -f /usr/share/applications/*balena*.desktop 2>/dev/null || true
    
    if [[ $removed -eq 0 ]]; then
        log_info "No desktop icons found"
    else
        log_success "Removed $removed desktop icon(s)"
    fi
}

remove_executables() {
    log_info "Removing executables..."
    
    # Remove from system paths
    rm -f /usr/bin/balena-etcher* 2>/dev/null || true
    rm -f /usr/bin/etcher 2>/dev/null || true
    rm -f /usr/local/bin/balena-etcher* 2>/dev/null || true
    rm -f /usr/local/bin/etcher 2>/dev/null || true
    
    # Remove from user local bins
    find /home -path "*/.local/bin/*etcher*" -delete 2>/dev/null || true
    find /home -path "*/.local/bin/*balena*" -delete 2>/dev/null || true
    
    log_success "Executables removed"
}

remove_installation_directories() {
    log_info "Removing installation directories..."
    
    # Remove from /opt
    rm -rf /opt/balena-etcher 2>/dev/null || true
    rm -rf /opt/etcher 2>/dev/null || true
    
    # Remove from user directories (be careful here)
    while IFS= read -r dir; do
        # Only remove if it's clearly an etcher installation
        if [[ -f "$dir/balena-etcher" ]] || [[ -f "$dir/etcher" ]] || [[ "$dir" == *"balena-etcher"* ]]; then
            rm -rf "$dir"
            log_success "Removed directory: $dir"
        fi
    done < <(find /home -type d -name "*balena-etcher*" -o -name "balena-etcher" 2>/dev/null)
    
    log_success "Installation directories removed"
}

remove_config_files() {
    log_info "Removing configuration files..."
    
    # Remove config directories
    while IFS= read -r dir; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            log_success "Removed config: $dir"
        fi
    done < <(find /home -path "*/.config/*etcher*" -o -path "*/.config/*balena*" 2>/dev/null)
    
    # Remove cache
    while IFS= read -r dir; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            log_success "Removed cache: $dir"
        fi
    done < <(find /home -path "*/.cache/*etcher*" -o -path "*/.cache/*balena*" 2>/dev/null)
    
    log_success "Configuration files removed"
}

clean_udev_rules() {
    log_info "Cleaning udev rules..."
    
    # Remove any balena/etcher specific udev rules
    if grep -r "balena\|etcher" /etc/udev/rules.d/ 2>/dev/null | grep -q .; then
        # Backup first
        mkdir -p /var/backups/udev-rules-backup
        cp -r /etc/udev/rules.d/ /var/backups/udev-rules-backup/$(date +%Y%m%d-%H%M%S)/
        
        # Remove problematic lines
        for file in /etc/udev/rules.d/*; do
            if [[ -f "$file" ]]; then
                sed -i '/balena/d' "$file"
                sed -i '/etcher/d' "$file"
            fi
        done
        
        # Reload udev
        udevadm control --reload-rules
        udevadm trigger
        
        log_success "Udev rules cleaned"
    else
        log_info "No problematic udev rules found"
    fi
}

update_desktop_database() {
    log_info "Updating desktop database..."
    
    # Update for each user
    for user_home in /home/*; do
        if [[ -d "$user_home/.local/share/applications" ]]; then
            su - "$(basename "$user_home")" -c "update-desktop-database ~/.local/share/applications" 2>/dev/null || true
        fi
    done
    
    # Update system-wide
    update-desktop-database /usr/share/applications 2>/dev/null || true
    
    log_success "Desktop database updated"
}

verify_removal() {
    log_info "Verifying removal..."
    echo ""
    
    local still_present=()
    
    # Check if anything remains
    if command -v balena-etcher-electron &> /dev/null; then
        still_present+=("Executable still found: balena-etcher-electron")
    fi
    
    if command -v balenaEtcher &> /dev/null; then
        still_present+=("Executable still found: balenaEtcher")
    fi
    
    if snap list 2>/dev/null | grep -q "etcher"; then
        still_present+=("Snap package still present")
    fi
    
    if [[ ${#still_present[@]} -eq 0 ]]; then
        log_success "✓ Balena Etcher completely removed!"
        return 0
    else
        log_warning "Some items may still be present:"
        for item in "${still_present[@]}"; do
            echo -e "  ${YELLOW}•${NC} $item"
        done
        return 1
    fi
}

show_summary() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          Balena Etcher Removal Complete                     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}What was removed:${NC}"
    echo -e "  ${GREEN}✓${NC} Snap packages"
    echo -e "  ${GREEN}✓${NC} APT packages"
    echo -e "  ${GREEN}✓${NC} AppImage files"
    echo -e "  ${GREEN}✓${NC} Desktop icons and shortcuts"
    echo -e "  ${GREEN}✓${NC} Executables"
    echo -e "  ${GREEN}✓${NC} Installation directories"
    echo -e "  ${GREEN}✓${NC} Configuration files"
    echo -e "  ${GREEN}✓${NC} Udev rules cleaned"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT NEXT STEP:${NC}"
    echo -e "  Run the recovery script to fix NTFS functionality:"
    echo -e "  ${CYAN}sudo ./scripts/balena-etcher-recovery.sh${NC}"
    echo ""
    echo -e "${BLUE}Log file saved to: $LOG_FILE${NC}"
    echo ""
}

main() {
    show_header
    check_root
    
    # Scan first
    if ! scan_system; then
        log_info "Nothing to remove. System is clean."
        exit 0
    fi
    
    echo ""
    read -p "Proceed with complete removal? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Removal cancelled"
        exit 0
    fi
    
    echo ""
    log_info "Starting complete removal process..."
    echo ""
    
    # Remove everything
    remove_snap_package
    remove_apt_packages
    remove_appimages
    remove_desktop_icons
    remove_executables
    remove_installation_directories
    remove_config_files
    clean_udev_rules
    update_desktop_database
    
    # Verify
    echo ""
    verify_removal
    
    # Show summary
    show_summary
}

main "$@"
