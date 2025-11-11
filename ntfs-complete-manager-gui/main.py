#!/usr/bin/env python3
"""
NTFS Complete Manager - GUI Application
A comprehensive NTFS drive management tool with GTK3 interface
"""

import gi
gi.require_version('Gtk', '3.0')
import sys
import os
import threading
import time
import fcntl
from pathlib import Path

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'backend'))

from gi.repository import Gtk, Gio, GLib, GdkPixbuf
import subprocess
import threading
import time
from pathlib import Path

# Import backend modules with error handling
try:
    from drive_manager import DriveManager, DriveInfo
    from ntfs_properties import NTFSProperties
    from gparted_integration import GPartedManager
    from logger import get_logger
except ImportError as e:
    print(f"Warning: Could not import backend modules: {e}")
    print("Some features may not be available")
    # Create dummy classes for fallback
    class DriveManager:
        def __init__(self): pass
        def get_all_drives(self): return []
        def refresh_drives(self): return []
        def get_drive_properties(self, drive): return {}
        def mount_drive(self, drive): return False
        def unmount_drive(self, drive): return False
        def format_drive(self, drive, fstype, label): return False
        def repair_drive(self, drive): return False
        def add_callback(self, callback): pass
        def start_monitoring(self): pass
        def stop_monitoring(self): pass
    
    class DriveInfo:
        def __init__(self, name="", size="", fstype="", mountpoint="", label="", model="", vendor="", serial="", uuid="", is_removable=False, is_rotational=False, health_status="Unknown", temperature=0.0, smart_status="Unknown"):
            for key, value in locals().items():
                setattr(self, key, value)
    
    class NTFSProperties:
        def __init__(self, device_path): pass
        def get_windows_style_properties(self): return ""
        def get_all_properties(self): return {}
        def run_disk_check(self): return {"timestamp": "", "overall_status": "Unknown", "checks": {}}
    
    class GPartedManager:
        def __init__(self): pass
        def is_available(self): return False
        def get_device_list(self): return []
        def create_partition(self, *args, **kwargs): return False
        def delete_partition(self, *args, **kwargs): return False
        def format_partition(self, *args, **kwargs): return False
        def resize_partition(self, *args, **kwargs): return False
        def set_partition_flag(self, *args, **kwargs): return False
        def get_partition_info(self, *args, **kwargs): return None
        def apply_changes(self, *args, **kwargs): return False
    
    class NTFSLogger:
        def __init__(self, name="ntfs_manager"): pass
        def info(self, msg): pass
        def debug(self, msg): pass
        def error(self, msg): pass
        def operation(self, op, device, status, details=None): pass
        def security_event(self, event_type, user, device, action, details=None): pass
        def audit_event(self, action, user, device, result, details=None): pass
        def drive_event(self, event_type, drive_info): pass
        def get_recent_logs(self, log_type="main", lines=100): return []
        def get_operation_history(self, device=None, limit=50): return []
        def get_error_summary(self, hours=24): return {"total_errors": 0, "error_types": {}, "recent_errors": []}
        def export_logs(self, output_file, format_type="json", start_date=None, end_date=None): return False
        def cleanup_old_logs(self, days=30): pass
        def get_log_stats(self): return {"log_directory": "/var/log/ntfs-manager", "total_log_files": 0, "total_size_mb": 0, "log_files": {}}
    
    def get_logger(name="ntfs_manager"):
        return NTFSLogger()

from gi.repository import Gtk, Gio, GLib, GdkPixbuf

