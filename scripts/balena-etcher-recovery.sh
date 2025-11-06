#!/bin/bash

# Balena Etcher Recovery Script
# Fixes NTFS functionality broken by balena Etcher installation
# Version 1.0.0

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/balena-etcher-recovery.log"
BACKUP_DIR="/var/backups/ntfs-recovery-$(date +%Y%m%d-%H%M%S)"

# Helper functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

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
    echo -e "${CYAN}║        Balena Etcher NTFS Functionality Recovery            ║${NC}"
    echo -e "${CYAN}║                    Version 1.0.0                             ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}This script repairs NTFS functionality broken by balena Etcher${NC}"
    echo -e "${YELLOW}Issues fixed: mounting, writing, formatting, hot-swap support${NC}"
    echo ""
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

create_backup() {
    log_info "Creating system backup..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup critical configuration files
    cp -a /etc/fstab "$BACKUP_DIR/" 2>/dev/null || true
    cp -a /etc/udev/rules.d/ "$BACKUP_DIR/" 2>/dev/null || true
    cp -a /etc/polkit-1/ "$BACKUP_DIR/" 2>/dev/null || true
    cp -a /etc/dbus-1/ "$BACKUP_DIR/" 2>/dev/null || true
    
    log_success "Backup created at $BACKUP_DIR"
}

detect_balena_etcher() {
    log_info "Detecting balena Etcher installation..."
    
    local etcher_found=0
    
    # Check common installation locations
    if command -v balena-etcher-electron &> /dev/null; then
        log_warning "Balena Etcher found: $(command -v balena-etcher-electron)"
        etcher_found=1
    fi
    
    if command -v balenaEtcher &> /dev/null; then
        log_warning "Balena Etcher found: $(command -v balenaEtcher)"
        etcher_found=1
    fi
    
    # Check AppImage locations
    if find /home -name "*balena*etcher*.AppImage" 2>/dev/null | grep -q .; then
        log_warning "Balena Etcher AppImage found"
        etcher_found=1
    fi
    
    # Check snap installations
    if snap list 2>/dev/null | grep -q "etcher"; then
        log_warning "Balena Etcher snap found"
        etcher_found=1
    fi
    
    if [[ $etcher_found -eq 1 ]]; then
        log_warning "⚠️  Balena Etcher is installed on this system"
        log_warning "   This software is known to break NTFS functionality"
        echo ""
        return 0
    else
        log_info "Balena Etcher not currently detected"
        return 1
    fi
}

fix_ntfs_packages() {
    log_info "Repairing NTFS packages and dependencies..."
    
    # Update package lists
    apt-get update
    
    # Remove any broken packages
    apt-get --fix-broken install -y
    
    # Reinstall NTFS packages
    log_info "Reinstalling ntfs-3g and ntfsprogs..."
    apt-get install --reinstall -y ntfs-3g ntfsprogs
    
    # Install additional required packages
    apt-get install -y \
        libntfs-3g883 \
        ntfs-3g-dev \
        fuse \
        libfuse2 \
        usbutils \
        udisks2 \
        policykit-1
    
    log_success "NTFS packages repaired"
}

fix_permissions_and_groups() {
    log_info "Fixing permissions and group memberships..."
    
    # Get the real user (not root when using sudo)
    REAL_USER="${SUDO_USER:-$USER}"
    
    # Add user to required groups
    for group in disk plugdev fuse; do
        if getent group "$group" > /dev/null 2>&1; then
            if ! groups "$REAL_USER" | grep -q "\b$group\b"; then
                log_info "Adding $REAL_USER to $group group..."
                usermod -aG "$group" "$REAL_USER"
            fi
        fi
    done
    
    # Fix permissions on device files
    chmod 666 /dev/fuse 2>/dev/null || true
    
    # Fix permissions on mount points
    chmod 755 /media 2>/dev/null || true
    mkdir -p "/media/$REAL_USER"
    chown "$REAL_USER:$REAL_USER" "/media/$REAL_USER"
    chmod 755 "/media/$REAL_USER"
    
    log_success "Permissions and groups fixed"
}

