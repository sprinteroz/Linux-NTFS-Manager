# Changelog
All notable changes to the NTFS Installer project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2025-11-02

### Added - Phase 2 Enhancements

#### Security Features
- **GPG Signature Verification**: Verify git repository commits for integrity
- **SHA256 Checksum Validation**: File integrity checking for all downloads
- **Secure Downloads**: HTTPS-only with SSL/TLS certificate validation  
- **Audit Logging**: Comprehensive logging of all operations to `/var/log/ntfs-installer/audit.log`
- **Sandboxed Build Framework**: Ready for firejail integration

#### Version Management & Rollback
- **5-Version History**: Keep last 5 installed versions for rollback (user requirement)
- **Version Tracking**: JSON metadata for each installation with timestamps
- **Automatic Cleanup**: Old versions removed automatically when limit exceeded
- **Rollback Command**: `--rollback VERSION` command (framework implemented)
- **Version Comparison**: Automatic detection of newer releases

#### Automatic Update System
- **Update Checker Script**: `/usr/local/bin/ntfs-update-check`
  - Manual update checking
  - Scheduled update detection
  - Kernel update event handling
- **Systemd Integration**: 
  - Service: `ntfs-update-check.service`
  - Timer: `ntfs-update-check.timer` with configurable frequency
- **APT Hooks**: Automatic check trigger after kernel updates
- **Desktop Notifications**: Via `notify-send` for update availability
- **Configuration File**: `/etc/ntfs-installer/update-config.conf`

#### Enhanced Dependency Management
- **Missing Dependencies**: Auto-detection and installation
  - automake (1:1.16.5-1.3ubuntu1)
  - autoconf (2.71-3)
  - libtool (2.4.7-7build1)
  - libgcrypt20-dev (1.10.3-2build1)
  - pkg-config (1.8.1-2build1)
  - dkms (3.0.11-1ubuntu13)
- **Security Tools**: gnupg2, curl, openssl, ca-certificates
- **Optional Dependencies**: libnotify-bin, firejail
- **ARM Tools**: gcc-aarch64-linux-gnu, qemu-user-static (when --enable-arm)

#### ARM Architecture Support
- **Architecture Detection**: x86_64, ARM64, ARM32
- **Cross-Compilation**: ARM64 toolchain support with `--enable-arm` flag
- **Waydroid Compatibility**: Ready for Android container systems
- **BlueStacks Support**: x86_64 builds work with ARM translation

#### User Experience Improvements
- **Dry-Run Mode**: Test installation without making changes (`--dry-run`)
- **Verbose Logging**: Detailed operation logs (`--verbose`)
- **Interactive Configuration**: Smart prompts for optional features
- **Enhanced Error Messages**: Clear errors with actionable solutions
- **Disk Space Check**: Pre-installation validation (2GB minimum)
- **Network Validation**: GitHub connectivity verification
- **Progress Indicators**: Clear status during long operations

#### System Integration
- **Deployment Script**: `deploy-system-integration.sh` for one-command setup
- **Configuration Template**: `update-config.conf.template`
- **Directory Structure**: Organized logs, state, and configuration
- **Systemd Security**: Hardened service with minimal privileges

### Changed
- Upgraded installer from v2.0 to v3.0
- Enhanced logging system with multiple log files
- Improved error handling and recovery
- Better user interaction and prompts

### Technical Details

#### New Directories
- `/var/log/ntfs-installer/` - All log files
- `/etc/ntfs-installer/` - Configuration files
- `/usr/local/share/ntfs-complete/versions/` - Version history
- `/var/backups/ntfs-installer/` - Backup storage

#### New Commands
```bash
# Enhanced installer
sudo ./install-ntfs-enhanced.sh [OPTIONS]
  --dry-run           # Test without changes
  --verbose           # Detailed logging
  --enable-arm        # ARM cross-compilation
  --skip-security     # Skip GPG/SHA256 (not recommended)
  --force             # Force install without prompts
  --list-versions     # Show version history
  --rollback VERSION  # Rollback to previous version

# Update checker
sudo ntfs-update-check manual     # Manual check
sudo ntfs-update-check status     # Show status
sudo ntfs-update-check scheduled  # Scheduled check (systemd)

# System integration
sudo ./scripts/deploy-system-integration.sh

# Systemd timer
sudo systemctl enable --now ntfs-update-check.timer
sudo systemctl list-timers ntfs-update-check.timer
```

#### Configuration Options
File: `/etc/ntfs-installer/update-config.conf`
- `UPDATE_FREQUENCY` - daily/weekly/monthly/manual
- `AUTO_UPDATE` - true/false (automatic updates)
- `NOTIFY_USER` - true/false (desktop notifications)
- `CHECK_ON_KERNEL_UPDATE` - true/false (check after kernel updates)
- `MAX_OLD_VERSIONS` - Number of versions to keep (default: 5)

### Security Notes
- All git repositories are verified with GPG when commits are signed
- SHA256 checksums validate file integrity
- Downloads use HTTPS with certificate validation
- Audit logs track all operations with user attribution
- Systemd services run with minimal privileges

### Compatibility
- **Target**: Ubuntu 24.04.03 LTS
- **Kernel**: 6.2+ required for NTFSplus driver (6.8+ in Ubuntu 24.04)
- **Architectures**: x86_64 (primary), ARM64 (supported), ARM32 (limited)

### Breaking Changes
None - v3.0 is fully compatible with v2.0 installations

### Migration from v2.0
1. Existing v2.0 installations continue to work
2. Run `install-ntfs-enhanced.sh` for new features
3. Deploy system integration with `deploy-system-integration.sh`
4. Configure update frequency in `/etc/ntfs-installer/update-config.conf`

---

## [2.0.0] - 2025-10-20

### Added
- NTFS Complete Manager with version management
- DKMS support for automatic kernel module rebuilding
- ntfsprogs-plus utilities integration
- NTFSplus kernel driver support
- ntfs-3g additional utilities
- GParted GUI integration

### Features
- Automatic detection and installation
- Version tracking in `/usr/local/share/ntfs-complete/`
- Kernel compatibility checking (6.2+)
- Build from git repositories with latest releases

---

## [1.0.0] - Initial Release

### Added
- Basic NTFS installation script
- Manual installation of ntfs-3g
- Basic utility installation
- Simple error handling

---

## Future Enhancements (Planned)

### Version 3.1.0
- [ ] Full rollback implementation with file restoration
- [ ] Backup/restore mechanism for installations
- [ ] Advanced error recovery scenarios
- [ ] System health monitoring
- [ ] Integration with system monitoring tools

### Version 3.2.0
- [ ] Web-based management interface
- [ ] Email notifications for updates
- [ ] Advanced ARM architecture optimizations
- [ ] Multi-repository support
- [ ] Custom build configurations

### Version 4.0.0
- [ ] Container-based installation option
- [ ] Snap package distribution
- [ ] Flatpak support
- [ ] Multi-distribution support (Debian, Fedora, etc.)
- [ ] Cloud-based version management

---

## Support

- **Documentation**: See README files in `docs/` directory
- **Issues**: Report via GitHub issues
- **Security**: Email security issues to maintainer
- **Updates**: Check with `sudo ntfs-update-check manual`

## Links
- Repository: https://github.com/darrylbennett/ntfs-installer
- Phase 1 Audit: `NTFS-ENHANCEMENT-REPORT.md`
- User Guide: `docs/USER-GUIDE.md`
- Troubleshooting: `docs/TROUBLESHOOTING.md`

---

*Version 3.0.0 represents a major enhancement focused on security, automation, and user experience while maintaining full compatibility with existing installations.*
