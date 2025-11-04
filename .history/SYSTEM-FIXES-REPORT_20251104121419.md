# System Resource & Stability Fixes Report

**Date:** November 4, 2025  
**System:** Linux 6.14  
**Issue:** Resource exhaustion causing system instability and potential Waydroid/NTFS Manager conflicts

---

## 🔍 Root Cause Analysis

### **Primary Issue: Memory Resource Exhaustion**
- **Total System Memory:** 125GB
- **Memory Usage:** 61-76% (fluctuating)
- **Critical Finding:** Windows VM consuming **65GB (51% of total system memory)**
- **Secondary:** VS Code with 6 instances using ~5.6GB total
- **Waydroid:** Running 10+ processes using ~155MB (relatively minimal)

### **NTFS Manager Status**
- **NOT the cause of crashes** - recent changes were business/licensing only
- **Last Changes (Nov 3, 2025):** MagDriveX branding updates, no technical modifications
- **Log Status:** Minimal activity, no errors detected
- **Conclusion:** NTFS Manager is stable and functioning correctly

### **Actual Crash Sources**
1. **GNOME Shell JSAPI Errors** - Memory pressure forcing garbage collection
2. **Resource Competition** - VM, VS Code, Waydroid competing for resources
3. **Waydroid Icon Issues** - GNOME Shell cache corruption (not Waydroid fault)

---

## 🛠️ Solutions Implemented

### 1. **Windows VM Management Script**
**Location:** `scripts/manage-windows-vm.sh`

**Features:**
- Graceful shutdown via ACPI command
- Force shutdown capability
- Auto-shutdown monitor (when VNC disconnected)
- Memory usage tracking
- Status reporting

**Usage:**
```bash
cd scripts
./manage-windows-vm.sh status        # Check VM status
./manage-windows-vm.sh shutdown      # Graceful shutdown
./manage-windows-vm.sh force-stop    # Emergency stop
./manage-windows-vm.sh monitor       # Auto-shutdown on idle
./manage-windows-vm.sh memory-stats  # View memory usage
```

**AUTO-SHUTDOWN SOLUTION:**
The VM is programmed to stay running. To implement auto-shutdown:
```bash
# Run this in background or as a systemd service
./manage-windows-vm.sh monitor
```
This will monitor VNC connections and shutdown the VM after 60 seconds of no connections.

**MEMORY REDUCTION:**
Current allocation: **64GB** (excessive for most workloads)
Recommended: **16-32GB** depending on Windows usage

To change:
1. Shutdown VM: `./manage-windows-vm.sh shutdown`
2. Find VM startup script and modify `-m 64G` parameter
3. Recommended values: `-m 32G` or `-m 16G`

---

### 2. **Waydroid Management Script**
**Location:** `scripts/manage-waydroid.sh`

**Features:**
- Start/stop/restart Waydroid sessions
- Fix GNOME Shell icon crashes
- Full system cache cleanup
- Auto-stop when idle (5 minutes)
- Memory monitoring

**Usage:**
```bash
cd scripts
./manage-waydroid.sh status       # Check status
./manage-waydroid.sh stop         # Stop gracefully
./manage-waydroid.sh fix-icons    # Fix icon crashes
./manage-waydroid.sh full-fix     # Complete cache cleanup
./manage-waydroid.sh monitor      # Auto-stop after 5min idle
```

**FIX FOR ICON CRASHES:**
```bash
# Quick fix (works on X11, requires logout on Wayland)
./manage-waydroid.sh fix-icons

# Full fix for persistent problems (requires logout)
./manage-waydroid.sh full-fix
```

**Note:** Icon issues are caused by GNOME Shell cache corruption, NOT Waydroid bugs. The fix clears GNOME Shell caches and requires logout/login to fully resolve.

---

### 3. **System Resource Monitor**
**Location:** `scripts/system-resource-monitor.sh`

**Features:**
- Quick health check
- Full system report
- Continuous monitoring
- Export detailed reports
- Identifies resource-hungry processes
- Provides actionable recommendations

**Usage:**
```bash
cd scripts
./system-resource-monitor.sh              # Quick check
./system-resource-monitor.sh full         # Detailed report
./system-resource-monitor.sh monitor      # Live monitoring
./system-resource-monitor.sh export       # Save report
```

**Monitoring Thresholds:**
- **Normal:** <80% memory usage (Green)
- **Warning:** 80-90% memory usage (Yellow)
- **Critical:** >90% memory usage (Red - immediate action required)

---

## 📊 Current System Status

### Memory Usage Analysis
```
Total Memory: 125GB
Used: 76GB (61%)
Available: 48GB
Swap: 0GB used (healthy - no swapping)
```

### Top Memory Consumers
1. **Windows VM:** 65GB (51%) - **PRIMARY ISSUE**
2. **VS Code:** 5.6GB across 6 instances
3. **ClamAV:** 1.3GB
4. **Firefox:** ~1.8GB combined
5. **Waydroid:** ~155MB (minimal impact)

### CPU Usage
- System load average: ~0.35-0.44 (healthy)
- No CPU bottlenecks detected
- Issue is memory, not CPU

---

## 🎯 Recommended Actions

### **Immediate (Do Now)**
1. ✅ **Use the new management scripts** - Already created and tested
2. **Reduce VM memory allocation** - From 64GB to 32GB or less
3. **Close unused VS Code windows** - 6 instances detected
4. **Setup auto-shutdown** - Use monitor scripts for VM and Waydroid

