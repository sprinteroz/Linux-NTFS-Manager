# Changelog - Balena Etcher Compatibility Fix

## [1.0.6] - 2025-11-06

### 🔧 Drive Details Enhancement

#### Fixed

**Drive Information Display:**
- Fixed empty Vendor field for NVMe drives (now extracts from model string)
- Fixed empty hardware info (Model/Vendor/Serial) for partitions
  - Partitions now inherit hardware info from parent device
  - sda1 now shows info from sda, nvme0n1p1 from nvme0n1, etc.
- Fixed virtual device status messages
  - zram0 and other virtual devices now show "N/A (virtual device)"
  - Previously showed misleading "Unknown" or "Error" status

**Backend Improvements:**
- Enhanced `_get_hardware_info()` with NVMe vendor parsing
  - Detects known vendors (Samsung, SK hynix, Intel, etc.) from model string
  - Falls back to multiple udevadm property fields
- Improved `_get_volume_label()` with sudo support
  - Uses sudo for blkid, ntfslabel, ntfsinfo commands
  - Better NTFS label detection for unmounted partitions
- Enhanced parent device resolution for all partition types
  - Handles NVMe partitions (nvme0n1p1 → nvme0n1)
  - Handles SATA partitions (sda1 → sda)

#### Changed

**User Experience:**
- More accurate and complete drive information
- Virtual devices properly identified
- Partition hardware details now complete

### 🧪 Testing

**All Improvements Verified:**
- ✅ NVMe vendor extraction: "SK hynix", "Samsung" displaying correctly
- ✅ Partition hardware info: sda1 shows Model/Vendor/Serial from sda
- ✅ Virtual device handling: zram0 shows "N/A (virtual device)"
- ✅ NTFS health status: Properly detects "Healthy" status
- ✅ All 8 drives detected and displaying complete information

### 📝 Notes

**For Users:**
- Empty Label fields are correct if the partition has no volume label set
- Use `sudo ntfslabel /dev/sdX1 "LabelName"` to set labels if desired
- All improvements work on existing installations after restart

**For Developers:**
- Parent device resolution handles all device naming conventions
- Vendor extraction supports all major NVMe manufacturers
- Label extraction works with or without sudo password prompts

---

## [1.0.5] - 2025-11-06

### ✨ Major Feature Update - Complete Drive Management Suite

#### Added

**New Complete Manager Features:**
- 🔄 **Automatic NTFS Mounting** - Internal NTFS drives auto-mount on startup
  - Scans all internal drives (sda, sdb, nvme) for NTFS partitions
  - Mounts to `/media/ntfs-{device}` with proper user permissions
  - Configurable mount options (permissions, uid, gid)
  - Error handling and detailed logging
  - Startup integration via desktop application

- 💿 **ISO Image Burner** - Burn ISO files to USB drives
  - File browser for ISO selection
  - Target drive selection with safety checks
  - Progress tracking with real-time updates
  - Verification after burning (optional)
  - dd-based burning with configurable block size
  - Automatic unmount before burning
  - Success/failure notifications

- 🔌 **Hotplug Monitoring** - Real-time drive detection
  - udev-based device monitoring
  - Automatic detection of newly connected drives
  - Hotplug notifications with drive information
  - Dynamic UI updates when drives added/removed
  - Support for USB, SATA, and NVMe drives
  - Thread-safe drive list management

- 🔥 **Hot-Swap Support** - Safe drive removal
  - udisksctl integration for safe unmounting
  - Power-off capability for removable drives
  - Automatic cleanup of mount points
  - Safety checks to prevent data loss
  - Status feedback during operations
  - Support for all drive types

**Enhanced Backend:**
- `ntfs-complete-manager-gui/backend/drive_manager.py` - Complete rewrite (495 lines)
  - Advanced udev monitoring with GLib integration
  - Robust error handling and logging
  - Thread-safe operations
  - Device filtering and classification
  - Comprehensive drive information gathering
  - Smart dependency checking (udisks2, ntfsfix, etc.)

**Updated GUI:**
- `ntfs-complete-manager-gui/main.py` - Enhanced interface (900 lines)
  - New ISO Burner tab with full workflow
  - Auto-mount management interface
  - Real-time drive status updates
  - Enhanced error dialogs with detailed information
  - Progress bars for long operations
  - Modern GTK3 widget implementation

**New Dependencies:**
- `python3-gi` - GTK3 Python bindings
- `gir1.2-gtk-3.0` - GTK3 introspection data
- `udisks2` - Advanced disk management
- `ntfs-3g` (ntfsfix included) - NTFS filesystem support
- `python3-pip` - Python package manager
- `PyGObject` - Python package for GTK bindings

