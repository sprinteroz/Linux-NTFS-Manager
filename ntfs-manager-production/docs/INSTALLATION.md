# NTFS Manager - Installation Guide

This guide provides detailed installation instructions for NTFS Manager on Linux systems.

## 📋 Prerequisites

### System Requirements

**Minimum:**
- Ubuntu 18.04+ / Debian 10+ or compatible Linux distribution
- Python 3.8 or higher
- Nautilus 3.20 or higher
- 512MB RAM
- 100MB free disk space

**Recommended:**
- Ubuntu 20.04+ / Debian 11+ or compatible Linux distribution
- Python 3.10 or higher
- Nautilus 3.24 or higher
- 1GB RAM
- 200MB free disk space

### Required Dependencies

The following packages must be installed:

```bash
# Core system dependencies
sudo apt update
sudo apt install -y \
    python3 \
    python3-pip \
    python3-gi \
    python3-gi-cairo \
    python3-nautilus \
    gir1.2-gtk-3.0 \
    ntfs-3g \
    util-linux \
    smartmontools \
    e2fsprogs \
    dosfstools \
    exfatprogs
```

### Optional Dependencies

For enhanced functionality:

```bash
# Optional but recommended
sudo apt install -y \
    gparted \
    hddtemp \
    libnotify-bin \
    policykit-1
```

## 🚀 Installation Methods

### Method 1: Quick Install (Recommended)

The easiest way to install NTFS Manager:

```bash
# Navigate to the package directory
cd ntfs-manager-production

# Run the main installer
sudo ./install.sh

# Restart Nautilus
nautilus -q && nautilus --no-default-window &
```

The installer will:
- Check all dependencies
- Install backend modules
- Install Nautilus extension
- Configure system integration
- Install standalone GUI (optional)
- Set up icons and desktop files

### Method 2: Nautilus Extension Only

To install only the Nautilus extension:

```bash
cd ntfs-manager-production/nautilus-extension

# Enhanced installer with full features
./install-enhanced.sh

# or basic installer
./install.sh

# Restart Nautilus
nautilus -q && nautilus --no-default-window &
```

### Method 3: Standalone GUI Only

To install only the standalone GUI application:

```bash
# Install backend modules first
sudo cp -r ntfs-manager-production/backend /usr/local/lib/ntfs-manager/

# Install standalone GUI
sudo cp ntfs-manager-production/standalone-gui/main.py /usr/local/bin/ntfs-manager-gui
sudo chmod +x /usr/local/bin/ntfs-manager-gui

# Install desktop file
sudo cp ntfs-manager-production/standalone-gui/ntfs-manager.desktop /usr/share/applications/

# Install icons
sudo cp -r ntfs-manager-production/icons/* /usr/share/icons/hicolor/

# Update icon cache
sudo gtk-update-icon-cache /usr/share/icons/hicolor/
```

### Method 4: Manual Installation

For advanced users who want full control:

#### Step 1: Install System Dependencies

```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-gi python3-gi-cairo \
                    python3-nautilus gir1.2-gtk-3.0 ntfs-3g \
                    util-linux smartmontools e2fsprogs dosfstools
```

#### Step 2: Install Python Dependencies

```bash
cd ntfs-manager-production
pip3 install -r requirements.txt --user
```

#### Step 3: Install Backend Modules

```bash
sudo mkdir -p /usr/local/lib/ntfs-manager/backend
sudo cp backend/*.py /usr/local/lib/ntfs-manager/backend/
sudo chmod 644 /usr/local/lib/ntfs-manager/backend/*.py
```

#### Step 4: Install Nautilus Extension

```bash
mkdir -p ~/.local/share/nautilus-python/extensions/
cp nautilus-extension/ntfs_manager_extension.py \
   ~/.local/share/nautilus-python/extensions/
```

#### Step 5: Install Icons

```bash
sudo cp -r icons/* /usr/share/icons/hicolor/
sudo gtk-update-icon-cache /usr/share/icons/hicolor/
```

#### Step 6: Install Desktop Files (Optional)

```bash
sudo cp standalone-gui/ntfs-manager.desktop /usr/share/applications/
sudo cp standalone-gui/main.py /usr/local/bin/ntfs-manager-gui
sudo chmod +x /usr/local/bin/ntfs-manager-gui
```

#### Step 7: Restart Nautilus

```bash
nautilus -q && nautilus --no-default-window &
```

## 🔧 Post-Installation Configuration

### User Permissions

Add your user to required groups:

```bash
sudo usermod -a -G disk $USER
sudo usermod -a -G plugdev $USER
```

**Note:** Log out and log back in for group changes to take effect.

### PolicyKit Configuration

For password-less mounting (optional):

```bash
sudo tee /etc/polkit-1/localauthority/50-local.d/ntfs-manager.pkla > /dev/null <<'EOF'
[NTFS Manager Permissions]
Identity=unix-group:disk
Action=org.freedesktop.udisks2.filesystem-mount*;org.freedesktop.udisks2.filesystem-unmount*
ResultActive=yes
ResultInactive=yes
ResultAny=yes
EOF
```

### Configuration File

Create user configuration (optional):

