# Linux NTFS Manager - Testing Guide

**How to help test Linux NTFS Manager and provide valuable feedback**

---

## 🎯 Who Should Test This Tool?

You're a perfect tester if you:

- ✅ Use a Linux/Windows dual-boot setup
- ✅ Have NTFS drives that mount as "read-only" in Linux
- ✅ Want to help improve open-source software
- ✅ Can report what works and what doesn't

**No programming experience required!** We need real users on real systems.

---

## 🚀 Quick Start Testing

### Step 1: Install the Tool

```bash
# Clone the repository
git clone https://github.com/sprinteroz/Linux-NTFS-Manager.git
cd Linux-NTFS-Manager

# Run the installer
cd ntfs-manager-production
sudo ./install.sh
```

### Step 2: Test Basic Functionality

1. **Launch the application**:
   ```bash
   ntfs-manager
   # Or find it in your applications menu under "System Tools"
   ```

2. **Check if your drives are detected**:
   - Does the tool show your NTFS drives?
   - Are the drive details accurate (size, label, filesystem)?

3. **Test the "refresh" button**:
   - Click the "Refresh" button
   - Do the drives update correctly?

### Step 3: Test Core Features

#### If you have a "dirty" NTFS drive:

1. Boot into Windows with Fast Startup enabled
2. Shut down Windows (not restart)
3. Boot into Linux
4. Open NTFS Manager
5. Select the drive that shows as "read-only"
6. Click "Repair" button
7. **Report**: Did it fix the issue? Can you now write to the drive?

#### If you don't have a "dirty" drive:

Test these features:
- **Mount/Unmount**: Try mounting and unmounting drives
- **Drive Info**: Check if drive information is accurate
- **Safe Eject**: Test the safe eject functionality
- **Properties**: Click "Advanced Properties" - does it show correct info?

---

## 🐛 What to Report

### Essential Information

When reporting bugs or feedback, please include:

1. **Your System Info**:
   ```bash
   # Run this command and include output:
   uname -a
   lsb_release -a
   ```

2. **NTFS Manager Version**:
   ```bash
   # Check the title bar or run:
   cat VERSION
   ```

3. **What You Did**: Step-by-step description

4. **What Happened**: Actual behavior

5. **What You Expected**: Expected behavior

6. **Error Messages**: Any error dialogs or terminal output

### How to Report

**Option 1: GitHub Issues (Preferred)**
- Go to: https://github.com/sprinteroz/Linux-NTFS-Manager/issues
- Click "New Issue"
- Use the template provided

**Option 2: GitHub Discussions**
- For questions or general feedback
- Go to: https://github.com/sprinteroz/Linux-NTFS-Manager/discussions

**Option 3: Reddit/Forum Threads**
- Reply to the post where you found the tool
- Tag the developer if possible

---

## ✅ Testing Checklist

Use this checklist to systematically test features:

### Basic Functionality
- [ ] Application launches without errors
- [ ] Main window displays correctly
- [ ] Can see all NTFS drives in the list
- [ ] Drive information is accurate (size, label, etc.)
- [ ] Refresh button updates drive list
- [ ] Status bar shows current operation

