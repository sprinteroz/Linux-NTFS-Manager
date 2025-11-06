#!/bin/bash

# Software Compatibility Checker for Linux NTFS Manager
# Detects known incompatible software and system issues
# Version 1.0.0

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
ISSUES_FOUND=0
WARNINGS_FOUND=0

log_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS_FOUND++))
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    ((ISSUES_FOUND++))
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

show_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        Software Compatibility Check for NTFS Manager        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_balena_etcher() {
    echo -e "${BLUE}[1/7] Checking for Balena Etcher...${NC}"
    
    local found=0
    
    # Check command availability
    if command -v balena-etcher-electron &> /dev/null; then
        log_error "Balena Etcher installed: $(command -v balena-etcher-electron)"
        found=1
    fi
    
    if command -v balenaEtcher &> /dev/null; then
        log_error "Balena Etcher installed: $(command -v balenaEtcher)"
        found=1
    fi
    
    # Check AppImage
    if find /home -name "*balena*etcher*.AppImage" 2>/dev/null | grep -q .; then
        log_error "Balena Etcher AppImage found in home directory"
        found=1
    fi
    
    # Check snap
    if snap list 2>/dev/null | grep -q "etcher"; then
        log_error "Balena Etcher snap package installed"
        found=1
    fi
    
    if [[ $found -eq 0 ]]; then
        log_ok "Balena Etcher not detected"
    else
        echo -e "${RED}   ⚠️  WARNING: Balena Etcher breaks NTFS functionality!${NC}"
        echo -e "${YELLOW}   Run: sudo ./scripts/balena-etcher-recovery.sh${NC}"
    fi
    echo ""
}

