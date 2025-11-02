# NTFS Manager - User Guide

Complete guide to using NTFS Manager for drive management on Linux.

## 🎯 Quick Start

### Launching NTFS Manager

**Via Nautilus (Recommended):**
1. Open Nautilus file manager
2. Navigate to any drive or folder
3. Right-click to access NTFS Management menu

**Via Standalone GUI:**
```bash
ntfs-manager-gui
```

## 📂 Basic Operations

### Mount a Drive

**Using Nautilus:**
1. Right-click on unmounted drive
2. Select "NTFS Management" → "Mount Drive"
3. Drive mounts automatically

**Using CLI:**
```bash
sudo mount /dev/sdX1 /mnt/mydrive
```

### Unmount a Drive

**Using Nautilus:**
1. Right-click on mounted drive
2. Select "NTFS Management" → "Unmount Drive"
3. Confirm the operation

**Safety Note:** Ensure no files are open before unmounting.

### View Drive Properties

1. Right-click on any drive
2. Select "NTFS Management" → "Drive Properties"
3. View tabs:
   - **Basic:** Size, used space, filesystem
   - **NTFS:** Compression, encryption status
   - **Health:** SMART data, errors

### Check Drive Health

1. Right-click on drive
2. Select "NTFS Management" → "Health Check"
3. Review:
   - SMART status
   - Bad sectors
   - Temperature
   - Read/write errors

### Repair Drive

**For filesystem errors:**
1. Unmount the drive first
2. Right-click on drive
3. Select "NTFS Management" → "Repair Drive"
4. Confirm operation
5. Wait for completion

**CLI method:**
```bash
sudo ntfsfix /dev/sdX1
```

### Format Drive

⚠️ **Warning:** This erases all data!

1. Backup important data first
2. Right-click on drive
3. Select "NTFS Management" → "Format Drive"
4. Choose filesystem (NTFS/exFAT/FAT32/EXT4)
5. Confirm twice (safety measure)
6. Wait for completion

### Safe Eject

**For removable drives:**
1. Right-click on drive
2. Select "NTFS Management" → "Safe Eject"
3. Wait for confirmation
4. Remove drive physically

## 🔧 Advanced Features

### Custom Mount Options

Edit `~/.config/ntfs-manager/config.ini`:

```ini
[NTFS Manager]
default_mount_options=uid=1000,gid=1000,dmask=022,fmask=133,permissions
```

**Common options:**
- `uid=1000` - Set owner user ID
- `gid=1000` - Set owner group ID  
- `dmask=022` - Directory permissions
- `fmask=133` - File permissions
- `permissions` - Enable Linux permissions
- `big_writes` - Better performance
- `compression` - Enable compression

### Auto-Mount Configuration

**Enable auto-mount:**
```bash
# Create fstab entry
sudo nano /etc/fstab

# Add line:
UUID=YOUR-UUID  /mnt/mydrive  ntfs-3g  defaults,uid=1000,gid=1000  0  0
```

**Find UUID:**
```bash
sudo blkid /dev/sdX1
```

### Monitoring and Notifications

**Enable notifications:**
```ini
[NTFS Manager]
notifications=true
health_monitoring=true
auto_monitoring=true
refresh_interval=30
```

**Monitor logs:**
```bash
tail -f ~/.local/share/ntfs-manager/logs/main.log
```

## 🎨 Configuration

### Configuration File

Location: `~/.config/ntfs-manager/config.ini`

**Full configuration:**
```ini
[NTFS Manager]
# Enable desktop notifications
notifications=true

# Drive refresh interval (seconds)
refresh_interval=30

# Logging level (DEBUG|INFO|WARNING|ERROR)
log_level=INFO

# Enable automatic health monitoring
health_monitoring=true

# Show advanced options in GUI
advanced_options=true

# Default mount options
default_mount_options=uid=1000,gid=1000,dmask=022,fmask=133

# Auto-start monitoring on login
auto_monitoring=true

# Fallback mode if dependencies missing
fallback_mode=true

# Preferred NTFS tool (auto|ntfs-3g|ntfsprogs)
preferred_ntfs_tool=auto

# System integration features
system_integration=true

# Debug mode (verbose logging)
debug_mode=false
```

### Logging Configuration

