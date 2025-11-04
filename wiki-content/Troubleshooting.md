# Troubleshooting Guide

Solutions to common issues with NTFS Manager.

---

## 📋 Table of Contents

- [Installation Issues](#installation-issues)
- [Permission Errors](#permission-errors)
- [Mount/Unmount Problems](#mountunmount-problems)
- [GUI Issues](#gui-issues)
- [Performance Problems](#performance-problems)
- [Error Messages](#error-messages)
- [Log Files](#log-files)
- [Getting Additional Help](#getting-additional-help)

---

## Installation Issues

### Issue: Python 3 not found

**Symptoms:**
```
bash: python3: command not found
```

**Solution:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3 python3-pip

# Fedora
sudo dnf install python3 python3-pip

# Arch Linux
sudo pacman -S python
```

**Verify installation:**
```bash
python3 --version
# Should output: Python 3.8.x or higher
```

---

### Issue: GTK bindings missing

**Symptoms:**
```
ModuleNotFoundError: No module named 'gi'
```

**Solution:**
```bash
# Ubuntu/Debian
sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0

# Fedora
sudo dnf install python3-gobject gtk3

# Arch Linux
sudo pacman -S python-gobject gtk3
```

**Verify installation:**
```bash
python3 -c "import gi; print('GTK bindings OK')"
```

---

### Issue: ntfs-3g not installed

**Symptoms:**
```
Error: ntfs-3g driver not found
mount: unknown filesystem type 'ntfs'
```

**Solution:**
```bash
# Ubuntu/Debian
sudo apt install ntfs-3g

# Fedora
sudo dnf install ntfs-3g

# Arch Linux
sudo pacman -S ntfs-3g

# openSUSE
sudo zypper install ntfs-3g
```

**Verify installation:**
```bash
which ntfs-3g
# Should output: /usr/bin/ntfs-3g or similar
```

---

### Issue: Installation script fails

**Symptoms:**
```
./install.sh: Permission denied
```

**Solution:**
```bash
# Make script executable
chmod +x install.sh

# Run with sudo
sudo ./install.sh
```

---

## Permission Errors

### Issue: "Permission denied" when mounting

**Symptoms:**
```
Error: Permission denied
mount: only root can do that
```

**Solution 1: Use sudo**
```bash
sudo ntfs-manager
# Or
sudo ntfs-manager --mount /dev/sdb1
```

**Solution 2: Add user to disk group**
```bash
# Add user to disk group
sudo usermod -a -G disk $USER

# Log out and log back in for changes to take effect
```

**Solution 3: Configure PolicyKit**
Create file `/etc/polkit-1/rules.d/50-ntfs-manager.rules`:
```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.udisks2.filesystem-mount" &&
        subject.isInGroup("disk")) {
        return polkit.Result.YES;
    }
});
```

---

### Issue: Cannot write to NTFS drive

**Symptoms:**
```
Error: Read-only file system
Permission denied when copying files
```

**Solution 1: Check mount options**
```bash
# Remount with write permissions
sudo umount /dev/sdb1
sudo mount -t ntfs-3g -o rw,uid=$(id -u),gid=$(id -g) /dev/sdb1 /mnt/ntfs

# Or use NTFS Manager
ntfs-manager --mount /dev/sdb1 --rw
```

**Solution 2: Fix NTFS errors**
```bash
# Unmount the drive first
sudo umount /dev/sdb1

# Check and fix NTFS filesystem
sudo ntfsfix /dev/sdb1

# Try mounting again
sudo mount -t ntfs-3g /dev/sdb1 /mnt/ntfs
```

**Solution 3: Remove fast startup (Windows)**
If the drive was used in Windows with fast startup enabled:
```bash
# Force remove Windows hibernation
sudo ntfs-3g -o remove_hiberfile /dev/sdb1 /mnt/ntfs
```

---

### Issue: "Dirty bit is set" error

**Symptoms:**
```
The disk contains an unclean file system (0, 0).
Metadata kept in Windows cache, refused to mount.
```

**Solution:**
```bash
# Fix the dirty bit
sudo ntfsfix /dev/sdb1

# If that doesn't work, mount with force option
sudo mount -t ntfs-3g -o force /dev/sdb1 /mnt/ntfs
```

**Prevention:**
- Properly eject drives in Windows before removing
- Disable Windows fast startup
- Use "Safely Remove Hardware" in Windows

---

## Mount/Unmount Problems

### Issue: Drive not detected

**Symptoms:**
- Drive doesn't appear in NTFS Manager
- `fdisk -l` doesn't show the drive

**Solution:**
```bash
# Check if drive is connected
lsblk

# Check USB connections
dmesg | tail -20

# Rescan for drives
sudo partprobe

# Check with fdisk
sudo fdisk -l
```

**If drive still not detected:**
1. Try a different USB port
2. Try a different USB cable
3. Test drive on another computer
4. Check drive with disk utility tools

---

### Issue: Mount point already in use

**Symptoms:**
```
Error: mount point /mnt/ntfs is already in use
```

**Solution:**
```bash
# Check what's using the mount point
mount | grep /mnt/ntfs

# Unmount the existing mount
sudo umount /mnt/ntfs

# Or use a different mount point
mkdir ~/ntfs-drive
sudo mount -t ntfs-3g /dev/sdb1 ~/ntfs-drive
```

---

### Issue: Device is busy

**Symptoms:**
```
umount: /mnt/ntfs: target is busy
```

**Solution:**
```bash
# Find processes using the mount point
sudo lsof +f -- /mnt/ntfs
# Or
sudo fuser -mv /mnt/ntfs

# Kill processes if necessary
sudo fuser -km /mnt/ntfs

# Force unmount
sudo umount -l /mnt/ntfs  # Lazy unmount
# Or
sudo umount -f /mnt/ntfs  # Force unmount
```

---

### Issue: Cannot safely remove drive

**Symptoms:**
- "Eject" button greyed out
- "Device busy" when trying to eject

**Solution:**
```bash
# Close all applications accessing the drive
# Check for open files
lsof | grep /dev/sdb1

# Sync filesystem before ejecting
sync

# Unmount all partitions
sudo umount /dev/sdb1

# Safely remove
sudo eject /dev/sdb
```

---

## GUI Issues

### Issue: NTFS Manager won't start

**Symptoms:**
- Double-click does nothing
- No window appears

**Solution 1: Run from terminal to see error**
```bash
ntfs-manager --verbose
```

**Solution 2: Check dependencies**
```bash
# Verify GTK installation
python3 -c "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk"
```

**Solution 3: Remove corrupted config**
```bash
# Backup and remove config
mv ~/.config/ntfs-manager ~/.config/ntfs-manager.bak
ntfs-manager
```

**Solution 4: Check log files**
```bash
cat ~/.local/share/ntfs-manager/logs/ntfs-manager.log
```

---

### Issue: GUI crashes on startup

**Symptoms:**
```
Segmentation fault (core dumped)
```

**Solution:**
```bash
# Update GTK and dependencies
sudo apt update
sudo apt upgrade

# Reinstall NTFS Manager
cd Linux-NTFS-Manager/ntfs-manager-production
sudo ./install.sh

# Check for conflicting packages
dpkg -l | grep gtk
```

---

### Issue: Icons not displaying

**Symptoms:**
- Placeholder icons shown
- Missing application icon

**Solution:**
```bash
# Update icon cache
sudo gtk-update-icon-cache /usr/share/icons/hicolor/

# Reinstall icons
cd Linux-NTFS-Manager/ntfs-manager-production
sudo cp -r icons/* /usr/share/icons/hicolor/

# Update icon cache again
sudo update-icon-caches /usr/share/icons/*
```

---

### Issue: Application menu entry missing

**Symptoms:**
- NTFS Manager not in applications menu
- Can't find in search

**Solution:**
```bash
# Reinstall desktop entry
sudo cp ntfs-manager.desktop /usr/share/applications/

# Update desktop database
sudo update-desktop-database

# Verify installation
ls -la /usr/share/applications/ntfs-manager.desktop
```

---

## Performance Problems

### Issue: Slow file transfers

**Symptoms:**
- Copy/paste very slow
- Transfer speeds < 10 MB/s

**Solution 1: Check USB version**
```bash
# Check USB speed
lsusb -t
# Look for 480M (USB 2.0) or 5000M (USB 3.0)
```

**Solution 2: Optimize mount options**
```bash
# Remount with optimized options
sudo umount /dev/sdb1
sudo mount -t ntfs-3g -o big_writes,noatime /dev/sdb1 /mnt/ntfs
```

**Solution 3: Check drive health**
```bash
# Check SMART status
sudo smartctl -a /dev/sdb
```

---

### Issue: High CPU usage

**Symptoms:**
- NTFS Manager using 100% CPU
- System becomes slow

**Solution:**
```bash
# Check what's consuming CPU
top -p $(pgrep -f ntfs-manager)

# Restart NTFS Manager
pkill -f ntfs-manager
ntfs-manager
```

---

### Issue: Memory leak

**Symptoms:**
- Memory usage increases over time
- System runs out of memory

**Solution:**
```bash
# Monitor memory usage
watch -n 1 'ps aux | grep ntfs-manager'

# Restart the application
pkill -f ntfs-manager
ntfs-manager
```

---

## Error Messages

### Error: "No such file or directory"

**Cause:** Device path incorrect or drive not connected

**Solution:**
```bash
# List all block devices
lsblk

# Check correct device path
sudo fdisk -l

# Use correct path
ntfs-manager --mount /dev/sdb1  # Not /dev/sdb
```

---

### Error: "Operation not permitted"

**Cause:** Insufficient permissions

**Solution:**
```bash
# Run with sudo
sudo ntfs-manager

# Or fix permissions (see Permission Errors section)
```

---

### Error: "Invalid argument"

**Cause:** Incorrect mount options or corrupted filesystem

**Solution:**
```bash
# Check filesystem
sudo ntfsfix /dev/sdb1

# Try basic mount
sudo mount -t ntfs-3g /dev/sdb1 /mnt/ntfs
```

---

### Error: "Input/output error"

**Cause:** Hardware problem or drive failure

**Solution:**
```bash
# Check drive health
sudo smartctl -a /dev/sdb

# Check dmesg for errors
dmesg | grep -i error

# Try read-only mount
sudo mount -t ntfs-3g -o ro /dev/sdb1 /mnt/ntfs
```

**Warning:** Input/output errors often indicate drive failure. Back up data immediately!

---

## Log Files

### Location

Log files are stored in:
```
~/.local/share/ntfs-manager/logs/
```

### Viewing Logs

```bash
# View main log
cat ~/.local/share/ntfs-manager/logs/ntfs-manager.log

# View with tail (live updates)
tail -f ~/.local/share/ntfs-manager/logs/ntfs-manager.log

# View last 50 lines
tail -n 50 ~/.local/share/ntfs-manager/logs/ntfs-manager.log

# Search for errors
grep -i error ~/.local/share/ntfs-manager/logs/ntfs-manager.log
```

### Enabling Debug Logging

```bash
# Run with verbose output
ntfs-manager --verbose

# Or set log level in config
echo "log_level = DEBUG" >> ~/.config/ntfs-manager/config.ini
```

### Log Rotation

Logs are automatically rotated:
- Maximum size: 10 MB
- Number of backups: 5
- Location: `~/.local/share/ntfs-manager/logs/`

---

## Getting Additional Help

### Before Asking for Help

Gather this information:

1. **System information:**
   ```bash
   uname -a
   cat /etc/os-release
   ```

2. **NTFS Manager version:**
   ```bash
   ntfs-manager --version
   ```

3. **Python version:**
   ```bash
   python3 --version
   ```

4. **Error messages:**
   ```bash
   ntfs-manager --verbose 2>&1 | tee error.log
   ```

5. **Log files:**
   ```bash
   cat ~/.local/share/ntfs-manager/logs/ntfs-manager.log
   ```

6. **Drive information:**
   ```bash
   sudo fdisk -l
   lsblk
   ```

### Where to Get Help

1. **GitHub Issues**
   - URL: https://github.com/sprinteroz/Linux-NTFS-Manager/issues
   - For bug reports and feature requests
   - Search existing issues first

2. **GitHub Discussions**
   - URL: https://github.com/sprinteroz/Linux-NTFS-Manager/discussions
   - For questions and general discussion
   - Community support

3. **Wiki Documentation**
   - URL: https://github.com/sprinteroz/Linux-NTFS-Manager/wiki
   - Complete documentation
   - Step-by-step guides

4. **Email Support**
   - Email: support_ntfs@magdrivex.com.au
   - For commercial license holders
   - Available in 6 months for business licenses

### Reporting Bugs

When reporting bugs, include:

- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- System information
- Log files
- Screenshots (if applicable)

Use this template:

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**System Information**
- OS: [e.g. Ubuntu 22.04]
- NTFS Manager Version: [e.g. 1.0.2]
- Python Version: [e.g. 3.11.0]

**Log Files**
<details>
<summary>Click to expand</summary>

```
Paste log contents here
```
</details>

**Additional context**
Any other relevant information.
```

---

## Quick Reference

### Common Commands

```bash
# List drives
ntfs-manager --list

# Mount drive
sudo ntfs-manager --mount /dev/sdb1

# Unmount drive
sudo ntfs-manager --unmount /dev/sdb1

# Get drive info
ntfs-manager --info /dev/sdb1

# Run with verbose output
ntfs-manager --verbose

# Check version
ntfs-manager --version

# View help
ntfs-manager --help
```

### Useful System Commands

```bash
# List block devices
lsblk

# Detailed device list
sudo fdisk -l

# Check mount points
mount | grep ntfs

# Check drive health
sudo smartctl -a /dev/sdb

# View system logs
sudo journalctl -xe

# Check USB devices
lsusb

# Monitor drive activity
sudo iotop
```

---

## Still Having Issues?

If you've tried everything and still have problems:

1. **Check the [FAQ](FAQ)** for common questions
2. **Search [existing issues](https://github.com/sprinteroz/Linux-NTFS-Manager/issues)** on GitHub
3. **Ask in [Discussions](https://github.com/sprinteroz/Linux-NTFS-Manager/discussions)**
4. **Open a [new issue](https://github.com/sprinteroz/Linux-NTFS-Manager/issues/new)** with detailed information

---

**Need more help?** Visit our [GitHub repository](https://github.com/sprinteroz/Linux-NTFS-Manager) or check the [Installation Guide](Installation-Guide) and [User Guide](User-Guide).
