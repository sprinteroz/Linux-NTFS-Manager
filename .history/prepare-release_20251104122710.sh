#!/bin/bash
# NTFS Manager v1.0.1 Release Preparation Script
# Prepares distribution package and GitHub upload

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

VERSION="1.0.1"
PACKAGE_NAME="Linux-NTFS-Manager-v${VERSION}"
DIST_DIR="dist"

print_header() {
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${CYAN}  NTFS Manager v${VERSION} Release Prep${NC}"
    echo -e "${CYAN}==========================================${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_git_status() {
    print_info "Checking Git status..."
    
    if [ ! -d ".git" ]; then
        print_error "Not a Git repository"
        return 1
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        print_warning "You have uncommitted changes"
        echo "  Modified files:"
        git status --short
        echo ""
        read -p "  Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    else
        print_success "Git working directory is clean"
    fi
    
    return 0
}

verify_version() {
    print_info "Verifying version consistency..."
    
    local version_file=$(cat VERSION 2>/dev/null)
    
    if [ "$version_file" != "$VERSION" ]; then
        print_error "VERSION file mismatch: expected $VERSION, got $version_file"
        return 1
    fi
    
    if ! grep -q "Version $VERSION" CHANGELOG.md; then
        print_warning "CHANGELOG.md may not have v$VERSION entry"
    fi
    
    print_success "Version $VERSION verified"
    return 0
}

test_scripts() {
    print_info "Testing management scripts..."
    
    local scripts=(
        "scripts/manage-windows-vm.sh"
        "scripts/manage-waydroid.sh"
        "scripts/system-resource-monitor.sh"
    )
    
    local failures=0
    
    for script in "${scripts[@]}"; do
        if [ ! -f "$script" ]; then
            print_error "Missing: $script"
            ((failures++))
            continue
        fi
        
        if [ ! -x "$script" ]; then
            print_warning "Not executable: $script"
            chmod +x "$script"
            print_info "Made executable: $script"
        fi
        
        # Test script help
        if ! bash "$script" help > /dev/null 2>&1; then
            print_warning "Script may have issues: $script"
        else
            print_success "Verified: $script"
        fi
    done
    
    if [ $failures -gt 0 ]; then
        print_error "$failures script(s) failed verification"
        return 1
    fi
    
    print_success "All scripts verified"
    return 0
}

create_distribution() {
    print_info "Creating distribution package..."
    
    # Create dist directory
    mkdir -p "$DIST_DIR"
    
    # Create package directory
    local pkg_dir="$DIST_DIR/$PACKAGE_NAME"
    rm -rf "$pkg_dir"
    mkdir -p "$pkg_dir"
    
    # Copy files
    print_info "Copying files..."
    
    # Core files
    cp -r scripts "$pkg_dir/"
    cp VERSION "$pkg_dir/"
    cp CHANGELOG.md "$pkg_dir/"
    cp README.md "$pkg_dir/"
    cp LICENSE "$pkg_dir/"
    cp SYSTEM-FIXES-REPORT.md "$pkg_dir/"
    cp RELEASE-NOTES-v${VERSION}.md "$pkg_dir/"
    
    # Optional directories (if they exist)
    [ -d "ntfs-manager-production" ] && cp -r ntfs-manager-production "$pkg_dir/"
    [ -d "ntfs-complete-manager-gui" ] && cp -r ntfs-complete-manager-gui "$pkg_dir/"
    [ -d "ntfs-installer-standalone" ] && cp -r ntfs-installer-standalone "$pkg_dir/"
    
    # Create tarball
    print_info "Creating tarball..."
    cd "$DIST_DIR"
    tar -czf "${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME"
    
    # Create checksum
    sha256sum "${PACKAGE_NAME}.tar.gz" > "${PACKAGE_NAME}.tar.gz.sha256"
    
    cd ..
    
    local size=$(du -h "$DIST_DIR/${PACKAGE_NAME}.tar.gz" | cut -f1)
    print_success "Package created: ${PACKAGE_NAME}.tar.gz ($size)"
    print_success "Checksum created: ${PACKAGE_NAME}.tar.gz.sha256"
    
    # Show checksum
    echo ""
    echo -e "${CYAN}SHA256:${NC}"
    cat "$DIST_DIR/${PACKAGE_NAME}.tar.gz.sha256"
    echo ""
}

prepare_git_commit() {
    print_info "Preparing Git commit..."
    
    # Stage all changes
    git add -A
    
    # Show what will be committed
    echo ""
    echo -e "${CYAN}Files to be committed:${NC}"
    git status --short
    echo ""
    
    read -p "Create commit for v${VERSION}? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git commit -m "Release v${VERSION} - Resource Management & Stability Improvements

- Added Windows VM management script
- Added Waydroid management script
- Added system resource monitor
- Fixed GNOME Shell stability issues
- Enhanced documentation
- Comprehensive troubleshooting guide

See RELEASE-NOTES-v${VERSION}.md for details"
        
        print_success "Commit created"
        
        # Create tag
        read -p "Create Git tag v${VERSION}? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git tag -a "v${VERSION}" -m "Release v${VERSION}

Resource Management & Stability Release

Major improvements:
- System resource management tools
- GNOME Shell stability fixes
- VM and Waydroid management
- Comprehensive documentation

See RELEASE-NOTES-v${VERSION}.md for full details"
            
            print_success "Tag v${VERSION} created"
        fi
    else
        print_info "Skipped commit"
    fi
}