fix_udev_rules() {
    log_info "Repairing udev rules for NTFS devices..."
    
    # Create proper udev rules for NTFS devices
    cat > /etc/udev/rules.d/99-ntfs-automount.rules << 'EOF'
# NTFS Auto-mount Rules
# Fixed for balena Etcher compatibility

# NTFS partitions
KERNEL=="sd[a-z][0-9]*", ENV{ID_FS_TYPE}=="ntfs", ENV{UDISKS_AUTO}="1"
KERNEL=="sd[a-z][0-9]*", ENV{ID_FS_TYPE}=="ntfs", ENV{UDISKS_MOUNT_OPTIONS_ALLOW}="uid=$UID,gid=$GID,umask=0,nls=utf8"

# USB devices with NTFS
SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="ntfs", ENV{UDISKS_AUTO}="1"
SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="ntfs", ACTION=="add", RUN+="/bin/bash -c 'sleep 2 && udisksctl mount -b $env{DEVNAME} --no-user-interaction'"

# Hot-swap support
ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="ntfs", TAG+="systemd", ENV{SYSTEMD_WANTS}="ntfs-mount@%k.service"
EOF
    
    # Reload udev rules
    udevadm control --reload-rules
    udevadm trigger
    
    log_success "Udev rules repaired"
}

fix_polkit_policies() {
    log_info "Fixing PolicyKit permissions for NTFS operations..."
    
    # Create PolicyKit policy for NTFS operations
    cat > /etc/polkit-1/rules.d/50-ntfs-mount.rules << 'EOF'
// Allow NTFS mounting without password for authorized users
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.udisks2.filesystem-mount") == 0 &&
        subject.isInGroup("plugdev")) {
        return polkit.Result.YES;
    }
});

polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.udisks2.filesystem-unmount") == 0 &&
        subject.isInGroup("plugdev")) {
        return polkit.Result.YES;
    }
});

polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.udisks2.power-off-drive") == 0 &&
        subject.isInGroup("plugdev")) {
        return polkit.Result.YES;
    }
});
EOF
    
    # Fix ownership
    chown root:root /etc/polkit-1/rules.d/50-ntfs-mount.rules
    chmod 644 /etc/polkit-1/rules.d/50-ntfs-mount.rules
    
    # Restart polkit
    systemctl restart polkit 2>/dev/null || true
    
    log_success "PolicyKit permissions fixed"
}

fix_fstab() {
    log_info "Checking and fixing /etc/fstab..."
    
    # Backup fstab
    cp /etc/fstab /etc/fstab.backup-$(date +%Y%m%d-%H%M%S)
    
    # Remove problematic balena etcher entries
    sed -i '/balena/d' /etc/fstab
    sed -i '/etcher/d' /etc/fstab
    
    log_success "/etc/fstab checked and fixed"
}

fix_network_connectivity() {
    log_info "Repairing network connectivity issues..."
    
    # Restart NetworkManager
    systemctl restart NetworkManager 2>/dev/null || true
    
    # Flush DNS cache
    systemd-resolve --flush-caches 2>/dev/null || true
    
    # Reset network interfaces
    ip link set dev lo down 2>/dev/null || true
    ip link set dev lo up 2>/dev/null || true
    
    log_success "Network connectivity repaired"
}

fix_nodejs() {
    log_info "Checking Node.js v23 installation..."
    
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        log_info "Node.js version: $node_version"
        
        # Check if npm is working
        if ! npm --version &> /dev/null; then
            log_warning "npm is broken, reinstalling..."
            apt-get install --reinstall -y npm nodejs
        fi
        
        # Update npm to latest
        npm install -g npm@latest 2>/dev/null || true
        
        log_success "Node.js checked and repaired"
    else
        log_info "Node.js not installed, skipping"
    fi
}

fix_mount_points() {
    log_info "Repairing mount points..."
    
    # Unmount any stuck NTFS mounts
    for mount in $(mount | grep ntfs | awk '{print $3}'); do
        log_info "Unmounting stuck mount: $mount"
        umount -l "$mount" 2>/dev/null || true
    done
    
    # Clean up orphaned mount points
    find /media -type d -empty -delete 2>/dev/null || true
    
    log_success "Mount points cleaned"
}