```bash
mkdir -p ~/.config/ntfs-manager
cat > ~/.config/ntfs-manager/config.ini <<EOF
[NTFS Manager]
notifications=true
refresh_interval=30
log_level=INFO
health_monitoring=true
advanced_options=true
default_mount_options=uid=1000,gid=1000,dmask=022,fmask=133
auto_monitoring=true
fallback_mode=true
preferred_ntfs_tool=auto
system_integration=true
debug_mode=false
EOF
```

## ✅ Verification

### Verify Installation

#### Check Nautilus Extension

1. Open Nautilus file manager
2. Navigate to any drive or mount point
3. Right-click and look for "NTFS Management" in the context menu

#### Check Standalone GUI

```bash
# Check if executable exists
which ntfs-manager-gui

# Launch the application
ntfs-manager-gui
```

#### Check Backend Modules

```bash
# Test Python imports
python3 -c "import sys; sys.path.insert(0, '/usr/local/lib/ntfs-manager'); from backend import drive_manager"
```

### Run Verification Script

```bash
cd ntfs-manager-production
./verify-package.sh
```

## 🐛 Troubleshooting

### Extension Not Loading

**Problem:** Nautilus extension doesn't appear in context menu

**Solutions:**
1. Verify Nautilus Python bindings:
   ```bash
   dpkg -l | grep python3-nautilus
   ```
2. Check extension file location:
   ```bash
   ls -l ~/.local/share/nautilus-python/extensions/
   ```
3. Check for errors:
   ```bash
   journalctl -f | grep nautilus
   ```
4. Restart Nautilus:
   ```bash
   nautilus -q
   killall nautilus
   nautilus --no-default-window &
   ```

### Permission Denied Errors

**Problem:** Operations fail with permission errors

**Solutions:**
1. Check user groups:
   ```bash
   groups $USER
   ```
2. Add to required groups:
   ```bash
   sudo usermod -a -G disk,plugdev $USER
   ```
3. Log out and log back in

### Python Import Errors

**Problem:** Backend modules not found

**Solutions:**
1. Verify installation:
   ```bash
   ls -l /usr/local/lib/ntfs-manager/backend/
   ```
2. Check Python path:
   ```bash
   python3 -c "import sys; print(sys.path)"
   ```
3. Reinstall backend:
   ```bash
   sudo cp -r backend/*.py /usr/local/lib/ntfs-manager/backend/
   ```

### Drive Not Detected

**Problem:** Drives don't appear in the interface

**Solutions:**
1. Check system detection:
   ```bash
   lsblk -f
   sudo fdisk -l
   ```
2. Verify udev rules:
   ```bash
   udevadm monitor
   ```
3. Restart udev:
   ```bash
   sudo systemctl restart systemd-udevd
   ```

## 🔄 Updating

### Update from Previous Version

```bash
# Backup current configuration
cp -r ~/.config/ntfs-manager ~/.config/ntfs-manager.backup

# Remove old installation
sudo rm -rf /usr/local/lib/ntfs-manager
rm -f ~/.local/share/nautilus-python/extensions/ntfs_manager_extension.py

# Install new version
cd ntfs-manager-production
sudo ./install.sh

# Restart Nautilus
nautilus -q && nautilus --no-default-window &
```

### Configuration Migration

Configuration files are typically compatible between versions. Check CHANGELOG.md for breaking changes.

## ❌ Uninstallation

### Complete Removal

```bash
# Remove Nautilus extension
rm -f ~/.local/share/nautilus-python/extensions/ntfs_manager_extension.py

# Remove backend modules
sudo rm -rf /usr/local/lib/ntfs-manager

# Remove standalone GUI
sudo rm -f /usr/local/bin/ntfs-manager-gui
sudo rm -f /usr/share/applications/ntfs-manager.desktop

# Remove icons
sudo rm -f /usr/share/icons/hicolor/*/apps/ntfs-manager.*

# Remove configuration
rm -rf ~/.config/ntfs-manager
rm -rf ~/.local/share/ntfs-manager

# Update icon cache
sudo gtk-update-icon-cache /usr/share/icons/hicolor/

# Restart Nautilus
nautilus -q && nautilus --no-default-window &
```

### Keep Configuration

To preserve your settings during removal:

```bash
# Backup configuration
cp -r ~/.config/ntfs-manager ~/ntfs-manager-config-backup

# Perform uninstallation (above steps)

# Restore configuration for future reinstall
cp -r ~/ntfs-manager-config-backup ~/.config/ntfs-manager
```

## 📚 Additional Resources

- **User Guide:** See `docs/USAGE.md`
- **Troubleshooting:** See `docs/TROUBLESHOOTING.md`
- **Architecture:** See `docs/ARCHITECTURE.md`
- **API Reference:** See `docs/API-REFERENCE.md`
- **Changelog:** See `CHANGELOG.md`
- **Main README:** See `README.md`

## 💬 Support

For installation issues:
1. Check this guide thoroughly
2. Review `docs/TROUBLESHOOTING.md`
3. Check system logs: `journalctl -xe`
4. Verify all dependencies are installed
5. Contact support: sales@magdrivex.com.au / sales@magdrivex.com

**Developer:** Darryl Bennett  
**Company:** MagDriveX (2023-2025)  
**Email:** sales@magdrivex.com.au / sales@magdrivex.com

---

**Installation completed successfully?** Next, read `docs/USAGE.md` to learn how to use NTFS Manager effectively.

**Copyright © 2023-2025 Darryl Bennett / MagDriveX. All rights reserved.**