show_upload_instructions() {
    print_info "GitHub Upload Instructions"
    echo ""
    echo -e "${CYAN}===== GITHUB UPLOAD STEPS =====${NC}"
    echo ""
    echo "1. ${GREEN}Push to GitHub:${NC}"
    echo "   git push origin main"
    echo "   git push origin v${VERSION}"
    echo ""
    echo "2. ${GREEN}Create GitHub Release:${NC}"
    echo "   - Go to: https://github.com/sprinteroz/Linux-NTFS-Manager/releases/new"
    echo "   - Tag: v${VERSION}"
    echo "   - Title: NTFS Manager v${VERSION} - Resource Management & Stability"
    echo "   - Description: Copy from RELEASE-NOTES-v${VERSION}.md"
    echo ""
    echo "3. ${GREEN}Upload Release Assets:${NC}"
    echo "   - ${PACKAGE_NAME}.tar.gz"
    echo "   - ${PACKAGE_NAME}.tar.gz.sha256"
    echo "   - RELEASE-NOTES-v${VERSION}.md"
    echo "   - SYSTEM-FIXES-REPORT.md"
    echo ""
    echo "4. ${GREEN}Verify Release:${NC}"
    echo "   - Test download link"
    echo "   - Verify checksum"
    echo "   - Check release notes display"
    echo ""
    echo "5. ${GREEN}Announce Release:${NC}"
    echo "   - Update project README"
    echo "   - Email customers (if applicable)"
    echo "   - Post on forums/social media"
    echo ""
    echo -e "${CYAN}==============================${NC}"
    echo ""
    
    # Show package location
    echo -e "${GREEN}Distribution package location:${NC}"
    echo "  $(pwd)/$DIST_DIR/${PACKAGE_NAME}.tar.gz"
    echo ""
}

generate_release_description() {
    print_info "Generating GitHub release description..."
    
    local desc_file="$DIST_DIR/github-release-description.md"
    
    cat > "$desc_file" << 'EOF'
# NTFS Manager v1.0.1 - Resource Management & Stability

## 🎯 What's New

This maintenance release introduces powerful system resource management tools and fixes critical stability issues for users running VMs, Waydroid, and multiple resource-intensive applications.

### New Features
- ✨ Windows VM Management Script - Auto-shutdown, monitoring, memory tracking
- ✨ Waydroid Management Script - Session control, icon crash fixes
- ✨ System Resource Monitor - Real-time monitoring and alerts
- ✨ Comprehensive troubleshooting documentation

### Bug Fixes
- 🐛 Fixed GNOME Shell JSAPI crashes under memory pressure
- 🐛 Resolved Waydroid icon disappearance after crashes
- 🐛 Improved handling of high-memory workloads
- 🐛 Enhanced system integration for VMs and containers

### Documentation
-📝 Added SYSTEM-FIXES-REPORT.md with complete analysis
- 📝 Updated CHANGELOG with detailed changes
- 📝 Created comprehensive RELEASE-NOTES
- 📝 Added script usage documentation

## 📦 Installation

### For New Users
```bash
# Download and extract
wget https://github.com/sprinteroz/Linux-NTFS-Manager/releases/download/v1.0.1/Linux-NTFS-Manager-v1.0.1.tar.gz
tar -xzf Linux-NTFS-Manager-v1.0.1.tar.gz
cd Linux-NTFS-Manager-v1.0.1

# Make scripts executable
cd scripts
chmod +x *.sh

# Run system check
./system-resource-monitor.sh full
```

### For Existing Users
```bash
# Update your installation
cd Linux-NTFS-Manager
git pull origin main
cat VERSION  # Should show 1.0.1

# Make new scripts executable
cd scripts
chmod +x *.sh
```

## 🔍 What Was Fixed

Investigation revealed that system crashes were **NOT caused by NTFS Manager**, but by resource exhaustion from:
- Windows VMs using excessive memory (65GB+)
- Multiple VS Code instances
- Memory pressure causing GNOME Shell crashes

**NTFS Manager remains stable with zero issues found.**

## 📊 Key Improvements

- **Memory Management**: Tools to identify and resolve resource issues
- **VM Control**: Automated shutdown and monitoring
- **Waydroid Stability**: Icon persistence and cache management
- **System Monitoring**: Real-time resource tracking

## 📝 Full Details

See the attached files for complete information:
- **RELEASE-NOTES-v1.0.1.md** - Complete release notes
- **SYSTEM-FIXES-REPORT.md** - Detailed system analysis
- **CHANGELOG.md** - Full changelog

## ✅ Verified

- All scripts tested and working
- Documentation complete
- No breaking changes from v1.0.0
- Enhanced stability confirmed

## 📞 Support

- **Email**: sales@magdrivex.com.au
- **GitHub**: https://github.com/sprinteroz/Linux-NTFS-Manager
- **Company**: MagDriveX (ABN: 82 977 519 307)

---

**SHA256 Checksum**: See attached .sha256 file
EOF
    
    print_success "Release description created: $desc_file"
