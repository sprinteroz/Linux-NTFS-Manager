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
        
        # Setup drive event callbacks
        self.drive_manager.add_callback(self.on_drive_event)
        
        self.setup_ui()
        self.refresh_drives()
        
        # Start drive monitoring
        self.drive_manager.start_monitoring()
    
    def setup_ui(self):
        # Create main window
        self.window = Gtk.Window(title="NTFS Complete Manager v2.0")
        self.window.set_default_size(1000, 700)
        self.window.set_border_width(10)
        
        # Create main container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        
        # Add header with title and refresh button
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        title_label = Gtk.Label(label="NTFS Complete Manager v2.0")
        title_label.get_style_context().add_class("title")
        
        refresh_btn = Gtk.Button(label="Refresh")
        refresh_btn.connect("clicked", self.on_refresh_clicked)
        
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
        
        mount_btn = Gtk.Button(label="Mount")
        mount_btn.connect("clicked", self.on_mount_clicked)
        
        unmount_btn = Gtk.Button(label="Unmount")
        unmount_btn.connect("clicked", self.on_unmount_clicked)
        
        repair_btn = Gtk.Button(label="Repair")
        repair_btn.connect("clicked", self.on_repair_clicked)
        
        format_btn = Gtk.Button(label="Format")
        format_btn.connect("clicked", self.on_format_clicked)
        
        eject_btn = Gtk.Button(label="Safe Eject")
        eject_btn.connect("clicked", self.on_eject_clicked)
        
        action_box.pack_start(mount_btn, False, False, 2)
        action_box.pack_start(unmount_btn, False, False, 2)
        action_box.pack_start(repair_btn, False, False, 2)
        action_box.pack_start(format_btn, False, False, 2)
        action_box.pack_start(eject_btn, False, False, 2)
        
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
        properties_btn = Gtk.Button(label="Advanced Properties")
        properties_btn.connect("clicked", self.on_properties_clicked)
        right_box.pack_start(properties_btn, False, False, 5)
        
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
        self.drive_treeview.get_selection().connect("changed", self.on_drive_selection_changed)
        
        # Show all widgets
        self.window.show_all()
        
        self.logger.info("NTFS Manager GUI started")
    
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
        """Update the drive details panel"""
        if not drive_name:
            return
        
        try:
            # Get drive properties
            properties = self.drive_manager.get_drive_properties(drive_name)
            
            # Get NTFS-specific properties if it's an NTFS drive
            if properties.get('fstype') == 'ntfs':
                device_path = f"/dev/{drive_name}"
                ntfs_props = NTFSProperties(device_path)
                ntfs_details = ntfs_props.get_windows_style_properties()
                
                details_text = f"NTFS Properties for {drive_name}:\n\n{ntfs_details}"
            else:
                # Basic properties for non-NTFS drives
                details_text = self.format_basic_properties(drive_name, properties)
            
            # Update the text view
            buffer = self.details_text.get_buffer()
            buffer.set_text(details_text)
            
        except Exception as e:
            self.logger.error(f"Error updating drive details for {drive_name}: {e}")
            buffer = self.details_text.get_buffer()
            buffer.set_text(f"Error loading drive details: {e}")
    
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
    
    def refresh_drives(self):
        """Refresh list of detected drives"""
        self.update_status("Refreshing drive list...")
        
        try:
            drives = self.drive_manager.refresh_drives()
            self.update_drive_list(drives)
            self.update_status(f"Found {len(drives)} drives")
            self.logger.info(f"Refreshed drive list: {len(drives)} drives found")
            
        except Exception as e:
            self.update_status(f"Error refreshing drives: {e}")
            self.logger.error(f"Error refreshing drives: {e}")
    
    def update_drive_list(self, drives):
        """Update the drive list in the GUI"""
        self.drive_list_store.clear()
        
        for drive in drives:
            status = "Mounted" if drive.mountpoint else "Unmounted"
            if drive.health_status == "Dirty":
                status += " (Dirty)"
            elif drive.health_status == "Error":
                status += " (Error)"
            
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
        """Handle drive events in GUI thread"""
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
        
        try:
            success = self.drive_manager.mount_drive(self.selected_drive)
            if success:
                self.update_status(f"Drive {self.selected_drive} mounted successfully")
                self.logger.operation("mount", self.selected_drive, "success")
            else:
                self.show_error_dialog("Mount failed", f"Failed to mount drive {self.selected_drive}")
                self.logger.operation("mount", self.selected_drive, "failed")
        except Exception as e:
            self.show_error_dialog("Mount error", f"Error mounting drive: {e}")
            self.logger.error(f"Error mounting drive {self.selected_drive}: {e}")
    
    def on_unmount_clicked(self, button):
        """Handle unmount button click"""
        if not self.selected_drive:
            self.show_error_dialog("No drive selected", "Please select a drive to unmount.")
            return
        
        try:
            success = self.drive_manager.unmount_drive(self.selected_drive)
            if success:
                self.update_status(f"Drive {self.selected_drive} unmounted successfully")
                self.logger.operation("unmount", self.selected_drive, "success")
            else:
                self.show_error_dialog("Unmount failed", f"Failed to unmount drive {self.selected_drive}")
                self.logger.operation("unmount", self.selected_drive, "failed")
        except Exception as e:
            self.show_error_dialog("Unmount error", f"Error unmounting drive: {e}")
            self.logger.error(f"Error unmounting drive {self.selected_drive}: {e}")
    
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
            try:
                self.update_status(f"Repairing drive {self.selected_drive}...")
                success = self.drive_manager.repair_drive(self.selected_drive)
                if success:
                    self.update_status(f"Drive {self.selected_drive} repaired successfully")
                    self.logger.operation("repair", self.selected_drive, "success")
                else:
                    self.show_error_dialog("Repair failed", f"Failed to repair drive {self.selected_drive}")
                    self.logger.operation("repair", self.selected_drive, "failed")
            except Exception as e:
                self.show_error_dialog("Repair error", f"Error repairing drive: {e}")
                self.logger.error(f"Error repairing drive {self.selected_drive}: {e}")
    
    def on_format_clicked(self, button):
        """Handle format button click"""
        if not self.selected_drive:
            self.show_error_dialog("No drive selected", "Please select a drive to format.")
            return
        
        self.show_format_dialog()
    
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
    
    def on_destroy(self, window):
        """Handle window destroy event"""
        self.drive_manager.stop_monitoring()
        self.logger.info("NTFS Manager GUI stopped")
        Gtk.main_quit()
    
    def show_format_dialog(self):
        """Show format dialog"""
        dialog = Gtk.Dialog(title="Format Drive", parent=self.window, flags=Gtk.DialogFlags.MODAL)
        dialog.add_button("Cancel", Gtk.ResponseType.CANCEL)
        dialog.add_button("Format", Gtk.ResponseType.OK)
        dialog.set_default_size(400, 300)
        
        content_area = dialog.get_content_area()
        
        # Warning label
        warning_label = Gtk.Label(label=f"WARNING: This will erase all data on {self.selected_drive}!")
        warning_label.get_style_context().add_class("warning")
        content_area.pack_start(warning_label, False, False, 10)
        
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
        
        # Label entry
        label_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        label_entry_label = Gtk.Label(label="Label:")
        label_entry = Gtk.Entry()
        
        label_box.pack_start(label_entry_label, False, False, 5)
        label_box.pack_start(label_entry, True, True, 5)
        content_area.pack_start(label_box, False, False, 5)
        
        dialog.show_all()
        response = dialog.run()
        
        if response == Gtk.ResponseType.OK:
            fstype = fs_combo.get_active_text()
            label = label_entry.get_text()
            
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
        
        dialog.destroy()
    
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

def main():
    app = NTFSManager()
    Gtk.main()

if __name__ == "__main__":
    main()
