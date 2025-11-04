# Wiki Content for GitHub

This directory contains markdown files for the NTFS Manager GitHub Wiki.

## 📁 Files Included

- **Home.md** - Main wiki landing page with navigation
- **Installation-Guide.md** - Complete installation instructions
- **Security-Setup.md** - GitHub security features configuration guide
- **Troubleshooting.md** - Solutions to common problems
- **Contributing.md** - Guidelines for contributors

## 🚀 How to Upload to GitHub Wiki

### Method 1: Manual Upload (Recommended)

1. **Enable Wiki on GitHub:**
   - Go to your repository: https://github.com/sprinteroz/Linux-NTFS-Manager
   - Click **Settings** tab
   - Scroll to **Features** section
   - Check ✅ **Wikis**

2. **Create Wiki Pages:**
   - Go to the **Wiki** tab
   - Click **Create the first page** (or **New Page**)
   - Set title as "Home"
   - Copy content from `Home.md`
   - Click **Save Page**

3. **Add Remaining Pages:**
   - Click **New Page**
   - Use these exact titles (case-sensitive):
     - Installation-Guide
     - Security-Setup
     - Troubleshooting
     - Contributing
   - Copy content from respective `.md` files
   - Click **Save Page** for each

### Method 2: Clone Wiki and Push (Advanced)

```bash
# Clone the wiki repository
git clone https://github.com/sprinteroz/Linux-NTFS-Manager.wiki.git
cd Linux-NTFS-Manager.wiki

# Copy wiki content files
cp ../Linux-NTFS-Manager/wiki-content/*.md .

# Remove this README (not needed in wiki)
rm README.md

# Commit and push
git add .
git commit -m "Add comprehensive wiki documentation"
git push origin master
```

## 📝 Page Titles and File Names

GitHub Wiki uses specific naming conventions:

| File Name | Wiki Page Title | URL |
|-----------|----------------|-----|
| Home.md | Home | /Home |
| Installation-Guide.md | Installation-Guide | /Installation-Guide |
| Security-Setup.md | Security-Setup | /Security-Setup |
| Troubleshooting.md | Troubleshooting | /Troubleshooting |
| Contributing.md | Contributing | /Contributing |

## 🔗 Internal Links

All internal wiki links use this format:
```markdown
[Link Text](Page-Name)
```

Examples:
- `[Installation Guide](Installation-Guide)`
- `[Security Setup](Security-Setup)`
- `[Troubleshooting](Troubleshooting)`

## ✅ Verification

After uploading, verify:

1. **All pages created:**
   - Home
   - Installation-Guide
   - Security-Setup
   - Troubleshooting
   - Contributing

2. **Navigation works:**
   - Click links between pages
   - Verify all internal links work

3. **Images display:**
   - Logo on Home page
   - Any screenshots or badges

4. **Formatting correct:**
   - Headers render properly
   - Code blocks display correctly
   - Lists and tables formatted

## 🎨 Customization

You can customize the wiki:

1. **Sidebar** - Create `_Sidebar.md`:
   ```markdown
   **Navigation**
   - [Home](Home)
   - [Installation](Installation-Guide)
   - [Security](Security-Setup)
   - [Troubleshooting](Troubleshooting)
   - [Contributing](Contributing)
   ```

2. **Footer** - Create `_Footer.md`:
   ```markdown
   © 2023-2025 NTFS Manager Project | [GitHub](https://github.com/sprinteroz/Linux-NTFS-Manager)
   ```

## 📊 Wiki Statistics

- **Total Pages:** 5
- **Total Content:** ~15,000 words
- **Sections Covered:**
  - Getting Started
  - User Guides
  - Security
  - Development
  - Support

## 🔄 Updating Wiki

To update wiki content:

1. **Edit locally:**
   - Modify files in `wiki-content/` directory
   - Test markdown rendering

2. **Push to wiki:**
   - Use Method 2 (git clone) above
   - Or manually copy/paste updated content

3. **Version control:**
   - Keep wiki-content in main repo
   - Wiki repository is separate

## 🆘 Need Help?

- [GitHub Wiki Documentation](https://docs.github.com/en/communities/documenting-your-project-with-wikis)
- [Markdown Guide](https://guides.github.com/features/mastering-markdown/)

---

**Ready to publish?**

1. Enable Wiki in repository settings
2. Go to Wiki tab
3. Create pages using the content from this directory
4. Verify all links work

Good luck! 🎉
