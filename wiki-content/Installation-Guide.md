# Installation Guide

Complete guide for installing NTFS Manager on Linux systems.

---

## 📋 Table of Contents

- [System Requirements](#system-requirements)
- [Quick Installation](#quick-installation)
- [Detailed Installation Steps](#detailed-installation-steps)
- [Installation Methods](#installation-methods)
- [Post-Installation](#post-installation)
- [Updating NTFS Manager](#updating-ntfs-manager)
- [Uninstallation](#uninstallation)
- [Enterprise Deployment](#enterprise-deployment)
- [Troubleshooting Installation](#troubleshooting-installation)

---

## System Requirements

### Minimum Requirements

| Component | Requirement |
|-----------|-------------|
| **Operating System** | Linux Kernel 5.15+ |
| **Distribution** | Ubuntu 20.04+, Debian 11+, Fedora 35+, openSUSE Leap 15.4+ |
| **Memory** | 4GB RAM |
| **Storage** | 500MB available space |
| **Python** | 3.8 or higher |
| **Desktop Environment** | GNOME, KDE, XFCE, MATE, Cinnamon, or similar |

### Recommended Requirements

| Component | Requirement |
|-----------|-------------|
| **Operating System** | Linux Kernel 6.0+ |
| **Memory** | 8GB RAM or more |
| **Storage** | 2GB available space |
| **Python** | 3.11 or higher |
| **Display** | 1024x768 resolution or higher |

### Dependencies

NTFS Manager requires the following packages:

- **Python 3.8+** with GTK bindings
- **python3-gi** - Python GObject introspection
- **gir1.2-gtk-3.0** - GTK+ 3 typelib files
- **ntfs-3g** - NTFS filesystem driver
- **policykit-1** - PolicyKit framework
- **util-linux** - System utilities

The installation script will automatically install missing dependencies.

---

## Quick Installation

### Method 1: Automated Installation (Recommended)

```bash
# Clone the repository
git clone https://github.com/sprinteroz/Linux-NTFS-Manager.git
cd Linux-NTFS-Manager

# Run the installation script
cd ntfs-manager-production
sudo ./install.sh
```

That's it! The application will be installed and available in your applications menu.

### Method 2: One-Line Installation

```bash
curl -sSL https://raw.githubusercontent.com/sprinteroz/Linux-NTFS-Manager/main/ntfs-manager-production/install.sh | sudo bash
```

**Note:** Always review scripts before running them with sudo privileges.

---

## Detailed Installation Steps

### Step 1: Download the Source Code

#### Option A: Using Git (Recommended)

```bash
# Install git if not already installed
sudo apt install git  # Ubuntu/Debian
# OR
sudo dnf install git  # Fedora
# OR
sudo zypper install git  # openSUSE

# Clone the repository
git clone https://github.com/sprinteroz/Linux-NTFS-Manager.git
cd Linux-NTFS-Manager
```

#### Option B: Download ZIP

1. Visit [GitHub Releases](https://github.com/sprinteroz/Linux-NTFS-Manager/releases)
2. Download the latest release ZIP file
3. Extract the archive:
   ```bash
   unzip Linux-NTFS-Manager-main.zip
   cd Linux-NTFS-Manager-main
   ```

### Step 2: Verify System Requirements

Check your system meets the requirements:

```bash
# Check Linux kernel version
uname -r

# Check Python version
python3 --version

# Check available disk space
df -h ~

# Check available memory
free -h
```

### Step 3: Run the Installer

```bash
cd ntfs-manager-production
sudo ./install.sh
```

The installer will:
- ✅ Check for dependencies
- ✅ Install missing packages
- ✅ Copy application files
- ✅ Install desktop entry
- ✅ Install icons
- ✅ Configure permissions
- ✅ Create symbolic links

### Step 4: Verify Installation

```bash
# Check if installed correctly
which ntfs-manager

# Test the application
ntfs-manager --version

# View help
ntfs-manager --help
```

---

## Installation Methods

### Ubuntu / Debian Installation

```bash
# Update package lists
sudo apt update

# Install dependencies
sudo apt install -y python3 python3-gi python3-gi-cairo \
    gir1.2-gtk-3.0 ntfs-3g policykit-1 git

# Clone and install
git clone https://github.com/sprinteroz/Linux-NTFS-Manager.git
cd Linux-NTFS-Manager/ntfs-manager-production
sudo ./install.sh
```

### Fedora Installation

```bash
# Update system
sudo dnf update

# Install dependencies
sudo dnf install -y python3 python3-gobject gtk3 \
    ntfs-3g polkit git

# Clone and install
git clone https://github.com/sprinteroz/Linux-NTFS-Manager.git
cd Linux-NTFS-Manager/ntfs-manager-production
sudo ./install.sh
```

### openSUSE Installation

```bash
# Update system
sudo zypper refresh

# Install dependencies
sudo zypper install -y python3 python3-gobject python3-gobject-Gdk \
    typelib-1_0-Gtk-3_0 ntfs-3g polkit git

# Clone and install
git clone https://github.com/sprinteroz/Linux-NTFS-Manager.git
cd Linux-NTFS-Manager/ntfs-manager-production
sudo ./install.sh
```

### Arch Linux Installation

```bash
# Update system
sudo pacman -Syu

# Install dependencies
sudo pacman -S python python-gobject gtk3 ntfs-3g polkit git

# Clone and install
git clone https://github.com/sprinteroz/Linux-NTFS-Manager.git
cd Linux-NTFS-Manager/ntfs-manager-production
sudo ./install.sh
```

---

## Post-Installation

### Launch the Application

#### GUI Method
1. Open your application menu
2. Search for "NTFS Manager"
3. Click the icon to launch

#### Command Line Method
```bash
# Launch GUI
ntfs-manager

# Get help
ntfs-manager --help

# List drives
ntfs-manager --list
```

### Configure Settings

On first launch, NTFS Manager will:
- Detect your system language automatically
- Create configuration directory: `~/.config/ntfs-manager/`
- Initialize log files: `~/.local/share/ntfs-manager/logs/`

### Install Language Packs (Optional)

```bash
cd Linux-NTFS-Manager/language-packs
sudo ./install-all-languages.sh

# Or install specific language
sudo ./install-language.sh es  # Spanish
sudo ./install-language.sh fr  # French
sudo ./install-language.sh de  # German
```

### Install Nautilus Extension (Optional)

For right-click context menu integration:

```bash
cd Linux-NTFS-Manager/ntfs-nautilus-extension
sudo ./install.sh

# Restart Nautilus
nautilus -q
```

---

## Updating NTFS Manager

### Update from Git

```bash
cd Linux-NTFS-Manager
git pull origin main
cd ntfs-manager-production
sudo ./install.sh
```

### Check for Updates

```bash
# Check current version
ntfs-manager --version

# Compare with latest release
curl -s https://api.github.com/repos/sprinteroz/Linux-NTFS-Manager/releases/latest | grep tag_name
```

---

## Uninstallation

### Remove NTFS Manager

```bash
# Remove application files
sudo rm -rf /usr/local/lib/ntfs-manager
sudo rm /usr/local/bin/ntfs-manager

# Remove desktop entry
sudo rm /usr/share/applications/ntfs-manager.desktop

# Remove icons
sudo rm /usr/share/icons/hicolor/*/apps/ntfs-manager.*

# Update icon cache
sudo gtk-update-icon-cache /usr/share/icons/hicolor/

# Remove user configuration (optional)
rm -rf ~/.config/ntfs-manager
rm -rf ~/.local/share/ntfs-manager
```

### Remove Nautilus Extension

```bash
rm ~/.local/share/nautilus-python/extensions/ntfs_manager_extension.py
nautilus -q
```

---

## Enterprise Deployment

### Automated Deployment Script

For deploying to multiple systems:

```bash
#!/bin/bash
# deploy-ntfs-manager.sh

set -e

# Configuration
REPO_URL="https://github.com/sprinteroz/Linux-NTFS-Manager.git"
INSTALL_DIR="/opt/ntfs-manager"

# Clone repository
git clone "$REPO_URL" "$INSTALL_DIR"

# Run installation
cd "$INSTALL_DIR/ntfs-manager-production"
./install.sh --silent

# Verify installation
ntfs-manager --version

echo "NTFS Manager installed successfully"
```

### Configuration Management

Create a central configuration file:

```bash
# /etc/ntfs-manager/config.conf
[global]
auto_mount = true
log_level = INFO
audit_enabled = true

[security]
require_auth = true
allow_format = false
```

### Deploy with Ansible

```yaml
# ansible-playbook.yml
---
- name: Deploy NTFS Manager
  hosts: workstations
  become: yes
  
  tasks:
    - name: Install dependencies
      apt:
        name:
          - python3
          - python3-gi
          - ntfs-3g
          - policykit-1
        state: present
      
    - name: Clone repository
      git:
        repo: https://github.com/sprinteroz/Linux-NTFS-Manager.git
        dest: /opt/ntfs-manager
        version: main
      
    - name: Run installer
      command: /opt/ntfs-manager/ntfs-manager-production/install.sh
      args:
        creates: /usr/local/bin/ntfs-manager
```

---

## Troubleshooting Installation

### Common Issues

#### Issue: "Python 3 not found"

**Solution:**
```bash
# Install Python 3
sudo apt install python3 python3-pip  # Ubuntu/Debian
sudo dnf install python3 python3-pip  # Fedora
```

#### Issue: "GTK bindings not found"

**Solution:**
```bash
sudo apt install python3-gi gir1.2-gtk-3.0  # Ubuntu/Debian
sudo dnf install python3-gobject gtk3       # Fedora
```

#### Issue: "Permission denied"

**Solution:**
```bash
# Ensure script is executable
chmod +x install.sh

# Run with sudo
sudo ./install.sh
```

#### Issue: "ntfs-3g not installed"

**Solution:**
```bash
sudo apt install ntfs-3g      # Ubuntu/Debian
sudo dnf install ntfs-3g      # Fedora
sudo pacman -S ntfs-3g        # Arch Linux
```

### Verification Commands

```bash
# Check all dependencies
dpkg -l | grep -E 'python3-gi|ntfs-3g|policykit'

# Verify Python modules
python3 -c "import gi; gi.require_version('Gtk', '3.0'); print('GTK bindings OK')"

# Check installation paths
ls -la /usr/local/bin/ntfs-manager
ls -la /usr/share/applications/ntfs-manager.desktop
```

### Getting Help

If you encounter issues:

1. **Check the logs:**
   ```bash
   cat ~/.local/share/ntfs-manager/logs/ntfs-manager.log
   ```

2. **Run with verbose output:**
   ```bash
   ntfs-manager --verbose
   ```

3. **Report an issue:**
   - Visit [GitHub Issues](https://github.com/sprinteroz/Linux-NTFS-Manager/issues)
   - Include system information
   - Attach log files
   - Describe the problem

---

## Next Steps

After installation:

1. **[Quick Start Guide](Quick-Start)** - Learn basic usage
2. **[User Guide](User-Guide)** - Explore all features
3. **[Configuration](Configuration)** - Customize settings
4. **[Troubleshooting](Troubleshooting)** - Solve common issues

---

**Installation complete!** 🎉

Need help? Check our [Troubleshooting](Troubleshooting) guide or [open an issue](https://github.com/sprinteroz/Linux-NTFS-Manager/issues).
