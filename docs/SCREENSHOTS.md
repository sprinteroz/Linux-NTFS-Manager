# Screenshot Creation Guide for Linux NTFS Manager

**Purpose:** Guidelines for creating effective promotional screenshots  
**Audience:** Developers, contributors, community managers  
**Last Updated:** November 2025

---

## 📸 Why Screenshots Matter

Good screenshots:
- Show the problem AND the solution
- Build trust through transparency
- Help users decide before installing
- Increase engagement in forum posts
- Make GitHub README more compelling

**Bad screenshots lose users. Good screenshots convert them.**

---

## 🎯 Screenshot Types Needed

### 1. Hero Screenshot (Primary)
**Purpose:** First impression on GitHub README  
**Shows:** Main window with clean, professional appearance  
**Use:** GitHub README, blog posts, social media

### 2. Problem Detection Screenshot
**Purpose:** Shows the tool identifying an issue  
**Shows:** Dialog explaining WHY drive is read-only  
**Use:** Forum posts, tutorials, educational content

### 3. Before/After Comparison
**Purpose:** Demonstrates the solution working  
**Shows:** Read-only error → Fixed drive  
**Use:** Promotional material, success stories

### 4. Educational Dialog Screenshot
**Purpose:** Shows the teaching aspect  
**Shows:** Detailed explanation of Windows Fast Startup  
**Use:** Highlighting educational features

### 5. Multi-Language Screenshot
**Purpose:** Demonstrates international support  
**Shows:** Same feature in different languages  
**Use:** Showing 32-language support

---

## 🖼️ Screenshot Standards

### Resolution & Format
- **Minimum Resolution:** 1920x1080 (Full HD)
- **Recommended Resolution:** 2560x1440 (2K) for Retina displays
- **File Format:** PNG (lossless, transparent if needed)
- **File Size:** Under 500KB per image (use compression)
- **Aspect Ratio:** 16:9 preferred

### Visual Quality
- **DPI:** 144 minimum, 192 preferred
- **Color Depth:** 24-bit minimum
- **Compression:** PNG-8 for simple images, PNG-24 for gradients
- **Anti-Aliasing:** Enabled for smooth text

---

## 🎨 Aesthetic Guidelines

### Clean Desktop
- **Wallpaper:** Neutral, professional background (solid color or subtle pattern)
- **Desktop Icons:** Minimal or none
- **Panel/Taskbar:** Clean, organized, default theme preferred
- **Open Windows:** Only NTFS Manager (close everything else)

