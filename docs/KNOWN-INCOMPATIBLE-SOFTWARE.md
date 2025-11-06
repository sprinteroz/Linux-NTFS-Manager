# Known Incompatible Software

This document lists software that is known to cause compatibility issues with Linux NTFS Manager and NTFS functionality in general.

## ⚠️ Critical Incompatibilities

### Balena Etcher

**Severity:** HIGH - Breaks core NTFS functionality

**Issues Caused:**
- ❌ NTFS drives fail to mount automatically
- ❌ Cannot write to NTFS partitions (read-only errors)
- ❌ Cannot format NTFS drives
- ❌ Hot-swap functionality completely broken
- ❌ May cause network connectivity issues
- ❌ Can break Node.js package management

**Why This Happens:**
Balena Etcher modifies system-level permissions and udev rules to gain low-level disk access. These changes interfere with:
- `/etc/udev/rules.d/` - Device auto-mounting rules
- `/etc/polkit-1/rules.d/` - Permission policies
- User group memberships (disk, plugdev, fuse groups)
- FUSE module configuration
- udisks2 service configuration

**Affected Systems:**
- All Linux distributions using udisks2
- Systems with NTFS-3g installed
- Users who dual-boot with Windows

**Recovery:**
If you've installed Balena Etcher and are experiencing NTFS issues, run our recovery script:

```bash
cd Linux-NTFS-Manager
sudo ./scripts/balena-etcher-recovery.sh
```

This script will:
- ✓ Detect balena Etcher installation
- ✓ Repair NTFS packages and dependencies
- ✓ Restore proper permissions and group memberships
- ✓ Fix udev and PolicyKit rules
- ✓ Clean mount points and test functionality
- ✓ Repair network connectivity
- ✓ Check and fix Node.js installation

**Recommended Alternatives:**

Instead of Balena Etcher, use these safer alternatives:

1. **GNOME Disks** (Recommended for Ubuntu/GNOME)
   ```bash
   sudo apt install gnome-disk-utility
   gnome-disks
   ```
   - ✓ Native integration with Linux
   - ✓ Doesn't modify system permissions
   - ✓ Full disk imaging support

2. **Popsicle** (Modern, Rust-based)
   ```bash
   sudo apt install popsicle-gtk
   ```
   - ✓ Fast and efficient
   - ✓ Safe permission model
   - ✓ Multiple USB writes simultaneously

3. **dd command** (Advanced users)
   ```bash
   sudo dd if=image.iso of=/dev/sdX bs=4M status=progress
   sudo sync
   ```
   - ✓ No additional software needed
   - ✓ Complete control
   - ✓ Zero system modification

4. **Ventoy** (For bootable USBs)
   ```bash
   # One-time setup, then just copy ISOs
   https://www.ventoy.net/
   ```
   - ✓ No need to re-flash
   - ✓ Store multiple ISOs
   - ✓ No system changes

---

## 🔶 Moderate Incompatibilities

### Other Disk Imaging Tools

Some disk imaging tools may cause similar issues. If you experience NTFS problems after installing any of these, run the recovery script:

1. **UNetbootin** - Older tool, may modify udev rules
2. **Rufus alternatives** - Some Linux ports may affect permissions
3. **Custom disk managers** - Third-party tools with root access

---

## 📋 Reporting New Incompatibilities

If you discover software that breaks NTFS Manager functionality:

1. **Open an issue** on GitHub with:
   - Software name and version
   - How it was installed (apt, snap, AppImage, etc.)
   - Specific issues you experienced
   - Your Linux distribution and version

2. **Include logs** from:
   ```bash
   journalctl -xe > system-logs.txt
   dmesg | grep -i ntfs > ntfs-logs.txt
   lsblk -f > disk-info.txt
   ```

3. **Test recovery** script and report results

---

## 🛡️ Prevention

### Before Installing Disk Tools

1. **Create a backup** of system configuration:
   ```bash
   sudo cp -r /etc/udev/rules.d /etc/udev/rules.d.backup
   sudo cp -r /etc/polkit-1 /etc/polkit-1.backup
   ```

2. **Use Timeshift** or another snapshot tool:
   ```bash
   sudo apt install timeshift
   sudo timeshift --create --comments "Before disk tool install"
   ```

3. **Check permissions** before and after:
   ```bash
   groups $USER > groups-before.txt
   # Install software
   groups $USER > groups-after.txt
   diff groups-before.txt groups-after.txt
   ```

### Safe Installation Practices

- ✓ Use official repository packages when available
- ✓ Check GitHub issues for reported problems
- ✓ Test in virtual machine first
- ✓ Create system snapshot before installing
- ✓ Monitor system logs during installation

---

## 🔧 Quick Compatibility Check

Run this command to check for known incompatible software:

```bash
cd Linux-NTFS-Manager
./scripts/check-software-compatibility.sh
```

This will scan your system for:
- Known problematic software
- Modified system files
- Permission issues
- Group membership problems
- NTFS functionality status

---

## 📊 Compatibility Database

We maintain a database of tested software:

| Software | Version Tested | Status | Notes |
|----------|---------------|--------|-------|
| Balena Etcher | 1.18.11+ | ❌ Incompatible | Breaks NTFS functionality |
| GNOME Disks | 43.0+ | ✅ Compatible | Recommended |
| Popsicle | 1.3.0+ | ✅ Compatible | Safe alternative |
| GParted | 1.5.0+ | ✅ Compatible | No issues |
| KDE Partition Manager | 23.08+ | ✅ Compatible | No issues |
| dd (coreutils) | 9.0+ | ✅ Compatible | Command-line only |
| Ventoy | 1.0.96+ | ✅ Compatible | Bootable USB manager |

---

## 💬 Community Support

Having issues with incompatible software?

- **GitHub Discussions**: [Ask for help](https://github.com/sprinteroz/Linux-NTFS-Manager/discussions)
- **Bug Reports**: [Report issues](https://github.com/sprinteroz/Linux-NTFS-Manager/issues)
- **Recovery Script**: `./scripts/balena-etcher-recovery.sh`
- **Documentation**: Check our [Troubleshooting Guide](../wiki-content/Troubleshooting.md)

---

**Last Updated:** November 6, 2025  
**Maintained By:** Linux NTFS Manager Team  
**License:** Same as project (Dual License - Personal/Commercial)