### Drive Operations
- [ ] Mount an unmounted drive
- [ ] Unmount a mounted drive
- [ ] Repair a "dirty" drive
- [ ] Safe eject removable drive
- [ ] Format dialog appears correctly (DON'T actually format unless testing on non-critical drive!)

### Drive Details
- [ ] "Advanced Properties" dialog opens
- [ ] Basic tab shows correct information
- [ ] NTFS tab shows filesystem details (for NTFS drives)
- [ ] Health tab shows drive status

### Error Handling
- [ ] Appropriate error message when operation fails
- [ ] Tool doesn't crash when drive is removed during operation
- [ ] Handle drives that require root permissions correctly

### Nautilus Integration (if installed)
- [ ] Right-click on NTFS drive in file manager
- [ ] "NTFS Manager" option appears in context menu
- [ ] Selecting it opens the tool with drive selected

### Multi-Language Support
- [ ] Change system language
- [ ] Tool displays in correct language
- [ ] No untranslated strings visible

---

## 🎓 Advanced Testing Scenarios

### Scenario 1: Dual-Boot with Fast Startup

**Setup**:
1. Windows 10/11 with Fast Startup enabled
2. Shared NTFS data partition

**Test Steps**:
1. Boot Windows, make changes to data partition
2. Shut down (not restart)
3. Boot Linux
4. Data partition shows as "read-only"
5. Use NTFS Manager to repair
6. Verify can now write to partition

**Report**: Success rate, any issues

---

### Scenario 2: Hot-Plug USB Drive

**Setup**:
1. External USB drive formatted as NTFS

**Test Steps**:
1. Have NTFS Manager open
2. Plug in USB drive
3. Does it appear automatically in the list?
4. Select drive and test mount/unmount
5. Test safe eject

**Report**: Detection time, any errors

---

### Scenario 3: Multiple NTFS Drives

**Setup**:
1. System with 2+ NTFS drives/partitions

**Test Steps**:
1. Open NTFS Manager
2. Verify all drives detected
3. Test operations on different drives
4. Check if correct drive is selected for operations

**Report**: Any confusion in drive identification

---

### Scenario 4: Different Distributions

We especially need testing on:
- ✅ **Ubuntu** and variants (Pop!_OS, Linux Mint, etc.)
- ✅ **Fedora** / RHEL-based
- ✅ **Arch** / Manjaro
- ✅ **Debian**
- ✅ **openSUSE**

**For each distro, report**:
- Does installation work?
- Any missing dependencies?
- Any UI rendering issues?

---

## 💬 Good Bug Reports vs. Bad Bug Reports

### ❌ Bad Bug Report

> "It doesn't work"

**Why it's bad**: No context, can't reproduce

---

### ✅ Good Bug Report

> **Title**: Drive repair fails on Fedora 39
>
> **System Info**:
> - Fedora 39 Workstation
> - NTFS Manager v1.0.3
> - Kernel 6.5.6
>
> **Steps to Reproduce**:
> 1. Boot Windows 11 with Fast Startup
> 2. Shutdown
> 3. Boot Fedora
> 4. Open NTFS Manager
> 5. Select /dev/sda3 (my data partition)
> 6. Click "Repair"
>
> **Expected**: Drive is repaired and becomes writable
>
> **Actual**: Error dialog: "Failed to repair drive: Permission denied"
>
> **Additional Info**: Running with sudo works fine
>
> **Error Log** (if any): [paste relevant logs]

**Why it's good**: Specific, reproducible, includes system info

---

## 🌟 Feature Requests Welcome!

Have ideas for improvement? We'd love to hear them!

**Good feature requests include**:
- What problem would it solve?
- How would it work?
- Why is it important?

**Examples**:
- "Add keyboard shortcuts for common operations"
- "Show drive temperature for SSDs"
- "Batch operations on multiple drives"

Submit via [GitHub Discussions](https://github.com/sprinteroz/Linux-NTFS-Manager/discussions)

---

## 🏆 Becoming a Power Tester

### Level 1: Basic Tester
- Install and run the tool
- Report if it works or not
- Basic feedback

### Level 2: Active Tester
- Test multiple scenarios
- Report detailed bugs
- Test on different systems

### Level 3: Power Tester
- Regular testing of new releases
- Detailed system configurations tested
- Help other testers troubleshoot
- Contribute to documentation

**Benefits of Power Testing**:
- Your name in CONTRIBUTORS.md
- Early access to new features
- Direct communication with developer
- Help shape the tool's future

---

## 📊 Testing Priorities

### High Priority (Test These First!)

1. **Drive Detection**: Does it find your NTFS drives?
2. **Repair Function**: Does it fix "dirty" drives?
3. **Mount/Unmount**: Do basic operations work?
4. **Stability**: Does it crash or freeze?

### Medium Priority

1. Format dialog (test only on non-critical drives)
2. Advanced properties accuracy
3. Nautilus integration
4. Language support

### Low Priority (Nice to Have)

1. UI polish feedback
2. Performance on many drives
3. Feature suggestions

---

## 🔧 Developer Testing Mode

For developers who want to test development versions:

```bash
# Clone the repo
git clone https://github.com/sprinteroz/Linux-NTFS-Manager.git
cd Linux-NTFS-Manager

# Create virtual environment (optional)
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r ntfs-manager-production/requirements.txt

# Run from source
cd ntfs-manager-production/standalone-gui
sudo python3 main.py
```

**Test unreleased features and provide early feedback!**

---

## ❓ FAQ

### Q: Will testing harm my drives?
**A**: The tool is designed to be safe. However, as with any disk utility, we recommend:
- Backing up important data first
- Not testing format operations on drives with data you need
- Testing on non-critical systems first if you're cautious

### Q: Do I need programming knowledge?
**A**: No! We need regular users to test real-world scenarios.

### Q: How much time does testing take?
**A**: 10-15 minutes for basic testing. More if you want to test advanced scenarios.

### Q: What if I find a serious bug?
**A**: Report it immediately via GitHub Issues and mark it as "urgent" or email the developer directly if it's security-related.

### Q: Can I test if I don't have the "dirty drive" problem?
**A**: Absolutely! Test other features like mount/unmount, drive info, USB hot-plug, etc.

### Q: Will my feedback really be considered?
**A**: Yes! This is a community-driven project. Your feedback directly shapes development priorities.

---

## 🙏 Thank You!

Every bug report, feature request, and piece of feedback makes this tool better for everyone. 

**You're not just testing software - you're helping thousands of dual-boot users.**

---

## 📚 Additional Resources

- **Main Promotion Guide**: See PROMOTION.md
- **Community Templates**: See `private-deployment/community-templates/`
- **GitHub Repository**: https://github.com/sprinteroz/Linux-NTFS-Manager
- **Report Issues**: https://github.com/sprinteroz/Linux-NTFS-Manager/issues

---

**Happy Testing! 🧪**

*Last Updated: 2025-01-15*
