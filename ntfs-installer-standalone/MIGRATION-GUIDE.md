# Migration Guide: v2.0 → v3.0
## Upgrading to Enhanced NTFS Installer with Security & Auto-Updates

This guide helps you migrate from NTFS Installer v2.0 to v3.0 with minimal disruption.

---

## 📋 Quick Migration Checklist

- [ ] Review new features and requirements
- [ ] Backup existing configuration (if any)
- [ ] Run enhanced installer
- [ ] Deploy system integration (optional but recommended)
- [ ] Configure update preferences
- [ ] Test NTFS functionality
- [ ] Enable automated updates (optional)

---

## 🎯 What's New in v3.0?

### Major Enhancements
1. **Security**: GPG/SHA256 verification, secure downloads, audit logging
2. **Auto-Updates**: Systemd timer + APT hooks for automatic checking
3. **Version Management**: 5-version rollback system
4. **ARM Support**: Cross-compilation for ARM64/ARM32 architectures
5. **Enhanced UX**: Dry-run mode, verbose logging, better errors

### Compatibility
- ✅ **Fully compatible** with v2.0 installations
- ✅ **No breaking changes** - v2.0 continues to work
- ✅ **Gradual migration** - upgrade at your own pace
- ✅ **Rollback supported** - can revert if needed

---

## 🔧 Migration Steps

### Step 1: Pre-Migration Check

```bash
# Check current installation status
sudo ntfs-complete-manager-v2.sh --scan

# Check kernel version (6.2+ required for NTFSplus)
uname -r

# Verify disk space (2GB minimum needed)
df -h /tmp
```

**Expected Output:**
- ntfsprogs-plus installed
- NTFSplus driver loaded (if kernel >= 6.2)
- At least 2GB free space

### Step 2: Backup Current Configuration (Optional)

```bash
# Create backup directory
mkdir -p ~/ntfs-backup-$(date +%Y%m%d)

# Backup version information
sudo cp -r /usr/local/share/ntfs-complete ~/ntfs-backup-$(date +%Y%m%d)/ 2>/dev/null || true

# Backup logs
sudo cp -r /tmp/ntfs-complete* ~/ntfs-backup-$(date +%Y%m%d)/ 2>/dev/null || true
```

### Step 3: Download Enhanced Installer

If you haven't already, get the latest version:

```bash
cd ntfs-installer-standalone
git pull  # If using git
# OR download the enhanced installer manually
```

### Step 4: Run Enhanced Installer

#### Option A: Standard Installation
```bash
cd ntfs-installer-standalone
sudo ./install-ntfs-enhanced.sh
```

#### Option B: Dry-Run First (Recommended)
```bash
# Test without making changes
sudo ./install-ntfs-enhanced.sh --dry-run

# Then run for real
sudo ./install-ntfs-enhanced.sh
```

#### Option C: With ARM Support
```bash
sudo ./install-ntfs-enhanced.sh --enable-arm
```

#### Option D: Verbose Mode
```bash
sudo ./install-ntfs-enhanced.sh --verbose
```

**What Happens:**
1. Checks system requirements
2. Installs missing dependencies (automake, autoconf, etc.)
3. Runs ntfs-complete-manager-v2.sh for actual installation
4. Creates enhanced directory structure
5. Initializes version tracking

### Step 5: Deploy System Integration (Recommended)

This adds automatic update checking:

```bash
cd ntfs-installer-standalone/scripts
sudo ./deploy-system-integration.sh
```

**What Gets Installed:**
- Update checker script: `/usr/local/bin/ntfs-update-check`
- Systemd service: `/etc/systemd/system/ntfs-update-check.service`
- Systemd timer: `/etc/systemd/system/ntfs-update-check.timer`
- APT hook: `/etc/apt/apt.conf.d/99ntfs-updater`
- Config file: `/etc/ntfs-installer/update-config.conf`

**Interactive Prompts:**
1. Enable automatic update checks? (Systemd timer)
2. Configure update frequency (daily/weekly/monthly)

### Step 6: Configure Update Preferences

Edit the configuration file:

```bash
sudo nano /etc/ntfs-installer/update-config.conf
```

**Key Settings:**
```bash
UPDATE_FREQUENCY="weekly"      # daily/weekly/monthly/manual
AUTO_UPDATE=false              # Set to true for automatic updates
NOTIFY_USER=true              # Desktop notifications
CHECK_ON_KERNEL_UPDATE=true   # Check after kernel updates
```

