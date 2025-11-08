# NTFS Mounting Guide for Linux

## Overview

This guide explains NTFS (New Technology File System) mounting on Linux, covering available drivers, recommended mount options, and common troubleshooting scenarios.

### NTFS Driver Landscape

Linux supports NTFS through multiple drivers, each with different characteristics:

| Driver | Type | Availability | Performance | Compatibility | Recommendation |
|--------|------|--------------|-------------|---------------|----------------|
| **ntfs3** | Kernel | Linux 5.15+ | Excellent | Good | **Best choice** for modern kernels |
| **lowntfs-3g** | FUSE | Package install | Good | Excellent | Best FUSE option |
| **ntfs-3g** | FUSE | Package install | Good | Excellent | Widely available fallback |

#### ntfs3 (Kernel Driver)
- **Introduced**: Linux kernel 5.15 (October 2021)
- **Maintained by**: Paragon Software
- **Performance**: Native kernel performance, 50-100% faster than FUSE
- **Features**: Full read/write support, Windows compatibility features
- **Check availability**: `modprobe -l | grep ntfs3`
- **When to use**: Default choice for kernel 5.15+

#### lowntfs-3g (Low-level FUSE Driver)
- **Type**: FUSE (Filesystem in Userspace)
- **Performance**: Better than ntfs-3g, closer to kernel performance
- **Reliability**: Enhanced error handling and recovery
- **When to use**: Fallback when ntfs3 unavailable, or for problematic drives

#### ntfs-3g (Standard FUSE Driver)
- **Type**: FUSE (Filesystem in Userspace)
- **Maturity**: Highly stable, 15+ years of development
- **Compatibility**: Works on all Linux kernels
- **When to use**: Universal fallback, legacy systems

### Linux NTFS Manager Automatic Selection

Linux NTFS Manager automatically detects and selects the best available driver:

1. **Primary**: ntfs3 (if kernel 5.15+ and module available)
2. **Fallback 1**: lowntfs-3g (if installed)
3. **Fallback 2**: ntfs-3g (universal fallback)
4. **Last resort**: Read-only mount

## Recommended Mount Options

### For ntfs3 (Kernel Driver) - Default

```
nofail,users,prealloc,windows_names,nocase
```

**Option Breakdown:**
- `nofail` - System continues booting if drive unavailable
- `users` - Non-root users can mount/unmount
- `prealloc` - Enable file preallocation for better performance
- `windows_names` - Enforce Windows filename rules (prevent illegal chars)
- `nocase` - Case-insensitive filenames (Windows compatibility)

**Performance Profile**: Optimized for speed and Windows compatibility

### For ntfs-3g / lowntfs-3g (FUSE Drivers) - Default

```
nofail,noexec,windows_names
```

**Option Breakdown:**
- `nofail` - System continues booting if drive unavailable
- `noexec` - Prevent execution of binaries (security)
- `windows_names` - Enforce Windows filename rules

**Performance Profile**: Prioritizes safety and reliability

### Advanced Options

#### Performance Tuning (ntfs3)
```bash
nofail,users,prealloc,windows_names,nocase,big_writes
```
- `big_writes` - Larger write operations (better for large files)

#### Maximum Security (All Drivers)
```bash
nofail,noexec,nosuid,nodev,ro
```
- `nosuid` - Ignore SUID bits
- `nodev` - Ignore device files
- `ro` - Read-only mount

#### Dual-Boot Safe (All Drivers)
```bash
nofail,windows_names,remove_hiberfile
```
- `remove_hiberfile` - Remove Windows hibernation file (use carefully!)

## Common Issues and Solutions

### 🔴 Issue 1: "NTFS is marked dirty" Error

**Most Common NTFS Problem in Dual-Boot Systems**

#### Symptoms
```
Error mounting /dev/sdX: mount exited with exit code 14: 
The disk contains an unclean file system (0, 0).
Metadata kept in Windows cache, refused to mount.
```

#### Root Causes
1. **Windows Fast Startup enabled** (90% of cases)
2. Improper Windows shutdown (power loss, forced shutdown)
3. System crash while NTFS volume was mounted
4. Windows hibernation active

#### Solutions (Ranked by Safety)

##### ✅ Solution 1: Boot Windows and Shutdown Properly (SAFEST)
```bash
# Steps:
1. Boot into Windows
2. Run CHKDSK if needed: chkdsk C: /f
3. Shutdown (not restart) Windows properly
4. Boot back to Linux
```
**Risk**: None  
**Success Rate**: 99%  
**Recommended**: Yes

