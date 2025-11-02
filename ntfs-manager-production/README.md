# NTFS Manager - Production Ready Solution

A comprehensive NTFS drive management solution that integrates seamlessly with Nautilus file manager, providing Windows-style drive management capabilities on Linux desktop environments.

## 🎯 Overview

NTFS Manager transforms the Linux desktop experience by providing native NTFS drive management directly within Nautilus file manager. Users can right-click on any drive or mount point to access comprehensive drive management functionality without launching a separate application.

## 📦 Features

### Core Functionality
- **Native Nautilus Integration**: Right-click context menu with "NTFS Management" submenu
- **Windows-style Properties**: Tabbed interface with Basic, NTFS, and Health information tabs
- **Real-time Monitoring**: Automatic drive detection and status updates
- **Multi-filesystem Support**: NTFS, EXT4, FAT32, exFAT compatibility
- **Safety Features**: Permission checks, confirmation dialogs, audit logging
- **Visual Enhancements**: Status emblems, additional columns, desktop notifications

### Advanced Capabilities
- **Comprehensive Logging**: Structured logging with JSON export capability
- **Configuration System**: User-customizable settings and preferences
- **Error Recovery**: Graceful fallbacks when dependencies unavailable
- **System Integration**: Desktop files, icons, and proper permissions
- **Extensible Architecture**: Foundation for future enhancements

## 🚀 Quick Start

### Installation
```bash
# Clone or download the production package
git clone <repository-url> ntfs-manager-production
cd ntfs-manager-production

# Install with enhanced installer
./install-enhanced.sh

# Restart Nautilus to load the extension
nautilus -q && nautilus --no-default-window &
```

### Basic Usage
1. **Right-click** on any drive or mount point in Nautilus
2. **Select "NTFS Management"** from the context menu
3. **Choose your operation**:
   - Mount/Unmount Drive
   - Drive Properties (Windows-style information)
   - Health Check (SMART and filesystem status)
   - Repair Drive (fix filesystem errors)
   - Format Drive (with safety warnings)
   - Safe Eject (for removable drives)

## 📁 System Requirements

### Minimum Requirements
- **OS**: Ubuntu 18.04+ / Debian 10+ or compatible Linux distribution
- **Python**: 3.8 or higher
- **Nautilus**: 3.20 or higher with Python bindings
- **Memory**: 512MB RAM
- **Storage**: 100MB free space

### Recommended Requirements
- **OS**: Ubuntu 20.04+ / Debian 11+ or compatible Linux distribution
- **Python**: 3.10 or higher
- **Nautilus**: 3.24 or higher
- **Memory**: 1GB RAM
- **Storage**: 200MB free space

### Optional Dependencies
- **GParted**: For advanced partitioning (gparted package)
- **HDDtemp**: For temperature monitoring (hddtemp package)
- **Notify-OSD**: For desktop notifications (libnotify-bin package)

## 📂 File Structure

```
ntfs-manager-production/
├── README.md                      # This file
├── INSTALLATION.md                # Installation guide
├── CHANGELOG.md                   # Version history
├── LICENSE                        # Software license
├── requirements.txt                 # Python dependencies
├── dependencies.txt                # System dependencies
├── VERSION                        # Current version
├── nautilus-extension/            # Nautilus integration
│   ├── ntfs_manager_extension.py    # Main extension
│   ├── install.sh                  # Basic installer
│   └── install-enhanced.sh         # Enhanced installer
├── backend/                       # Backend modules
│   ├── drive_manager.py
│   ├── ntfs_properties.py
│   ├── logger.py
│   └── gparted_integration.py
├── standalone-gui/               # Optional standalone GUI
│   ├── main.py
│   ├── ntfs-manager.desktop
│   └── icons/
├── icons/                         # Application icons
├── docs/                          # Additional documentation
│   ├── USAGE.md
│   ├── TROUBLESHOOTING.md
│   ├── API-REFERENCE.md
│   └── ARCHITECTURE.md
└── tests/                         # Testing scripts
    └── test_integration.py
```

## 🔧 Configuration

The extension creates configuration at `~/.config/ntfs-manager/config.ini` with the following default settings:

```ini
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
```

## 📊 Logging

Comprehensive logging is available at `~/.local/share/ntfs-manager/logs/` with the following log files:
- `main.log` - General application logs
- `operations.log` - Drive operation history
- `errors.log` - Error and warning messages
- `security.log` - Security-related events
- `structured.json` - Machine-readable JSON logs

## 🛡️ Security

- **Permission Validation**: Verifies user permissions before operations
- **Mount Protection**: Prevents mounting of system partitions
- **Format Confirmation**: Multiple confirmation dialogs for destructive operations
- **Audit Logging**: All operations logged with user context
- **Encryption Support**: Detection and handling of encrypted volumes

## 📈 Troubleshooting

### Common Issues

**Extension Not Loading:**
1. Install Nautilus Python bindings: `sudo apt install python3-nautilus`
2. Restart Nautilus: `nautilus -q && nautilus --no-default-window &`
3. Check extension: Look for "NTFS Management" in right-click menu

**Operations Failing:**
1. Check user permissions: Ensure user is in `disk` and `plugdev` groups
2. Verify system tools: Ensure `ntfs-3g`, `smartctl`, `mount`, `umount` are available
3. Check backend modules: Verify backend files are properly installed

**Drive Not Detected:**
1. Check system tools: Ensure `lsblk` and `udevadm` are working
2. Check permissions: Ensure user can read `/dev/` directory
3. Restart system: Some drive detection requires system restart

## 📞 Support

For issues, support, and contributions:
- **Documentation**: See `docs/` directory for comprehensive guides
- **Troubleshooting**: See `docs/TROUBLESHOOTING.md` for common issues
- **API Reference**: See `docs/API-REFERENCE.md` for developer documentation
- **Architecture**: See `docs/ARCHITECTURE.md` for technical details

## 📜 License

This project is released under a dual-license model:
- **Free for personal/non-commercial use** under the MIT License
- **Commercial license required** for business use

See `LICENSING.md` file for complete licensing information and pricing.

## 👨‍💻 Author & Company

**Developer:** Darryl Bennett  
**Company:** MagDriveX (2023-2025)  
**ABN:** 82 977 519 307  
**Address:** PO Box 28 Ardlethan NSW 2665 Australia  
**Email:** sales@magdrivex.com.au / sales@magdrivex.com

**Copyright © 2023-2025 Darryl Bennett / MagDriveX. All rights reserved.**

---

**NTFS Manager** - Professional NTFS drive management integrated directly into your Linux file manager.

*Transform your Linux desktop experience with Windows-style drive management capabilities while maintaining the power and security of Linux tools.*