**Recommended Settings:**
- **Conservative**: `UPDATE_FREQUENCY="monthly"`, `AUTO_UPDATE=false`
- **Balanced**: `UPDATE_FREQUENCY="weekly"`, `AUTO_UPDATE=false`
- **Aggressive**: `UPDATE_FREQUENCY="daily"`, `AUTO_UPDATE=true`

### Step 7: Verify Installation

```bash
# Check enhanced installer version
sudo ./install-ntfs-enhanced.sh --help

# Check update system
sudo ntfs-update-check status

# Check timer status
systemctl status ntfs-update-check.timer

# List installed versions
sudo ./install-ntfs-enhanced.sh --list-versions

# Verify NTFS functionality
sudo ntfs-complete-manager-v2.sh --scan
```

### Step 8: Test NTFS Operations

```bash
# Check if NTFS utilities work
ntfsck --help
ntfsclone --help

# Check kernel module (if kernel >= 6.2)
lsmod | grep ntfsplus

# Check version tracking
ls -la /usr/local/share/ntfs-complete/versions/
```

---

## 🔄 Configuration Differences

### v2.0 Configuration
```
/usr/local/share/ntfs-complete/
├── ntfsprogs-manifest.txt
├── ntfsplus-installed
└── versions.txt
```

### v3.0 Configuration (Enhanced)
```
/var/log/ntfs-installer/          # New: Organized logs
├── audit.log                      # New: Audit trail
├── install-YYYYMMDD-HHMMSS.log   # New: Per-install logs
└── update-check.log              # New: Update logs

/etc/ntfs-installer/               # New: Configuration
└── update-config.conf            # New: Update settings

/usr/local/share/ntfs-complete/
├── versions/                      # New: Version history
│   ├── ntfsprogs-plus/
│   │   ├── v1.0.0.json
│   │   └── current.txt
│   └── ntfsplus/
│       ├── main-abc1234.json
│       └── current.txt
├── ntfsprogs-manifest.txt        # Existing
├── ntfsplus-installed            # Existing
└── versions.txt                  # Existing (still used)
```

---

## 🎓 New Features & Usage

### 1. Manual Update Checking

```bash
# Check for updates manually
sudo ntfs-update-check manual

# View update status
sudo ntfs-update-check status
```

### 2. Automatic Update Checking

```bash
# Enable timer
sudo systemctl enable --now ntfs-update-check.timer

# Check when next update check runs
systemctl list-timers ntfs-update-check.timer

# Disable timer
sudo systemctl disable --now ntfs-update-check.timer
```

### 3. Version Management

```bash
# List all installed versions
sudo ./install-ntfs-enhanced.sh --list-versions

# Rollback to previous version (framework ready)
sudo ./install-ntfs-enhanced.sh --rollback VERSION
```

### 4. Desktop Notifications

When updates are available, you'll see desktop notifications automatically (if libnotify-bin is installed and `NOTIFY_USER=true`).

### 5. Kernel Update Integration

After kernel updates, APT hook automatically checks if NTFS components need rebuilding.

### 6. Security Features

```bash
# GPG verification happens automatically
# Check audit log
sudo tail -f /var/log/ntfs-installer/audit.log

# View installation log
sudo tail -f /var/log/ntfs-installer/install-*.log
```

---

## 🚨 Troubleshooting

### Issue: "ntfs-update-check: command not found"

**Solution:**
```bash
# Re-run system integration deployment
cd ntfs-installer-standalone/scripts
sudo ./deploy-system-integration.sh
```

### Issue: Timer not running

**Solution:**
```bash
# Check timer status
systemctl status ntfs-update-check.timer

# If disabled, enable it
sudo systemctl enable --now ntfs-update-check.timer

# Check for errors
journalctl -u ntfs-update-check.service -n 50
```

### Issue: No desktop notifications

**Solution:**
```bash
# Install libnotify-bin
sudo apt install libnotify-bin

# Check config
grep NOTIFY_USER /etc/ntfs-installer/update-config.conf

# Test notification manually
notify-send "Test" "NTFS Update Test"
```

### Issue: "Dependency installation failed"

**Solution:**
```bash
# Update package lists
sudo apt update

# Try manual installation
sudo apt install automake autoconf libtool libgcrypt20-dev pkg-config dkms

# Re-run enhanced installer
sudo ./install-ntfs-enhanced.sh
```

### Issue: Want to disable all auto-updates

**Solution:**
```bash
# Disable systemd timer
sudo systemctl disable --now ntfs-update-check.timer

# Remove APT hook
sudo rm /etc/apt/apt.conf.d/99ntfs-updater

# Or edit config to manual only
sudo nano /etc/ntfs-installer/update-config.conf
# Set: UPDATE_FREQUENCY="manual"
```

