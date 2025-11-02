# NTFS Manager - API Reference

Developer reference for NTFS Manager backend modules.

## Backend API

### DriveManager Class

**Location:** `backend/drive_manager.py`

```python
from backend import drive_manager

manager = drive_manager.DriveManager()
```

#### Methods

**list_drives()**
- Returns list of all detected drives
- Return type: `List[Dict]`
- Example:
```python
drives = manager.list_drives()
# [{'device': '/dev/sda1', 'label': 'Data', 'fstype': 'ntfs', ...}]
```

**mount_drive(device, mount_point, options)**
- Mounts a drive at specified location
- Parameters:
  - device (str): Device path (e.g., '/dev/sda1')
  - mount_point (str): Mount location
  - options (str): Mount options (optional)
- Returns: bool (success/failure)
- Raises: `PermissionError`, `IOError`

**unmount_drive(mount_point)**
- Unmounts a mounted drive
- Parameters:
  - mount_point (str): Mount location
- Returns: bool

**get_drive_info(device)**
- Retrieves detailed drive information
- Parameters:
  - device (str): Device path
- Returns: Dict with drive details

### NTFS Properties Class

**Location:** `backend/ntfs_properties.py`

```python
from backend import ntfs_properties

props = ntfs_properties.NTFSProperties(device='/dev/sda1')
```

#### Methods

**get_filesystem_info()**
-  Returns NTFS filesystem information  
- Return type: Dict

**check_health()**
- Performs health check
- Returns: Dict with health status

### Logger Class

**Location:** `backend/logger.py`

```python
from backend import logger

log = logger.NTFSLogger()
```

#### Methods

**log_operation(operation, details)**
- Logs drive operations
- Parameters:
  - operation (str): Operation name
  - details (Dict): Operation details

**log_error(error, traceback)**
- Logs errors with traceback
- Parameters:
  - error (str): Error message
  - traceback (str): Stack trace

## Related Documentation

- Installation: See INSTALLATION.md
- Usage: See USAGE.md
- Architecture: See ARCHITECTURE.md

---

## 👨‍💻 Developer Information

**Developer:** Darryl Bennett  
**Company:** MagDriveX (2023-2025)  
**ABN:** 82 977 519 307  
**Email:** sales@magdrivex.com.au / sales@magdrivex.com

**API Version:** 3.0.0  
**Last Updated:** November 2025

**Copyright © 2023-2025 Darryl Bennett / MagDriveX. All rights reserved.**
