# NTFS Manager - Troubleshooting Guide

Common issues and solutions for NTFS Manager.

## 🔍 Diagnostic Tools

### Check Installation Status

```bash
# Verify Nautilus extension
ls -l ~/.local/share/nautilus-python/extensions/ntfs_manager_extension.py

# Check backend modules
ls -l /usr/local/lib/ntfs-manager/backend/

# Test Python imports
python3 -c "import sys; sys.path.insert(0, '/usr/local/lib/ntfs-manager'); from backend import drive_manager; print('OK')"
```

### Check System Logs

```bash
# Nautilus logs
journalctl -f | grep nautilus

# System logs
journalctl -xe

# Application logs
tail -f ~/.local/share/ntfs-manager/logs/errors.log
```

## 🐛 Common Issues

### Extension Not Appearing in Context Menu

**Symptoms:** Right-click menu doesn't show "NTFS Management"

**Solutions:**

1. **Verify Python Nautilus bindings:**
   ```bash
   dpkg -l | grep python3-nautilus
   # If missing:
   sudo apt install python3-nautilus
   ```

2. **Check extension location:**
   ```bash
   mkdir -p ~/.local/share/nautilus-python/extensions/
   cp ntfs-manager-production/nautilus-extension/ntfs_manager_extension.py \
      ~/.local/share/nautilus-python/extensions/
   ```

3. **Restart Nautilus properly:**
   ```bash
   nautilus -q
   killall nautilus
   nautilus --no-default-window &
   ```

4. **Check for Python errors:**
   ```bash
   python3 -m py_compile ~/.local/share/nautilus-python/extensions/ntfs_manager_extension.py
   ```

### Permission Denied Errors

**Symptoms:** "Permission denied" when mounting/unmounting drives

**Solutions:**

1. **Add user to required groups:**
   ```bash
   sudo usermod -a -G disk,plugdev $USER
   ```
   **Important:** Log out and log back in!

2. **Check PolicyKit rules:**
   ```bash
   sudo tee /etc/polkit-1/localauthority/50-local.d/ntfs-manager.pkla > /dev/null <<'EOF'
   [NTFS Manager Permissions]
   Identity=unix-group:disk
   Action=org.freedesktop.udisks2.*
   ResultActive=yes
   EOF
   ```

3. **Verify device permissions:**
   ```bash
   ls -l /dev/sd*
   groups $USER
   ```

### Drive Not Detected

**Symptoms:** Drive doesn't appear in manager

**Solutions:**

1. **Check system detection:**
   ```bash
   lsblk -f
   sudo fdisk -l
   ```

2. **Verify udev is running:**
   ```bash
   sudo systemctl status systemd-udevd
   sudo systemctl restart systemd-udevd
   ```

3. **Check drive health:**
   ```bash
   sudo smartctl -a /dev/sdX
   ```

### Mount Fails

**Symptoms:** Drive won't mount or mount operation fails

**Solutions:**

1. **Check filesystem integrity:**
   ```bash
   sudo ntfsfix /dev/sdX1
   ```

2. **Try manual mount:**
   ```bash
   sudo mkdir -p /mnt/test
   sudo mount -t ntfs-3g /dev/sdX1 /mnt/test
   ```

3. **Check for existing mount:**
   ```bash
   mount | grep sdX1
   ```

4. **View detailed error:**
   ```bash
   sudo dmesg | tail -20
   ```

### Slow Performance

**Symptoms:** File operations are very slow

**Solutions:**

1. **Use big_writes option:**
   ```bash
   sudo mount -t ntfs-3g -o big_writes /dev/sdX1 /mnt/drive
   ```

2. **For SSDs, add noatime:**
   ```bash
   sudo mount -t ntfs-3g -o big_writes,noatime /dev/sdX1 /mnt/drive
   ```

3. **Check drive health:**
   ```bash
   sudo smartctl -a /dev/sdX
   ```

### Python Import Errors

**Symptoms:** "ModuleNotFoundError" or import failures

**Solutions:**

1. **Verify backend installation:**
   ```bash
   ls -l /usr/local/lib/ntfs-manager/backend/
   ```

2. **Check Python path:**
   ```bash
   python3 -c "import sys; print('\n'.join(sys.path))"
   ```

3. **Reinstall backend:**
   ```bash
   sudo mkdir -p /usr/local/lib/ntfs-manager/backend
   sudo cp -r backend/*.py /usr/local/lib/ntfs-manager/backend/
   ```

4. **Install Python dependencies:**
   ```bash
   pip3 install -r requirements.txt --user
   ```

### GTK Errors

**Symptoms:** GTK warnings or GUI issues

**Solutions:**

1. **Install GTK dependencies:**
   ```bash
   sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0
   ```