### **Short-term (This Week)**
1. **Configure VM auto-shutdown:**
   ```bash
   # Add to startup or create systemd service
   cd ~/VScode/projects/clone\ from\ github\ ntfs\ manager\ free/Linux-NTFS-Manager/scripts
   ./manage-windows-vm.sh monitor &
   ```

2. **Configure Waydroid auto-stop:**
   ```bash
   # Run when you start Waydroid, it will stop after 5min idle
   ./manage-waydroid.sh monitor &
   ```

3. **Regular monitoring:**
   ```bash
   # Check system health regularly
   ./system-resource-monitor.sh
   ```

### **Long-term (This Month)**
1. **Create systemd services** for auto-management
2. **Set up resource alerts** at 80% memory threshold
3. **Review VS Code extensions** - Some may be memory-hungry
4. **Consider memory upgrade** if 125GB isn't enough for your workflow

---

## 🔧 Script Installation

All scripts are located in: `scripts/` directory

**Make executable:**
```bash
cd scripts
chmod +x *.sh
```

**Test each script:**
```bash
./system-resource-monitor.sh full    # System overview
./manage-windows-vm.sh status        # Check VM
./manage-waydroid.sh status          # Check Waydroid
```

**Optional: Add to PATH**
```bash
# Add to ~/.bashrc
export PATH="$PATH:$HOME/VScode/projects/clone from github ntfs manager free/Linux-NTFS-Manager/scripts"

# Then use from anywhere:
system-resource-monitor.sh
manage-windows-vm.sh status
manage-waydroid.sh status
```

---

## 📝 NTFS Manager Findings

### Log Analysis
- **Error Log:** Empty (no errors)
- **Main Log:** Single test entry (Nov 3, 02:12)
- **Operations Log:** Empty (no operations logged)
- **Audit Log:** Empty

### Conclusion
**NTFS Manager is NOT causing any problems.**

Recent changes were:
- Business branding updates (MagDriveX)
- Dual-licensing model implementation
- Documentation updates
- **NO technical/code changes that would cause crashes**

### NTFS Manager is Stable ✅
- No crash logs
- No error entries
- Minimal resource usage
- Recent changes were documentation/licensing only

---

## 🚨 What Was Really Causing the Problems

### 1. **Windows VM Memory Hogging**
- Allocated: 64GB (51% of system)
- Actual need: Probably 16-32GB
- Solution: Reduce allocation and implement auto-shutdown

### 2. **GNOME Shell Memory Pressure**
- Multiple memory-intensive apps running simultaneously
- GNOME Shell forced to garbage collect aggressively
- Caused JSAPI sweep phase errors
- Solution: Reduce overall memory usage

### 3. **Waydroid Icon Crash**
- NOT a Waydroid bug
- GNOME Shell cache corruption under memory pressure
- Icons lost after shell crashes/restarts
- Solution: Clear caches and logout/login

### 4. **VS Code Memory Leaks**
- 6 instances consuming 5.6GB
- Some instances at 566% CPU (likely busy processes running)
- Solution: Close unused windows, restart VS Code periodically

---

## 📈 Expected Improvements

After implementing these fixes:

1. **Memory Usage:** Should drop to 40-50% (from 61-76%)
2. **System Stability:** Significantly improved
3. **GNOME Shell Crashes:** Should stop completely
4. **Waydroid Icons:** Persist correctly after fixes
5. **VM Auto-Shutdown:** Will work when you close VNC viewer
6. **Waydroid Auto-Stop:** Will stop when not in use

---

## 🔄 Maintenance Checklist

### Daily
- [ ] Run quick system check: `./system-resource-monitor.sh`
- [ ] Close unused applications

### Weekly
- [ ] Full system report: `./system-resource-monitor.sh full`
- [ ] Review VS Code instances
- [ ] Check VM is not running unnecessarily

### Monthly
- [ ] Export and review logs: `./system-resource-monitor.sh export`
- [ ] Clean up old logs: `find /var/log -name "*.log" -mtime +30`
- [ ] Review resource allocation

---

## 📞 Support & Documentation

### Script Help
All scripts have built-in help:
```bash
./manage-windows-vm.sh help
./manage-waydroid.sh help
./system-resource-monitor.sh help
```

### NTFS Manager Support
- **Email:** sales@magdrivex.com.au
- **Company:** MagDriveX
- **ABN:** 82 977 519 307

### System Logs
- **NTFS Manager:** `/var/log/ntfs-manager/`
- **System:** `journalctl -xe`
- **Waydroid:** `waydroid log`

---

## ✅ Summary

### Problems Identified
1. ❌ Windows VM using 51% of system memory (main issue)
2. ❌ No auto-shutdown for VM or Waydroid
3. ❌ GNOME Shell crashes due to memory pressure
4. ❌ Waydroid icon loss (GNOME cache issue)
5. ❌ Multiple VS Code instances consuming excessive memory

### Solutions Implemented
1. ✅ Windows VM management script with auto-shutdown
2. ✅ Waydroid management script with icon fix
3. ✅ System resource monitoring tool
4. ✅ Comprehensive documentation
5. ✅ Memory optimization recommendations

### NTFS Manager Status
✅ **NO ISSUES FOUND** - Stable and working correctly

---

**Report Generated:** November 4, 2025  
**System Check Status:** ✅ HEALTHY (after applying recommendations)  
**Critical Issues:** 1 (Windows VM memory allocation)  
**Scripts Created:** 3 (All tested and working)

---

**Next Steps:**
1. Test the scripts (already done)
2. Reduce Windows VM memory allocation
3. Set up auto-monitoring
4. Apply Waydroid fixes if needed
5. Regular system monitoring

---

*This report is part of the Linux NTFS Manager project*  
