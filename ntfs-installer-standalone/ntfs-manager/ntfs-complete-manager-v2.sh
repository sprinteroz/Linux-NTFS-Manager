#!/bin/bash

#############################################
# Complete NTFS Solution Manager v2.0
# Enhanced with version management
# 
# Unified installer/updater/uninstaller for:
# - ntfsprogs-plus (utilities)
# - NTFSplus (kernel driver)
# - ntfs-3g (additional utilities)
#############################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
NTFSPROGS_REPO="https://github.com/ntfsprogs-plus/ntfsprogs-plus.git"
NTFSPLUS_REPO="https://github.com/namjaejeon/ntfs-kernel.git"
NTFSPLUS_BRANCH="ntfsplus"
BUILD_DIR="/tmp/ntfs-complete-build-$$"
DKMS_NAME="ntfsplus"
DKMS_VERSION="2025.10.20"
LOG_FILE="/tmp/ntfs-complete-$$.log"
STATE_DIR="/usr/local/share/ntfs-complete"
PROGS_MANIFEST="$STATE_DIR/ntfsprogs-manifest.txt"
DRIVER_MARKER="$STATE_DIR/ntfsplus-installed"
VERSION_FILE="$STATE_DIR/versions.txt"

# Progress tracking
STEP=0
TOTAL_STEPS=0

#############################################
# Helper Functions
#############################################