2. **Check GObject introspection:**
   ```bash
   python3 -c "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk"
   ```

### Formatting Fails

**Symptoms:** Cannot format drive

**Solutions:**

1. **Unmount first:**
   ```bash
   sudo umount /dev/sdX1
   ```

2. **Check for partitions in use:**
   ```bash
   lsof | grep sdX
   ```

3. **Use mkfs directly:**
   ```bash
   sudo mkfs.ntfs -f /dev/sdX1
   ```

### Safe Eject Fails

**Symptoms:** "Device is busy" error

**Solutions:**

1. **Find processes using the drive:**
   ```bash
   lsof | grep /mnt/drive
   fuser -m /mnt/drive
   ```

2. **Force unmount (last resort):**
   ```bash
   sudo umount -l /dev/sdX1
   ```

## 🔧 Advanced Troubleshooting

### Enable Debug Mode

Edit `~/.config/ntfs-manager/config.ini`:

```ini
[NTFS Manager]
debug_mode=true
log_level=DEBUG
```

### Collect Diagnostic Information

```bash
#!/bin/bash
# Run this script to collect diagnostic info

echo "=== System Information ===" > ntfs-manager-diag.txt
uname -a >> ntfs-manager-diag.txt

echo -e "\n=== Python Version ===" >> ntfs-manager-diag.txt
python3 --version >> ntfs-manager-diag.txt

echo -e "\n=== Installed Packages ===" >> ntfs-manager-diag.txt
dpkg -l | grep -E 'ntfs|python3-nautilus|python3-gi' >> ntfs-manager-diag.txt

echo -e "\n=== Drives ===" >> ntfs-manager-diag.txt
lsblk -f >> ntfs-manager-diag.txt

echo -e "\n=== Mount Points ===" >> ntfs-manager-diag.txt
mount | grep -E 'ntfs|fuse' >> ntfs-manager-diag.txt

echo -e "\n=== User Groups ===" >> ntfs-manager-diag.txt
groups >> ntfs-manager-diag.txt

echo -e "\n=== Extension Status ===" >> ntfs-manager-diag.txt
ls -l ~/.local/share/nautilus-python/extensions/ >> ntfs-manager-diag.txt

echo -e "\n=== Backend Status ===" >> ntfs-manager-diag.txt
ls -l /usr/local/lib/ntfs-manager/backend/ >> ntfs-manager-diag.txt

echo -e "\n=== Recent Logs ===" >> ntfs-manager-diag.txt
tail -50 ~/.local/share/ntfs-manager/logs/errors.log >> ntfs-manager-diag.txt 2>&1

echo "Diagnostic info saved to ntfs-manager-diag.txt"
```

### Reset Configuration

```bash
# Backup current config
cp -r ~/.config/ntfs-manager ~/.config/ntfs-manager.backup

# Reset to defaults
rm -rf ~/.config/ntfs-manager
mkdir -p ~/.config/ntfs-manager

# Create fresh config
cat > ~/.config/ntfs-manager/config.ini <<EOF
[NTFS Manager]
notifications=true
refresh_interval=30
log_level=INFO
EOF
```

### Reinstall Clean

```bash
# Complete removal
rm -f ~/.local/share/nautilus-python/extensions/ntfs_manager_extension.py
sudo rm -rf /usr/local/lib/ntfs-manager
rm -rf ~/.config/ntfs-manager
rm -rf ~/.local/share/ntfs-manager

# Fresh install
cd ntfs-manager-production
sudo ./install.sh

# Restart Nautilus
nautilus -q && nautilus --no-default-window &
```

## 📝 Reporting Issues

When reporting issues, include:

1. **System information:**
   - OS version: `lsb_release -a`
   - Kernel: `uname -r`
   - Python version: `python3 --version`

2. **Error messages:**
   - Full error text
   - Log files from `~/.local/share/ntfs-manager/logs/`

3. **Steps to reproduce:**
   - What you were trying to do
   - Exact steps taken
   - Expected vs actual behavior

4. **Diagnostic output:**
   - Run diagnostic script above
   - Include ntfs-manager-diag.txt

## 📚 Additional Help

- Installation Guide: See `INSTALLATION.md`
- User Guide: See `USAGE.md`
- Architecture: See `ARCHITECTURE.md`
- Main README: See `README.md`

## 💬 Support Contact

**Developer:** Darryl Bennett  
**Company:** MagDriveX (2023-2025)  
**Email:** sales@magdrivex.com.au / sales@magdrivex.com  
**ABN:** 82 977 519 307  
**Address:** PO Box 28 Ardlethan NSW 2665 Australia

---

**Still having issues?** Check system logs and enable debug mode for more detailed information.

**Copyright © 2023-2025 Darryl Bennett / MagDriveX. All rights reserved.**
