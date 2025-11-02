# NTFS Complete Manager v2.0

A comprehensive GTK3-based GUI application for NTFS drive management on Linux systems.

## Features

### Core Functionality
- **Drive Detection**: Automatically detects all connected drives (USB, SATA, NVMe)
- **Real-time Monitoring**: Hot-swap support with automatic drive event notifications
- **Mount/Unmount**: Safe mount and unmount operations with proper error handling
- **Format Support**: NTFS, EXT4, FAT32 filesystem formatting
- **Drive Repair**: Automatic filesystem repair using integrated repair scripts
- **Safe Eject**: Proper unmount and eject sequence for removable drives

### NTFS-Specific Features
- **Windows-style Properties**: Comprehensive NTFS volume information display
- **Health Monitoring**: SMART status, dirty bit detection, bad sector tracking
- **Security Info**: ACL permissions, ownership, encryption status
- **Volume Details**: Cluster size, usage statistics, timestamps

### Advanced Features
- **Comprehensive Logging**: Structured logging with JSON export capability
- **Drive Events**: Real-time callbacks for drive connection/disconnection
- **Health Checks**: Integrated SMART and filesystem health monitoring
- **System Integration**: .desktop file with system menu integration

## Installation

### Prerequisites
```bash
# Install required system packages
sudo apt update
sudo apt install python3-gi python3-gtk3 python3-psutil \
    ntfs-3g ntfsprogs smartmontools util-linux \
    e2fsprogs dosfstools

# Install Python dependencies
pip3 install -r requirements.txt
```

### Setup
```bash
# Clone or extract the application
cd ntfs-complete-manager-gui

# Install system integration (optional)
sudo cp ntfs-manager.desktop /usr/share/applications/
sudo cp main.py /usr/local/bin/ntfs-manager
sudo chmod +x /usr/local/bin/ntfs-manager

# Run the application
python3 main.py
```

## Usage

### Basic Operations
1. **View Drives**: Launch the application to see all detected drives
2. **Select Drive**: Click on a drive in the list to view details
3. **Mount/Unmount**: Use the action buttons for mount operations
4. **Format**: Select a drive and click Format (with confirmation)
5. **Repair**: Automatic filesystem repair with progress feedback

### Advanced Features
- **Properties Dialog**: Right-click or use Advanced Properties button
- **Health Monitoring**: View SMART status and drive health
- **NTFS Details**: Comprehensive NTFS volume information
- **Log Viewing**: Access detailed operation logs

## Backend Integration

The application integrates with existing NTFS management tools:

### Drive Management Scripts
- `modules/08-drive-management/core/udev-monitor.sh` - Drive event monitoring
- `modules/08-drive-management/core/auto-repair.sh` - Automatic repair functionality

### System Tools Used
- `lsblk` - Drive detection and information
- `ntfsinfo` - NTFS volume details
- `ntfsck` - NTFS filesystem checking
- `smartctl` - SMART health monitoring
- `mount/umount` - Mount operations
- `eject` - Safe drive ejection

## Configuration

### Logging Configuration
Logs are stored in `/var/log/ntfs-manager/`:
- `main.log` - General application logs
- `operations.log` - Drive operation history
- `errors.log` - Error and warning messages
- `security.log` - Security-related events
- `structured.json` - Machine-readable JSON logs

### Customization
Edit the configuration in `backend/logger.py`:
- Log levels and destinations
- Rotation policies
- Output formats

## Security Features

### Safe Operations
- **Mount Protection**: Prevents mounting of system partitions
- **Format Confirmation**: Multiple confirmation dialogs for destructive operations
- **Permission Checks**: Verifies user permissions for operations
- **Audit Logging**: All operations logged with user context

### Data Protection
- **Backup Creation**: Automatic backups before format operations
- **Dirty Bit Handling**: Safe NTFS dirty bit management
- **Error Recovery**: Rollback capabilities for failed operations

## Troubleshooting

### Common Issues