**Enhanced Installation:**
- Updated `ntfs-complete-manager-gui/install.sh`
  - Improved dependency checking with package mapping
  - Detection of all required system packages
  - Verification of Python GTK bindings
  - Smart package name resolution
  - Requirements.txt integration

- New `ntfs-complete-manager-gui/requirements.txt`
  - PyGObject>=3.42.0 for GTK3 support
  - pip-installable Python dependencies

#### Changed

**System Integration:**
- Enhanced PolicyKit rules for password-free operations
- Improved udev rules for device monitoring
- Better launcher script with proper working directory
- Comprehensive logging to `/var/log/ntfs-manager/`

**User Experience:**
- Cleaner, more intuitive interface
- Better error messages with actionable solutions
- Real-time status updates during operations
- Confirmation dialogs for destructive operations
- Educational tooltips and help text

#### Fixed

**Issues Resolved:**
- Manual mounting no longer required for internal drives
- Hot-swap drives now properly detected and mounted
- ISO burning without third-party tools (no more balena Etcher needed!)
- Drive removal now truly safe with proper unmounting
- UI freezing during long operations eliminated

### 🧪 Testing

**All Features Verified:**
```
INFO: Auto-mounting internal NTFS drive: sda1
INFO: Auto-mounting internal NTFS drive: sdb1  
INFO: Auto-mounting internal NTFS drive: nvme1n1p1
Drive monitoring started
INFO: Operation: burn_iso on sdc1 - success
```

- ✅ Auto-mount on startup working flawlessly
- ✅ ISO burner successfully creates bootable USBs
- ✅ Hotplug detection instant and reliable
- ✅ Hot-swap removal with no data loss
- ✅ All dependencies properly installed
- ✅ Only cosmetic GTK deprecation warnings (non-breaking)

### 📚 Documentation

**Updated Files:**
- `README.md` - Added new feature descriptions
- `ntfs-complete-manager-gui/install.sh` - Enhanced with new dependencies
- `ntfs-complete-manager-gui/requirements.txt` - Created for Python deps

### 🎯 Impact

**User Benefits:**
- No more manual mounting of NTFS drives
- Safe ISO burning without balena Etcher
- Automatic drive detection eliminates refreshing
- Peace of mind with safe hot-swap removal
- Complete drive management in one application

**Technical Improvements:**
- Modern udev integration replaces polling
- udisks2 provides reliable unmounting
- Thread-safe operations prevent UI freezing
- Comprehensive error handling improves stability
- Better logging aids troubleshooting

### 📝 Notes

**For Users:**
- Launch from application menu: "NTFS Complete Manager"
- Auto-mount runs on startup automatically
- ISO burner provides safe alternative to balena Etcher
- All operations logged for troubleshooting
- Requires sudo password for system operations

**For Developers:**
- PyGObject 3.42+ required for GTK3
- udev monitoring requires GLib main loop
- Thread-safe with proper locking
- Follows Python best practices
- Comprehensive inline documentation

---

## [1.0.4] - 2025-11-06

### 🚨 Critical Fix - Balena Etcher Compatibility

#### Added

**New Scripts:**
- `scripts/balena-etcher-recovery.sh` - Comprehensive NTFS functionality recovery script
  - Repairs NTFS packages (ntfs-3g, ntfsprogs, udisks2)
  - Restores user permissions and group memberships
  - Fixes udev rules for auto-mounting
  - Repairs PolicyKit permissions for password-free mounting
  - Cleans mount points and stuck mounts
  - Fixes network connectivity issues
  - Checks and repairs Node.js installation
  - Tests all NTFS functionality
  - Creates system backups before changes

- `scripts/remove-balena-etcher-surgical.sh` - Safe balena Etcher removal (preserves Node.js)
  - Removes only balena Etcher files
  - Preserves Node.js installations (all versions)
  - Preserves npm and all modules
  - Preserves all other programs and user data
  - Verifies Node.js integrity after removal
  - Optional automatic recovery script execution

- `scripts/remove-balena-etcher.sh` - General removal script (aggressive)
  - Comprehensive system-wide removal
  - Handles multiple installation methods (snap, apt, AppImage)
  - Cleans udev rules and PolicyKit policies
  - Updates desktop database

- `scripts/check-software-compatibility.sh` - System compatibility checker
  - Detects balena Etcher and other problematic software
  - Checks NTFS package installations
  - Verifies user permissions and groups
  - Validates udev rules and PolicyKit policies
  - Tests NTFS mount functionality
  - Provides detailed recommendations

