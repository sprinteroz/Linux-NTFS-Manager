# NTFS Manager v1.0.1 Release Notes

**Release Date:** November 4, 2025  
**Release Type:** Maintenance Release  
**Previous Version:** 1.0.0

---

## 🎯 Overview

Version 1.0.1 is a maintenance release that addresses system stability issues and introduces powerful resource management tools. This release focuses on improving system integration, especially for users running virtual machines, Android containers (Waydroid), and multiple resource-intensive applications.

**Key Focus Areas:**
- System resource management and optimization
- GNOME Shell stability improvements
- Virtual machine lifecycle management
- Waydroid session and icon crash fixes

---

## ✨ What's New

### System Resource Management Scripts

Three new powerful management scripts have been added to help users optimize their system resources:

#### 1. **Windows VM Management** (`scripts/manage-windows-vm.sh`)
- Graceful VM shutdown via ACPI commands
- Auto-shutdown monitoring (stops VM when VNC disconnects)
- Memory usage tracking and reporting
- Force shutdown capability for emergency situations
- Status monitoring and health checks

**Usage Example:**
```bash
cd scripts
./manage-windows-vm.sh status        # Check VM status
./manage-windows-vm.sh shutdown      # Graceful shutdown
./manage-windows-vm.sh monitor       # Auto-shutdown monitoring
```

#### 2. **Waydroid Management** (`scripts/manage-waydroid.sh`)
- Start/stop/restart Waydroid sessions
- Fix GNOME Shell icon crashes
- Full system cache cleanup
- Auto-stop when idle (5 minutes)
- Memory usage monitoring

**Usage Example:**
```bash
cd scripts
./manage-waydroid.sh stop         # Stop Waydroid
./manage-waydroid.sh fix-icons    # Fix icon crashes
./manage-waydroid.sh full-fix     # Complete system fix
```

#### 3. **System Resource Monitor** (`scripts/system-resource-monitor.sh`)
- Quick health checks
- Full system resource reports
- Continuous live monitoring
- Export detailed reports
- Identify resource-hungry processes
- Actionable recommendations

**Usage Example:**
```bash
cd scripts
./system-resource-monitor.sh         # Quick check
./system-resource-monitor.sh full    # Detailed report
./system-resource-monitor.sh monitor # Live monitoring
```

---

## 🐛 Bug Fixes

### GNOME Shell Stability
- **Fixed:** JSAPI garbage collection crashes under memory pressure
- **Issue:** GNOME Shell was crashing with "Attempting to call back into JSAPI during the sweeping phase of GC" errors
- **Solution:** Identified root cause as memory exhaustion, provided tools to manage resources

### Waydroid Icon Persistence
- **Fixed:** Icon disappearance after GNOME Shell crashes/restarts
- **Issue:** Waydroid app icons would vanish after system restarts or shell crashes
