# NTFS Manager - Language Support

**Complete Multi-Language Support for 32 Languages**

---

## 🌍 Overview

NTFS Manager now supports **32 languages** with automatic language detection based on your system locale. This ensures users worldwide can use NTFS Manager in their native language.

## 📋 Supported Languages

### Core Languages (100% Complete)
1. **English (en)** - Base language
2. **Spanish (es)** - Español
3. **French (fr)** - Français
4. **German (de)** - Deutsch

### Additional Languages (Partial Translation)
5. **Chinese Simplified (zh)** - 简体中文
6. **Japanese (ja)** - 日本語
7. **Korean (ko)** - 한국어
8. **Russian (ru)** - Русский
9. **Italian (it)** - Italiano
10. **Portuguese (pt)** - Português
11. **Dutch (nl)** - Nederlands
12. **Polish (pl)** - Polski
13. **Turkish (tr)** - Türkçe
14. **Swedish (sv)** - Svenska
15. **Norwegian (no)** - Norsk
16. **Danish (da)** - Dansk
17. **Finnish (fi)** - Suomi
18. **Czech (cs)** - Čeština
19. **Greek (el)** - Ελληνικά
20. **Hebrew (he)** - עברית
21. **Arabic (ar)** - العربية
22. **Hindi (hi)** - हिन्दी
23. **Thai (th)** - ไทย
24. **Vietnamese (vi)** - Tiếng Việt
25. **Indonesian (id)** - Bahasa Indonesia
26. **Malay (ms)** - Bahasa Melayu
27. **Hungarian (hu)** - Magyar
28. **Romanian (ro)** - Română
29. **Ukrainian (uk)** - Українська
30. **Bulgarian (bg)** - Български
31. **Croatian (hr)** - Hrvatski
32. **Serbian (sr)** - Српски

---

## 📦 Installation

### Option 1: Install All Languages (Recommended)
```bash
cd Linux-NTFS-Manager
sudo ./language-packs/install-all-languages.sh
```

### Option 2: Install Single Language
```bash
cd Linux-NTFS-Manager
sudo ./language-packs/install-language.sh <language_code>

# Examples:
sudo ./language-packs/install-language.sh es  # Spanish
sudo ./language-packs/install-language.sh fr  # French
sudo ./language-packs/install-language.sh de  # German
sudo ./language-packs/install-language.sh zh  # Chinese
```

### Option 3: Download Language Pack
Download the pre-packaged language pack from GitHub releases:
```bash
wget https://github.com/sprinteroz/Linux-NTFS-Manager/releases/download/v1.0.1/NTFS-Manager-Language-Packs-v1.0.1.tar.gz
tar -xzf NTFS-Manager-Language-Packs-v1.0.1.tar.gz
cd NTFS-Manager-Language-Packs-v1.0.1
sudo ./language-packs/install-all-languages.sh
```

---

## 🚀 Usage

### Automatic Language Detection
NTFS Manager automatically detects your system language:
```bash
# Simply run NTFS Manager - it will use your system language
ntfs-manager
```

### Manual Language Selection
Override the automatic detection:
```bash
# Set language for session
LANG=es_ES.UTF-8 ntfs-manager  # Spanish
LANG=fr_FR.UTF-8 ntfs-manager  # French
LANG=de_DE.UTF-8 ntfs-manager  # German
LANG=zh_CN.UTF-8 ntfs-manager  # Chinese
LANG=ja_JP.UTF-8 ntfs-manager  # Japanese
LANG=ko_KR.UTF-8 ntfs-manager  # Korean
```

### Permanent Language Change
Set your preferred language permanently:
```bash
# Edit your shell profile (~/.bashrc, ~/.zshrc, etc.)
export LANG=es_ES.UTF-8

# Reload configuration
source ~/.bashrc
```

---

## 🛠️ For Developers

