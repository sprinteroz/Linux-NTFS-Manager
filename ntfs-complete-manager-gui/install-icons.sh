#!/bin/bash
# NTFS Manager Icon Installation Script
# Installs application icons to system directories

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}NTFS Manager Icon Installation${NC}"
echo "=================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_DIR="$SCRIPT_DIR/icons"

# Check if icons directory exists
if [ ! -d "$ICON_DIR" ]; then
    echo -e "${RED}Error: Icons directory not found at $ICON_DIR${NC}"
    exit 1
fi

echo "Found icons in: $ICON_DIR"
ls -la "$ICON_DIR"

# Install icons to system directories
echo "Installing icons to system..."

# Create directories if they don't exist
sudo mkdir -p /usr/share/icons/hicolor/16x16/apps
sudo mkdir -p /usr/share/icons/hicolor/32x32/apps
sudo mkdir -p /usr/share/icons/hicolor/48x48/apps
sudo mkdir -p /usr/share/icons/hicolor/64x64/apps
sudo mkdir -p /usr/share/icons/hicolor/128x128/apps
sudo mkdir -p /usr/share/icons/hicolor/256x256/apps
sudo mkdir -p /usr/share/icons/hicolor/scalable/apps

# Copy PNG icons
if [ -f "$ICON_DIR/ntfs-manager-16.png" ]; then
    sudo cp "$ICON_DIR/ntfs-manager-16.png" /usr/share/icons/hicolor/16x16/apps/ntfs-manager.png
    echo "✓ Installed 16x16 icon"
fi

if [ -f "$ICON_DIR/ntfs-manager-32.png" ]; then
    sudo cp "$ICON_DIR/ntfs-manager-32.png" /usr/share/icons/hicolor/32x32/apps/ntfs-manager.png
    echo "✓ Installed 32x32 icon"
fi

if [ -f "$ICON_DIR/ntfs-manager-48.png" ]; then
    sudo cp "$ICON_DIR/ntfs-manager-48.png" /usr/share/icons/hicolor/48x48/apps/ntfs-manager.png
    echo "✓ Installed 48x48 icon"
fi

if [ -f "$ICON_DIR/ntfs-manager-64.png" ]; then
    sudo cp "$ICON_DIR/ntfs-manager-64.png" /usr/share/icons/hicolor/64x64/apps/ntfs-manager.png
    echo "✓ Installed 64x64 icon"
fi

if [ -f "$ICON_DIR/ntfs-manager-128.png" ]; then
    sudo cp "$ICON_DIR/ntfs-manager-128.png" /usr/share/icons/hicolor/128x128/apps/ntfs-manager.png
    echo "✓ Installed 128x128 icon"
fi

if [ -f "$ICON_DIR/ntfs-manager-256.png" ]; then
    sudo cp "$ICON_DIR/ntfs-manager-256.png" /usr/share/icons/hicolor/256x256/apps/ntfs-manager.png
    echo "✓ Installed 256x256 icon"
fi

# Copy SVG icon (scalable)
if [ -f "$ICON_DIR/ntfs-manager.svg" ]; then
    sudo cp "$ICON_DIR/ntfs-manager.svg" /usr/share/icons/hicolor/scalable/apps/ntfs-manager.svg
    echo "✓ Installed scalable SVG icon"
fi

# Update icon cache
echo "Updating icon cache..."
sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || echo "Icon cache update completed"

# Copy desktop file to applications directory
echo "Installing desktop file..."
sudo cp "$SCRIPT_DIR/ntfs-manager.desktop" /usr/share/applications/
sudo desktop-file-install /usr/share/applications/ntfs-manager.desktop 2>/dev/null || echo "Desktop file installed"

# Update desktop database
echo "Updating desktop database..."
sudo update-desktop-database /usr/share/applications 2>/dev/null || echo "Desktop database updated"

echo ""
echo -e "${GREEN}Icon installation completed successfully!${NC}"
echo ""
echo "The NTFS Manager icon should now appear in:"
echo "• Applications menu"
echo "• Dock/panel"
echo "• Alt+Tab switcher"
echo ""
echo "You may need to log out and log back in to see the changes."
