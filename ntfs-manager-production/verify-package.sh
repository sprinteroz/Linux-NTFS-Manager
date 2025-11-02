#!/bin/bash

# NTFS Manager - Production Package Verification Script
# Verifies all components are present and functional

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_CHECKS++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

check_file() {
    local file="$1"
    local description="$2"
    ((TOTAL_CHECKS++))
    
    if [[ -f "$file" ]]; then
        log_success "$description: $file"
    else
        log_error "$description: $file (MISSING)"
    fi
}

check_directory() {
    local dir="$1"
    local description="$2"
    ((TOTAL_CHECKS++))
    
    if [[ -d "$dir" ]]; then
        log_success "$description: $dir"
    else
        log_error "$description: $dir (MISSING)"
    fi
}

check_executable() {
    local file="$1"
    local description="$2"
    ((TOTAL_CHECKS++))
    
    if [[ -x "$file" ]]; then
        log_success "$description: $file"
    else
        log_error "$description: $file (NOT EXECUTABLE)"
    fi
}

check_python_syntax() {
    local file="$1"
    local description="$2"
    ((TOTAL_CHECKS++))
    
    if python3 -m py_compile "$file" 2>/dev/null; then
        log_success "$description: $file"
    else
        log_error "$description: $file (SYNTAX ERROR)"
    fi
}

verify_core_files() {
    log_info "Verifying core package files..."
    
    check_file "$SCRIPT_DIR/README.md" "README documentation"
    check_file "$SCRIPT_DIR/VERSION" "Version file"
    check_file "$SCRIPT_DIR/CHANGELOG.md" "Changelog"
    check_file "$SCRIPT_DIR/LICENSE" "License file"
    check_file "$SCRIPT_DIR/requirements.txt" "Python requirements"
    check_file "$SCRIPT_DIR/dependencies.txt" "System dependencies"
    check_executable "$SCRIPT_DIR/install.sh" "Main installation script"
}

verify_backend_modules() {
    log_info "Verifying backend modules..."
    
    check_directory "$SCRIPT_DIR/backend" "Backend directory"
    check_file "$SCRIPT_DIR/backend/drive_manager.py" "Drive manager module"
    check_file "$SCRIPT_DIR/backend/ntfs_properties.py" "NTFS properties module"
    check_file "$SCRIPT_DIR/backend/logger.py" "Logger module"
    check_file "$SCRIPT_DIR/backend/gparted_integration.py" "GParted integration module"
    
    # Check Python syntax
    check_python_syntax "$SCRIPT_DIR/backend/drive_manager.py" "Drive manager syntax"
    check_python_syntax "$SCRIPT_DIR/backend/ntfs_properties.py" "NTFS properties syntax"
    check_python_syntax "$SCRIPT_DIR/backend/logger.py" "Logger syntax"
    check_python_syntax "$SCRIPT_DIR/backend/gparted_integration.py" "GParted integration syntax"
}

verify_standalone_gui() {
    log_info "Verifying standalone GUI..."
    
    check_directory "$SCRIPT_DIR/standalone-gui" "Standalone GUI directory"
    check_file "$SCRIPT_DIR/standalone-gui/main.py" "Main GUI application"
    check_file "$SCRIPT_DIR/standalone-gui/ntfs-manager.desktop" "Desktop file"
    
    # Check Python syntax
    check_python_syntax "$SCRIPT_DIR/standalone-gui/main.py" "Main GUI syntax"
    
    # Check desktop file format
    if grep -q "Exec=" "$SCRIPT_DIR/standalone-gui/ntfs-manager.desktop"; then
        log_success "Desktop file has Exec entry"
    else
        log_error "Desktop file missing Exec entry"
    fi
}