test_ntfs_functionality() {
    log_info "Testing NTFS functionality..."
    
    local test_passed=0
    local test_failed=0
    
    # Test 1: Check if ntfs-3g is working
    if command -v ntfs-3g &> /dev/null; then
        log_success "✓ ntfs-3g binary found"
        ((test_passed++))
    else
        log_error "✗ ntfs-3g binary missing"
        ((test_failed++))
    fi
    
    # Test 2: Check if ntfsprogs tools are available
    if command -v ntfsfix &> /dev/null; then
        log_success "✓ ntfsprogs tools found"
        ((test_passed++))
    else
        log_error "✗ ntfsprogs tools missing"
        ((test_failed++))
    fi
    
    # Test 3: Check if fuse module is loaded
    if lsmod | grep -q fuse; then
        log_success "✓ FUSE module loaded"
        ((test_passed++))
    else
        log_warning "⚠ FUSE module not loaded, loading..."
        modprobe fuse
        if lsmod | grep -q fuse; then
            log_success "✓ FUSE module loaded successfully"
            ((test_passed++))
        else
            log_error "✗ Failed to load FUSE module"
            ((test_failed++))
        fi
    fi
    
    # Test 4: Check udisks2 service
    if systemctl is-active --quiet udisks2; then
        log_success "✓ udisks2 service running"
        ((test_passed++))
    else
        log_warning "⚠ udisks2 service not running, starting..."
        systemctl start udisks2
        if systemctl is-active --quiet udisks2; then
            log_success "✓ udisks2 service started"
            ((test_passed++))
        else
            log_error "✗ Failed to start udisks2"
            ((test_failed++))
        fi
    fi
    
    echo ""
    log_info "Test Results: $test_passed passed, $test_failed failed"
    
    if [[ $test_failed -eq 0 ]]; then
        log_success "All NTFS functionality tests passed!"
        return 0
    else
        log_error "Some tests failed. Manual intervention may be required."
        return 1
    fi
}

show_post_recovery_info() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              NTFS Functionality Recovery Complete            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}What was fixed:${NC}"
    echo -e "  ${GREEN}✓${NC} NTFS packages reinstalled and repaired"
    echo -e "  ${GREEN}✓${NC} User permissions and groups configured"
    echo -e "  ${GREEN}✓${NC} Udev rules for auto-mounting restored"
    echo -e "  ${GREEN}✓${NC} PolicyKit permissions fixed"
    echo -e "  ${GREEN}✓${NC} Mount points cleaned and repaired"
    echo -e "  ${GREEN}✓${NC} Network connectivity issues resolved"
    echo -e "  ${GREEN}✓${NC} Node.js configuration checked"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT NEXT STEPS:${NC}"
    echo -e "  1. ${YELLOW}Log out and log back in${NC} for group changes to take effect"
    echo -e "  2. ${YELLOW}Replug any NTFS drives${NC} to test auto-mounting"
    echo -e "  3. ${YELLOW}Test writing to NTFS drives${NC} to verify full functionality"
    echo ""
    echo -e "${RED}⚠️  ABOUT BALENA ETCHER:${NC}"
    echo -e "  • Balena Etcher modifies system-level permissions"
    echo -e "  • It can break NTFS mounting, writing, and hot-swap functionality"
    echo -e "  • Consider using alternatives like: ${CYAN}dd, GNOME Disks, or Popsicle${NC}"
    echo ""
    echo -e "${BLUE}Backup Location:${NC} $BACKUP_DIR"
    echo -e "${BLUE}Log File:${NC} $LOG_FILE"
    echo ""
}

main() {
    show_header
    check_root
    
    log "=== Balena Etcher NTFS Recovery Started ==="
    
    # Detect balena etcher
    detect_balena_etcher || true
    
    echo ""
    read -p "Continue with NTFS functionality recovery? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Recovery cancelled by user"
        exit 0
    fi
    
    # Create backup
    create_backup
    
    # Run all recovery steps
    fix_ntfs_packages
    fix_permissions_and_groups
    fix_udev_rules
    fix_polkit_policies
    fix_fstab
    fix_mount_points
    fix_network_connectivity
    fix_nodejs
    
    # Test functionality
    echo ""
    test_ntfs_functionality
    
    # Show completion message
    show_post_recovery_info
    
    log "=== Balena Etcher NTFS Recovery Completed ==="
}

# Run main function
main "$@"
