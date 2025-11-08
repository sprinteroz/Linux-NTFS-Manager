# NTFS Manager - Professional NTFS Drive Management for Linux

[![NTFS Manager Logo](https://github.com/sprinteroz/Linux-NTFS-Manager/raw/main/icons/ntfs-manager-256.png)]

[![CI](https://github.com/sprinteroz/Linux-NTFS-Manager/workflows/Continuous%20Integration%20(Simple)/badge.svg)](https://github.com/sprinteroz/Linux-NTFS-Manager/actions/workflows/ci-simple.yml)
[![Dependency Review](https://github.com/sprinteroz/Linux-NTFS-Manager/workflows/Dependency%20Review/badge.svg)](https://github.com/sprinteroz/Linux-NTFS-Manager/actions/workflows/dependency-review.yml)
[![Security Policy](https://img.shields.io/badge/security-policy-blue.svg)](SECURITY.md)
[![License: Dual](https://img.shields.io/badge/License-Dual-orange.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.3-green.svg)](VERSION)

---

## 🔴 Frustrated by "NTFS Drive is Read-Only" Errors?

**You're not alone.** Millions of dual-boot Linux users face this every day:

> *"Help! My external drive suddenly became read-only!"*  
> *"I can see my files but can't copy anything to the drive!"*  
> *"Why does my Windows partition mount read-only in Linux?"*

### 🤔 Why This Happens

When Windows 10/11 "shuts down" with **Fast Startup enabled** (the default), it's actually **hibernating**. This leaves your NTFS drives in a "hibernated" state with a dirty bit set.

Linux's ntfs-3g driver **correctly refuses** to mount these drives read-write to protect your data from corruption. You'll see errors like:
- `The disk contains an unclean file system`
- `Metadata kept in Windows cache, refused to mount`
- `Mount is denied because the NTFS volume is in an unsafe state`

### ✅ The Solution

**Linux NTFS Manager** makes fixing this **simple and safe**:

- 🎯 **One-Click Fix** - Safely removes the Windows hibernation flag
- 📚 **Educational** - Explains what's wrong and why (not just "click here")
- 🛡️ **Safe** - No data loss, no force-mounting, no dangerous flags
- 🌍 **32 Languages** - Helps users worldwide understand NTFS issues
- 🔄 **Prevents Recurrence** - Guides you to disable Fast Startup permanently

**No more rebooting to Windows just to shut it down properly.**  
**No more searching forums for `ntfsfix` commands.**  
**No more panicking about "lost" files.**

---

## 🚨 CRITICAL WARNING: Known Incompatible Software

### ⚠️ Balena Etcher Breaks NTFS Functionality

**DO NOT INSTALL BALENA ETCHER** if you need NTFS drive functionality!

Balena Etcher modifies system-level permissions that **break**:
- ❌ NTFS drive mounting
- ❌ Writing to NTFS partitions
- ❌ NTFS drive formatting
- ❌ Hot-swap functionality
- ❌ May also affect network connectivity and Node.js

**If you've already installed balena Etcher and are experiencing NTFS issues:**

```bash
# Run our recovery script to fix the damage
cd Linux-NTFS-Manager
sudo ./scripts/balena-etcher-recovery.sh
```

**Safe Alternatives to Balena Etcher:**
- ✅ **GNOME Disks** (recommended): `sudo apt install gnome-disk-utility`
- ✅ **Popsicle**: `sudo apt install popsicle-gtk`
- ✅ **dd command**: Native Linux tool, no installation needed
- ✅ **Ventoy**: Multi-boot USB solution

📖 **[Full Details: Known Incompatible Software](docs/KNOWN-INCOMPATIBLE-SOFTWARE.md)**

---

## 🚀 Quick Start

```bash
# Clone and install
git clone https://github.com/sprinteroz/Linux-NTFS-Manager.git
cd Linux-NTFS-Manager
./install.sh

# Or fix read-only NTFS drives directly
sudo ntfsfix /dev/sdX1  # Clears Windows hibernation flag
```

**[📥 Download Latest Release](https://github.com/sprinteroz/Linux-NTFS-Manager/releases/tag/v1.0.3)** | **[📖 Read Testing Guide](TESTING-GUIDE.md)** | **[🐛 Report Issues](https://github.com/sprinteroz/Linux-NTFS-Manager/issues)**

---

## 💡 Who This Is For

✅ **Dual-boot users** tired of NTFS mounting issues  
✅ **New Linux users** who need clear explanations  
✅ **System administrators** managing multiple NTFS drives  
✅ **Anyone** who shares drives between Windows and Linux

---

## ✨ Features

### Core Functionality
- **🔄 Automatic NTFS Mounting**: Internal NTFS drives auto-mount on startup with proper permissions
- **💿 ISO Burner**: Burn ISO images to USB drives with progress tracking and verification
- **🔌 Hotplug Monitoring**: Real-time udev monitoring for automatic drive detection and mounting
- **🔥 Hot-Swap Ready**: Safely remove drives without data loss using udisksctl
- **Drive Management**: Mount, unmount, and safely remove NTFS drives
- **Dirty Bit Detection**: Identifies Windows hibernation issues automatically
- **Safe NTFS Repair**: Uses ntfsfix to clear hibernation flags safely
- **One-Click Remounting**: Automatically remounts after fixing
- **File Operations**: Copy, move, delete files on NTFS partitions
- **Drive Information**: View disk space, health status, and partition details
- **Format Options**: Quick format with multiple filesystem options
- **GParted Integration**: Advanced partitioning operations
- **Permission Management**: Handle ownership and permission issues

### User Interface
- **Modern GTK3 Interface**: Clean, intuitive desktop application
- **Educational Dialogs**: Explains WHY drives are read-only, not just HOW to fix
- **Command Line Tools**: Full CLI support for automation and scripting
- **Nautilus Integration**: Right-click context menu for file operations
- **System Tray**: Quick access and status monitoring
- **Multi-Language Support**: 32 languages with automatic detection

### Enterprise Features
- **Audit Logging**: Comprehensive operation tracking
- **Role-Based Access**: User permission management
- **API Integration**: Extensible for custom workflows
- **Performance Monitoring**: Resource usage tracking
- **Security Scanning**: Regular vulnerability assessments

---

## 🌍 Multi-Language Support

**32 Languages Fully Supported:**
English, Spanish, French, German, Chinese, Japanese, Korean, Russian, Italian, Portuguese, Dutch, Polish, Turkish, Swedish, Norwegian, Danish, Finnish, Czech, Greek, Hebrew, Arabic, Hindi, Thai, Vietnamese, Indonesian, Malay, Hungarian, Romanian, Ukrainian, Bulgarian, Croatian, Serbian

### Language Detection
- **Automatic**: System locale detection
- **Manual**: Language selection option
- **Fallback**: English default for missing translations


Linux-NTFS-Manager: Hot-Swap Support & WinBoat Integration
---

[Screencast from 2025-11-05 11-21-32.webm](https://github.com/user-attachments/assets/97b88555-5cee-4549-b051-a5d4bec91a1e)

---

https://github.com/sprinteroz/Linux-NTFS-Manager/discussions

---

Breaking: Play Steam Games on NTFS Drives in Linux with Linux-NTFS-Manager 
---

[Screencast from 2025-11-05 16-25-22.webm](https://github.com/user-attachments/assets/3f0bf3da-f227-447c-bb01-4eb142e6a3d9)

---
 
## 🚀 Installation

### Quick Install
```bash
# Clone the repository
git clone https://github.com/sprinteroz/Linux-NTFS-Manager.git
cd Linux-NTFS-Manager

# Run installation script
./install.sh
```

### Requirements
- **Linux**: Ubuntu 20.04+, Debian 11+, Fedora 35+, openSUSE Leap 15.4+
- **Memory**: 4GB+ RAM recommended
- **Storage**: 500MB available space
- **Permissions**: sudo access for system integration

### Package Managers
- **APT**: `sudo apt install ntfs-manager`
- **DNF**: `sudo dnf install ntfs-manager`
- **Pacman**: `sudo pacman -S ntfs-manager`

---

## 📊 System Requirements

### Minimum Requirements
- **OS**: Linux (Kernel 5.15+)
- **Desktop**: GNOME, KDE, XFCE, MATE, Cinnamon
- **Memory**: 4GB RAM
- **Storage**: 500MB free space
- **Python**: 3.8+ (included with package)

### Recommended Requirements
- **OS**: Linux (Kernel 6.0+)
- **Memory**: 8GB+ RAM
- **Storage**: 2GB free space
- **Display**: 1024x768 resolution

---

## 🔧 Usage

### GUI Application
```bash
# Launch from applications menu
ntfs-manager

# Or run from command line
ntfs-manager --help
```

### Command Line
```bash
# List all drives
ntfs-manager --list

# Mount specific drive
ntfs-manager --mount /dev/sdb1

# Get drive information
ntfs-manager --info /dev/sdb1

# Unmount drive
ntfs-manager --unmount /dev/sdb1
```

---

## 📁 Downloads

### Stable Release
- **Version**: 1.0.3
- **Release Date**: November 4, 2025
- **Status**: Production Ready

### Download Options
- **GitHub Releases**: [Download Latest Release](https://github.com/sprinteroz/Linux-NTFS-Manager/releases)
- **Source Code**: [Browse Repository](https://github.com/sprinteroz/Linux-NTFS-Manager)
- **Language Packs**: [Available Separately](https://github.com/sprinteroz/Linux-NTFS-Manager/releases)

---

## 🛠️ Troubleshooting

### Common Issues
- **Permission Denied**: Use `sudo` for system operations
- **Drive Not Found**: Check device paths in `/dev/`
- **Mount Failed**: Verify NTFS-3g is installed
- **GUI Not Starting**: Check display environment variables

### Getting Help
- **Documentation**: [Online Manual](https://github.com/sprinteroz/Linux-NTFS-Manager/wiki)
- **Community Support**: [GitHub Discussions](https://github.com/sprinteroz/Linux-NTFS-Manager/discussions)
- **Bug Reports**: [GitHub Issues](https://github.com/sprinteroz/Linux-NTFS-Manager/issues)

---

## 💬 Community & Discussions

Join our growing community of Linux NTFS Manager users!

- **[GitHub Discussions](https://github.com/sprinteroz/Linux-NTFS-Manager/discussions)** - Ask questions, share feedback, request features
- **[Bug Reports](https://github.com/sprinteroz/Linux-NTFS-Manager/issues)** - Report issues and track fixes
- **[Testing Program](TESTING-GUIDE.md)** - Help test the free version and shape development

**Note:** Linux NTFS Manager is free for personal use. Commercial use requires a paid license - see [LICENSE](LICENSE) for details.

---

## 📞 Support

### Professional Support
- **Email**: support_ntfs@magdrivex.com.au  **Available in 6 months for business - once proven stable** 
- **Documentation**: [Online Manual](https://github.com/sprinteroz/Linux-NTFS-Manager/wiki)
- **Community**: [GitHub Discussions](https://github.com/sprinteroz/Linux-NTFS-Manager/discussions)

### Reporting Issues
Please include:
- System information (`uname -a`)
- NTFS Manager version
- Error messages
- Steps to reproduce

---

## 🔒 Security

### Security Features
- **Permission Management**: User access control
- **Audit Logging**: Comprehensive operation tracking
- **Safe Operations**: Verified hot-swap support
- **Regular Updates**: Security patches and improvements
- **Code Review**: Professional development practices

### Privacy
- **No Telemetry**: No data collection without consent
- **Local Processing**: All operations performed locally
- **Open Source**: Transparent and auditable codebase

---

## 📄 License

### Dual License Model
This project uses a **DUAL LICENSE** system:

### 🏠 Personal Use - FREE
**For home users, students, and personal projects**
- ✅ **100% FREE** for personal, non-commercial use
- ✅ Use at home for personal computing
- ✅ Educational and learning purposes
- ✅ Personal hobby projects
- ❌ **NOT for business or commercial use**

### 💼 Commercial Use - PAID LICENSE REQUIRED
**Available in 6 months or once proven to be publiclly stable - in free version** 
**For businesses, companies, and organizations**
- ⚠️ **Paid license required** for any business use
- 💼 Pricing: $99 - $2,999 USD/year (based on company size)
- 📧 Contact: sales@magdrivex.com.au / sales@magdrivex.com
- 🆓 30-day free trial available/ comming soon

### License Files
- **[LICENSE](LICENSE)** - Dual license overview
- **[LICENSE-PERSONAL](LICENSE-PERSONAL)** - Free personal use terms
- **[LICENSE-COMMERCIAL](LICENSE-COMMERCIAL)** - Paid commercial terms
- **[ntfs-manager-production/LICENSING.md](ntfs-manager-production/LICENSING.md)** - Detailed pricing and commercial information

### Quick Guide
✅ **FREE if:** Using at home, learning, personal projects  
❌ **PAID if:** Using at work, in a business, or for profit

**When in doubt, you need a commercial license.**

---

## 🤝 Contributing

We welcome contributions from the community!

### How to Contribute
- **Bug Reports**: [Open Issue](https://github.com/sprinteroz/Linux-NTFS-Manager/issues)
- **Feature Requests**: [Start Discussion](https://github.com/sprinteroz/Linux-NTFS-Manager/discussions)
- **Code Contributions**: [Pull Requests](https://github.com/sprinteroz/Linux-NTFS-Manager/pulls)
- **Translations**: [Translation Guide](https://github.com/sprinteroz/Linux-NTFS-Manager/wiki/Translating)

### Development
- **Code Style**: Follow existing patterns
- **Testing**: Include tests with contributions
- **Documentation**: Update relevant sections

---

## 🏆️ Acknowledgments

### Core Technologies
- **GTK+**: Modern user interface framework
- **NTFS-3g**: NTFS filesystem support
- **Python**: Cross-platform compatibility
- **Linux**: Native system integration

### Community
Thanks to all users who have contributed to making NTFS Manager better through feedback, testing, and suggestions.

---

## 📈 Version History

**Current Version**: 1.0.3 (Stable)

### Recent Updates
- **v1.0.3**: Testing new stable release
- **v1.0.2**: Security fixes and stability improvements
- **v1.0.1**: System resource management tools
- **v1.0.0**: Initial stable release

---

**NTFS Manager - Professional NTFS Drive Management for Linux**

*© 2023-2025 MagDriveX - NTFS Manager Project. All rights reserved.*