verify_nautilus_extension() {
    log_info "Verifying Nautilus extension..."
    
    check_directory "$SCRIPT_DIR/nautilus-extension" "Nautilus extension directory"
    check_file "$SCRIPT_DIR/nautilus-extension/ntfs_manager_extension.py" "Extension module"
    check_file "$SCRIPT_DIR/nautilus-extension/install.sh" "Extension installer"
    check_file "$SCRIPT_DIR/nautilus-extension/install-enhanced.sh" "Enhanced installer"
    check_file "$SCRIPT_DIR/nautilus-extension/README.md" "Extension documentation"
    check_file "$SCRIPT_DIR/nautilus-extension/test_integration.py" "Integration test"
    
    # Check Python syntax
    check_python_syntax "$SCRIPT_DIR/nautilus-extension/ntfs_manager_extension.py" "Extension syntax"
    check_python_syntax "$SCRIPT_DIR/nautilus-extension/test_integration.py" "Test script syntax"
}

verify_icons() {
    log_info "Verifying icons..."
    
    check_directory "$SCRIPT_DIR/icons" "Icons directory"
    check_file "$SCRIPT_DIR/icons/ntfs-manager.svg" "SVG icon"
    check_file "$SCRIPT_DIR/icons/ntfs-manager-16.png" "16x16 PNG icon"
    check_file "$SCRIPT_DIR/icons/ntfs-manager-32.png" "32x32 PNG icon"
    check_file "$SCRIPT_DIR/icons/ntfs-manager-48.png" "48x48 PNG icon"
    check_file "$SCRIPT_DIR/icons/ntfs-manager-64.png" "64x64 PNG icon"
    check_file "$SCRIPT_DIR/icons/ntfs-manager-128.png" "128x128 PNG icon"
    check_file "$SCRIPT_DIR/icons/ntfs-manager-256.png" "256x256 PNG icon"
}

verify_documentation() {
    log_info "Verifying documentation quality..."
    
    # Check README has required sections
    if grep -q "## Installation" "$SCRIPT_DIR/README.md"; then
        log_success "README has Installation section"
    else
        log_error "README missing Installation section"
    fi
    
    if grep -q "## Usage" "$SCRIPT_DIR/README.md"; then
        log_success "README has Usage section"
    else
        log_error "README missing Usage section"
    fi
    
    # Check CHANGELOG format
    if grep -q "## \[.*\]" "$SCRIPT_DIR/CHANGELOG.md"; then
        log_success "CHANGELOG has proper version format"
    else
        log_error "CHANGELOG missing version format"
    fi
}

verify_package_integrity() {
    log_info "Verifying package integrity..."
    
    # Check version consistency
    if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
        VERSION=$(cat "$SCRIPT_DIR/VERSION")
        if grep -q "$VERSION" "$SCRIPT_DIR/CHANGELOG.md"; then
            log_success "Version consistent across files"
        else
            log_warning "Version mismatch between VERSION and CHANGELOG"
        fi
    fi
    
    # Check dependencies completeness
    if [[ -f "$SCRIPT_DIR/requirements.txt" && -f "$SCRIPT_DIR/dependencies.txt" ]]; then
        log_success "Both Python and system dependencies documented"
    else
        log_error "Missing dependency documentation"
    fi
}

show_verification_results() {
    local failed_checks=$((TOTAL_CHECKS - PASSED_CHECKS))
    
    echo
    echo -e "${BLUE}=== Verification Results ===${NC}"
    echo -e "Total checks: $TOTAL_CHECKS"
    echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
    echo -e "${RED}Failed: $failed_checks${NC}"
    echo
    
    if [[ $failed_checks -eq 0 ]]; then
        echo -e "${GREEN}✓ All checks passed! Package is ready for distribution.${NC}"
        return 0
    else
        echo -e "${RED}✗ $failed_checks check(s) failed. Review and fix issues.${NC}"
        return 1
    fi
}

# Main verification flow
main() {
    echo -e "${BLUE}=== NTFS Manager Package Verification ===${NC}"
    echo
    
    verify_core_files
    verify_backend_modules
    verify_standalone_gui
    verify_nautilus_extension
    verify_icons
    verify_documentation
    verify_package_integrity
    
    show_verification_results
}

# Run main function
main "$@"
