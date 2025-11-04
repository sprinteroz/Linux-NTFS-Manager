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
- **Solution:** Created full-fix script that clears GNOME Shell caches and provides recovery steps

### Memory Management
- **Improved:** Detection and handling of resource exhaustion
- **Issue:** Systems with large VMs (64GB+) experiencing instability
- **Solution:** Added monitoring tools and recommendations for optimal memory allocation

### System Integration
- **Enhanced:** Compatibility with high-memory workloads
- **Issue:** Multiple resource-intensive applications competing for resources
- **Solution:** Provided resource mon

itoring and management strategies

---

## 📊 System Investigation Report

A comprehensive system investigation was conducted, revealing:

### Root Cause Analysis
- **Primary Issue:** Memory resource exhaustion (not NTFS Manager)
- **Finding:** Windows VMs consuming excessive memory (51% of system)
- **Secondary:** Multiple VS Code instances and other applications
- **NTFS Manager:** Confirmed stable with no issues found

### What Was Fixed
1. ✅ Provided tools to manage Windows VM memory allocation
2. ✅ Created Waydroid management and icon fix scripts
3. ✅ Implemented system resource monitoring
4. ✅ Documented comprehensive troubleshooting guide

### What Was NOT Causing Issues
- ✅ NTFS Manager (all logs clean, recent changes were business/licensing only)
- ✅ Waydroid itself (minimal resource usage ~155MB)

---

## 📝 Documentation Updates

### New Documentation
- **SYSTEM-FIXES-REPORT.md** - Comprehensive troubleshooting and resource management guide
- **Management Script Documentation** - Complete usage guides for all new scripts
- **Installation Recommendations** - Updated with resource requirements

### Enhanced Documentation
- Updated CHANGELOG.md with v1.0.1 details
- Added troubleshooting sections
- Improved resource management guidelines

---

## 🔧 Technical Improvements

### Error Detection
- Enhanced crash log analysis
- System diagnostics integration
- Automated problem identification

### Resource Alerts
- Threshold-based monitoring (80% warning, 90% critical)
- Real-time alerts for memory and CPU usage
- Proactive recommendations

### Auto-Recovery
- Automated fixes for common issues
- Cache cleanup for GNOME Shell
- Resource optimization suggestions

### Performance Monitoring
- Real-time system resource tracking
- Process-level analysis
- Memory usage breakdown

---

## 💾 Installation & Upgrade

### For New Users
```bash
# Clone repository
git clone https://github.com/sprinteroz/Linux-NTFS-Manager.git
cd Linux-NTFS-Manager

# Make scripts executable
cd scripts
chmod +x *.sh

# Run system check
./system-resource-monitor.sh
```

### For Existing Users (Upgrade from v1.0.0)
```bash
# Navigate to your installation
cd Linux-NTFS-Manager

# Pull latest changes
git pull origin main

# Verify version
cat VERSION  # Should show 1.0.1

# Make scripts executable
cd scripts
chmod +x *.sh

# Test the new scripts
./system-resource-monitor.sh full
```

---

## 🎯 Recommended Actions

### Immediate
1. **Run system health check:**
   ```bash
   cd scripts
   ./system-resource-monitor.sh full
   ```

2. **If running Windows VM:**
   - Check memory allocation (recommend 16-32GB instead of 64GB)
   - Set up auto-shutdown monitoring
   ```bash
   ./manage-windows-vm.sh monitor &
   ```

3. **If using Waydroid:**
   - Set up auto-stop when idle
   ```bash
   ./manage-waydroid.sh monitor &
   ```

### Short-term
1. Review VM memory allocation
2. Close unused applications
3. Monitor system resources regularly
4. Apply Waydroid icon fix if needed

### Long-term
1. Create systemd services for auto-management
2. Set up resource alerts
3. Regular system health monitoring
4. Consider memory upgrade if needed

---

## ⚠️ Known Limitations

- Scripts are designed for Linux systems only
- Windows VM management requires QEMU/KVM setup
- Waydroid fixes require logout/login for full effect
- Some operations require sudo privileges

---

## 🔄 Compatibility

### Maintained Compatibility
- All features from v1.0.0 are maintained
- No breaking changes
- Enhanced stability on high-memory systems
- Better VM and container integration

### System Requirements
- **Recommended:** 32GB+ RAM for VM workloads
- **Minimum:** 16GB RAM
- **Linux Kernel:** 5.15+ (6.0+ recommended)
- **Desktop Environment:** GNOME (for Waydroid fixes)

---

## 📞 Support & Resources

### Getting Help
- **System Report:** Full analysis in SYSTEM-FIXES-REPORT.md
- **Script Documentation:** Built-in help in all scripts
  ```bash
  ./manage-windows-vm.sh help
  ./manage-waydroid.sh help
  ./system-resource-monitor.sh help
  ```

### Contact Information
- **Email:** sales@magdrivex.com.au
- **Company:** MagDriveX
- **ABN:** 82 977 519 307
- **GitHub:** https://github.com/sprinteroz/Linux-NTFS-Manager

### Reporting Issues
If you encounter any problems with v1.0.1:
1. Run: `./system-resource-monitor.sh export /tmp/report.txt`
2. Include the report when filing issues
3. Open issue on GitHub or email support

---

## 🙏 Acknowledgments

Special thanks to users who reported system stability issues that led to this investigation and the creation of these powerful management tools. Your feedback helps make NTFS Manager better for everyone.

---

## 📋 Checklist for Upgrading

- [ ] Backup current configuration
- [ ] Pull latest code from GitHub
- [ ] Verify VERSION shows 1.0.1
- [ ] Make new scripts executable
- [ ] Run system health check
- [ ] Review SYSTEM-FIXES-REPORT.md
- [ ] Apply recommended optimizations
- [ ] Test all scripts
- [ ] Set up auto-monitoring if needed

---

**NTFS Manager v1.0.1 - Better Resource Management, Enhanced Stability**

*© 2023-2025 Darryl Bennett / MagDriveX. All rights reserved.*