#### Application Won't Start
```bash
# Check Python GTK bindings
python3 -c "import gi; gi.require_version('Gtk', '3.0'); print('GTK OK')"

# Check backend modules
python3 -c "import sys; sys.path.insert(0, 'backend'); import drive_manager; print('Backend OK')"
```

#### Drive Not Detected
```bash
# Check lsblk output
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL

# Check udev rules
sudo udevadm monitor
```

#### Mount Operations Fail
```bash
# Check ntfs-3g installation
which ntfs-3g

# Check mount points
findmnt -l

# Check system permissions
groups | grep disk
```

### Debug Mode
Enable debug logging:
```bash
# Set debug environment variable
export NTFS_MANAGER_DEBUG=1
python3 main.py
```

## Development

### Project Structure
```
ntfs-complete-manager-gui/
├── main.py                 # Main GUI application
├── backend/                 # Backend modules
│   ├── drive_manager.py     # Drive detection and management
│   ├── ntfs_properties.py  # NTFS-specific properties
│   └── logger.py           # Comprehensive logging
├── frontend/               # Frontend components (future)
├── resources/              # Icons and resources
├── services/               # System services
├── tests/                  # Test suite
├── docs/                   # Documentation
├── ntfs-manager.desktop     # Desktop integration
└── README.md               # This file
```

### Adding New Features
1. **Backend Modules**: Add to `backend/` directory
2. **GUI Components**: Extend main.py with new dialogs
3. **System Integration**: Update .desktop file and services
4. **Testing**: Add tests to `tests/` directory

### Code Style
- Python 3.8+ compatibility
- GTK3 for GUI components
- Type hints for all functions
- Comprehensive error handling
- Structured logging throughout

## License

This project integrates several open-source components:
- GTK3 - LGPL
- NTFS-3G - GPL
- Smartmontools - GPL
- Various system utilities - GPL/LGPL

See individual component licenses for details.

## Contributing

### Development Setup
```bash
# Install development dependencies
pip3 install -r requirements-dev.txt

# Run tests
python3 -m pytest tests/

# Code formatting
black --line-length 100 backend/
flake8 backend/
```

### Pull Requests
1. Fork the repository
2. Create feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit pull request with description

## Support

### Documentation
- **User Guide**: See `docs/user-guide.md`
- **API Reference**: See `docs/api-reference.md`
- **Troubleshooting**: See `docs/troubleshooting.md`

### Community
- **Issues**: Report bugs via GitHub Issues
- **Features**: Request features via GitHub Discussions
- **Patches**: Submit pull requests for improvements

## Version History

### v2.0 (Current)
- Complete GTK3 GUI rewrite
- Backend module system
- Comprehensive NTFS properties
- Real-time drive monitoring
- Structured logging system
- System integration

### v1.0 (Legacy)
- Basic drive management
- Simple mount/unmount operations
- Limited NTFS support

## System Requirements

### Minimum Requirements
- **OS**: Ubuntu 18.04+ / Debian 10+
- **Python**: 3.8 or higher
- **GTK**: 3.20 or higher
- **Memory**: 512MB RAM
- **Storage**: 50MB free space

### Recommended Requirements
- **OS**: Ubuntu 20.04+ / Debian 11+
- **Python**: 3.10 or higher
- **GTK**: 3.24 or higher
- **Memory**: 1GB RAM
- **Storage**: 100MB free space

### Optional Dependencies
- **GParted**: For advanced partitioning (gparted package)
- **HDDtemp**: For temperature monitoring (hddtemp package)
- **Notify-OSD**: For desktop notifications (libnotify-bin package)

## Performance

### Optimization Features
- **Async Operations**: Non-blocking drive operations
- **Caching**: Drive information caching
- **Lazy Loading**: On-demand property loading
- **Memory Management**: Efficient data structures

### Benchmarks
- **Startup Time**: < 2 seconds on typical systems
- **Drive Detection**: < 1 second for refresh
- **Memory Usage**: < 50MB typical usage
- **CPU Usage**: < 5% during operations

---

**NTFS Complete Manager** - Professional NTFS drive management for Linux systems
