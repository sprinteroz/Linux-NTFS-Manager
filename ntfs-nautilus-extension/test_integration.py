#!/usr/bin/env python3
"""
NTFS Manager Nautilus Extension Test Script
Tests the integration functionality without requiring full Nautilus environment
"""

import os
import sys
import subprocess
import tempfile
import time
from pathlib import Path

# Add backend modules to path
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
backend_path = os.path.join(project_root, 'ntfs-complete-manager-gui', 'backend')

if os.path.exists(backend_path):
    sys.path.insert(0, backend_path)

# Colors for output
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'  # No Color

def log_info(msg):
    print(f"{BLUE}[INFO]{NC} {msg}")

def log_success(msg):
    print(f"{GREEN}[SUCCESS]{NC} {msg}")

def log_warning(msg):
    print(f"{YELLOW}[WARNING]{NC} {msg}")

def log_error(msg):
    print(f"{RED}[ERROR]{NC} {msg}")

def test_dependencies():
    """Test if required dependencies are available"""
    log_info("Testing dependencies...")
    
    tests = []
    
    # Test Python GI bindings
    try:
        import gi
        gi.require_version('Gtk', '3.0')
        from gi.repository import Gtk
        tests.append(("GTK3", True, "GTK3 bindings available"))
    except (ImportError, ValueError) as e:
        tests.append(("GTK3", False, f"GTK3 bindings not available: {e}"))
    
    # Test Nautilus bindings
    try:
        gi.require_version('Nautilus', '3.0')
        from gi.repository import Nautilus
        tests.append(("Nautilus", True, "Nautilus bindings available"))
    except (ImportError, ValueError) as e:
        tests.append(("Nautilus", False, f"Nautilus bindings not available: {e}"))
    
    # Test backend modules
    try:
        from drive_manager import DriveManager
        tests.append(("DriveManager", True, "DriveManager backend available"))
    except ImportError as e:
        tests.append(("DriveManager", False, f"DriveManager backend not available: {e}"))
    
    try:
        from ntfs_properties import NTFSProperties
        tests.append(("NTFSProperties", True, "NTFSProperties backend available"))
    except ImportError as e:
        tests.append(("NTFSProperties", False, f"NTFSProperties backend not available: {e}"))
    
    try:
        from logger import get_logger
        tests.append(("Logger", True, "Logger backend available"))
    except ImportError as e:
        tests.append(("Logger", False, f"Logger backend not available: {e}"))
    
    # Display results
    all_passed = True
    for name, passed, message in tests:
        if passed:
            log_success(f"✓ {name}: {message}")
        else:
            log_error(f"✗ {name}: {message}")
            all_passed = False
    
    return all_passed