print_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Complete NTFS Solution Manager v2.0${NC}"
    echo -e "${CYAN}  Unified Management with Version Control${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    ((STEP++))
    echo ""
    echo -e "${GREEN}[Step $STEP/$TOTAL_STEPS]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗ ERROR:${NC} $1" >&2
    echo "Check log file: $LOG_FILE" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠ WARNING:${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

cleanup_on_error() {
    print_error "Operation failed!"
    if [ -d "$BUILD_DIR" ]; then
        print_info "Cleaning up temporary files..."
        rm -rf "$BUILD_DIR"
    fi
    print_info "Log file preserved at: $LOG_FILE"
    exit 1
}

#############################################
# Version Management
#############################################

get_installed_version() {
    local component="$1"
    
    if [ ! -f "$VERSION_FILE" ]; then
        echo "unknown"
        return
    fi
    
    grep "^${component}=" "$VERSION_FILE" 2>/dev/null | cut -d= -f2 || echo "unknown"
}

save_version() {
    local component="$1"
    local version="$2"
    
    mkdir -p "$STATE_DIR"
    
    # Remove old entry if exists
    if [ -f "$VERSION_FILE" ]; then
        grep -v "^${component}=" "$VERSION_FILE" > "${VERSION_FILE}.tmp" 2>/dev/null || true
        mv "${VERSION_FILE}.tmp" "$VERSION_FILE"
    fi
    
    # Add new entry
    echo "${component}=${version}" >> "$VERSION_FILE"
    log "Saved version: $component=$version"
}

get_latest_release() {
    local repo="$1"
    
    # Try to get latest release tag
    local latest=$(git ls-remote --tags --refs "$repo" | grep -v '\^{}' | tail -n1 | sed 's/.*\///' || echo "")
    
    if [ -n "$latest" ]; then
        echo "$latest"
    else
        echo "main"
    fi
}

get_current_commit() {
    local repo_dir="$1"
    cd "$repo_dir"
    git rev-parse --short HEAD 2>/dev/null || echo "unknown"
}

check_for_updates() {
    local component="$1"
    local repo="$2"
    
    print_info "Checking for updates to $component..."
    
    local current_version=$(get_installed_version "$component")
    print_info "Current version: $current_version"
    
    # Get latest release
    local latest_release=$(get_latest_release "$repo")
    print_info "Latest release: $latest_release"
    
    if [ "$current_version" = "unknown" ]; then
        echo "not_installed"
    elif [ "$current_version" = "$latest_release" ]; then
        echo "up_to_date"
    else
        echo "update_available"
    fi
}

#############################################
# System Checks
#############################################

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_kernel_version() {
    local KERNEL_VERSION=$(uname -r | cut -d. -f1,2)
    local MAJOR=$(echo $KERNEL_VERSION | cut -d. -f1)
    local MINOR=$(echo $KERNEL_VERSION | cut -d. -f2)
    
    if [ "$MAJOR" -lt 6 ] || ([ "$MAJOR" -eq 6 ] && [ "$MINOR" -lt 2 ]); then
        return 1
    fi
    return 0
}

#############################################
# Scanning Functions
#############################################

scan_system() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  System Scan${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    print_info "Scanning system for existing NTFS components..."
    
    # Check kernel version
    echo -n "Kernel Version: "
    if check_kernel_version; then
        echo -e "${GREEN}$(uname -r) ✓${NC} (6.2+ required for NTFSplus)"
    else
        echo -e "${YELLOW}$(uname -r) ⚠${NC} (Upgrade needed for NTFSplus)"
    fi
    
    # Version information
    echo ""
    echo "Installed Versions:"
    
    local ntfsprogs_ver=$(get_installed_version "ntfsprogs-plus")
    echo "  ntfsprogs-plus: $ntfsprogs_ver"
    
    local ntfsplus_ver=$(get_installed_version "ntfsplus")
    echo "  NTFSplus:       $ntfsplus_ver"
    
    local ntfs3g_ver=$(get_installed_version "ntfs-3g")
    if dpkg -s ntfs-3g >/dev/null 2>&1; then
        ntfs3g_ver=$(dpkg -s ntfs-3g | grep '^Version:' | awk '{print $2}')
    fi
    echo "  ntfs-3g:        ${ntfs3g_ver:-not installed}"
    
    # Check ntfsprogs-plus utilities
    echo ""
    echo "ntfsprogs-plus Utilities:"
    local PROGS_BINARIES=("ntfsck" "ntfsclone" "ntfscluster" "ntfsinfo")
    local PROGS_INSTALLED=false
    
    for binary in "${PROGS_BINARIES[@]}"; do
        if command -v "$binary" &> /dev/null; then
            local LOCATION=$(which "$binary")
            echo -e "  ${GREEN}✓${NC} $binary: $LOCATION"
            PROGS_INSTALLED=true
        else
            echo -e "  ${RED}✗${NC} $binary: Not installed"
        fi
    done
    
    # Check ntfs-3g utilities
    echo ""
    echo "ntfs-3g Additional Utilities:"
    local NTFS3G_BINARIES=("ntfsresize" "ntfsundelete" "ntfslabel" "mkntfs" "ntfsfix")
    
    for binary in "${NTFS3G_BINARIES[@]}"; do
        if command -v "$binary" &> /dev/null; then
            local LOCATION=$(which "$binary")
            echo -e "  ${GREEN}✓${NC} $binary: $LOCATION"
        else
            echo -e "  ${YELLOW}○${NC} $binary: Not installed"
        fi
    done
    
    # Check NTFSplus driver
    echo ""
    echo "NTFSplus Kernel Driver:"
    
    if dkms status -m "$DKMS_NAME" -v "$DKMS_VERSION" >/dev/null 2>&1; then
        local STATUS=$(dkms status -m "$DKMS_NAME" -v "$DKMS_VERSION")
        echo -e "  ${GREEN}✓${NC} DKMS Module: $STATUS"
    else
        echo -e "  ${RED}✗${NC} DKMS Module: Not installed"
    fi
    
    if lsmod | grep -q "^ntfsplus "; then
        echo -e "  ${GREEN}✓${NC} Module Status: Loaded"
    else
        echo -e "  ${YELLOW}⚠${NC} Module Status: Not loaded"
    fi
    
    # Check for updates
    echo ""
    echo "Update Status:"
    
    if [ -f "$PROGS_MANIFEST" ]; then
        local update_status=$(check_for_updates "ntfsprogs-plus" "$NTFSPROGS_REPO")
        case "$update_status" in
            "up_to_date")
                echo -e "  ${GREEN}✓${NC} ntfsprogs-plus: Up to date"
                ;;
            "update_available")
                echo -e "  ${YELLOW}⚠${NC} ntfsprogs-plus: Update available"
                ;;
            *)
                echo -e "  ${BLUE}ℹ${NC} ntfsprogs-plus: $update_status"
                ;;
        esac
    fi
    
    if [ -f "$DRIVER_MARKER" ]; then
        local update_status=$(check_for_updates "ntfsplus" "$NTFSPLUS_REPO")
        case "$update_status" in
            "up_to_date")
                echo -e "  ${GREEN}✓${NC} NTFSplus: Up to date"
                ;;
            "update_available")
                echo -e "  ${YELLOW}⚠${NC} NTFSplus: Update available"
                ;;
            *)
                echo -e "  ${BLUE}ℹ${NC} NTFSplus: $update_status"
                ;;
        esac
    fi
    
    # Check other tools
    echo ""
    echo "GUI Tools:"
    
    if dpkg -s gparted >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} GParted: Installed"
    else
        echo -e "  ${YELLOW}○${NC} GParted: Not installed (optional)"
    fi
    
    # Check for conflicts
    echo ""
    echo "Mounted NTFS Partitions:"
    local MOUNTED=$(mount | grep "type ntfs" || true)
    if [ -n "$MOUNTED" ]; then
        echo "$MOUNTED" | while read -r line; do
            echo -e "  ${BLUE}ℹ${NC} $line"
        done
    else
        echo -e "  ${GREEN}✓${NC} No NTFS partitions currently mounted"
    fi
    
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