class NTFSManager:
    def __init__(self):
        super().__init__()
        self.drive_manager = DriveManager()
        self.logger = get_logger()
        self.selected_drive = None
        self.drive_list_store = None
        
        # Cache for drive list to avoid unnecessary refreshes
        self.drive_cache = {}
        self.last_refresh_time = 0
        self.refresh_cooldown = 1.0  # Debounce: min 1 second between refreshes
        
        # Cache for NTFS properties to avoid expensive re-queries
        self.ntfs_properties_cache = {}  # {device_path: {'properties': NTFSProperties, 'timestamp': float}}
        self.ntfs_cache_ttl = 60.0  # 60 second TTL for NTFS properties
        
        # Tool availability - check which external tools are available
        self.available_tools = self.check_tool_availability()
        
        # Setup drive event callbacks
        self.drive_manager.add_callback(self.on_drive_event)
        
        self.setup_ui()
        self.refresh_drives()
        
        # Auto-mount internal NTFS drives on startup
        self.auto_mount_internal_drives()
        
        # Start drive monitoring
        self.drive_manager.start_monitoring()
    
    def check_tool_availability(self):
        """Check which external tools are available on the system"""
        tools = {
            'ntfsfix': False,
            'mkfs.ntfs': False,
            'gparted': False,
            'dd': False,
            'eject': False,
            'lsof': False,
            'fuser': False
        }
        
        for tool in tools.keys():
            try:
                result = subprocess.run(['which', tool], capture_output=True, text=True)
                tools[tool] = (result.returncode == 0)
                if tools[tool]:
                    self.logger.debug(f"Tool available: {tool}")
                else:
                    self.logger.debug(f"Tool missing: {tool}")
            except Exception as e:
                self.logger.debug(f"Error checking {tool}: {e}")
                tools[tool] = False
        
        return tools
    
    def validate_filesystem_label(self, label: str, fstype: str) -> tuple[bool, str]:
        """Validate filesystem label according to filesystem rules
        
        Returns: (is_valid, error_message)
        """
        if not label:
            return True, ""  # Empty label is valid
        
        # Common restrictions
        if len(label) > 255:
            return False, "Label too long (max 255 characters)"
        
        # Filesystem-specific rules
        if fstype == 'ntfs':
            # NTFS allows most characters but has length limit of 32
            if len(label) > 32:
                return False, "NTFS label too long (max 32 characters)"
            # No path separators
            if '/' in label or '\\' in label:
                return False, "NTFS label cannot contain / or \\"
        elif fstype == 'fat32':
            # FAT32 is more restrictive
            if len(label) > 11:
                return False, "FAT32 label too long (max 11 characters)"
            # No special characters
            invalid_chars = ['/', '\\', '*', '?', '"', '<', '>', '|', '+', ',', ';', '=', '[', ']']
            for char in invalid_chars:
                if char in label:
                    return False, f"FAT32 label cannot contain: {', '.join(invalid_chars)}"
        elif fstype == 'ext4':
            # EXT4 allows most characters
            if len(label) > 16:
                return False, "EXT4 label too long (max 16 characters)"
        
        return True, ""
    
    def validate_iso_file(self, iso_path: str) -> tuple[bool, str]:
        """Validate ISO file path and properties
        
        Returns: (is_valid, error_message)
        """
        # Check if path is provided
        if not iso_path or not iso_path.strip():
            return False, "No ISO file selected"
        
        # Sanitize path
        iso_path = os.path.abspath(os.path.expanduser(iso_path.strip()))
        
        # Check if file exists
        if not os.path.exists(iso_path):
            return False, f"File not found: {iso_path}"
        
        # Check if it's a file (not directory)
        if not os.path.isfile(iso_path):
            return False, f"Not a file: {iso_path}"
        
        # Check if file is readable
        if not os.access(iso_path, os.R_OK):
            return False, f"File is not readable: {iso_path}"
        
        # Check file extension
        if not iso_path.lower().endswith('.iso'):
            return False, "File must have .iso extension"
        
        # Check file size (should be reasonable, at least 1MB, max 100GB)
        try:
            file_size = os.path.getsize(iso_path)
            if file_size < 1024 * 1024:  # 1MB
                return False, "ISO file too small (less than 1MB - likely corrupt)"
            if file_size > 100 * 1024 * 1024 * 1024:  # 100GB
                return False, "ISO file too large (over 100GB - check file)"
        except Exception as e:
            return False, f"Cannot read file size: {e}"
        
        return True, ""
    
    def sanitize_device_path(self, device_name: str) -> tuple[bool, str]:
        """Sanitize and validate device path to prevent injection
        
        Returns: (is_valid, sanitized_path)
        """
        if not device_name:
            return False, ""
        
        # Remove any path components - device name should be simple
        device_name = os.path.basename(device_name)
        
        # Validate device name format (sda, sda1, nvme0n1p1, etc.)
        import re
        # Pattern: sd[a-z], sd[a-z][0-9]+, nvme[0-9]+n[0-9]+, nvme[0-9]+n[0-9]+p[0-9]+
        valid_patterns = [
            r'^sd[a-z]$',                    # sda, sdb
            r'^sd[a-z][0-9]+$',              # sda1, sdb2
            r'^nvme[0-9]+n[0-9]+$',          # nvme0n1
            r'^nvme[0-9]+n[0-9]+p[0-9]+$',  # nvme0n1p1
            r'^mmcblk[0-9]+$',               # mmcblk0
            r'^mmcblk[0-9]+p[0-9]+$',       # mmcblk0p1
        ]
        
        is_valid = any(re.match(pattern, device_name) for pattern in valid_patterns)
        
        if not is_valid:
            return False, ""
        
        return True, f"/dev/{device_name}"
    
    def check_device_busy(self, device_path: str) -> tuple[bool, list]:
        """Check if device is busy (has open file handles)
        
        Returns: (is_busy, list_of_processes)
        """
        processes = []
        
        # Try lsof first
        if self.available_tools.get('lsof'):
            try:
                result = subprocess.run(['lsof', device_path], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0 and result.stdout.strip():
                    # Parse lsof output to get process names
                    for line in result.stdout.split('\n')[1:]:  # Skip header
                        if line.strip():
                            parts = line.split()
                            if len(parts) >= 2:
                                processes.append(parts[0])  # Command name
                    return True, processes
            except Exception as e:
                self.logger.debug(f"lsof check failed: {e}")
        
        # Try fuser as fallback
        if self.available_tools.get('fuser'):
            try:
                result = subprocess.run(['fuser', device_path], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0 and result.stdout.strip():
                    return True, ['unknown process']
            except Exception as e:
                self.logger.debug(f"fuser check failed: {e}")
        
        return False, []
    
    def retry_operation(self, operation_func, max_retries=3, delay=1.0):
        """Retry an operation with exponential backoff
        
        Args:
            operation_func: Function to retry (should return bool success)
            max_retries: Maximum number of retry attempts
            delay: Initial delay between retries (doubles each time)
        
        Returns: (success, error_message)
        """
        for attempt in range(max_retries):
            try:
                success = operation_func()
                if success:
                    return True, ""
                
                # Operation failed, check if we should retry
                if attempt < max_retries - 1:
                    wait_time = delay * (2 ** attempt)  # Exponential backoff
                    self.logger.debug(f"Retry attempt {attempt + 1}/{max_retries}, waiting {wait_time}s")
                    time.sleep(wait_time)
                else:
                    return False, "Operation failed after maximum retries"
                    
            except Exception as e:
                if attempt < max_retries - 1:
                    wait_time = delay * (2 ** attempt)
                    self.logger.debug(f"Exception on attempt {attempt + 1}: {e}, retrying in {wait_time}s")
                    time.sleep(wait_time)
                else:
                    return False, f"Operation failed: {str(e)}"
        
        return False, "Operation failed"
    
    def auto_mount_internal_drives(self):
        """Auto-mount internal NTFS drives on startup"""
        try:
            mounted_count = 0
            for drive_name, drive_info in self.drive_manager.drives.items():
                # Mount internal NTFS drives that aren't already mounted
                # Include sda1, sdb1, nvme1n1p1 but skip nvme0n1p (system disk)
                if (not drive_info.mountpoint and 
                    drive_info.fstype == "ntfs" and 
                    not drive_info.is_removable and
                    not drive_name.startswith("nvme0n1p")):
                    
                    print(f"DEBUG: Attempting to auto-mount {drive_name}")
                    self.logger.info(f"Auto-mounting internal NTFS drive: {drive_name}")
                    success = self.drive_manager.mount_drive(drive_name)
                    if success:
                        mounted_count += 1
                        print(f"DEBUG: Successfully mounted {drive_name}")
                        self.update_status(f"Auto-mounted {drive_name}")
                    else:
                        print(f"DEBUG: Failed to mount {drive_name}")
                        self.logger.error(f"Failed to auto-mount {drive_name}")
                        
            # Refresh drive list to show mounted drives
            if mounted_count > 0:
                self.refresh_drives()
                self.update_status(f"Auto-mounted {mounted_count} internal NTFS drive(s)")
        except Exception as e:
            print(f"DEBUG: Auto-mount error: {e}")
            self.logger.error(f"Error in auto-mount: {e}")
    
    def setup_ui(self):
        # Create main window
        self.window = Gtk.Window(title="NTFS Complete Manager v2.0")
        self.window.set_default_size(1000, 700)
        self.window.set_border_width(10)
        
        # Create main container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        
        # Add menu bar
        menubar = self.create_menu_bar()
        main_box.pack_start(menubar, False, False, 0)
        
        # Add header with title and refresh button
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        title_label = Gtk.Label(label="NTFS Complete Manager v2.0")
        title_label.get_style_context().add_class("title")
        
        refresh_btn = Gtk.Button(label="Refresh")
        refresh_btn.connect("clicked", self.on_refresh_clicked)
        refresh_btn.set_tooltip_text("Refresh drive list (Ctrl+R or F5)")
        
        header_box.pack_start(title_label, True, True, 0)
        header_box.pack_start(refresh_btn, False, False, 0)
        main_box.pack_start(header_box, False, False, 0)
        
        # Create paned view for drives and details
        paned = Gtk.HPaned()
        paned.set_position(400)
        
        # Left side - Drive list
        left_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        
        drives_frame = Gtk.Frame(label="Detected Drives")
        drives_scrolled = Gtk.ScrolledWindow()
        drives_scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        drives_scrolled.set_min_content_width(350)
        drives_scrolled.set_min_content_height(400)
        
        # Create TreeView for drives
        self.create_drive_list()
        drives_scrolled.add(self.drive_treeview)
        drives_frame.add(drives_scrolled)
        left_box.pack_start(drives_frame, True, True, 5)
        
        # Action buttons for drives
        action_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        
        # Store button references for spinner management
        self.mount_btn = Gtk.Button(label="Mount")
        self.mount_btn.connect("clicked", self.on_mount_clicked)
        self.mount_btn.set_tooltip_text("Mount the selected drive to access its contents")
        
        self.unmount_btn = Gtk.Button(label="Unmount")
        self.unmount_btn.connect("clicked", self.on_unmount_clicked)
        self.unmount_btn.set_tooltip_text("Safely unmount the selected drive")
        
        self.repair_btn = Gtk.Button(label="Repair")
        self.repair_btn.connect("clicked", self.on_repair_clicked)
        self.repair_btn.set_tooltip_text("Check and repair filesystem errors")
        
        self.format_btn = Gtk.Button(label="Format")
        self.format_btn.connect("clicked", self.on_format_clicked)
        self.format_btn.set_tooltip_text("Format drive (WARNING: Erases all data)")
        
        self.burn_iso_btn = Gtk.Button(label="Burn ISO")
        self.burn_iso_btn.connect("clicked", self.on_burn_iso_clicked)
        self.burn_iso_btn.set_tooltip_text("Create a bootable USB drive from ISO file")
        
        self.eject_btn = Gtk.Button(label="Safe Eject")
        self.eject_btn.connect("clicked", self.on_eject_clicked)
        self.eject_btn.set_tooltip_text("Safely eject removable drive")
        
        action_box.pack_start(self.mount_btn, False, False, 2)
        action_box.pack_start(self.unmount_btn, False, False, 2)
        action_box.pack_start(self.repair_btn, False, False, 2)
        action_box.pack_start(self.format_btn, False, False, 2)
        action_box.pack_start(self.burn_iso_btn, False, False, 2)
        action_box.pack_start(self.eject_btn, False, False, 2)
        
        left_box.pack_start(action_box, False, False, 5)
        paned.pack1(left_box, False, False)
        
        # Right side - Drive details
        right_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        
        details_frame = Gtk.Frame(label="Drive Details")
        details_scrolled = Gtk.ScrolledWindow()
        details_scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        
        self.details_text = Gtk.TextView()
        self.details_text.set_editable(False)
        self.details_text.set_wrap_mode(Gtk.WrapMode.WORD)
        details_scrolled.add(self.details_text)
        details_frame.add(details_scrolled)
        right_box.pack_start(details_frame, True, True, 5)
        
        # Properties button
        self.properties_btn = Gtk.Button(label="Advanced Properties")
        self.properties_btn.connect("clicked", self.on_properties_clicked)
        self.properties_btn.set_tooltip_text("View detailed drive properties and health information")
        right_box.pack_start(self.properties_btn, False, False, 5)
        
        paned.pack2(right_box, True, False)
        main_box.pack_start(paned, True, True, 10)
        
        # Add status bar
        self.status_bar = Gtk.Statusbar()
        status_context = self.status_bar.get_context_id("status")
        self.status_bar.push(status_context, "Ready")
        main_box.pack_start(self.status_bar, False, False, 0)
        
        # Add main window content
        self.window.add(main_box)
        
        # Connect events
        self.window.connect("destroy", self.on_destroy)
        self.window.connect("key-press-event", self.on_key_press)
        self.drive_treeview.get_selection().connect("changed", self.on_drive_selection_changed)
        
        # Show all widgets
        self.window.show_all()
        
        self.logger.info("NTFS Manager GUI started")
    
    def create_menu_bar(self):
        """Create the menu bar with Help menu"""
        menubar = Gtk.MenuBar()
        
        # Create Help menu
        help_menu = Gtk.Menu()
        help_item = Gtk.MenuItem(label="Help")
        help_item.set_submenu(help_menu)
        
        # About menu item
        about_item = Gtk.MenuItem(label="About NTFS Manager")
        about_item.connect("activate", lambda w: self.show_about_dialog())
        help_menu.append(about_item)
        
        # Report Issue menu item
        report_item = Gtk.MenuItem(label="Report Issue")
        report_item.connect("activate", lambda w: self.open_url("https://github.com/sprinteroz/Linux-NTFS-Manager/issues"))
        help_menu.append(report_item)
        
        # Community Discussions menu item
        discuss_item = Gtk.MenuItem(label="Community Discussions")
        discuss_item.connect("activate", lambda w: self.open_url("https://github.com/sprinteroz/Linux-NTFS-Manager/discussions"))
        help_menu.append(discuss_item)
        
        # Separator
        help_menu.append(Gtk.SeparatorMenuItem())
        
        # View on GitHub menu item
        github_item = Gtk.MenuItem(label="View on GitHub")
        github_item.connect("activate", lambda w: self.open_url("https://github.com/sprinteroz/Linux-NTFS-Manager"))
        help_menu.append(github_item)
        
        menubar.append(help_item)
        
        return menubar
    
    def open_url(self, url):
        """Open URL in default browser"""
        import webbrowser
        try:
            webbrowser.open(url)
            self.update_status(f"Opening {url}...")
            self.logger.info(f"Opened URL: {url}")
        except Exception as e:
            self.show_error_dialog("Error", f"Could not open URL: {e}")
            self.logger.error(f"Error opening URL {url}: {e}")
    
    def show_about_dialog(self):
        """Show About dialog with version, links, and license info"""
        # Read version from VERSION file
        version = "1.0.11"  # Default
        try:
            version_file = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "VERSION")
            if os.path.exists(version_file):
                with open(version_file, 'r') as f:
                    version = f.read().strip()
        except Exception as e:
            self.logger.debug(f"Could not read VERSION file: {e}")
        
        # Create About dialog using Gtk.AboutDialog
        about = Gtk.AboutDialog(transient_for=self.window, modal=True)
        
        # Set program information
        about.set_program_name("NTFS Complete Manager")
        about.set_version(f"v{version}")
        about.set_copyright("© 2023-2025 MagDriveX")
        about.set_comments("Professional NTFS Drive Management for Linux\n\n"
                          "✅ FREE for personal use\n"
                          "💼 Commercial license required for business")
        
        # Set logo if available
        try:
            icon_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icons", "ntfs-manager-256.png")
            if os.path.exists(icon_path):
                logo = GdkPixbuf.Pixbuf.new_from_file(icon_path)
                about.set_logo(logo)
        except Exception as e:
            self.logger.debug(f"Could not load logo: {e}")
        
        # Set website
        about.set_website("https://github.com/sprinteroz/Linux-NTFS-Manager")
        about.set_website_label("View on GitHub")
        
        # Set license text
        license_text = ("DUAL LICENSE: Personal & Commercial\n\n"
                       "This software is FREE for personal, non-commercial use.\n\n"
                       "FREE Personal License:\n"
                       "• Home/personal computing\n"
                       "• Educational purposes\n"
                       "• Non-profit activities\n\n"
                       "Commercial License Required:\n"
                       "• Business/workplace use\n"
                       "• Revenue-generating activities\n"
                       "• Organizational deployment\n\n"
                       "For commercial licensing:\n"
                       "Email: support_ntfs@magdrivex.com.au\n\n"
                       "See LICENSE-PERSONAL and LICENSE-COMMERCIAL files for full terms.")
        about.set_license(license_text)
        about.set_wrap_license(True)
        
        # Add authors
        about.set_authors(["MagDriveX Team"])
        
        # Add documenters (optional)
        about.set_documenters(["See GitHub contributors"])
        
        # Show dialog and wait for response
        about.run()
        about.destroy()
        
        self.logger.info("About dialog shown")
    
    def create_drive_list(self):
        """Create the drive list TreeView"""
        self.drive_list_store = Gtk.ListStore(str, str, str, str, str, str)  # Name, Size, FSType, MountPoint, Label, Status
        
        self.drive_treeview = Gtk.TreeView(model=self.drive_list_store)
        self.drive_treeview.set_headers_visible(True)
        
        # Create columns
        renderer = Gtk.CellRendererText()
        
        # Device column
        column = Gtk.TreeViewColumn("Device", renderer, text=0)
        column.set_sort_column_id(0)
        column.set_resizable(True)
        self.drive_treeview.append_column(column)
        
        # Size column
        column = Gtk.TreeViewColumn("Size", renderer, text=1)
        column.set_sort_column_id(1)
        column.set_resizable(True)
        self.drive_treeview.append_column(column)
        
        # Filesystem column
        column = Gtk.TreeViewColumn("Filesystem", renderer, text=2)
        column.set_sort_column_id(2)
        column.set_resizable(True)
        self.drive_treeview.append_column(column)
        
        # Mount point column
        column = Gtk.TreeViewColumn("Mount Point", renderer, text=3)
        column.set_sort_column_id(3)
        column.set_resizable(True)
        self.drive_treeview.append_column(column)
        
        # Label column
        column = Gtk.TreeViewColumn("Label", renderer, text=4)
        column.set_sort_column_id(4)
        column.set_resizable(True)
        self.drive_treeview.append_column(column)
        
        # Status column
        column = Gtk.TreeViewColumn("Status", renderer, text=5)
        column.set_sort_column_id(5)
        column.set_resizable(True)
        self.drive_treeview.append_column(column)
    
    def on_drive_selection_changed(self, selection):
        """Handle drive selection change"""
        model, treeiter = selection.get_selected()
        if treeiter is not None:
            drive_name = model[treeiter][0]
            self.selected_drive = drive_name
            self.update_drive_details(drive_name)
            self.logger.debug(f"Selected drive: {drive_name}")
        else:
            self.selected_drive = None
            self.clear_drive_details()
    
    def update_drive_details(self, drive_name):
        """Update the drive details panel with caching for NTFS properties"""
        if not drive_name:
            return
        
        try:
            # Get drive properties
            properties = self.drive_manager.get_drive_properties(drive_name)
            
            # Check if we got valid properties
            if not properties:
                buffer = self.details_text.get_buffer()
                buffer.set_text(f"Drive {drive_name} - No properties available")
                return
            
            # Get NTFS-specific properties if it's an NTFS drive
            if properties.get('fstype') == 'ntfs':
                device_path = f"/dev/{drive_name}"
                current_time = time.time()
                
                # Check cache first
                cache_entry = self.ntfs_properties_cache.get(device_path)
                if cache_entry:
                    # Check if cache is still valid (within TTL)
                    cache_age = current_time - cache_entry['timestamp']
                    if cache_age < self.ntfs_cache_ttl:
                        # Cache hit - use cached properties
                        self.logger.debug(f"NTFS properties cache hit for {drive_name} (age: {cache_age:.1f}s)")
                        ntfs_props = cache_entry['properties']
                        try:
                            ntfs_details = ntfs_props.get_windows_style_properties()
                            details_text = f"NTFS Properties for {drive_name}:\n\n{ntfs_details}"
                        except Exception as ntfs_error:
                            # Cache entry might be stale, remove it and fallback
                            self.logger.debug(f"Cached NTFS properties failed, removing cache entry")
                            del self.ntfs_properties_cache[device_path]
                            details_text = self.format_basic_properties(drive_name, properties)
                    else:
                        # Cache expired - remove and query fresh
                        self.logger.debug(f"NTFS properties cache expired for {drive_name} (age: {cache_age:.1f}s)")
                        del self.ntfs_properties_cache[device_path]
                        cache_entry = None
                
                # Cache miss or expired - query fresh NTFS properties
                if not cache_entry or cache_age >= self.ntfs_cache_ttl:
                    try:
                        self.logger.debug(f"NTFS properties cache miss for {drive_name}, querying fresh data")
                        ntfs_props = NTFSProperties(device_path)
                        
                        # Store in cache
                        self.ntfs_properties_cache[device_path] = {
                            'properties': ntfs_props,
                            'timestamp': current_time
                        }
                        self.logger.debug(f"Cached NTFS properties for {drive_name}")
                        
                        ntfs_details = ntfs_props.get_windows_style_properties()
                        details_text = f"NTFS Properties for {drive_name}:\n\n{ntfs_details}"
                    except Exception as ntfs_error:
                        # Fallback to basic properties if NTFS check fails
                        self.logger.debug(f"NTFS properties query failed: {ntfs_error}")
                        details_text = self.format_basic_properties(drive_name, properties)
            else:
                # Basic properties for non-NTFS drives
                details_text = self.format_basic_properties(drive_name, properties)
            
            # Update the text view
            buffer = self.details_text.get_buffer()
            buffer.set_text(details_text)
            
        except Exception as e:
            self.logger.error(f"Error updating drive details for {drive_name}: {e}")
            buffer = self.details_text.get_buffer()
            buffer.set_text(f"Select a drive to view details")
    
    def format_basic_properties(self, drive_name: str, properties: dict) -> str:
        """Format basic drive properties"""
        lines = [
            f"Drive: {drive_name}",
            f"Size: {properties.get('size', 'Unknown')}",
            f"Filesystem: {properties.get('fstype', 'Unknown')}",
            f"Mount Point: {properties.get('mountpoint', 'Not mounted')}",
            f"Label: {properties.get('label', 'No label')}",
            f"Model: {properties.get('model', 'Unknown')}",
            f"Vendor: {properties.get('vendor', 'Unknown')}",
            f"Serial: {properties.get('serial', 'Unknown')}",
            f"Removable: {'Yes' if properties.get('is_removable') else 'No'}",
            f"Health Status: {properties.get('health_status', 'Unknown')}",
            f"SMART Status: {properties.get('smart_status', 'Unknown')}",
        ]
        
        if properties.get('temperature', 0) > 0:
            lines.append(f"Temperature: {properties.get('temperature')}°C")
        
        return "\n".join(lines)
    
    def clear_drive_details(self):
        """Clear the drive details panel"""
        buffer = self.details_text.get_buffer()
        buffer.set_text("Select a drive to view details")
    
    def refresh_drives(self, force=False):
        """Refresh list of detected drives with debouncing"""
        current_time = time.time()
        
        # Debounce: skip if refreshed recently (unless forced)
        if not force and (current_time - self.last_refresh_time) < self.refresh_cooldown:
            self.logger.debug(f"Refresh debounced (last refresh {current_time - self.last_refresh_time:.1f}s ago)")
            return
        
        self.update_status("Refreshing drive list...")
        self.last_refresh_time = current_time
        
        try:
            drives = self.drive_manager.refresh_drives()
            
            # Update cache
            self.drive_cache = {drive.name: drive for drive in drives}
            
            self.update_drive_list(drives)
            self.update_status(f"Found {len(drives)} drives")
            self.logger.info(f"Refreshed drive list: {len(drives)} drives found")
            
        except Exception as e:
            error_msg = self.get_user_friendly_error("refresh", str(e))
            self.update_status(f"Error refreshing drives: {error_msg}")
            self.logger.error(f"Error refreshing drives: {e}")
    
    def update_drive_list(self, drives):
        """Update the drive list in the GUI"""
        self.drive_list_store.clear()
        
        for drive in drives:
            # Determine status with better UX
            if drive.mountpoint:
                status = "Mounted"
            else:
                # Not mounted - determine if it's ready or has issues
                if drive.health_status == "Dirty":
                    status = "Unmounted (Dirty - Needs Repair)"
                elif drive.health_status == "Error" and drive.fstype != "Unknown":
                    # Real filesystem error
                    status = "Unmounted (Error)"
                else:
                    # Default: All unmounted drives are hot-swappable
                    status = "Hot-Swap Ready"
            
            self.drive_list_store.append([
                drive.name,
                drive.size,
                drive.fstype,
                drive.mountpoint or "Not mounted",
                drive.label or "No label",
                status
            ])
    
    def on_drive_event(self, event_type: str, drive_info: DriveInfo):
        """Handle drive events from the drive manager"""
        # Update GUI in main thread
        GLib.idle_add(self.handle_drive_event_gui, event_type, drive_info)
    
    def handle_drive_event_gui(self, event_type: str, drive_info: DriveInfo):
        """Handle drive events in GUI thread with cache invalidation"""
        device_path = f"/dev/{drive_info.name}"
        
        # Invalidate NTFS properties cache for this drive
        if device_path in self.ntfs_properties_cache:
            self.logger.debug(f"Invalidating NTFS properties cache for {drive_info.name} due to {event_type} event")
            del self.ntfs_properties_cache[device_path]
        
        if event_type == "added":
            self.update_status(f"Drive {drive_info.name} connected")
            self.refresh_drives()
        elif event_type == "removed":
            self.update_status(f"Drive {drive_info.name} disconnected")
            self.refresh_drives()
        elif event_type == "mounted":
            self.update_status(f"Drive {drive_info.name} mounted")
            self.refresh_drives()
        elif event_type == "unmounted":
            self.update_status(f"Drive {drive_info.name} unmounted")
            self.refresh_drives()
    
    def on_mount_clicked(self, button):
        """Handle mount button click"""
        if not self.selected_drive:
            self.show_error_dialog("No drive selected", "Please select a drive to mount.")
            return
        
        # Show spinner
        self.show_button_spinner(button, True)
        
        def mount_thread():
            max_retries = 3
            for attempt in range(max_retries):
                try:
                    success = self.drive_manager.mount_drive(self.selected_drive)
                    if success:
                        GLib.idle_add(self.update_status, f"Drive {self.selected_drive} mounted successfully")
                        self.logger.operation("mount", self.selected_drive, "success")
                        GLib.idle_add(self.refresh_drives, True)
                        break
                    else:
                        if attempt < max_retries - 1:
                            time.sleep(1)  # Wait before retry
                            continue
                        error_msg = self.get_user_friendly_error("mount", "mount failed")
                        GLib.idle_add(self.show_error_dialog, "Mount failed", error_msg)
                        self.logger.operation("mount", self.selected_drive, "failed")
                except Exception as e:
                    if attempt < max_retries - 1:
                        time.sleep(1)
                        continue
                    error_msg = self.get_user_friendly_error("mount", str(e))
                    GLib.idle_add(self.show_error_dialog, "Mount error", error_msg)
                    self.logger.error(f"Error mounting drive {self.selected_drive}: {e}")
            
            # Hide spinner
            GLib.idle_add(self.show_button_spinner, button, False)
        
        threading.Thread(target=mount_thread, daemon=True).start()
    
    def on_unmount_clicked(self, button):
        """Handle unmount button click"""
        if not self.selected_drive:
            self.show_error_dialog("No drive selected", "Please select a drive to unmount.")
            return
        
        # Show spinner
        self.show_button_spinner(button, True)
        
        def unmount_thread():
            try:
                success = self.drive_manager.unmount_drive(self.selected_drive)
                if success:
                    GLib.idle_add(self.update_status, f"Drive {self.selected_drive} unmounted successfully")
                    self.logger.operation("unmount", self.selected_drive, "success")
                    GLib.idle_add(self.refresh_drives, True)
                else:
                    error_msg = self.get_user_friendly_error("unmount", "unmount failed")
                    GLib.idle_add(self.show_error_dialog, "Unmount failed", error_msg)
                    self.logger.operation("unmount", self.selected_drive, "failed")
            except Exception as e:
                error_msg = self.get_user_friendly_error("unmount", str(e))
                GLib.idle_add(self.show_error_dialog, "Unmount error", error_msg)
                self.logger.error(f"Error unmounting drive {self.selected_drive}: {e}")
            
            # Hide spinner
            GLib.idle_add(self.show_button_spinner, button, False)
        
        threading.Thread(target=unmount_thread, daemon=True).start()
    
    def on_repair_clicked(self, button):
        """Handle repair button click"""
        if not self.selected_drive:
            self.show_error_dialog("No drive selected", "Please select a drive to repair.")
            return
        
        # Show confirmation dialog
        dialog = Gtk.MessageDialog(
            parent=self.window,
            flags=Gtk.DialogFlags.MODAL,
            type=Gtk.MessageType.QUESTION,
            buttons=Gtk.ButtonsType.YES_NO,
            message_format=f"Repair drive {self.selected_drive}?\n\nThis will attempt to fix filesystem errors."
        )
        
        response = dialog.run()
        dialog.destroy()
        
        if response == Gtk.ResponseType.YES:
            # Show spinner
            self.show_button_spinner(button, True)
            
            def repair_thread():
                try:
                    GLib.idle_add(self.update_status, f"Repairing drive {self.selected_drive}...")
                    success = self.drive_manager.repair_drive(self.selected_drive)
                    if success:
                        GLib.idle_add(self.update_status, f"Drive {self.selected_drive} repaired successfully")
                        self.logger.operation("repair", self.selected_drive, "success")
                        GLib.idle_add(self.refresh_drives, True)
                    else:
                        error_msg = self.get_user_friendly_error("repair", "repair failed")
                        GLib.idle_add(self.show_error_dialog, "Repair failed", error_msg)
                        self.logger.operation("repair", self.selected_drive, "failed")
                except Exception as e:
                    error_msg = self.get_user_friendly_error("repair", str(e))
                    GLib.idle_add(self.show_error_dialog, "Repair error", error_msg)
                    self.logger.error(f"Error repairing drive {self.selected_drive}: {e}")
                
                # Hide spinner
                GLib.idle_add(self.show_button_spinner, button, False)
            
            threading.Thread(target=repair_thread, daemon=True).start()
    
    def on_format_clicked(self, button):
        """Handle format button click"""
        if not self.selected_drive:
            self.show_error_dialog("No drive selected", "Please select a drive to format.")
            return
        
        self.show_format_dialog()
    
    def on_burn_iso_clicked(self, button):
        """Handle burn ISO button click"""
        if not self.selected_drive:
            self.show_error_dialog("No drive selected", "Please select a target drive for ISO burning.")
            return
        
        self.show_iso_burn_dialog()
    
    def on_eject_clicked(self, button):
        """Handle safe eject button click"""
        if not self.selected_drive:
            self.show_error_dialog("No drive selected", "Please select a drive to eject.")
            return
        
        try:
            # First unmount if mounted
            if self.drive_manager.drives.get(self.selected_drive, DriveInfo("", "", "", "", "")).mountpoint:
                self.drive_manager.unmount_drive(self.selected_drive)

            # Then eject the device
            device_path = f"/dev/{self.selected_drive}"
            result = subprocess.run(["eject", device_path], capture_output=True, text=True)

            if result.returncode == 0:
                self.update_status(f"Drive {self.selected_drive} ejected safely")
                self.logger.operation("eject", self.selected_drive, "success")
            else:
                self.show_error_dialog("Eject failed", f"Failed to eject drive {self.selected_drive}")
                self.logger.operation("eject", self.selected_drive, "failed")
        except Exception as e:
            self.show_error_dialog("Eject Error", f"An error occurred: {str(e)}")
            self.logger.operation("eject", self.selected_drive, f"error: {str(e)}")

    def on_refresh_clicked(self, button):
        """Handle refresh button click"""
        self.refresh_drives()
    
    def on_properties_clicked(self, button):
        """Handle properties button click"""
        if not self.selected_drive:
            self.show_error_dialog("No drive selected", "Please select a drive to view properties.")
            return
        
        self.show_properties_dialog()
    
    def on_key_press(self, widget, event):
        """Handle keyboard shortcuts"""
        from gi.repository import Gdk
        
        # F1 - Open About dialog
        if event.keyval == Gdk.KEY_F1:
            self.show_about_dialog()
            return True
        
        # Ctrl+H - Open About dialog
        if (event.state & Gdk.ModifierType.CONTROL_MASK) and event.keyval == Gdk.KEY_h:
            self.show_about_dialog()
            return True
        
        # Ctrl+R or F5 - Refresh
        if ((event.state & Gdk.ModifierType.CONTROL_MASK) and event.keyval == Gdk.KEY_r) or \
           (event.keyval == Gdk.KEY_F5):
            self.on_refresh_clicked(None)
            return True
        
        # Escape - Close window
        if event.keyval == Gdk.KEY_Escape:
            self.window.destroy()
            return True
        
        return False
    
    def show_button_spinner(self, button, show=True):
        """Show or hide spinner on button"""
        if show:
            # Create spinner and box
            spinner = Gtk.Spinner()
            spinner.start()
            box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
            label = Gtk.Label(label=button.get_label())
            box.pack_start(spinner, False, False, 0)
            box.pack_start(label, False, False, 0)
            
            # Store original child and replace with spinner box
            button.original_child = button.get_child()
            button.remove(button.original_child)
            button.add(box)
            button.set_sensitive(False)
            button.show_all()
        else:
            # Restore original button content
            if hasattr(button, 'original_child'):
                child = button.get_child()
                if child:
                    button.remove(child)
                button.add(button.original_child)
                button.set_sensitive(True)
                button.show_all()
    
    def on_destroy(self, window):
        """Handle window destroy event"""
        self.drive_manager.stop_monitoring()
        self.logger.info("NTFS Manager GUI stopped")
        Gtk.main_quit()
    
    def show_format_dialog(self):
        """Show format dialog with input validation"""
        dialog = Gtk.Dialog(title="Format Drive", parent=self.window, flags=Gtk.DialogFlags.MODAL)
        dialog.add_button("Cancel", Gtk.ResponseType.CANCEL)
        dialog.add_button("Format", Gtk.ResponseType.OK)
        dialog.set_default_size(400, 350)
        
        content_area = dialog.get_content_area()
        
        # Warning label
        warning_label = Gtk.Label(label=f"⚠️ WARNING: This will erase ALL data on {self.selected_drive}!")
        warning_label.set_markup(f"<b><span foreground='red'>⚠️ WARNING: This will erase ALL data on {self.selected_drive}!</span></b>")
        content_area.pack_start(warning_label, False, False, 10)
        
        # Tool availability check
        if not self.available_tools.get('mkfs.ntfs'):
            info_label = Gtk.Label(label="Note: ntfs-3g tools not found. NTFS formatting may not be available.")
            info_label.set_line_wrap(True)
            content_area.pack_start(info_label, False, False, 5)
        
        # Filesystem selection
        fs_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        fs_label = Gtk.Label(label="Filesystem:")
        fs_combo = Gtk.ComboBoxText()
        fs_combo.append_text("ntfs")
        fs_combo.append_text("ext4")
        fs_combo.append_text("fat32")
        fs_combo.set_active(0)  # Default to NTFS
        
        fs_box.pack_start(fs_label, False, False, 5)
        fs_box.pack_start(fs_combo, True, True, 5)
        content_area.pack_start(fs_box, False, False, 5)
        
        # Label entry with validation feedback
        label_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        label_entry_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        label_entry_label = Gtk.Label(label="Label:")
        label_entry = Gtk.Entry()
        label_entry.set_placeholder_text("Optional - leave empty for no label")
        
        label_entry_box.pack_start(label_entry_label, False, False, 5)
        label_entry_box.pack_start(label_entry, True, True, 5)
        label_box.pack_start(label_entry_box, False, False, 0)
        
        # Validation feedback label
        validation_label = Gtk.Label(label="")
        validation_label.set_line_wrap(True)
        label_box.pack_start(validation_label, False, False, 0)
        content_area.pack_start(label_box, False, False, 5)
        
        # Real-time validation on label entry
        def on_label_changed(entry):
            text = entry.get_text()
            fstype = fs_combo.get_active_text()
            is_valid, error_msg = self.validate_filesystem_label(text, fstype)
            
            if not is_valid:
                validation_label.set_markup(f"<span foreground='red'>⚠️ {error_msg}</span>")
            elif text:
                validation_label.set_markup(f"<span foreground='green'>✓ Label is valid</span>")
            else:
                validation_label.set_text("")
        
        label_entry.connect("changed", on_label_changed)
        fs_combo.connect("changed", lambda _: on_label_changed(label_entry))
        
        dialog.show_all()
        response = dialog.run()
        
        if response == Gtk.ResponseType.OK:
            fstype = fs_combo.get_active_text()
            label = label_entry.get_text()
            
            # Validate label
            is_valid, error_msg = self.validate_filesystem_label(label, fstype)
            if not is_valid:
                dialog.destroy()
                self.show_error_dialog("Invalid Label", error_msg)
                return
            
            # Check if device is busy
            device_path = f"/dev/{self.selected_drive}"
            is_busy, processes = self.check_device_busy(device_path)
            if is_busy:
                dialog.destroy()
                process_list = ", ".join(processes[:3])  # Show first 3 processes
                self.show_error_dialog(
                    "Device Busy", 
                    f"Cannot format {self.selected_drive}.\n\n"
                    f"The device is being used by: {process_list}\n\n"
                    f"Please close these programs and try again."
                )
                return
            
            dialog.destroy()
            
            try:
                success = self.drive_manager.format_drive(self.selected_drive, fstype, label)
                if success:
                    self.update_status(f"Drive {self.selected_drive} formatted successfully")
                    self.logger.operation("format", self.selected_drive, "success", {"filesystem": fstype, "label": label})
                    self.refresh_drives()
                else:
                    self.show_error_dialog("Format failed", f"Failed to format drive {self.selected_drive}")
                    self.logger.operation("format", self.selected_drive, "failed", {"filesystem": fstype, "label": label})
            except Exception as e:
                self.show_error_dialog("Format error", f"Error formatting drive: {e}")
                self.logger.error(f"Error formatting drive {self.selected_drive}: {e}")
        else:
            dialog.destroy()
    
    def show_iso_burn_dialog(self):
        """Show ISO burning dialog"""
        dialog = Gtk.Dialog(title="Burn ISO to Drive", parent=self.window, flags=Gtk.DialogFlags.MODAL)
        dialog.add_button("Cancel", Gtk.ResponseType.CANCEL)
        dialog.add_button("Burn", Gtk.ResponseType.OK)
        dialog.set_default_size(500, 300)
        
        content_area = dialog.get_content_area()
        
        # Warning label
        warning_label = Gtk.Label(label=f"⚠️  WARNING: This will ERASE ALL DATA on {self.selected_drive}!")
        warning_label.set_markup(f"<b><span foreground='red'>⚠️  WARNING: This will ERASE ALL DATA on {self.selected_drive}!</span></b>")
        content_area.pack_start(warning_label, False, False, 10)
        
        # ISO file selection
        iso_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        iso_label = Gtk.Label(label="ISO File:")
        iso_entry = Gtk.Entry()
        iso_entry.set_placeholder_text("Select an ISO file...")
        
        iso_browse_btn = Gtk.Button(label="Browse...")
        
        def on_iso_browse(button):
            chooser = Gtk.FileChooserDialog(
                title="Select ISO File",
                parent=dialog,
                action=Gtk.FileChooserAction.OPEN
            )
            chooser.add_button("Cancel", Gtk.ResponseType.CANCEL)
            chooser.add_button("Open", Gtk.ResponseType.OK)
            
            # Add file filter for ISO files
            filter_iso = Gtk.FileFilter()
            filter_iso.set_name("ISO Files")
            filter_iso.add_pattern("*.iso")
            filter_iso.add_pattern("*.ISO")
            chooser.add_filter(filter_iso)
            
            filter_all = Gtk.FileFilter()
            filter_all.set_name("All Files")
            filter_all.add_pattern("*")
            chooser.add_filter(filter_all)
            
            response = chooser.run()
            if response == Gtk.ResponseType.OK:
                iso_entry.set_text(chooser.get_filename())
            chooser.destroy()
        
        iso_browse_btn.connect("clicked", on_iso_browse)
        
        iso_box.pack_start(iso_label, False, False, 5)
        iso_box.pack_start(iso_entry, True, True, 5)
        iso_box.pack_start(iso_browse_btn, False, False, 5)
        content_area.pack_start(iso_box, False, False, 5)
        
        # Target drive info
        target_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        target_label = Gtk.Label(label=f"Target Drive: /dev/{self.selected_drive}")
        target_label.set_markup(f"<b>Target Drive: /dev/{self.selected_drive}</b>")
        
        # Get drive info
        drive_info = self.drive_manager.drives.get(self.selected_drive)
        if drive_info:
            info_text = f"Size: {drive_info.size}\nModel: {drive_info.model or 'Unknown'}"
            info_label = Gtk.Label(label=info_text)
            target_box.pack_start(target_label, False, False, 5)
            target_box.pack_start(info_label, False, False, 5)
        
        content_area.pack_start(target_box, False, False, 10)
        
        # Verification checkbox
        verify_check = Gtk.CheckButton(label="Verify after burning (recommended)")
        verify_check.set_active(True)
        content_area.pack_start(verify_check, False, False, 5)
        
        dialog.show_all()
        response = dialog.run()
        
        if response == Gtk.ResponseType.OK:
            iso_file = iso_entry.get_text()
            verify = verify_check.get_active()
            
            # Validate ISO file
            is_valid, error_msg = self.validate_iso_file(iso_file)
            if not is_valid:
                dialog.destroy()
                self.show_error_dialog("Invalid ISO File", error_msg)
                return
            
            # Check if device is busy
            device_path = f"/dev/{self.selected_drive}"
            is_busy, processes = self.check_device_busy(device_path)
            if is_busy:
                dialog.destroy()
                process_list = ", ".join(processes[:3])
                self.show_error_dialog(
                    "Device Busy", 
                    f"Cannot burn ISO to {self.selected_drive}.\n\n"
                    f"The device is being used by: {process_list}\n\n"
                    f"Please close these programs and try again."
                )
                return
            
            # Check if dd tool is available
            if not self.available_tools.get('dd'):
                dialog.destroy()
                self.show_error_dialog(
                    "Missing Tool",
                    "The 'dd' command is not available on your system.\n\n"
                    "Please install coreutils package to burn ISO files."
                )
                return
            
            # Perform the burn operation
            dialog.destroy()
            self.burn_iso_to_drive(iso_file, self.selected_drive, verify)
        else:
            dialog.destroy()
    
    def burn_iso_to_drive(self, iso_file: str, drive_name: str, verify: bool = False):
        """Burn ISO file to drive using optimized dd command with progress tracking"""
        device_path = f"/dev/{drive_name}"
        
        # Get ISO file size for progress calculation
        try:
            iso_size = os.path.getsize(iso_file)
        except:
            iso_size = 0
        
        # Show progress dialog
        progress_dialog = Gtk.Dialog(title="Burning ISO...", parent=self.window, flags=Gtk.DialogFlags.MODAL)
        progress_dialog.set_default_size(500, 180)
        
        content = progress_dialog.get_content_area()
        
        status_label = Gtk.Label(label="Preparing to burn ISO...")
        content.pack_start(status_label, False, False, 10)
        
        progress_bar = Gtk.ProgressBar()
        progress_bar.set_show_text(True)
        content.pack_start(progress_bar, False, False, 10)
        
        eta_label = Gtk.Label(label="Calculating...")
        content.pack_start(eta_label, False, False, 5)
        
        progress_dialog.show_all()
        
        def burn_thread():
            try:
                # Unmount drive if mounted
                if self.drive_manager.drives.get(drive_name, DriveInfo("", "", "", "", "")).mountpoint:
                    self.drive_manager.unmount_drive(drive_name)
                
                # Optimized dd command for better speed
                cmd = ["pkexec", "dd", f"if={iso_file}", f"of={device_path}", 
                       "bs=16M",  # Larger block size for better throughput
                       "conv=fdatasync",  # Faster than oflag=sync
                       "status=progress"]
                
                process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, 
                                         text=True, bufsize=1, universal_newlines=True)
                
                start_time = time.time()
                last_update = start_time
                
                while process.poll() is None:
                    # Read stderr for progress (dd outputs to stderr)
                    line = process.stderr.readline()
                    if line and iso_size > 0:
                        # Parse dd output: "X bytes (Y GB) copied, Z s, A MB/s"
                        import re
                        match = re.search(r'(\d+)\s+bytes', line)
                        if match:
                            bytes_copied = int(match.group(1))
                            percent = min(100, (bytes_copied / iso_size) * 100)
                            
                            # Calculate speed and ETA
                            elapsed = time.time() - start_time
                            if elapsed > 0 and bytes_copied > 0:
                                speed_bps = bytes_copied / elapsed
                                remaining_bytes = iso_size - bytes_copied
                                eta_seconds = remaining_bytes / speed_bps if speed_bps > 0 else 0
                                
                                # Format ETA
                                eta_min = int(eta_seconds // 60)
                                eta_sec = int(eta_seconds % 60)
                                eta_str = f"{eta_min}m {eta_sec}s remaining" if eta_min > 0 else f"{eta_sec}s remaining"
                                
                                # Update UI (throttle updates)
                                current_time = time.time()
                                if current_time - last_update > 0.5:
                                    GLib.idle_add(progress_bar.set_fraction, percent / 100)
                                    GLib.idle_add(status_label.set_text, f"Burning... {percent:.1f}%")
                                    GLib.idle_add(eta_label.set_text, eta_str)
                                    last_update = current_time
                    else:
                        time.sleep(0.1)
                
                stdout, stderr = process.communicate()
                
                if process.returncode == 0:
                    GLib.idle_add(progress_bar.set_fraction, 1.0)
                    GLib.idle_add(status_label.set_text, "ISO burned successfully!")
                    GLib.idle_add(eta_label.set_text, "Complete")
                    GLib.idle_add(self.update_status, f"ISO burned to {drive_name} successfully")
                    self.logger.operation("burn_iso", drive_name, "success", {"iso_file": iso_file})
                    time.sleep(2)
                    GLib.idle_add(progress_dialog.destroy)
                    GLib.idle_add(self.refresh_drives)
                else:
                    error_msg = stderr or "Unknown error"
                    GLib.idle_add(status_label.set_text, f"Error: {error_msg}")
                    self.logger.operation("burn_iso", drive_name, "failed", {"error": error_msg})
                    time.sleep(3)
                    GLib.idle_add(progress_dialog.destroy)
                    GLib.idle_add(self.show_error_dialog, "Burn Failed", f"Failed to burn ISO: {error_msg}")
                    
            except Exception as e:
                GLib.idle_add(progress_dialog.destroy)
                GLib.idle_add(self.show_error_dialog, "Burn Error", f"An error occurred: {str(e)}")
                self.logger.error(f"Error burning ISO: {e}")
        
        # Start burning in background thread
        burn_thread_obj = threading.Thread(target=burn_thread, daemon=True)
        burn_thread_obj.start()
    
    def show_properties_dialog(self):
        """Show advanced properties dialog"""
        dialog = Gtk.Dialog(title="Advanced Properties", parent=self.window, flags=Gtk.DialogFlags.MODAL)
        dialog.add_button("Close", Gtk.ResponseType.CLOSE)
        dialog.set_default_size(600, 500)
        
        content_area = dialog.get_content_area()
        
        # Create notebook for tabbed properties
        notebook = Gtk.Notebook()
        
        # Basic properties tab
        basic_page = Gtk.ScrolledWindow()
        basic_text = Gtk.TextView()
        basic_text.set_editable(False)
        basic_text.set_wrap_mode(Gtk.WrapMode.WORD)
        basic_page.add(basic_text)
        notebook.append_page(basic_page, Gtk.Label(label="Basic"))
        
        # NTFS properties tab (if applicable)
        properties = self.drive_manager.get_drive_properties(self.selected_drive)
        if properties.get('fstype') == 'ntfs':
            ntfs_page = Gtk.ScrolledWindow()
            ntfs_text = Gtk.TextView()
            ntfs_text.set_editable(False)
            ntfs_text.set_wrap_mode(Gtk.WrapMode.WORD)
            ntfs_page.add(ntfs_text)
            notebook.append_page(ntfs_page, Gtk.Label(label="NTFS"))
            
            # Load NTFS properties
            try:
                device_path = f"/dev/{self.selected_drive}"
                ntfs_props = NTFSProperties(device_path)
                ntfs_details = ntfs_props.get_all_properties()
                
                # Format NTFS properties
                ntfs_content = self.format_ntfs_properties(ntfs_details)
                buffer = ntfs_text.get_buffer()
                buffer.set_text(ntfs_content)
            except Exception as e:
                buffer = ntfs_text.get_buffer()
                buffer.set_text(f"Error loading NTFS properties: {e}")
        
        # Health tab
        health_page = Gtk.ScrolledWindow()
        health_text = Gtk.TextView()
        health_text.set_editable(False)
        health_text.set_wrap_mode(Gtk.WrapMode.WORD)
        health_page.add(health_text)
        notebook.append_page(health_page, Gtk.Label(label="Health"))
        
        content_area.pack_start(notebook, True, True, 5)
        
        # Load basic properties
        basic_content = self.format_basic_properties(self.selected_drive, properties)
        buffer = basic_text.get_buffer()
        buffer.set_text(basic_content)
        
        # Load health information
        try:
            device_path = f"/dev/{self.selected_drive}"
            ntfs_props = NTFSProperties(device_path)
            health_results = ntfs_props.run_disk_check()
            health_content = self.format_health_results(health_results)
            health_buffer = health_text.get_buffer()
            health_buffer.set_text(health_content)
        except Exception as e:
            health_buffer = health_text.get_buffer()
            health_buffer.set_text(f"Error loading health information: {e}")
        
        dialog.show_all()
        dialog.run()
        dialog.destroy()
    
    def format_ntfs_properties(self, properties: dict) -> str:
        """Format NTFS properties for display"""
        lines = []
        
        volume = properties.get('volume', {})
        lines.append("=== NTFS Volume Information ===")
        lines.append(f"Volume Name: {volume.get('name', 'Unknown')}")
        lines.append(f"Volume Serial: {volume.get('serial', 'Unknown')}")
        lines.append(f"Cluster Size: {volume.get('cluster_size', 0)} bytes")
        lines.append(f"Total Clusters: {volume.get('total_clusters', 0)}")
        lines.append(f"Free Clusters: {volume.get('free_clusters', 0)}")
        lines.append(f"Usage: {volume.get('usage_percentage', 0)}%")
        lines.append("")
        
        security = properties.get('security', {})
        lines.append("=== Security Information ===")
        lines.append(f"Owner: {security.get('owner', 'Unknown')}")
        lines.append(f"Group: {security.get('group', 'Unknown')}")
        lines.append(f"Permissions: {security.get('permissions', 'Unknown')}")
        lines.append(f"Encryption Status: {security.get('encryption_status', 'Unknown')}")
        lines.append("")
        
        return "\n".join(lines)
    
    def format_health_results(self, health_results: dict) -> str:
        """Format health check results for display"""
        lines = []
        lines.append("=== Drive Health Check ===")
        lines.append(f"Check Time: {health_results.get('timestamp', 'Unknown')}")
        lines.append(f"Overall Status: {health_results.get('overall_status', 'Unknown')}")
        lines.append("")
        
        checks = health_results.get('checks', {})
        for check_name, check_result in checks.items():
            lines.append(f"=== {check_name.title()} ===")
            lines.append(f"Status: {check_result.get('status', 'Unknown')}")
            
            if 'error' in check_result:
                lines.append(f"Error: {check_result['error']}")
            if 'dirty_bit' in check_result:
                lines.append(f"Dirty Bit: {'Set' if check_result['dirty_bit'] else 'Clear'}")
            if 'errors' in check_result:
                lines.append(f"Errors: {check_result['errors']}")
            lines.append("")
        
        return "\n".join(lines)
    
    def get_user_friendly_error(self, operation: str, error: str) -> str:
        """Convert technical errors to user-friendly messages with solutions"""
        error_lower = error.lower()
        
        # Common error patterns and solutions
        if "permission denied" in error_lower or "not permitted" in error_lower:
            return (f"Permission denied.\n\n"
                    f"💡 Solution: Make sure you have administrator privileges.\n"
                    f"Try restarting the application or check file permissions.")
        
        elif "device is busy" in error_lower or "target is busy" in error_lower:
            return (f"Drive is busy and cannot be {operation}ed.\n\n"
                    f"💡 Solutions:\n"
                    f"• Close any programs using files on this drive\n"
                    f"• Check if the drive is open in file manager\n"
                    f"• Wait a moment and try again")
        
        elif "not found" in error_lower or "no such" in error_lower:
            return (f"Drive not found.\n\n"
                    f"💡 Solutions:\n"
                    f"• The drive may have been disconnected\n"
                    f"• Click Refresh to update the drive list\n"
                    f"• Check physical connections")
        
        elif "already mounted" in error_lower:
            return (f"Drive is already mounted.\n\n"
                    f"💡 Solution: Use the Unmount button first, then try again.")
        
        elif "not mounted" in error_lower:
            return (f"Drive is not mounted.\n\n"
                    f"💡 Solution: Mount the drive first before accessing it.")
        
        elif "filesystem" in error_lower and "corrupt" in error_lower:
            return (f"Filesystem appears corrupted.\n\n"
                    f"💡 Solutions:\n"
                    f"• Try the Repair button to fix filesystem errors\n"
                    f"• Back up important data if possible\n"
                    f"• Consider reformatting if repair fails (WARNING: Erases data)")
        
        elif "read-only" in error_lower:
            return (f"Drive is mounted read-only.\n\n"
                    f"💡 Solutions:\n"
                    f"• The filesystem may need repair - use Repair button\n"
                    f"• Check if drive has a physical write-protect switch\n"
                    f"• Unmount and remount the drive")
        
        else:
            # Generic error with basic guidance
            return (f"Operation failed: {error}\n\n"
                    f"💡 Try:\n"
                    f"• Refreshing the drive list\n"
                    f"• Checking drive connections\n"
                    f"• Viewing logs for more details")
    
    def show_error_dialog(self, title: str, message: str):
        """Show error dialog"""
        dialog = Gtk.MessageDialog(
            parent=self.window,
            flags=Gtk.DialogFlags.MODAL,
            type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            message_format=message
        )
        dialog.set_title(title)
        dialog.run()
        dialog.destroy()
    
    def update_status(self, message: str):
        """Update status bar"""
        context = self.status_bar.get_context_id("status")
        self.status_bar.push(context, message)

def check_single_instance():
    """Check if another instance is already running"""
    lock_file = "/tmp/ntfs-manager.lock"
    try:
        # Try to open lock file
        lock_fd = open(lock_file, 'w')
        # Try to acquire exclusive lock (non-blocking)
        fcntl.flock(lock_fd.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        # Write PID to lock file
        lock_fd.write(str(os.getpid()))
        lock_fd.flush()
        return lock_fd  # Return file descriptor to keep lock
    except IOError:
        # Another instance is running
        print("NTFS Manager is already running!")
        dialog = Gtk.MessageDialog(
            parent=None,
            flags=0,
            type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            message_format="NTFS Manager is already running"
        )
        dialog.format_secondary_text(
            "Another instance of NTFS Complete Manager is already open.\n"
            "Please use the existing window."
        )
        dialog.run()
        dialog.destroy()
        sys.exit(0)

def main():
    # Check for single instance
    lock_fd = check_single_instance()
    
    # Set GTK application properties for proper window grouping
    # This ensures the window appears under the correct launcher icon
    import gi
    gi.require_version('Gtk', '3.0')
    from gi.repository import Gtk, GLib
    
    # Set WM_CLASS to match .desktop file's StartupWMClass
    GLib.set_prgname("ntfs-complete-manager")
    GLib.set_application_name("NTFS Complete Manager")
    
    app = NTFSManager()
    
    # Set window class name for proper icon binding
    app.window.set_wmclass("ntfs-complete-manager", "ntfs-complete-manager")
    
    Gtk.main()
    
    # Cleanup lock file on exit
    try:
        fcntl.flock(lock_fd.fileno(), fcntl.LOCK_UN)
        lock_fd.close()
        os.unlink("/tmp/ntfs-manager.lock")
    except:
        pass

if __name__ == "__main__":
    main()
