# NTFS Manager - Architecture Documentation

Technical architecture and design documentation for NTFS Manager.

## 🏗️ System Architecture

### Overview

NTFS Manager follows a modular architecture with three main components:

```
┌─────────────────────────────────────────────┐
│         User Interface Layer                │
├─────────────────┬───────────────────────────┤
│  Nautilus       │   Standalone GUI          │
│  Extension      │   Application             │
└────────┬────────┴──────────┬────────────────┘
         │                   │
         └───────┬───────────┘
                 │
         ┌───────▼───────────┐
         │   Backend Layer   │
         ├───────────────────┤
         │ - Drive Manager   │
         │ - NTFS Properties │
         │ - Logger          │
         │ - GParted API     │
         └───────┬───────────┘
                 │
         ┌───────▼───────────┐
         │   System Layer    │
         ├───────────────────┤
         │ - ntfs-3g         │
         │ - udisks2         │
         │ - smartmontools   │
         │ - udev            │
         └───────────────────┘
```

## 📦 Component Details

### Backend Modules

#### 1. Drive Manager (`drive_manager.py`)

**Purpose:** Core drive detection and management

**Key Classes:**
- `DriveManager`: Main drive management class
- `Drive`: Represents a physical or logical drive
- `MountPoint`: Represents mount point information

**Key Methods:**
```python
class DriveManager:
    def list_drives() -> List[Drive]
    def mount_drive(device: str, mount_point: str) -> bool
    def unmount_drive(mount_point: str) -> bool
    def get_drive_info(device: str) -> Dict
    def format_drive(device: str, filesystem: str) -> bool
```

## 📚 Related Documentation

- Installation: See INSTALLATION.md
- Usage: See USAGE.md  
- Troubleshooting: See TROUBLESHOOTING.md

---

## 👨‍💻 Developer Information

**Developer:** Darryl Bennett  
**Company:** MagDriveX (2023-2025)  
**ABN:** 82 977 519 307  
**Email:** sales@magdrivex.com.au / sales@magdrivex.com

**Architecture Version:** 3.0.0  
**Last Updated:** November 2025

**Copyright © 2023-2025 Darryl Bennett / MagDriveX. All rights reserved.**
