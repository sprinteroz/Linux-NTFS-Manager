# Balena Etcher Recovery Guide

## 🚨 Quick Recovery for NTFS Functionality

If you've installed balena Etcher and are experiencing NTFS issues (mounting, writing, formatting, or hot-swap problems), this guide will help you recover full functionality.

---

## Step 1: Run the Recovery Script

```bash
cd Linux-NTFS-Manager
sudo ./scripts/balena-etcher-recovery.sh
```

The script will automatically:
- ✓ Detect balena Etcher installation
- ✓ Repair NTFS packages (ntfs-3g, ntfsprogs)
- ✓ Fix user permissions and group memberships
- ✓ Restore udev rules for auto-mounting
- ✓ Repair PolicyKit permissions
- ✓ Clean mount points
- ✓ Fix network connectivity issues
- ✓ Check Node.js installation
- ✓ Test NTFS functionality

---

## Step 2: Log Out and Back In

After the recovery script completes, you **must log out and log back in** for group membership changes to take effect.

```bash
# In terminal
logout
# Or press Ctrl+Alt+Backspace (on some systems)
```

---

## Step 3: Test NTFS Functionality

### Test Mounting
1. Plug in an NTFS USB drive
2. It should auto-mount to `/media/your-username/`
3. Check if you can see files

### Test Writing
```bash
# Try creating a test file
echo "test" > /media/your-username/drive-name/test.txt
```

### Test Hot-Swap
1. Right-click the drive in your file manager
2. Select "Safely Remove" or "Eject"
3. The drive should unmount properly

---

## Step 4: Run Compatibility Check

Verify everything is working:

```bash
cd Linux-NTFS-Manager
./scripts/check-software-compatibility.sh
```

This will check:
- NTFS packages are installed
- User has correct permissions
- Udev rules are in place
- PolicyKit is configured
- No incompatible software issues

---

## What If Recovery Fails?

### Manual Steps

1. **Reinstall NTFS packages:**
```bash
sudo apt update
sudo apt install --reinstall ntfs-3g ntfsprogs udisks2
```

2. **Add yourself to required groups:**
```bash
sudo usermod -aG disk,plugdev,fuse $USER
```

3. **Load FUSE module:**
```bash
sudo modprobe fuse
```

4. **Restart services:**
```bash
sudo systemctl restart udisks2
sudo systemctl restart polkit
```

5. **Log out and back in**

---

## Preventing Future Issues

### Don't Install Balena Etcher

Balena Etcher modifies system-level permissions that break NTFS functionality. Instead, use these safe alternatives:

#### Option 1: GNOME Disks (Recommended)
```bash
sudo apt install gnome-disk-utility
gnome-disks
```
- Native Linux integration
- No system modifications
- Full disk imaging support

#### Option 2: Popsicle
```bash
sudo apt install popsicle-gtk
```
- Modern Rust-based tool
- Safe permission model
- Multiple USB writes

#### Option 3: dd Command
```bash
sudo dd if=image.iso of=/dev/sdX bs=4M status=progress
sudo sync
```
- No installation needed
- Complete control
- Zero system changes

#### Option 4: Ventoy
Visit: https://www.ventoy.net/
- One-time USB setup
- Store multiple ISOs
- No re-flashing needed

---

## Understanding the Issues

### What Balena Etcher Breaks

1. **Udev Rules** - Device auto-detection and mounting
2. **PolicyKit Permissions** - Password-free mounting for authorized users
3. **Group Memberships** - Access to disk, plugdev, and fuse groups
4. **FUSE Configuration** - User-space filesystem mounting
5. **udisks2 Service** - Disk management daemon

### Why It Happens

Balena Etcher requires low-level disk access to write bootable USBs. To achieve this, it modifies system permissions, but these changes persist after creating the bootable USB and interfere with normal NTFS operations.

---

## Recovery Script Technical Details

The recovery script performs these operations:

### 1. System Backup
Creates backup of:
- `/etc/fstab`
- `/etc/udev/rules.d/`
- `/etc/polkit-1/`
- `/etc/dbus-1/`

### 2. Package Repair
```bash
apt-get update
apt-get --fix-broken install -y
apt-get install --reinstall -y ntfs-3g ntfsprogs
apt-get install -y libntfs-3g883 ntfs-3g-dev fuse libfuse2 usbutils udisks2 policykit-1
```

### 3. Permission Restoration
- Adds user to disk, plugdev, and fuse groups
- Sets correct permissions on `/dev/fuse`
- Creates proper mount point structure

### 4. Udev Rules Recreation
Creates `/etc/udev/rules.d/99-ntfs-automount.rules` with proper NTFS mounting rules

### 5. PolicyKit Policy Restoration
Creates `/etc/polkit-1/rules.d/50-ntfs-mount.rules` for password-free mounting

### 6. System Cleanup
- Removes balena/etcher entries from fstab
- Unmounts stuck NTFS mounts
- Cleans orphaned mount points

### 7. Service Restarts
- NetworkManager
- polkit
- udisks2

---

## Getting Help

### Still Having Issues?

1. **Check the log file:**
```bash
sudo cat /var/log/balena-etcher-recovery.log
```

2. **Run diagnostics:**
```bash
# Check if NTFS tools are working
ntfs-3g --version
ntfsfix --help

# Check group memberships
groups $USER

# Check udev rules
ls -la /etc/udev/rules.d/*ntfs*

# Check PolicyKit rules
ls -la /etc/polkit-1/rules.d/*ntfs*

# Check services
systemctl status udisks2
systemctl status polkit
```

3. **Create a system report:**
```bash
cd Linux-NTFS-Manager
./scripts/check-software-compatibility.sh > system-report.txt 2>&1
journalctl -xe > journal.txt
dmesg | grep -i ntfs > dmesg-ntfs.txt
lsblk -f > drives.txt
```

4. **Open a GitHub issue** with your system report:
https://github.com/sprinteroz/Linux-NTFS-Manager/issues

---

## Additional Resources

- **Full Incompatibility Documentation:** `docs/KNOWN-INCOMPATIBLE-SOFTWARE.md`
- **General Troubleshooting:** `wiki-content/Troubleshooting.md`
- **Installation Guide:** `wiki-content/Installation-Guide.md`
- **GitHub Discussions:** https://github.com/sprinteroz/Linux-NTFS-Manager/discussions

---

## Success Indicators

You'll know the recovery was successful when:

- ✓ NTFS drives auto-mount when plugged in
- ✓ You can create, edit, and delete files on NTFS drives
- ✓ You can format NTFS drives in GNOME Disks or GParted
- ✓ "Safely Remove" / "Eject" works without errors
- ✓ No password prompts when mounting NTFS drives
- ✓ Compatibility checker shows all green checkmarks

---

**Remember:** Always create system backups before installing disk imaging tools!

**Recommendation:** Use Timeshift for easy system snapshots:
```bash
sudo apt install timeshift
sudo timeshift --create --comments "Before installing disk tools"
```

---

*Last Updated: November 6, 2025*  
*Part of Linux NTFS Manager Project*