##### ✅ Solution 2: Disable Windows Fast Startup (PREVENTS FUTURE ISSUES)
```
Steps:
1. Boot into Windows
2. Control Panel → Power Options
3. "Choose what the power buttons do" (left sidebar)
4. "Change settings that are currently unavailable"
5. Uncheck "Turn on fast startup (recommended)"
6. Save changes
7. Shutdown and boot to Linux
```
**Effect**: Prevents 90% of future dirty volume errors  
**Recommended**: **ESSENTIAL for dual-boot systems**

##### ⚠️ Solution 3: Use ntfsfix (MODERATE RISK)
```bash
# Check status first
sudo ntfsfix -n /dev/sdX1

# Apply repair
sudo ntfsfix -d /dev/sdX1
```
**Risk**: Low, but not as thorough as Windows CHKDSK  
**Success Rate**: 85%  
**When to use**: When Windows is unavailable

##### ✅ Solution 4: Mount Read-Only (SAFE FOR DATA RECOVERY)
```bash
# Linux NTFS Manager does this automatically as fallback
sudo udisksctl mount -b /dev/sdX1 -o ro
```
**Risk**: None - no writes occur  
**Use case**: Access files while planning proper repair

### 🔴 Issue 2: Windows Fast Startup

**CRITICAL FOR DUAL-BOOT USERS**

#### What is Fast Startup?

Windows Fast Startup is a hybrid shutdown mode that hibernates the kernel instead of fully shutting down. This keeps NTFS volumes in an "in-use" state that Linux sees as dirty.

#### Why It Causes Problems

1. NTFS volumes are not cleanly unmounted
2. Windows keeps filesystem metadata in hibernation file
3. Linux refuses to mount (data safety protection)
4. Users see "dirty volume" errors on every boot

#### How to Disable (Detailed Steps)

**Method 1: Control Panel (Recommended)**
```
1. Press Windows + R
2. Type: powercfg.cpl
3. Click "Choose what the power buttons do"
4. Click "Change settings that are currently unavailable"
5. Scroll to "Shutdown settings"
6. Uncheck "Turn on fast startup (recommended)"
7. Click "Save changes"
```

**Method 2: PowerShell (For Advanced Users)**
```powershell
# Run as Administrator
powercfg /h off
```

**Method 3: Registry Edit (Not Recommended)**
```
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power
HiberbootEnabled = 0
```

#### Verification
```bash
# In Linux, check for hiberfil.sys
ls -lh /path/to/windows/partition/hiberfil.sys
# If file is 0 bytes or missing, Fast Startup is disabled
```

### 🔴 Issue 3: Permission Denied

#### Symptoms
```
Error mounting /dev/sdX: Permission denied
```

#### Causes
1. PolicyKit not configured
2. User not in required groups
3. SELinux blocking mount

#### Solutions

**Check PolicyKit Configuration**
```bash
# File: /etc/polkit-1/rules.d/50-ntfs-manager.rules
# Should allow storage mounting for active users
```

**Add User to Required Groups**
```bash
sudo usermod -aG storage,plugdev $USER
# Logout and login for changes to take effect
```

**Check SELinux Status**
```bash
sestatus
sudo setenforce 0  # Temporary, for testing only
```

### 🔴 Issue 4: Driver Not Available

#### Symptoms
```
Error: unknown filesystem type 'ntfs'
```

#### Detection

**Check for ntfs3**
```bash
uname -r  # Check kernel version (need 5.15+)
modprobe -l | grep ntfs3
```

**Check for ntfs-3g**
```bash
which ntfs-3g
dpkg -l | grep ntfs-3g  # Debian/Ubuntu
rpm -qa | grep ntfs-3g  # Fedora/RHEL
```

#### Installation

**Ubuntu/Debian**
```bash
sudo apt update
sudo apt install ntfs-3g
```

**Fedora/RHEL**
```bash
sudo dnf install ntfs-3g
```

**Arch Linux**
```bash
sudo pacman -S ntfs-3g
```

### 🔴 Issue 5: Performance Problems

#### Symptoms
- Slow file transfers
- High CPU usage during operations
- System lag when accessing NTFS

#### Diagnosis

**Check Active Driver**
```bash
mount | grep ntfs
# Look for: type ntfs3 (best) or type fuse.ntfs-3g
```

**Check Mount Options**
```bash
mount | grep /dev/sdX1
# Should see: prealloc, big_writes for best performance
```

#### Solutions

**Ensure ntfs3 is Being Used**
```bash
# Check kernel version
uname -r  # Need 5.15+

# Load ntfs3 module
sudo modprobe ntfs3

# Linux NTFS Manager will auto-detect and use ntfs3
```