### Integration Example
```python
from backend.i18n import TranslationManager, _

# Initialize translation manager
translator = TranslationManager()

# Auto-detect system language
print(translator.current_language)  # e.g., 'es' for Spanish

# Translate strings
title = _('app_title')  # Returns translated app title
mount_btn = _('mount')  # Returns translated "Mount" button text

# With format arguments
message = _('mount_success', drive='sda1')  # "Drive sda1 mounted successfully"
```

### Adding New Translations
1. Edit the translation file: `translations/<lang_code>.json`
2. Add or modify translation strings
3. Test the translation
4. Submit a pull request

### Translation File Format
```json
{
  "_metadata": {
    "language_code": "es",
    "language_name": "Spanish",
    "version": "1.0.1",
    "translator": "Manual",
    "completeness": "100%"
  },
  "translations": {
    "app_title": "NTFS Complete Manager v2.0",
    "mount": "Montar",
    "unmount": "Desmontar"
  }
}
```

---

## 🧪 Testing

### Test Translation Loading
```bash
# Test i18n module
python3 ntfs-manager-production/backend/i18n.py

# Expected output:
# Current language: en (or your system language)
# Available languages: ['en', 'es', 'fr', 'de', ...]
# English translations:  
#   app_title: NTFS Complete Manager v2.0
#   mount: Mount
#   unmount: Unmount
```

### Verify Installation
```bash
# Check installed languages
ls -1 /usr/share/ntfs-manager/translations/

# Should show:
# ar.json
# bg.json
# ...
# zh.json
```

---

## 📊 Translation Coverage

| Language | Code | Coverage | Translator |
|----------|------|----------|------------|
| English | en | 100% | Manual |
| Spanish | es | 100% | Manual |
| French | fr | 100% | Manual |
| German | de | 100% | Manual |
| Chinese | zh | Partial | Auto |
| Japanese | ja | Partial | Auto |
| All Others | various | Partial | Auto |

---

## 🤝 Contributing Translations

We welcome translation improvements! Here's how to contribute:

1. **Fork the repository**
2. **Improve translations** in `translations/<lang_code>.json`
3. **Test your changes**
4. **Submit a pull request**

### Translation Guidelines
- Use formal language for professional contexts
- Keep technical terms in English when appropriate  
- Test on actual NTFS Manager interface
- Ensure UTF-8 encoding
- Follow existing format

### Priority Languages
We're actively seeking translators for:
- Chinese (Simplified & Traditional)
- Japanese
- Korean
- Russian
- Arabic
- Hindi

---

## 🐛 Troubleshooting

### Translations Not Loading
```bash
# Check if translations are installed
ls /usr/share/ntfs-manager/translations/

# If empty, run installer
sudo ./language-packs/install-all-languages.sh
```

### Wrong Language Displayed
```bash
# Check system locale
echo $LANG

# Set correct locale
export LANG=es_ES.UTF-8  # Change to your preferred language
```

### Missing Translations
Some strings may not be translated yet. They will display in English as fallback. This is normal for partially completed translations.

---

## 📝 Technical Details

### Architecture
- **Translation Format**: JSON files with UTF-8 encoding
- **Loading**: Automatic detection via system locale
- **Fallback**: English for untranslated strings
- **Module**: Python-based i18n manager
- **Location**: `/usr/share/ntfs-manager/translations/`

### Performance
- Translations loaded at startup (< 10ms)
- Minimal memory footprint (~50KB per language)
- No runtime performance impact

### Right-to-Left (RTL) Support
Languages like Arabic and Hebrew are supported with proper RTL text direction in GTK interface.

---

## 📞 Support

### Language Issues
- **Email**: sales@magdrivex.com.au
- **GitHub**: https://github.com/sprinteroz/Linux-NTFS-Manager/issues
- **Label**: Use `translation` label for language-related issues

### Request New Language
Open an issue on GitHub with:
- Language name and ISO code
- Your willingness to contribute/review translations
- Priority level for your use case

---

## 📄 License

Translations are part of NTFS Manager and follow the same license terms.

**Company**: MagDriveX  
**ABN**: 82 977 519 307  
**Version**: 1.0.1  
**Last Updated**: November 2025

---

*Making NTFS management accessible to users worldwide* 🌍