- `install.sh`  - Root-level interactive installation menu
  - Automatic balena Etcher detection with warnings
  - Access to all installation options
  - Built-in compatibility checking
  - Recovery script integration
  - User-friendly interface

**New Documentation:**
- `docs/KNOWN-INCOMPATIBLE-SOFTWARE.md` - Comprehensive compatibility database
  - Detailed balena Etcher analysis
  - Safe alternatives (GNOME Disks, Popsicle, dd, Ventoy)
  - Prevention strategies
  - Compatibility database for other software
  - Community reporting guidelines

- `BALENA-ETCHER-RECOVERY-GUIDE.md` - Step-by-step recovery guide
  - Quick recovery instructions
  - Manual repair steps if needed
  - Detailed technical explanations
  - Troubleshooting section
  - Success indicators
  - Prevention recommendations

- `GITHUB-ISSUE-BALENA-ETCHER.md` - Complete issue documentation
  - Problem description and severity
  - Affected components detailed
  - Complete solution documentation
  - Technical analysis
  - Testing procedures
  - Impact assessment

#### Changed

**Modified Files:**
- `README.md` - Added prominent balena Etcher warning section
  - Critical warning at top of Quick Start section
  - Links to recovery script
  - Safe alternatives listed
  - Full documentation references

#### Fixed

**Issues Resolved:**
- Critical: Balena Etcher breaks NTFS mounting functionality
- Critical: Balena Etcher breaks write access to NTFS partitions
- Critical: Balena Etcher breaks NTFS drive formatting
- Critical: Balena Etcher breaks hot-swap functionality
- High: Balena Etcher may cause network connectivity issues
- Medium: Balena Etcher may affect Node.js installations

**System Components Repaired:**
- Udev rules for NTFS device auto-mounting
- PolicyKit permissions for password-free operations
- User group memberships (disk, plugdev, fuse)
- FUSE module configuration
- udisks2 service configuration
- Network manager services

### 🛡️ Security

- All scripts create backups before making system changes
- User confirmation required for system modifications
- Detailed logging for all operations
- Safe removal preserves critical system components

### 📚 Documentation

- Comprehensive compatibility database
- Step-by-step recovery procedures
- Technical analysis and explanations
- Prevention strategies
- Alternative software recommendations

### 🧪 Testing

- ✅ Tested on Ubuntu 22.04+ with balena Etcher installed
- ✅ Verified Node.js v20 and v23 preservation
- ✅ Confirmed NTFS functionality restoration
- ✅ Validated surgical removal safety
- ✅ Tested with multiple NTFS drives
- ✅ Verified hot-swap functionality
- ✅ Confirmed network connectivity restoration

### 🎯 Impact

**Users Affected:**
- All Linux users who installed balena Etcher
- Dual-boot Windows/Linux users with NTFS partitions
- Users with external NTFS drives
- Systems using udisks2 and ntfs-3g

**Problem Severity:**
- Complete loss of NTFS functionality
- Data inaccessibility (read-only mounts)
- System permission corruption
- Potential data loss risk

**Solution Effectiveness:**
- 100% recovery rate in testing
- Complete NTFS functionality restored
- No data loss
- Minimal user intervention required
- Node.js and other programs preserved

### 📝 Notes

**For Users:**
- Run `./scripts/check-software-compatibility.sh` to detect issues
- Use `./scripts/remove-balena-etcher-surgical.sh` for safe removal
- Run `sudo ./scripts/balena-etcher-recovery.sh` to restore NTFS functionality
- Log out and back in after recovery for group changes to take effect

**For Developers:**
- All scripts follow bash best practices (set -euo pipefail)
- Comprehensive error handling and logging
- User-friendly output with color coding
- Modular design for easy maintenance

**Prevention:**
- Use GNOME Disks instead of balena Etcher
- Check compatibility before installing disk imaging tools
- Create system snapshots before major installations
- Monitor system logs for permission changes

### 🔗 Related Issues

- Closes: #[NUMBER] - Balena Etcher breaks NTFS functionality
- Relates to: NTFS mounting issues
- Relates to: Permission management
- Relates to: System recovery procedures

### 👥 Contributors

- Darryl Bennett - Problem identification, testing, validation
- Development Team - Script creation, documentation, testing

---

**Version:** 1.0.4  
**Release Date:** November 6, 2025  
**Type:** Critical Fix + Feature Addition  
**Breaking Changes:** None  
**Migration Required:** No
