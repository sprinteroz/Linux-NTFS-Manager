#!/bin/bash

# Linux NTFS Manager - Master Installation Script
# This script provides easy access to all installation options
# Version 1.0.0

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Linux NTFS Manager - Installation Menu              ║${NC}"
    echo -e "${CYAN}║                    Version 1.0.3                             ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Professional NTFS Drive Management for Linux${NC}"
    echo ""
}

check_balena_etcher_warning() {
    echo -e "${YELLOW}⚠️  Checking for incompatible software...${NC}"
    
    if command -v balena-etcher-electron &> /dev/null || \
       command -v balenaEtcher &> /dev/null || \
       find /home -name "*balena*etcher*.AppImage" 2>/dev/null | grep -q . || \
       snap list 2>/dev/null | grep -q "etcher"; then
        
        echo ""
        echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║                  ⚠️  WARNING DETECTED ⚠️                      ║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}Balena Etcher is installed on your system!${NC}"
        echo ""
        echo -e "${RED}Known Issues:${NC}"
        echo -e "  • Breaks NTFS mounting functionality"
        echo -e "  • Prevents writing to NTFS drives"
        echo -e "  • Disables hot-swap support"
        echo -e "  • May cause network connectivity issues"
        echo ""
        echo -e "${CYAN}Recommendation:${NC}"
        echo -e "  Run the recovery script first: ${GREEN}sudo ./scripts/balena-etcher-recovery.sh${NC}"
        echo ""
        read -p "Press Enter to continue with installation anyway, or Ctrl+C to exit..."
        echo ""
    else
        echo -e "${GREEN}✓${NC} No incompatible software detected"
        echo ""
    fi
}

show_installation_options() {
    echo -e "${BLUE}Available Installation Options:${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} Production Installation (Recommended)"
    echo -e "   • Full-featured NTFS Manager with GUI"
    echo -e "   • Nautilus file manager integration"
    echo -e "   • User-level installation"
    echo -e "   • Location: ${CYAN}ntfs-manager-production/install.sh${NC}"
    echo ""
    echo -e "${GREEN}2)${NC} Complete Manager GUI"
    echo -e "   • System-wide GUI installation"
    echo -e "   • Desktop integration"
    echo -e "   • Requires root access"
    echo -e "   • Location: ${CYAN}ntfs-complete-manager-gui/install.sh${NC}"
    echo ""
    echo -e "${GREEN}3)${NC} Standalone NTFS Tools"
    echo -e "   • Complete NTFS solution installer"
    echo -e "   • Multiple NTFS drivers and tools"
    echo -e "   • Advanced features"
    echo -e "   • Location: ${CYAN}ntfs-installer-standalone/install-ntfs.sh${NC}"
    echo ""
    echo -e "${YELLOW}4)${NC} Run Compatibility Check"
    echo -e "   • Detect system issues"
    echo -e "   • Check for incompatible software"
    echo -e "   • Verify NTFS functionality"
    echo ""
    echo -e "${YELLOW}5)${NC} Run Balena Etcher Recovery"
    echo -e "   • Fix NTFS issues caused by balena Etcher"
    echo -e "   • Restore mounting functionality"
    echo -e "   • Requires sudo"
    echo ""
    echo -e "${RED}6)${NC} Exit"
    echo ""
}

install_production() {
    echo -e "${BLUE}Starting Production Installation...${NC}"
    echo ""
    cd "$SCRIPT_DIR/ntfs-manager-production"
    bash install.sh
}

install_complete_gui() {
    echo -e "${BLUE}Starting Complete Manager GUI Installation...${NC}"
    echo ""
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}This installation requires root access.${NC}"
        echo -e "${YELLOW}Relaunching with sudo...${NC}"
        sudo bash "$SCRIPT_DIR/ntfs-complete-manager-gui/install.sh"
    else
        cd "$SCRIPT_DIR/ntfs-complete-manager-gui"
        bash install.sh
    fi
}

install_standalone() {
    echo -e "${BLUE}Starting Standalone NTFS Tools Installation...${NC}"
    echo ""
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}This installation requires root access.${NC}"
        echo -e "${YELLOW}Relaunching with sudo...${NC}"
        sudo bash "$SCRIPT_DIR/ntfs-installer-standalone/install-ntfs.sh"
    else
        cd "$SCRIPT_DIR/ntfs-installer-standalone"
        bash install-ntfs.sh
    fi
}

run_compatibility_check() {
    echo -e "${BLUE}Running Compatibility Check...${NC}"
    echo ""
    bash "$SCRIPT_DIR/scripts/check-software-compatibility.sh"
    echo ""
    read -p "Press Enter to return to menu..."
}

run_recovery() {
    echo -e "${BLUE}Running Balena Etcher Recovery...${NC}"
    echo ""
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}Recovery requires root access.${NC}"
        echo -e "${YELLOW}Relaunching with sudo...${NC}"
        sudo bash "$SCRIPT_DIR/scripts/balena-etcher-recovery.sh"
    else
        bash "$SCRIPT_DIR/scripts/balena-etcher-recovery.sh"
    fi
    echo ""
    read -p "Press Enter to return to menu..."
}

main_menu() {
    while true; do
        show_header
        check_balena_etcher_warning
        show_installation_options
        
        read -p "Enter your choice [1-6]: " -n 1 -r choice
        echo ""
        echo ""
        
        case $choice in
            1)
                install_production
                break
                ;;
            2)
                install_complete_gui
                break
                ;;
            3)
                install_standalone
                break
                ;;
            4)
                run_compatibility_check
                ;;
            5)
                run_recovery
                ;;
            6)
                echo -e "${BLUE}Exiting installation. Thank you!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

show_post_install() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                 Installation Complete!                       ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo -e "  1. Review the installation logs above"
    echo -e "  2. Log out and log back in (if prompted)"
    echo -e "  3. Launch NTFS Manager from your applications menu"
    echo ""
    echo -e "${CYAN}Documentation:${NC}"
    echo -e "  • README: ${BLUE}$SCRIPT_DIR/README.md${NC}"
    echo -e "  • Troubleshooting: ${BLUE}$SCRIPT_DIR/wiki-content/Troubleshooting.md${NC}"
    echo -e "  • Known Issues: ${BLUE}$SCRIPT_DIR/docs/KNOWN-INCOMPATIBLE-SOFTWARE.md${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Important:${NC}"
    echo -e "  • Avoid installing balena Etcher (breaks NTFS functionality)"
    echo -e "  • Use GNOME Disks or Popsicle for disk imaging instead"
    echo -e "  • Run compatibility check: ${CYAN}./scripts/check-software-compatibility.sh${NC}"
    echo ""
}

# Check if script is being run from correct directory
if [[ ! -d "$SCRIPT_DIR/ntfs-manager-production" ]]; then
    echo -e "${RED}Error: This script must be run from the Linux-NTFS-Manager directory${NC}"
    echo -e "${YELLOW}Current directory: $SCRIPT_DIR${NC}"
    exit 1
fi

# Main execution
main_menu
show_post_install