check_other_disk_tools() {
    echo -e "${BLUE}[2/7] Checking other disk imaging tools...${NC}"
    
    local tools=("unetbootin" "etcher" "balena")
    local found_tools=()
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            found_tools+=("$tool")
        fi
    done
    
    if [[ ${#found_tools[@]} -eq 0 ]]; then
        log_ok "No problematic disk tools detected"
    else
        log_warning "Found potentially problematic tools: ${found_tools[*]}"
        echo -e "${YELLOW}   Monitor NTFS functionality after using these tools${NC}"
    fi
    echo ""
}

check_ntfs_packages() {
    echo -e "${BLUE}[3/7] Checking NTFS packages...${NC}"
    
    # Check ntfs-3g
    if command -v ntfs-3g &> /dev/null; then
        log_ok "ntfs-3g installed"
    else
        log_error "ntfs-3g not installed or not in PATH"
    fi
    
    # Check ntfsprogs
    if command -v ntfsfix &> /dev/null; then
        log_ok "ntfsprogs installed"
    else
        log_error "ntfsprogs not installed"
    fi
    
    # Check fuse
    if lsmod | grep -q fuse; then
        log_ok "FUSE module loaded"
    else
        log_warning "FUSE module not loaded"
    fi
    
    # Check udisks2
    if systemctl is-active --quiet udisks2 2>/dev/null; then
        log_ok "udisks2 service running"
    else
        log_error "udisks2 service not running"
    fi
    echo ""
}

check_permissions() {
    echo -e "${BLUE}[4/7] Checking user permissions...${NC}"
    
    local user="${SUDO_USER:-$USER}"
    
    # Check disk group
    if groups "$user" | grep -q "\bdisk\b"; then
        log_ok "User in 'disk' group"
    else
        log_warning "User not in 'disk' group"
        echo -e "${YELLOW}   Add with: sudo usermod -aG disk $user${NC}"
    fi
    
    # Check plugdev group
    if groups "$user" | grep -q "\bplugdev\b"; then
        log_ok "User in 'plugdev' group"
    else
        log_warning "User not in 'plugdev' group"
        echo -e "${YELLOW}   Add with: sudo usermod -aG plugdev $user${NC}"
    fi
    
    # Check fuse group
    if getent group fuse > /dev/null 2>&1; then
        if groups "$user" | grep -q "\bfuse\b"; then
            log_ok "User in 'fuse' group"
        else
            log_warning "User not in 'fuse' group"
            echo -e "${YELLOW}   Add with: sudo usermod -aG fuse $user${NC}"
        fi
    else
        log_info "FUSE group not present (may not be required)"
    fi
    echo ""
}

check_udev_rules() {
    echo -e "${BLUE}[5/7] Checking udev rules...${NC}"
    
    # Check for NTFS-related rules
    if ls /etc/udev/rules.d/*ntfs* 2>/dev/null | grep -q .; then
        log_ok "NTFS udev rules found"
    else
        log_warning "No NTFS-specific udev rules found"
        echo -e "${YELLOW}   May need to run recovery script${NC}"
    fi
    
    # Check for problematic balena rules
    if grep -r "balena\|etcher" /etc/udev/rules.d/ 2>/dev/null | grep -q .; then
        log_error "Balena Etcher udev rules detected"
        echo -e "${RED}   These rules may interfere with NTFS mounting${NC}"
    else
        log_ok "No problematic balena/etcher rules found"
    fi
    echo ""
}

check_polkit_policies() {
    echo -e "${BLUE}[6/7] Checking PolicyKit permissions...${NC}"
    
    # Check for NTFS mount policies
    if ls /etc/polkit-1/rules.d/*ntfs* 2>/dev/null | grep -q .; then
        log_ok "NTFS PolicyKit rules found"
    else
        log_warning "No NTFS-specific PolicyKit rules"
        echo -e "${YELLOW}   May require password for mounting${NC}"
    fi
    
    # Check polkit service
    if systemctl is-active --quiet polkit 2>/dev/null; then
        log_ok "PolicyKit service running"
    else
        log_warning "PolicyKit service not running"
    fi
    echo ""
}

check_mount_functionality() {
    echo -e "${BLUE}[7/7] Checking NTFS mount functionality...${NC}"
    
    # Check for currently mounted NTFS drives
    local ntfs_mounts=$(mount | grep -c "type ntfs" || echo "0")
    
    if [[ $ntfs_mounts -gt 0 ]]; then
        log_ok "Found $ntfs_mounts mounted NTFS filesystem(s)"
    else
        log_info "No NTFS filesystems currently mounted"
    fi
    
    # Check for orphaned mount points
    local orphaned=$(find /media -type d -empty 2>/dev/null | wc -l)
    if [[ $orphaned -gt 2 ]]; then
        log_warning "Found $orphaned empty mount points in /media"
        echo -e "${YELLOW}   May need cleaning with recovery script${NC}"
    else
        log_ok "No orphaned mount points detected"
    fi
    echo ""
}

show_summary() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    Compatibility Summary                     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ $ISSUES_FOUND -eq 0 && $WARNINGS_FOUND -eq 0 ]]; then
        echo -e "${GREEN}✓ All checks passed! Your system is compatible.${NC}"
        echo ""
    else
        echo -e "${RED}Issues found: $ISSUES_FOUND${NC}"
        echo -e "${YELLOW}Warnings: $WARNINGS_FOUND${NC}"
        echo ""
        
        if [[ $ISSUES_FOUND -gt 0 ]]; then
            echo -e "${RED}⚠️  Action required:${NC}"
            echo -e "   1. Review issues above marked with ${RED}✗${NC}"
            echo -e "   2. Run recovery script if Balena Etcher detected:"
            echo -e "      ${CYAN}sudo ./scripts/balena-etcher-recovery.sh${NC}"
            echo -e "   3. Install missing packages:"
            echo -e "      ${CYAN}sudo apt install ntfs-3g ntfsprogs udisks2${NC}"
            echo ""
        fi
        
        if [[ $WARNINGS_FOUND -gt 0 ]]; then
            echo -e "${YELLOW}⚠️  Recommendations:${NC}"
            echo -e "   1. Add user to required groups"
            echo -e "   2. Review warnings marked with ${YELLOW}⚠${NC}"
            echo -e "   3. Log out and back in for group changes"
            echo ""
        fi
    fi
    
    echo -e "${BLUE}Documentation:${NC}"
    echo -e "   • Compatibility: ${CYAN}docs/KNOWN-INCOMPATIBLE-SOFTWARE.md${NC}"
    echo -e "   • Troubleshooting: ${CYAN}wiki-content/Troubleshooting.md${NC}"
    echo -e "   • Recovery Script: ${CYAN}scripts/balena-etcher-recovery.sh${NC}"
    echo ""
}

main() {
    show_header
    
    check_balena_etcher
    check_other_disk_tools
    check_ntfs_packages
    check_permissions
    check_udev_rules
    check_polkit_policies
    check_mount_functionality
    
    show_summary
    
    # Return appropriate exit code
    if [[ $ISSUES_FOUND -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"
