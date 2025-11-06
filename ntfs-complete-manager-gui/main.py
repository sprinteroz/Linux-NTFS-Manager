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
        
        # Auto-mount internal NTFS drives on startup
        self.auto_mount_internal_drives()
        
        # Start drive monitoring
        self.drive_manager.start_monitoring()
    
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
        
        burn_iso_btn = Gtk.Button(label="Burn ISO")
        burn_iso_btn.connect("clicked", self.on_burn_iso_clicked)
        
        eject_btn = Gtk.Button(label="Safe Eject")
        eject_btn.connect("clicked", self.on_eject_clicked)
        
        action_box.pack_start(mount_btn, False, False, 2)
        action_box.pack_start(unmount_btn, False, False, 2)
        action_box.pack_start(repair_btn, False, False, 2)
        action_box.pack_start(format_btn, False, False, 2)
        action_box.pack_start(burn_iso_btn, False, False, 2)
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
            
            # Check if we got valid properties
            if not properties:
                buffer = self.details_text.get_buffer()
                buffer.set_text(f"Drive {drive_name} - No properties available")
                return
            
            # Get NTFS-specific properties if it's an NTFS drive
            if properties.get('fstype') == 'ntfs':
                device_path = f"/dev/{drive_name}"
                try:
                    ntfs_props = NTFSProperties(device_path)
                    ntfs_details = ntfs_props.get_windows_style_properties()
                    details_text = f"NTFS Properties for {drive_name}:\n\n{ntfs_details}"
                except Exception as ntfs_error:
                    # Fallback to basic properties if NTFS check fails
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
            
            if not iso_file:
                dialog.destroy()
                self.show_error_dialog("No ISO selected", "Please select an ISO file to burn.")
                return
            
            if not os.path.exists(iso_file):
                dialog.destroy()
                self.show_error_dialog("File not found", f"ISO file not found: {iso_file}")
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
