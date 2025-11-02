#!/bin/bash

#############################################
# NTFS System Integration Deployment Script
# Installs system hooks, timers, and configuration
#
# Run after main NTFS installation
#############################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

#############################################
# Functions
#############################################

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}ERROR: This script must be run as root (use sudo)${NC}"
        exit 1
    fi
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

show_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  NTFS System Integration Deployment${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

#############################################
# Deployment Functions
#############################################

deploy_update_checker() {
    echo -e "${BLUE}Deploying update checker script...${NC}"
    
    if [ ! -f "$SCRIPT_DIR/ntfs-update-check" ]; then
        log_error "Update checker script not found: $SCRIPT_DIR/ntfs-update-check"
        return 1
    fi
    
    # Install script
    cp "$SCRIPT_DIR/ntfs-update-check" /usr/local/bin/
    chmod +x /usr/local/bin/ntfs-update-check
    
    log_success "Update checker installed: /usr/local/bin/ntfs-update-check"
}

deploy_systemd_units() {
    echo -e "${BLUE}Deploying systemd service and timer...${NC}"
    
    # Check if files exist
    if [ ! -f "$SCRIPT_DIR/ntfs-update-check.service" ]; then
        log_error "Service file not found"
        return 1
    fi
    
    if [ ! -f "$SCRIPT_DIR/ntfs-update-check.timer" ]; then
        log_error "Timer file not found"
        return 1
    fi
    
    # Install systemd units
    cp "$SCRIPT_DIR/ntfs-update-check.service" /etc/systemd/system/
    cp "$SCRIPT_DIR/ntfs-update-check.timer" /etc/systemd/system/
    
    # Reload systemd
    systemctl daemon-reload
    
    log_success "Systemd units installed"
    
    # Ask about enabling timer
    echo ""
    read -p "Enable automatic update checks? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl enable ntfs-update-check.timer
        systemctl start ntfs-update-check.timer
        log_success "Update timer enabled and started"
        
        # Show timer status
        echo ""
        systemctl status ntfs-update-check.timer --no-pager || true
    else
        log_info "Timer not enabled. Enable later with: sudo systemctl enable --now ntfs-update-check.timer"
    fi
}

deploy_apt_hook() {
    echo -e "${BLUE}Deploying APT hook...${NC}"
    
    if [ ! -f "$SCRIPT_DIR/apt-hook-ntfs-updater" ]; then
        log_error "APT hook file not found"
        return 1
    fi
    
    # Install APT hook
    cp "$SCRIPT_DIR/apt-hook-ntfs-updater" /etc/apt/apt.conf.d/99ntfs-updater
    chmod 644 /etc/apt/apt.conf.d/99ntfs-updater
    
    log_success "APT hook installed: /etc/apt/apt.conf.d/99ntfs-updater"
    log_info "NTFS will be checked for updates after kernel updates"
}

deploy_configuration() {
    echo -e "${BLUE}Deploying configuration file...${NC}"
    
    # Create config directory
    mkdir -p /etc/ntfs-installer
    
    # Check if config already exists
    if [ -f /etc/ntfs-installer/update-config.conf ]; then
        log_warn "Configuration file already exists"
        read -p "Overwrite existing configuration? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing configuration"
            return 0
        fi
    fi
    
    # Install template
    if [ -f "$SCRIPT_DIR/update-config.conf.template" ]; then
        cp "$SCRIPT_DIR/update-config.conf.template" /etc/ntfs-installer/update-config.conf
        chmod 644 /etc/ntfs-installer/update-config.conf
        log_success "Configuration installed: /etc/ntfs-installer/update-config.conf"
    else
        # Create basic config
        cat > /etc/ntfs-installer/update-config.conf << 'EOF'
# NTFS Update Configuration
UPDATE_FREQUENCY="weekly"
AUTO_UPDATE=false
NOTIFY_USER=true
CHECK_ON_KERNEL_UPDATE=true
EOF
        log_success "Basic configuration created"
    fi
    
    echo ""
    echo -e "${CYAN}Configuration Options:${NC}"
    echo "  Update Frequency: weekly (daily/weekly/monthly/manual)"
    echo "  Auto Update:      false (updates require manual approval)"
    echo "  Notifications:    true (desktop notifications enabled)"
    echo ""
    echo "Edit: /etc/ntfs-installer/update-config.conf"
}

run_initial_check() {
    echo -e "${BLUE}Running initial update check...${NC}"
    
    if [ -x /usr/local/bin/ntfs-update-check ]; then
        /usr/local/bin/ntfs-update-check status || true
    else
        log_warn "Update checker not executable"
    fi
}

show_summary() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  System Integration Deployment Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}Installed Components:${NC}"
    echo "  ${GREEN}✓${NC} Update checker:      /usr/local/bin/ntfs-update-check"
    echo "  ${GREEN}✓${NC} Systemd service:     /etc/systemd/system/ntfs-update-check.service"
    echo "  ${GREEN}✓${NC} Systemd timer:       /etc/systemd/system/ntfs-update-check.timer"
    echo "  ${GREEN}✓${NC} APT hook:            /etc/apt/apt.conf.d/99ntfs-updater"
    echo "  ${GREEN}✓${NC} Configuration:       /etc/ntfs-installer/update-config.conf"
    echo ""
    echo -e "${CYAN}Usage:${NC}"
    echo "  Check for updates:     sudo ntfs-update-check manual"
    echo "  View status:           sudo ntfs-update-check status"
    echo "  View timer status:     systemctl status ntfs-update-check.timer"
    echo "  Enable auto-updates:   Edit /etc/ntfs-installer/update-config.conf"
    echo ""
    echo -e "${CYAN}Timer Management:${NC}"
    echo "  Enable:                sudo systemctl enable --now ntfs-update-check.timer"
    echo "  Disable:               sudo systemctl disable --now ntfs-update-check.timer"
    echo "  Check next run:        systemctl list-timers ntfs-update-check.timer"
    echo ""
}

#############################################
# Main
#############################################

main() {
    show_header
    check_root
    
    echo "This will install:"
    echo "  • Update checker script"
    echo "  • Systemd timer for scheduled checks"
    echo "  • APT hook for kernel update detection"
    echo "  • Configuration file"
    echo ""
    
    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
    
    echo ""
    
    # Deploy components
    deploy_update_checker || log_error "Failed to deploy update checker"
    echo ""
    
    deploy_systemd_units || log_error "Failed to deploy systemd units"
    echo ""
    
    deploy_apt_hook || log_error "Failed to deploy APT hook"
    echo ""
    
    deploy_configuration || log_error "Failed to deploy configuration"
    echo ""
    
    run_initial_check
    
    show_summary
}

main "$@"