#############################################
# Dependency Installation
#############################################

install_dependencies() {
    print_step "Installing dependencies..."
    
    local DEPS=(
        "build-essential"
        "automake"
        "autoconf"
        "libtool"
        "libgcrypt20-dev"
        "pkg-config"
        "git"
        "dkms"
        "linux-headers-$(uname -r)"
        "bc"
        "kmod"
    )
    
    local MISSING_DEPS=()
    
    for dep in "${DEPS[@]}"; do
        if [[ "$dep" == linux-headers-* ]]; then
            if ! dpkg -s "$dep" >/dev/null 2>&1; then
                MISSING_DEPS+=("$dep")
            fi
        else
            if ! dpkg -s "$dep" >/dev/null 2>&1; then
                MISSING_DEPS+=("$dep")
            fi
        fi
    done
    
    if [ ${#MISSING_DEPS[@]} -eq 0 ]; then
        print_success "All dependencies already installed"
        return 0
    fi
    
    print_info "Missing dependencies: ${MISSING_DEPS[*]}"
    log "Installing dependencies: ${MISSING_DEPS[*]}"
    
    print_info "Updating package lists..."
    if ! apt-get update >> "$LOG_FILE" 2>&1; then
        print_error "Failed to update package lists"
        cleanup_on_error
    fi
    
    print_info "Installing missing dependencies..."
    if ! apt-get install -y "${MISSING_DEPS[@]}" >> "$LOG_FILE" 2>&1; then
        print_error "Failed to install dependencies"
        cleanup_on_error
    fi
    
    print_success "Dependencies installed successfully"
    log "Dependencies installed: ${MISSING_DEPS[*]}"
}

#############################################
# ntfsprogs-plus Installation
#############################################

install_ntfsprogs_plus() {
    local use_version="${1:-latest}"
    
    print_step "Installing ntfsprogs-plus utilities..."
    
    mkdir -p "$BUILD_DIR" || cleanup_on_error
    cd "$BUILD_DIR" || cleanup_on_error
    
    print_info "Cloning ntfsprogs-plus repository..."
    if ! git clone "$NTFSPROGS_REPO" >> "$LOG_FILE" 2>&1; then
        print_error "Failed to clone ntfsprogs-plus"
        cleanup_on_error
    fi
    
    cd ntfsprogs-plus || cleanup_on_error
    
    # Checkout specific version if requested
    if [ "$use_version" != "latest" ] && [ "$use_version" != "main" ]; then
        print_info "Checking out version: $use_version"
        if ! git checkout "$use_version" >> "$LOG_FILE" 2>&1; then
            print_warning "Failed to checkout $use_version, using main branch"
        fi
    else
        # Get latest stable release
        local latest_release=$(git tag -l | grep -E '^v?[0-9]' | sort -V | tail -n1 || echo "")
        if [ -n "$latest_release" ]; then
            print_info "Using latest release: $latest_release"
            git checkout "$latest_release" >> "$LOG_FILE" 2>&1 || true
            use_version="$latest_release"
        else
            use_version="main-$(git rev-parse --short HEAD)"
        fi
    fi
    
    local COMMIT=$(git rev-parse --short HEAD)
    print_info "Commit: $COMMIT"
    
    # Build
    print_info "Running autogen.sh..."
    if ! ./autogen.sh >> "$LOG_FILE" 2>&1; then
        print_error "autogen.sh failed"
        cleanup_on_error
    fi
    
    print_info "Configuring..."
    if ! ./configure >> "$LOG_FILE" 2>&1; then
        print_error "configure failed"
        cleanup_on_error
    fi
    
    print_info "Compiling (using $(nproc) cores)..."
    if ! make -j$(nproc) >> "$LOG_FILE" 2>&1; then
        print_error "Build failed"
        cleanup_on_error
    fi
    
    # Create manifest
    mkdir -p "$STATE_DIR"
    local TEMP_BEFORE="/tmp/files-before-$$.txt"
    find /usr/local/bin /usr/local/lib /usr/local/sbin /usr/local/share 2>/dev/null | sort > "$TEMP_BEFORE" || true
    
    print_info "Installing to /usr/local..."
    if ! make install >> "$LOG_FILE" 2>&1; then
        print_error "Installation failed"
        rm -f "$TEMP_BEFORE"
        cleanup_on_error
    fi
    
    # Generate manifest
    local TEMP_AFTER="/tmp/files-after-$$.txt"
    find /usr/local/bin /usr/local/lib /usr/local/sbin /usr/local/share 2>/dev/null | sort > "$TEMP_AFTER" || true
    comm -13 "$TEMP_BEFORE" "$TEMP_AFTER" > "$PROGS_MANIFEST"
    rm -f "$TEMP_BEFORE" "$TEMP_AFTER"
    
    # Update library cache
    ldconfig >> "$LOG_FILE" 2>&1 || true
    
    # Save version
    save_version "ntfsprogs-plus" "$use_version"
    
    local FILE_COUNT=$(wc -l < "$PROGS_MANIFEST")
    print_success "ntfsprogs-plus $use_version installed ($FILE_COUNT files)"
    log "ntfsprogs-plus installed: version=$use_version, files=$FILE_COUNT"
}

update_ntfsprogs_plus() {
    print_step "Updating ntfsprogs-plus utilities..."
    
    local current_version=$(get_installed_version "ntfsprogs-plus")
    print_info "Current version: $current_version"
    
    # Check for updates
    local latest_release=$(get_latest_release "$NTFSPROGS_REPO")
    print_info "Latest release: $latest_release"
    
    if [ "$current_version" = "$latest_release" ] && [ "$current_version" != "unknown" ]; then
        print_success "Already at latest version"
        return 0
    fi
    
    # Uninstall old version
    if [ -f "$PROGS_MANIFEST" ]; then
        print_info "Removing old version ($current_version)..."
        while IFS= read -r file; do
            [ -e "$file" ] && rm -f "$file" 2>/dev/null
        done < "$PROGS_MANIFEST"
    fi
    
    # Install new version
    install_ntfsprogs_plus "$latest_release"
    
    print_success "Updated from $current_version to $latest_release"
}

uninstall_ntfsprogs_plus() {
    print_info "Uninstalling ntfsprogs-plus..."
    
    if [ ! -f "$PROGS_MANIFEST" ]; then
        print_warning "Manifest not found, attempting manual removal"
        
        local BINARIES=("ntfsck" "ntfsclone" "ntfscluster" "ntfsinfo")
        for binary in "${BINARIES[@]}"; do
            rm -f "/usr/local/bin/$binary" 2>/dev/null
            rm -f "/usr/local/sbin/$binary" 2>/dev/null
        done
        
        return 0
    fi
    
    local REMOVED=0
    while IFS= read -r file; do
        if [ -e "$file" ]; then
            rm -f "$file" 2>/dev/null && ((REMOVED++))
        fi
    done < "$PROGS_MANIFEST"
    
    rm -f "$PROGS_MANIFEST"
    
    # Remove version entry
    if [ -f "$VERSION_FILE" ]; then
        grep -v "^ntfsprogs-plus=" "$VERSION_FILE" > "${VERSION_FILE}.tmp" 2>/dev/null || true
        mv "${VERSION_FILE}.tmp" "$VERSION_FILE" 2>/dev/null || true
    fi
    
    # Update library cache
    ldconfig >> "$LOG_FILE" 2>&1 || true
    
    print_success "ntfsprogs-plus uninstalled ($REMOVED files removed)"
}

#############################################
# NTFSplus Driver Installation
#############################################

install_ntfsplus_driver() {
    local use_version="${1:-latest}"
    
    print_step "Installing NTFSplus kernel driver..."
    
    if ! check_kernel_version; then
        print_error "NTFSplus requires kernel 6.2 or later"
        print_info "Your kernel: $(uname -r)"
        print_info "Upgrade command: sudo apt install linux-generic-hwe-24.04"
        return 1
    fi
    
    cd "$BUILD_DIR" || cleanup_on_error
    
    print_info "Cloning NTFSplus kernel source..."
    print_info "Branch: $NTFSPLUS_BRANCH"
    
    if ! git clone -b "$NTFSPLUS_BRANCH" "$NTFSPLUS_REPO" ntfs-kernel >> "$LOG_FILE" 2>&1; then
        print_warning "Failed to clone ntfsplus branch"
        print_info "The ntfsplus branch may not be available yet"
        print_info "Visit: https://github.com/namjaejeon/ntfs-kernel for updates"
        return 1
    fi
    
    cd ntfs-kernel || cleanup_on_error
    
    # Checkout specific version if needed
    if [ "$use_version" != "latest" ] && [ "$use_version" != "main" ]; then
        print_info "Checking out version: $use_version"
        git checkout "$use_version" >> "$LOG_FILE" 2>&1 || true
    fi
    
    local COMMIT=$(git rev-parse --short HEAD)
    print_info "Commit: $COMMIT"
    use_version="${NTFSPLUS_BRANCH}-${COMMIT}"
    
    # Find ntfsplus source directory
    local NTFSPLUS_DIR=$(find . -type d -name ntfsplus -o -name fs/ntfsplus 2>/dev/null | head -n1)
    
    if [ -z "$NTFSPLUS_DIR" ]; then
        print_error "Could not find ntfsplus source directory"
        return 1
    fi
    
    print_info "Found source at: $NTFSPLUS_DIR"
    
    # Create DKMS configuration
    cat > "$NTFSPLUS_DIR/dkms.conf" << EOF
PACKAGE_NAME="$DKMS_NAME"
PACKAGE_VERSION="$DKMS_VERSION"
BUILT_MODULE_NAME[0]="ntfsplus"
DEST_MODULE_LOCATION[0]="/updates/dkms"
AUTOINSTALL="yes"
REMAKE_INITRD="no"
EOF
    
    # Copy to DKMS directory
    local DKMS_SOURCE="/usr/src/$DKMS_NAME-$DKMS_VERSION"
    print_info "Installing to $DKMS_SOURCE..."
    
    mkdir -p "$DKMS_SOURCE"
    cp -r "$NTFSPLUS_DIR"/* "$DKMS_SOURCE/" || cleanup_on_error
    
    # Add to DKMS
    print_info "Adding to DKMS..."
    dkms remove -m "$DKMS_NAME" -v "$DKMS_VERSION" --all >> "$LOG_FILE" 2>&1 || true
    
    if ! dkms add -m "$DKMS_NAME" -v "$DKMS_VERSION" >> "$LOG_FILE" 2>&1; then
        print_error "Failed to add DKMS module"
        return 1
    fi
    
    # Build
    print_info "Building module (this may take 2-5 minutes)..."
    if ! dkms build -m "$DKMS_NAME" -v "$DKMS_VERSION" >> "$LOG_FILE" 2>&1; then
        print_error "Failed to build DKMS module"
        return 1
    fi
    
    # Install
    print_info "Installing module..."
    if ! dkms install -m "$DKMS_NAME" -v "$DKMS_VERSION" >> "$LOG_FILE" 2>&1; then
        print_error "Failed to install DKMS module"
        return 1
    fi
    
    # Configure system
    print_info "Configuring system..."
    
    # Create udev rule
    cat > /etc/udev/rules.d/90-ntfsplus.rules << 'EOF'
# Prefer ntfsplus over ntfs3 for NTFS filesystems
ENV{ID_FS_TYPE}=="ntfs", ENV{ID_FS_TYPE}="ntfsplus"
EOF
    
    # Module autoload
    echo "ntfsplus" > /etc/modules-load.d/ntfsplus.conf
    
    # Update module dependencies
    depmod -a
    
    # Try to load module
    if modprobe ntfsplus >> "$LOG_FILE" 2>&1; then
        print_success "Module loaded successfully"
    else
        print_warning "Module will be available after reboot"
    fi
    
    # Create marker and save version
    mkdir -p "$STATE_DIR"
    cat > "$DRIVER_MARKER" << EOF
NTFSplus Installation
=====================
Installed: $(date)
Version: $use_version
Kernel: $(uname -r)
Commit: $COMMIT
EOF
    
    save_version "ntfsplus" "$use_version"
    
    print_success "NTFSplus driver $use_version installed"
    log "NTFSplus installed: version=$use_version"
    
    return 0
}

update_ntfsplus_driver() {
    print_step "Updating NTFSplus kernel driver..."
    
    local current_version=$(get_installed_version "ntfsplus")
    print_info "Current version: $current_version"
    
    # Unload module if loaded
    if lsmod | grep -q "^ntfsplus "; then
        print_info "Unloading module..."
        modprobe -r ntfsplus >> "$LOG_FILE" 2>&1 || true
    fi
    
    # Remove old DKMS version
    if dkms status -m "$DKMS_NAME" -v "$DKMS_VERSION" >/dev/null 2>&1; then
        print_info "Removing old DKMS version..."
        dkms remove -m "$DKMS_NAME" -v "$DKMS_VERSION" --all >> "$LOG_FILE" 2>&1 || true
    fi
    
    # Install new version
    install_ntfsplus_driver "latest"
    
    local new_version=$(get_installed_version "ntfsplus")
    print_success "Updated from $current_version to $new_version"
}

uninstall_ntfsplus_driver() {
    print_info "Uninstalling NTFSplus driver..."
    
    # Check for mounted partitions
    local MOUNTED=$(mount | grep "type ntfsplus" || true)
    if [ -n "$MOUNTED" ]; then
        print_warning "NTFSplus partitions are mounted:"
        echo "$MOUNTED"
        print_info "Unmounting..."
        
        mount | grep "type ntfsplus" | awk '{print $3}' | while read -r mountpoint; do
            umount "$mountpoint" 2>/dev/null || true
        done
    fi
    
    # Unload module
    if lsmod | grep -q "^ntfsplus "; then
        print_info "Unloading module..."
        modprobe -r ntfsplus >> "$LOG_FILE" 2>&1 || true
    fi
    
    # Remove DKMS module
    if dkms status -m "$DKMS_NAME" >/dev/null 2>&1; then
        print_info "Removing DKMS module..."
        dkms remove -m "$DKMS_NAME" -v "$DKMS_VERSION" --all >> "$LOG_FILE" 2>&1 || true
    fi
    
    # Remove source
    rm -rf "/usr/src/$DKMS_NAME-"* 2>/dev/null || true
    
    # Remove configuration
    rm -f /etc/udev/rules.d/90-ntfsplus.rules
    rm -f /etc/modules-load.d/ntfsplus.conf
    rm -f "$DRIVER_MARKER"
    
    # Remove version entry
    if [ -f "$VERSION_FILE" ]; then
        grep -v "^ntfsplus=" "$VERSION_FILE" > "${VERSION_FILE}.tmp" 2>/dev/null || true
        mv "${VERSION_FILE}.tmp" "$VERSION_FILE" 2>/dev/null || true
    fi
    
    # Update modules
    depmod -a
    
    print_success "NTFSplus driver uninstalled"
}

#############################################
# Optional Components (ntfs-3g + GParted)
#############################################

install_optional_components() {
    print_step "Installing optional components..."
    
    local OPTIONAL=()
    
    # Check for ntfs-3g (provides additional utilities)
    if ! dpkg -s ntfs-3g >/dev/null 2>&1; then
        OPTIONAL+=("ntfs-3g")
        print_info "Will install ntfs-3g (ntfsresize, ntfsundelete, ntfslabel, mkntfs, etc.)"
    else
        print_info "ntfs-3g already installed"
        # Save version
        local version=$(dpkg -s ntfs-3g | grep '^Version:' | awk '{print $2}')
        save_version "ntfs-3g" "$version"
    fi
    
    # Check for GParted (GUI partition manager)
    if ! dpkg -s gparted >/dev/null 2>&1; then
        OPTIONAL+=("gparted")
        print_info "Will install GParted (GUI partition manager)"
    else
        print_info "GParted already installed"
    fi
    
    if [ ${#OPTIONAL[@]} -eq 0 ]; then
        print_success "Optional components already installed"
        return 0
    fi
    
    print_info "Installing: ${OPTIONAL[*]}"
    
    if apt-get install -y "${OPTIONAL[@]}" >> "$LOG_FILE" 2>&1; then
        print_success "Optional components installed"
        
        # Save ntfs-3g version if just installed
        if [[ " ${OPTIONAL[@]} " =~ " ntfs-3g " ]]; then
            local version=$(dpkg -s ntfs-3g | grep '^Version:' | awk '{print $2}')
            save_version "ntfs-3g" "$version"
        fi
    else
        print_warning "Some optional components failed to install"
    fi
}

update_optional_components() {
    print_info "Updating optional components..."
    
    local TO_UPDATE=()
    
    if dpkg -s ntfs-3g >/dev/null 2>&1; then
        TO_UPDATE+=("ntfs-3g")
    fi
    
    if dpkg -s gparted >/dev/null 2>&1; then
        TO_UPDATE+=("gparted")
    fi
    
    if [ ${#TO_UPDATE[@]} -eq 0 ]; then
        return 0
    fi
    
    print_info "Updating: ${TO_UPDATE[*]}"
    
    if apt-get install --only-upgrade -y "${TO_UPDATE[@]}" >> "$LOG_FILE" 2>&1; then
        print_success "Optional components updated"
        
        # Update ntfs-3g version
        if [[ " ${TO_UPDATE[@]} " =~ " ntfs-3g " ]]; then
            local version=$(dpkg -s ntfs-3g | grep '^Version:' | awk '{print $2}')
            save_version "ntfs-3g" "$version"
        fi
    else
        print_warning "Some updates failed"
    fi
}

#############################################
# Main Operations
#############################################

do_install() {
    TOTAL_STEPS=6
    
    trap cleanup_on_error ERR
    
    print_header
    echo -e "${GREEN}Installation Mode${NC}"
    echo ""
    
    log "========================================="
    log "Complete NTFS installation started"
    log "System: $(uname -a)"
    log "========================================="
    
    check_root
    install_dependencies
    install_ntfsprogs_plus "latest"
    
    if check_kernel_version; then
        install_ntfsplus_driver "latest" || print_warning "NTFSplus driver installation skipped"
    else
        print_warning "Kernel too old for NTFSplus (6.2+ required)"
        print_info "Upgrade: sudo apt install linux-generic-hwe-24.04 && sudo reboot"
    fi
    
    install_optional_components
    
    # Cleanup
    print_info "Cleaning up build directory..."
    rm -rf "$BUILD_DIR"
    
    print_summary
    
    log "Installation completed"
}

do_update() {
    TOTAL_STEPS=5
    
    trap cleanup_on_error ERR
    
    print_header
    echo -e "${YELLOW}Update Mode${NC}"
    echo ""
    
    log "========================================="
    log "Complete NTFS update started"
    log "========================================="
    
    check_root
    
    print_step "Checking for updates..."
    
    # Update dependencies
    install_dependencies
    
    # Update ntfsprogs-plus if installed
    if [ -f "$PROGS_MANIFEST" ] || command -v ntfsck &> /dev/null; then
        update_ntfsprogs_plus
    else
        print_info "ntfsprogs-plus not installed, installing..."
        install_ntfsprogs_plus "latest"
    fi
    
    # Update NTFSplus if installed
    if [ -f "$DRIVER_MARKER" ] || dkms status -m "$DKMS_NAME" >/dev/null 2>&1; then
        if check_kernel_version; then
            update_ntfsplus_driver || print_warning "NTFSplus update failed"
        else
            print_warning "Kernel too old for NTFSplus"
        fi
    fi
    
    # Update optional components
    update_optional_components
    
    # Cleanup
    print_step "Cleanup..."
    print_info "Cleaning up build directory..."
    rm -rf "$BUILD_DIR"
    
    print_step "Update Summary"
    echo ""
    echo -e "${GREEN}Update completed!${NC}"
    echo ""
    echo "Current versions:"
    echo "  ntfsprogs-plus: $(get_installed_version 'ntfsprogs-plus')"
    echo "  NTFSplus:       $(get_installed_version 'ntfsplus')"
    echo "  ntfs-3g:        $(get_installed_version 'ntfs-3g')"
    echo ""
    echo "Check versions:"
    echo "  ntfsck --help 2>&1 | head -n1"
    echo "  modinfo ntfsplus | grep version"
    echo ""
    
    log "Update completed"
}

do_uninstall() {
    TOTAL_STEPS=3
    
    print_header
    echo -e "${RED}Uninstallation Mode${NC}"
    echo ""
    
    log "========================================="
    log "Complete NTFS uninstallation started"
    log "========================================="
    
    check_root
    
    print_step "Uninstalling components..."
    
    # Uninstall NTFSplus first (kernel module)
    if [ -f "$DRIVER_MARKER" ] || dkms status -m "$DKMS_NAME" >/dev/null 2>&1; then
        uninstall_ntfsplus_driver
    else
        print_info "NTFSplus driver not installed"
    fi
    
    # Uninstall ntfsprogs-plus
    if [ -f "$PROGS_MANIFEST" ] || command -v ntfsck &> /dev/null; then
        uninstall_ntfsprogs_plus
    else
        print_info "ntfsprogs-plus not installed"
    fi
    
    # Clean up state directory
    print_step "Removing installation state..."
    rm -rf "$STATE_DIR"
    
    print_step "Verification..."
    
    local ISSUES=()
    
    if command -v ntfsck &> /dev/null; then
        ISSUES+=("ntfsprogs-plus utilities still present")
    fi
    
    if lsmod | grep -q "^ntfsplus "; then
        ISSUES+=("ntfsplus module still loaded")
    fi
    
    if [ ${#ISSUES[@]} -eq 0 ]; then
        print_success "Complete NTFS solution removed"
    else
        print_warning "Some components may remain:"
        for issue in "${ISSUES[@]}"; do
            echo "  • $issue"
        done
    fi
    
    echo ""
    echo -e "${GREEN}Uninstallation Complete!${NC}"
    echo ""
    echo "Note: ntfs-3g and GParted were NOT removed (system packages)"
    echo "      Remove manually if desired: sudo apt remove ntfs-3g gparted"
    echo ""
    echo "Remaining NTFS options:"
    echo "  • ntfs3 (kernel built-in)"
    echo "  • ntfs-3g (FUSE userspace)"
    echo ""
    echo "Reinstall: sudo ./ntfs-complete-manager.sh --install"
    echo ""
    
    log "Uninstallation completed"
}

print_summary() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation Complete!${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "✓ Complete NTFS Solution Installed"
    echo ""
    echo "Installed Versions:"
    echo "  ntfsprogs-plus: $(get_installed_version 'ntfsprogs-plus')"
    echo "  NTFSplus:       $(get_installed_version 'ntfsplus')"
    echo "  ntfs-3g:        $(get_installed_version 'ntfs-3g')"
    echo ""
    echo "Components:"
    
    if [ -f "$PROGS_MANIFEST" ]; then
        echo "  ${GREEN}✓${NC} ntfsprogs-plus utilities"
        echo "      • ntfsck    - Check and repair NTFS"
        echo "      • ntfsclone - Backup and restore"
        echo "      • ntfsinfo  - Inspect filesystem"
        echo "      • ntfscluster - Find files by cluster"
    fi
    
    if [ -f "$DRIVER_MARKER" ]; then
        echo "  ${GREEN}✓${NC} NTFSplus kernel driver (DKMS)"
        echo "      • 35-110% faster writes vs ntfs3"
        echo "      • Modern iomap + folio support"
        echo "      • Auto-updates with kernel"
    fi
    
    if dpkg -s ntfs-3g >/dev/null 2>&1; then
        echo "  ${GREEN}✓${NC} ntfs-3g (additional utilities)"
        echo "      • ntfsresize   - Resize partitions"
        echo "      • ntfsundelete - Recover deleted files"
        echo "      • ntfslabel    - Change volume labels"
        echo "      • mkntfs       - Format NTFS"
        echo "      • ntfsfix      - Quick fixes"
    fi
    
    if dpkg -s gparted >/dev/null 2>&1; then
        echo "  ${GREEN}✓${NC} GParted (GUI partition manager)"
    fi
    
    echo ""
    echo "Quick Start:"
    echo "  Mount NTFS: sudo mount -t ntfsplus /dev/sdXY /mnt/point"
    echo "  Check NTFS: sudo ntfsck -a /dev/sdXY"
    echo "  Clone NTFS: sudo ntfsclone -s -O backup.img /dev/sdXY"
    echo "  Resize:     sudo ntfsresize /dev/sdXY"
    echo "  Undelete:   sudo ntfsundelete /dev/sdXY"
    echo ""
    echo "Management:"
    echo "  Update:     sudo $0 --update"
    echo "  Uninstall:  sudo $0 --uninstall"
    echo "  Scan:       sudo $0 --scan"
    echo ""
    echo "Documentation:"
    echo "  Installation state: $STATE_DIR/"
    echo "  Versions:           $VERSION_FILE"
    echo "  Log file:           $LOG_FILE"
    echo ""
    
    if ! lsmod | grep -q "^ntfsplus "; then
        echo -e "${YELLOW}NOTE: Reboot recommended to activate NTFSplus driver${NC}"
        echo ""
    fi
}

show_usage() {
    cat << EOF
Complete NTFS Solution Manager v2.0
====================================

Usage: $0 [OPTION]

Options:
  --install, -i     Install complete NTFS solution
  --update, -u      Update all components to latest stable releases
  --uninstall, -r   Uninstall all components
  --scan, -s        Scan system and show version info
  --help, -h        Show this help message

Components Managed:
  • ntfsprogs-plus  - NTFS utilities (ntfsck, ntfsclone, etc.)
  • NTFSplus        - Modern kernel driver (requires 6.2+)
  • ntfs-3g         - Additional utilities (resize, undelete, etc.)
  • GParted         - GUI partition manager

Version Management:
  • Installs latest stable releases by default
  • Tracks installed versions
  • Update checks for newer stable releases
  • Preserves installation history

Examples:
  sudo $0 --scan         # Check versions & updates
  sudo $0 --install      # Install latest stable
  sudo $0 --update       # Update to latest stable
  sudo $0 --uninstall    # Remove everything

Requirements:
  • Ubuntu 24.04 or compatible
  • Kernel 6.2+ (for NTFSplus driver)
  • Root/sudo access
  • Internet connection

Documentation:
  README-COMPLETE.md - Full documentation
  QUICK-REFERENCE-COMPLETE.txt - Command reference

EOF
}

#############################################
# Main Entry Point
#############################################

main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    case "${1:-}" in
        --install|-i)
            do_install
            ;;
        --update|-u)
            do_update
            ;;
        --uninstall|-r|--remove)
            do_uninstall
            ;;
        --scan|-s)
            check_root
            scan_system
            ;;
        --help|-h)
            show_usage
            ;;
        *)
            echo "Unknown option: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"

exit 0