**Log locations:**
- Main log: `~/.local/share/ntfs-manager/logs/main.log`
- Operations: `~/.local/share/ntfs-manager/logs/operations.log`
- Errors: `~/.local/share/ntfs-manager/logs/errors.log`
- Security: `~/.local/share/ntfs-manager/logs/security.log`
- Structured: `~/.local/share/ntfs-manager/logs/structured.json`

**Log rotation:**
Logs automatically rotate at 10MB with 5 backup files.

## 💡 Tips and Tricks

### Performance Optimization

**For large drives:**
```ini
default_mount_options=uid=1000,gid=1000,big_writes,compression
```

**For SSDs:**
```ini
default_mount_options=uid=1000,gid=1000,discard,noatime
```

### Keyboard Shortcuts

**In Nautilus:**
- `F2` - Rename drive label
- `Ctrl+Shift+N` - New folder on drive
- `Ctrl+H` - Show hidden files

### CLI Commands

**List all drives:**
```bash
lsblk -f
```

**Check NTFS drive:**
```bash
sudo ntfsfix -n /dev/sdX1  # Check only
sudo ntfsfix /dev/sdX1     # Check and fix
```

**Mount with options:**
```bash
sudo mount -t ntfs-3g -o uid=1000,gid=1000,dmask=022,fmask=133 /dev/sdX1 /mnt/mydrive
```

## 🐛 Common Issues

### Drive Not Mounting

**Check filesystem:**
```bash
sudo ntfsfix /dev/sdX1
```

**Try manual mount:**
```bash
sudo mkdir -p /mnt/test
sudo mount -t ntfs-3g /dev/sdX1 /mnt/test
```

### Permission Denied

**Add to groups:**
```bash
sudo usermod -a -G disk,plugdev $USER
```
Then log out and back in.

### Slow Performance

**Use big_writes:**
```bash
sudo mount -t ntfs-3g -o big_writes /dev/sdX1 /mnt/mydrive
```

## 📊 Understanding Drive Information

### Drive Status Indicators

- 🟢 **Healthy:** Drive is functioning normally
- 🟡 **Warning:** Minor issues detected
- 🔴 **Critical:** Immediate attention required
- ⚫ **Unknown:** Unable to read SMART data

### SMART Attributes

**Important attributes:**
- **Reallocated Sectors:** Should be 0
- **Current Pending Sectors:** Should be 0  
- **Temperature:** Should be under 50°C
- **Power-On Hours:** Drive age indicator

### Filesystem Information

**NTFS Features:**
- Compression supported
- Encryption supported
- File permissions
- Large file support (>4GB)
- Journal for crash recovery

## 🔒 Security Best Practices

### Safe Operations

1. **Always backup** before format/repair
2. **Unmount properly** before unplugging
3. **Check health** regularly
4. **Monitor logs** for errors
5. **Use encryption** for sensitive data

### Encrypted Drives

**LUKS-encrypted NTFS:**
```bash
# Unlock encrypted container
sudo cryptsetup open /dev/sdX1 mydrive_crypt

# Mount the NTFS inside
sudo mount /dev/mapper/mydrive_crypt /mnt/mydrive
```

## 📱 Integration Examples

### Backup Script Using NTFS Manager

```bash
#!/bin/bash
# Auto-mount, backup, unmount

DEVICE="/dev/sdb1"
MOUNT_POINT="/mnt/backup"

# Mount drive
sudo mkdir -p "$MOUNT_POINT"
sudo mount "$DEVICE" "$MOUNT_POINT"

# Perform backup
rsync -av ~/Documents/ "$MOUNT_POINT/backup/"

# Unmount safely
sudo umount "$MOUNT_POINT"
```

### System Tray Integration

NTFS Manager can integrate with system tray for quick access to mounted drives.

## 📚 Additional Resources

- Installation: See `INSTALLATION.md`
- Troubleshooting: See `TROUBLESHOOTING.md`
- Architecture: See `ARCHITECTURE.md`
- API Reference: See `API-REFERENCE.md`

## 💬 Getting Help

**For usage questions:**
1. Check this guide
2. Review troubleshooting guide
3. Check logs for error messages
4. Contact support: sales@magdrivex.com.au / sales@magdrivex.com

**Developer:** Darryl Bennett  
**Company:** MagDriveX (2023-2025)  
**Email:** sales@magdrivex.com.au / sales@magdrivex.com

---

**Master NTFS management on Linux with confidence!**

**Copyright © 2023-2025 Darryl Bennett / MagDriveX. All rights reserved.**