---

## 🔙 Rollback to v2.0 (If Needed)

If you need to revert to v2.0 behavior:

### Option 1: Keep v3.0 but disable new features

```bash
# Disable automatic updates
sudo systemctl disable --now ntfs-update-check.timer

# Remove APT hook
sudo rm /etc/apt/apt.conf.d/99ntfs-updater

# Continue using v2.0 commands
sudo ntfs-complete-manager-v2.sh --update
```

### Option 2: Full revert to v2.0

```bash
# Uninstall system integration
sudo rm /usr/local/bin/ntfs-update-check
sudo rm /etc/systemd/system/ntfs-update-check.{service,timer}
sudo rm /etc/apt/apt.conf.d/99ntfs-updater
sudo rm -r /etc/ntfs-installer
sudo systemctl daemon-reload

# Keep using original installer
sudo ./install-ntfs.sh
```

**Note:** Your NTFS installation (ntfsprogs-plus, NTFSplus driver, ntfs-3g) remains intact in both cases.

---

## 📊 Feature Comparison

| Feature | v2.0 | v3.0 |
|---------|------|------|
| NTFS utilities | ✅ | ✅ |
| NTFSplus driver | ✅ | ✅ |
| Manual updates | ✅ | ✅ |
| Version tracking | Basic | ✅ Enhanced |
| GPG verification | ❌ | ✅ |
| SHA256 checksums | ❌ | ✅ |
| Audit logging | ❌ | ✅ |
| Auto-update checks | ❌ | ✅ |
| Desktop notifications | ❌ | ✅ |
| Kernel update hooks | ❌ | ✅ |
| Rollback system | ❌ | ✅ 5 versions |
| ARM support | ❌ | ✅ |
| Dry-run mode | ❌ | ✅ |
| Verbose logging | ❌ | ✅ |
| Enhanced errors | ❌ | ✅ |

---

## ✅ Post-Migration Checklist

After migration, verify:

- [ ] NTFS utilities work: `ntfsck --help`
- [ ] Kernel module loaded: `lsmod | grep ntfsplus` (if kernel >= 6.2)
- [ ] Update checker installed: `which ntfs-update-check`
- [ ] Version tracking works: `sudo ./install-ntfs-enhanced.sh --list-versions`
- [ ] Logs created: `ls -la /var/log/ntfs-installer/`
- [ ] Config file exists: `cat /etc/ntfs-installer/update-config.conf`
- [ ] Timer enabled (optional): `systemctl status ntfs-update-check.timer`
- [ ] Test mount and operations on NTFS drives

---

## 🆘 Getting Help

**Documentation:**
- Main README: `ntfs-installer-standalone/README.md`
- Changelog: `ntfs-installer-standalone/CHANGELOG.md`
- Phase 1 Audit: `ntfs-installer-standalone/NTFS-ENHANCEMENT-REPORT.md`

**Commands:**
```bash
# Show help
sudo ./install-ntfs-enhanced.sh --help
sudo ntfs-update-check help

# Check status
sudo ntfs-update-check status
sudo ntfs-complete-manager-v2.sh --scan

# View logs
sudo tail -f /var/log/ntfs-installer/audit.log
sudo tail -f /var/log/ntfs-installer/update-check.log
```

**Common Issues:**
- Dependency problems: Run `sudo apt update && sudo apt upgrade`
- Kernel too old: Upgrade to Ubuntu 24.04 or kernel 6.2+
- Permission errors: Always use `sudo`

---

## 💡 Best Practices

1. **Start with dry-run**: Test before committing
2. **Enable notifications**: Stay informed of updates
3. **Weekly checks**: Good balance of security and convenience
4. **Review logs periodically**: Check `/var/log/ntfs-installer/audit.log`
5. **Keep config backed up**: Save `/etc/ntfs-installer/update-config.conf`
6. **Test after updates**: Verify NTFS operations after major updates

---

## 🎯 Migration Success Criteria

You've successfully migrated when:

1. ✅ Enhanced installer runs without errors
2. ✅ NTFS utilities work (ntfsck, ntfsclone, etc.)
3. ✅ Update system reports status correctly
4. ✅ Logs are being created
5. ✅ Version history is tracked
6. ✅ Optional: Timer is enabled and scheduled

---

**Congratulations!** You've successfully migrated to NTFS Installer v3.0 with enhanced security, automation, and user experience. 🎉

For questions or issues, refer to the documentation or check the audit logs for detailed operation history.