def test_system_tools():
    """Test if required system tools are available"""
    log_info("Testing system tools...")
    
    tools = [
        ('lsblk', 'Block device listing'),
        ('ntfs-3g', 'NTFS mount support'),
        ('ntfsck', 'NTFS filesystem check'),
        ('smartctl', 'SMART monitoring'),
        ('mount', 'Mount utility'),
        ('umount', 'Unmount utility'),
        ('eject', 'Eject utility'),
        ('notify-send', 'Desktop notifications')
    ]
    
    all_available = True
    for tool, description in tools:
        if subprocess.call(['which', tool], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0:
            log_success(f"✓ {tool}: {description}")
        else:
            log_warning(f"✗ {tool}: {description} - not available")
            if tool in ['ntfs-3g', 'ntfsck', 'smartctl']:
                all_available = False
    
    return all_available

def test_backend_functionality():
    """Test backend functionality"""
    log_info("Testing backend functionality...")
    
    try:
        from drive_manager import DriveManager
        from ntfs_properties import NTFSProperties
        from logger import get_logger
        
        # Test DriveManager
        dm = DriveManager()
        drives = dm.get_all_drives()
        log_success(f"✓ DriveManager: Found {len(drives)} drives")
        
        if drives:
            # Test getting properties for first drive
            first_drive = drives[0]
            props = dm.get_drive_properties(first_drive.name)
            log_success(f"✓ Properties: Retrieved for {first_drive.name}")
            
            # Test NTFS properties if it's an NTFS drive
            if first_drive.fstype == 'ntfs':
                device_path = f"/dev/{first_drive.name}"
                ntfs_props = NTFSProperties(device_path)
                all_props = ntfs_props.get_all_properties()
                log_success(f"✓ NTFS Properties: Retrieved for {first_drive.name}")
            else:
                log_info(f"ℹ Skipping NTFS properties test for {first_drive.name} (not NTFS)")
        
        # Test logger
        logger = get_logger()
        logger.info("Test log message")
        log_success("✓ Logger: Working correctly")
        
        return True
        
    except Exception as e:
        log_error(f"✗ Backend functionality test failed: {e}")
        return False

def test_extension_loading():
    """Test if extension can be loaded"""
    log_info("Testing extension loading...")
    
    try:
        # Try to import the extension
        extension_path = os.path.join(script_dir, 'ntfs_manager_extension.py')
        
        if not os.path.exists(extension_path):
            log_error(f"✗ Extension file not found: {extension_path}")
            return False
        
        # Read and compile the extension
        with open(extension_path, 'r') as f:
            extension_code = f.read()
        
        compile(extension_code, extension_path, 'exec')
        log_success("✓ Extension: Syntax is valid")
        
        # Try to execute the extension in a limited way
        namespace = {}
        exec(extension_code, namespace)
        
        if 'NTFSManagerExtension' in namespace:
            log_success("✓ Extension: Main class found")
        else:
            log_error("✗ Extension: Main class not found")
            return False
        
        return True
        
    except SyntaxError as e:
        log_error(f"✗ Extension: Syntax error: {e}")
        return False
    except Exception as e:
        log_error(f"✗ Extension: Load error: {e}")
        return False

def test_file_operations():
    """Test basic file operations"""
    log_info("Testing file operations...")
    
    try:
        # Create a temporary test file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write("NTFS Manager Extension Test")
            temp_file = f.name
        
        log_success(f"✓ File operations: Created test file")
        
        # Test reading
        with open(temp_file, 'r') as f:
            content = f.read()
        
        if content == "NTFS Manager Extension Test":
            log_success("✓ File operations: Read test successful")
        else:
            log_error("✗ File operations: Read test failed")
            return False
        
        # Clean up
        os.unlink(temp_file)
        log_success("✓ File operations: Cleanup successful")
        
        return True
        
    except Exception as e:
        log_error(f"✗ File operations test failed: {e}")
        return False

def test_permissions():
    """Test user permissions"""
    log_info("Testing user permissions...")
    
    # Check if user is in relevant groups
    try:
        result = subprocess.run(['groups'], capture_output=True, text=True)
        groups = result.stdout.strip().split()
        
        required_groups = ['disk', 'plugdev']
        missing_groups = [g for g in required_groups if g not in groups]
        
        if missing_groups:
            log_warning(f"⚠ Permissions: Not in groups: {', '.join(missing_groups)}")
            log_info("  Some operations may require sudo or group membership")
        else:
            log_success("✓ Permissions: In required groups")
        
        # Test if we can read block devices
        if os.access('/dev/', os.R_OK):
            log_success("✓ Permissions: Can read /dev/")
        else:
            log_warning("⚠ Permissions: Cannot read /dev/ (may need sudo)")
        
        return True
        
    except Exception as e:
        log_error(f"✗ Permission test failed: {e}")
        return False

def run_integration_tests():
    """Run all integration tests"""
    print("=" * 60)
    print("NTFS Manager Nautilus Extension Integration Tests")
    print("=" * 60)
    print()
    
    tests = [
        ("Dependencies", test_dependencies),
        ("System Tools", test_system_tools),
        ("Backend Functionality", test_backend_functionality),
        ("Extension Loading", test_extension_loading),
        ("File Operations", test_file_operations),
        ("Permissions", test_permissions)
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\n--- {test_name} ---")
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            log_error(f"Test {test_name} crashed: {e}")
            results.append((test_name, False))
    
    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    
    passed = 0
    total = len(results)
    
    for test_name, result in results:
        status = "PASS" if result else "FAIL"
        color = GREEN if result else RED
        print(f"{color}{test_name:<25} {status}{NC}")
        if result:
            passed += 1
    
    print(f"\nOverall: {passed}/{total} tests passed")
    
    if passed == total:
        log_success("🎉 All tests passed! Extension should work correctly.")
        print("\nNext steps:")
        print("1. Run ./install.sh to install the extension")
        print("2. Restart Nautilus: nautilus -q && nautilus --no-default-window &")
        print("3. Right-click on drives in Nautilus to test functionality")
    else:
        log_warning(f"⚠ {total - passed} test(s) failed. Check dependencies and configuration.")
        print("\nTroubleshooting:")
        print("1. Install missing dependencies: sudo apt install python3-nautilus ntfs-3g")
        print("2. Ensure backend modules are available")
        print("3. Check user permissions for disk access")
        print("4. Review test output above for specific issues")

if __name__ == "__main__":
    run_integration_tests()