**Optimize Mount Options**
```bash
# For ntfs3 (best performance)
nofail,users,prealloc,windows_names,nocase,big_writes

# For FUSE drivers
nofail,windows_names,compression,big_writes
```

**Defragment in Windows**
```
1. Boot Windows
2. Run: defrag C: /O
3. Shutdown properly
4. Boot Linux
```

## Custom Mount Options Configuration

### User Configuration File

Create: `~/.config/ntfs-manager/mount-options.conf`

```ini
[ntfs3]
options = nofail,users,prealloc,windows_names,nocase

[ntfs-3g]
options = nofail,noexec,windows_names

[lowntfs-3g]
options = nofail,noexec,windows_names

[fallback]
options = nofail
```

### System-Wide Configuration

Edit `/etc/fstab` for permanent mounts:

```bash
# ntfs3 example
UUID=XXXX-XXXX /mnt/data ntfs3 nofail,users,prealloc,windows_names,nocase 0 0

# ntfs-3g example
UUID=XXXX-XXXX /mnt/data ntfs-3g nofail,noexec,windows_names 0 0
```

**Find UUID:**
```bash
sudo lsblk -f
# or
sudo blkid /dev/sdX1
```

## Best Practices

### For Dual-Boot Systems

1. **✅ ALWAYS disable Windows Fast Startup**
2. ✅ Always shutdown Windows properly (not restart)
3. ✅ Run CHKDSK regularly in Windows
4. ✅ Use Linux NTFS Manager's auto-detection
5. ❌ DON'T force mount dirty volumes
6. ❌ DON'T use remove_hiberfile unless you understand risks

### For Data Drives

1. ✅ Use ntfs3 driver for best performance (kernel 5.15+)
2. ✅ Enable prealloc mount option
3. ✅ Keep backups of important data
4. ✅ Regularly check drive health (SMART data)

### For External Drives

1. ✅ Always safely unmount before disconnecting
2. ✅ Use nofail mount option
3. ✅ Use noexec for security
4. ✅ Scan for errors periodically

### For System Partitions

1. ⚠️ Mount read-only if Windows is in hibernation
2. ⚠️ Never modify Windows system files from Linux
3. ⚠️ Use extreme caution with repair tools
4. ✅ Boot Windows for system repairs

## Troubleshooting Workflows

### Workflow 1: Cannot Mount After Windows Boot

```bash
# 1. Check if volume is dirty
sudo ntfsfix -n /dev/sdX1

# 2a. If dirty: Boot Windows, shutdown properly, try again
# 2b. If not dirty: Check dmesg for errors
dmesg | grep -i ntfs

# 3. Try different driver
# Linux NTFS Manager does this automatically

# 4. Try read-only mount
sudo udisksctl mount -b /dev/sdX1 -o ro
```

### Workflow 2: Slow Performance

```bash
# 1. Check which driver is active
mount | grep /dev/sdX1

# 2. If not ntfs3, check if available
uname -r  # Need >= 5.15
modprobe -l | grep ntfs3

# 3. Check mount options
mount | grep /dev/sdX1
# Should see: prealloc, big_writes

# 4. Remount with better options
# Linux NTFS Manager optimizes automatically
```

### Workflow 3: Dual-Boot Mount Issues

```bash
# 1. Disable Windows Fast Startup (see above)

# 2. In Windows: Run CHKDSK
chkdsk C: /f

# 3. In Windows: Shutdown (not restart)

# 4. In Linux: Try mount again
# Linux NTFS Manager handles automatically

# 5. If still fails: Check for hibernation
ls -lh /media/*/hiberfil.sys
```

## Additional Resources

### Documentation
- [Linux NTFS Manager GitHub](https://github.com/sprinteroz/Linux-NTFS-Manager)
- [ntfs3 Kernel Documentation](https://www.kernel.org/doc/html/latest/filesystems/ntfs3.html)
- [ntfs-3g Documentation](https://github.com/tuxera/ntfs-3g)

### Support
- Report issues: [GitHub Issues](https://github.com/sprinteroz/Linux-NTFS-Manager/issues)
- Community: [Discussions](https://github.com/sprinteroz/Linux-NTFS-Manager/discussions)

### Related Guides
- [Troubleshooting Guide](../wiki-content/Troubleshooting.md)
- [Installation Guide](../wiki-content/Installation-Guide.md)
- [Security Setup](../wiki-content/Security-Setup.md)

---

**Last Updated**: November 2025  
**Version**: 1.0.7  
**Maintainer**: Linux NTFS Manager Project