### Window Appearance
- **Theme:** Use default or popular theme (Adwaita, Breeze, Arc)
- **Window Decorations:** Keep default (don't use custom borders)
- **Font Rendering:** Clear, readable system fonts
- **Shadows:** Natural, not disabled

### Content
- **Test Data:** Use realistic but generic examples
- **Drive Names:** "External Drive", "Windows Partition" (not "Bob's Stuff")
- **File Paths:** `/media/user/Data` (not personal paths)
- **Timestamps:** Recent but not specific personal dates

---

##  Screenshot Scenarios

### Scenario 1: "The Discovery"
**Goal:** Show user encountering read-only issue

**Setup:**
1. Have an NTFS drive mounted read-only
2. Open file manager showing the drive
3. Attempt to copy a file (show permission denied dialog)
4. Capture the frustration moment

**Screenshot Elements:**
- File manager window
- Permission denied error
- NTFS drive visible in sidebar
- Mouse cursor hovering over "Copy" action

**Caption:** "The problem: NTFS drive suddenly read-only after using Windows"

---

### Scenario 2: "The Explanation"
**Goal:** Show Linux NTFS Manager explaining the issue

**Setup:**
1. Open Linux NTFS Manager
2. Select the problematic drive
3. Trigger the "Why is this read-only?" dialog
4. Capture the educational explanation

**Screenshot Elements:**
- Main NTFS Manager window
- Info dialog explaining Windows Fast Startup
- Dirty bit status visible
- Clear, readable text

**Caption:** "NTFS Manager explains WHY it's read-only, not just HOW to fix it"

---

### Scenario 3: "The Fix"
**Goal:** Show the one-click solution

**Setup:**
1. Show NTFS Manager with "Fix Drive" button visible
2. Capture mid-fix (progress dialog)
3. Show success dialog
4. Show drive now writable

**Screenshot Elements:**
- Fix button prominently displayed
- Progress indicator (if using)
- Success confirmation
- Before/after status comparison

**Caption:** "One click safely removes the Windows hibernation flag"

---

### Scenario 4: "The Result"
**Goal:** Prove it works

**Setup:**
1. Open file manager again
2. Successfully copy file to previously read-only drive
3. Show write permissions restored
4. Capture successful operation

**Screenshot Elements:**
- File being copied successfully
- Drive showing as writable
- No error dialogs
- Happy path workflow

**Caption:** "Fixed! Drive now writable, no data loss, no force-mounting"

---

## 🔧 Technical Setup

### Recommended Tools

**Screenshot Capture:**
- **Linux:** GNOME Screenshot, Flameshot, Spectacle
- **Command:** `gnome-screenshot --window` or `flameshot gui`
- **Area Selection:** Use Flameshot for annotated screenshots

**Image Editing:**
- **GIMP:** Professional editing, resizing, effects
- **Krita:** Digital painting and touch-ups
- **ImageMagick:** Batch processing, command-line edits
- **Pinta:** Simple quick edits

**Compression:**
- **pngquant:** Lossy PNG compression
- **OptiPNG:** Lossless PNG optimization
- **TinyPNG:** Online compression service

### Capture Commands

```bash
# Capture entire screen
gnome-screenshot

# Capture active window
gnome-screenshot --window

# Capture selection with delay
gnome-screenshot --area --delay=3

# Flameshot (interactive)
flameshot gui

# Spectacle (KDE)
spectacle --region
```

### Post-Processing

```bash
# Resize to 1920x1080
convert input.png -resize 1920x1080 output.png

# Compress PNG
pngquant --quality=65-80 input.png -o output.png

# Add border
convert input.png -border 2 -bordercolor black output.png

# Add shadow
convert input.png \( +clone -background black -shadow 80x3+5+5 \) +swap -background none -layers merge +repage output.png
```

---

## 📐 Screenshot Composition

### Rule of Thirds
- Position key elements at intersection points
- Don't center everything
- Create visual balance

### Focal Points
- User's eye should land on the most important element first
- Use contrast to highlight key areas
- Avoid clutter in focal zones

### Whitespace
- Don't fill every pixel
- Let the interface breathe
- Guide eye movement with empty space

### Color Theory
- Use neutral backgrounds (grays, whites)
- Let the application colors stand out
- Avoid competing color schemes

---

## 🖼️ Screenshot Checklist

Before finalizing screenshots:

**Technical:**
- [ ] Resolution is 1920x1080 or higher
- [ ] File format is PNG
- [ ] File size is under 500KB
- [ ] No personal information visible
- [ ] No copyrighted content in background
- [ ] System time/date is generic or removed

**Visual:**
- [ ] Desktop is clean and professional
- [ ] Theme is standard/popular
- [ ] Text is readable at all sizes
- [ ] Colors are accurate and vibrant
- [ ] No visual artifacts or compression issues
- [ ] Window is fully visible (not cut off)

**Content:**
- [ ] Shows actual functionality (not mockup)
- [ ] Demonstrates clear value
- [ ] Free of distracting elements
- [ ] Uses realistic but generic data
- [ ] No offensive or inappropriate content
- [ ] Represents current version

**Purpose:**
- [ ] Serves specific promotional goal
- [ ] Has clear caption/description planned
- [ ] Fits platform requirements (GitHub, Reddit, etc.)
- [ ] Tells part of the story
- [ ] Can stand alone OR works in sequence

---

## 🎬 Creating Screenshot Series

### The Journey Series (4 screenshots)

**1. The Problem**
- Drive showing read-only
- Permission denied error
- User frustration visible

**2. The Discovery**
- Finding Linux NTFS Manager
- Clean, professional interface
- Promise of solution

**3. The Understanding**
- Educational dialog open
- Clear explanation visible
- "Aha!" moment captured

**4. The Resolution**
- Drive now writable
- Successful file operation
- Problem solved

**Use:** README, blog posts, tutorials

---

### The Feature Showcase Series (6 screenshots)

**1. Main Interface**
- All drives listed
- Status indicators
- Action buttons

**2. Drive Information**
- Detailed drive properties
- Health status
- Partition info

**3. NTFS Fixing Dialog**
- Dirty bit detection
- Explanation text
- Fix button

**4. Multi-Language**
- Same feature in 2-3 languages
- Demonstrates localization
- Global appeal

**5. Nautilus Integration**
- Right-click context menu
- Seamless integration
- Workflow enhancement

**6. Settings/Preferences**
- Configuration options
- User control
- Professional features

**Use:** Documentation, feature comparison

---

### The Comparison Series (2 screenshots)

**Before:**
- Terminal output: `mount: ... read-only file system`
- Error messages
- Confusion

**After:**
- Clean GUI explanation
- One-click fix
- Success state

**Use:** Homepage, promotional material

---

## 📱 Platform-Specific Guidelines

### GitHub README
- **Hero Image:** 1200x630 (Open Graph)
- **Inline Images:** 800-1000px wide
- **GIFs:** Max 5MB, under 10 seconds
- **Format:** PNG preferred over JPG
- **Quantity:** 3-5 screenshots maximum

### Reddit Posts
- **Thumbnail:** 1200x1200 (square)
- **Post Images:** 1920x1080
- **Gallery:** 2-5 images max
- **File Size:** Under 20MB total
- **Format:** PNG or JPG

### Dev.to / Blog Posts
- **Hero Image:** 1000x420
- **Inline Screenshots:** 800px wide
- **GIFs:** Highly encouraged
- **Alt Text:** Always include descriptions
- **Format:** WebP or PNG

### Hacker News
- **No Images:** HN doesn't display images
- **Link:** Can link to imgur album
- **Demo Site:** Host interactive demo instead
- **Fall Back:** Detailed text description

### Twitter/X
- **Single Image:** 1200x675
- **Multiple Images:** 1200x600 each
- **GIF:** Max 15MB, 512x accelerated
- **Text Overlay:** Large, readable text
- **Format:** PNG or GIF

---

## 🎥 Creating GIFs & Videos

### When to Use GIFs
- Showing a complete workflow (5-10 seconds)
- Demonstrating smooth UX
- One-click solutions
- Before/after transitions

### GIF Creation Tools
- **Peek:** Simple screen recorder for Linux
- **Gifcurry:** Video to GIF converter
- **Gifsicle:** GIF optimization
- **FFmpeg:** Command-line conversion

### GIF Best Practices
- **Duration:** 3-10 seconds
- **FPS:** 15-24 (30 for smooth animations)
- **Loop:** Always loop seamlessly
- **File Size:** Under 5MB
- **Resolution:** 800x600 to 1280x720

### Recording Commands

```bash
# Record with Peek (GUI)
peek

# Record with FFmpeg
ffmpeg -video_size 1920x1080 -framerate 30 -f x11grab -i :0.0 output.mp4

# Convert video to GIF
ffmpeg -i input.mp4 -vf "fps=15,scale=800:-1:flags=lanczos" output.gif

# Optimize GIF
gifsicle -O3 --colors 256 input.gif -o output.gif
```

---

## 🔍 Screenshot Don'ts

### ❌ Never Include:
- Personal information (names, emails, addresses)
- Proprietary/copyrighted content
- Offensive or inappropriate material
- Competitor products (unless fair comparison)
- Real user data
- Development/debug information
- Error logs with sensitive paths
- IP addresses or network info
- API keys or tokens
- Personal wallpapers with faces

### ❌ Avoid:
- Cluttered desktops
- Multiple notification popups
- Inconsistent themes
- Low resolution or blurry captures
- Dark mode (hard to print/view)
- Unusual window managers
- Custom fonts  (hard to read)
- Bright, distracting wallpapers
- Watermarks (unless branding)

---

## 📊 Screenshot Metrics

### Measuring Effectiveness

**GitHub:**
- README scroll depth (users who scroll past screenshot)
- Star conversion rate after viewing
- Click-through to releases

**Reddit:**
- Upvote ratio
- Comments mentioning screenshot quality
- Image click-through rate

**Blogs:**
- Time on page
- Screenshot click-to-enlarge rate
- Share rate of posts with screenshots

### A/B Testing
- Try different hero images
- Test with/without annotations
- Compare real UI vs. mockups
- Measure dark vs. light theme

---

## 📝 Captions & Alt Text

### Writing Effective Captions

**Good Caption:**
> "Linux NTFS Manager explains WHY your drive is read-only (Windows Fast Startup hibernation) before showing you how to fix it safely."

**Bad Caption:**
> "Screenshot of the app"

### Caption Formula:
1. What's shown: "Main window showing..."
2. Key benefit: "...detecting NTFS issues"
3. Action: "...with one-click fix"

### Alt Text for Accessibility

**Purpose:** Describe image for screen readers

**Format:**
```html
<img src="screenshot.png" alt="Linux NTFS Manager main window displaying a list of NTFS drives with their mount status. The selected drive shows a 'Dirty Bit Detected' warning and displays an informational dialog explaining Windows Fast Startup causes this issue. A blue 'Fix Drive' button is prominently displayed.">
```

**Guidelines:**
- Be descriptive but concise
- Include key UI elements
- Describe functionality shown
- Don't start with "Image of..." or "Screenshot of..."

---

## 🎨 Branding & Watermarks

### When to Watermark
- ✅ High-quality promotional images
- ✅ Images you want others to share
- ✅ Official press kit materials
- ❌ Documentation screenshots
- ❌ Bug reports
- ❌ Technical tutorials

### Watermark Placement
- Bottom right corner: 10% opacity
- Subtle, not distracting
- Just logo or " NTFS Manager"
- Never covers important UI elements

### Watermark Example
```bash
# Add subtle watermark
composite -dissolve 10 -gravity SouthEast watermark.png screenshot.png output.png
```

---

## 📦 Screenshot Organization

### File Naming Convention
```
ntfs-manager-[type]-[feature]-[version].png
```

**Examples:**
- `ntfs-manager-hero-main-window-v1.0.3.png`
- `ntfs-manager-feature-dirty-bit-detection-v1.0.3.png`
- `ntfs-manager-tutorial-fixing-drive-step1-v1.0.3.png`
- `ntfs-manager-comparison-before-after.png`

### Directory Structure
```
screenshots/
├── promotional/
│   ├── hero/
│   ├── social-media/
│   └── comparison/
├── documentation/
│   ├── installation/
│   ├── usage/
│   └── troubleshooting/
├── press-kit/
│   ├── high-res/
│   └── thumbnails/
└── archive/
    └── old-versions/
```

---

## 🚀 Quick Start Checklist

**For Your First Promotional Screenshot:**

1. [ ] Clean your desktop
2. [ ] Set neutral wallpaper
3. [ ] Use standard theme
4. [ ] Close all other applications
5. [ ] Open Linux NTFS Manager
6. [ ] Position window centered
7. [ ] Ensure window is fully visible
8. [ ] Wait for window animations to complete
9. [ ] Take screenshot (gnome-screenshot --window)
10. [ ] Review for personal information
11. [ ] Resize to 1920x1080 if needed
12. [ ] Compress with pngquant
13. [ ] Add to GitHub README
14. [ ] Write descriptive alt text
15. [ ] Get feedback before publishing

---

## 📚 Additional Resources

### Inspiration
- **Awesome Screenshots:** Look at popular FOSS projects
- **Dribble:** UI/UX design inspiration
- **GitHub Stars:** Top repos with great screenshots

### Learning
- **GIMP Tutorials:** Image editing skills
- **Color Theory:** Understanding visual impact
- **UX Design:** Creating clear interfaces

### Tools List
- **Capture:** Flameshot, Spectacle, GNOME Screenshot
- **Edit:** GIMP, Krita, Inkscape
- **Optimize:** pngquant, OptiPNG, ImageMagick
- **GIF:** Peek, gifsicle, FFmpeg
- **Mockup:** Figma, Lunacy (for polished presentations)

---

## Remember

**Screenshots are your first impression.**

- Show, don't just tell
- Quality over quantity
- Keep them current (update with new versions)
- Test on different screens (mobile, desktop, Retina)
- Get feedback from community
- Iterate and improve

**Great screenshots make users say:** 
> "I understand what this does and I want to try it."

**Bad screenshots make users say:**
> "I don't get it. Next."

Take the time to get screenshots right. They're worth it.

---

**Questions or need help creating screenshots?**  
Open a discussion: https://github.com/sprinteroz/Linux-NTFS-Manager/discussions
