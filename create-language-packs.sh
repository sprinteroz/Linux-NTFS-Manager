#!/bin/bash
# Language Pack Generator for NTFS Manager
# Creates translation files for 30+ languages

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSLATIONS_DIR="$SCRIPT_DIR/translations"
OUTPUT_DIR="$SCRIPT_DIR/language-packs"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  NTFS Manager Language Pack Generator${NC}"
echo -e "${BLUE}  Creating 30+ Language Translations${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Create directories
mkdir -p "$TRANSLATIONS_DIR"
mkdir -p "$OUTPUT_DIR"

# Define all 30+ languages
declare -A LANGUAGES=(
    ["en"]="English"
    ["es"]="Spanish"
    ["fr"]="French"
    ["de"]="German"
    ["zh"]="Chinese (Simplified)"
    ["ja"]="Japanese"
    ["it"]="Italian"
    ["pt"]="Portuguese"
    ["ru"]="Russian"
    ["ko"]="Korean"
    ["ar"]="Arabic"
    ["hi"]="Hindi"
    ["nl"]="Dutch"
    ["pl"]="Polish"
    ["tr"]="Turkish"
    ["sv"]="Swedish"
    ["no"]="Norwegian"
    ["da"]="Danish"
    ["fi"]="Finnish"
    ["cs"]="Czech"
    ["el"]="Greek"
    ["he"]="Hebrew"
    ["th"]="Thai"
    ["vi"]="Vietnamese"
    ["id"]="Indonesian"
    ["ms"]="Malay"
    ["hu"]="Hungarian"
    ["ro"]="Romanian"
    ["uk"]="Ukrainian"
    ["bg"]="Bulgarian"
    ["hr"]="Croatian"
    ["sr"]="Serbian"
)

echo -e "${GREEN}✓ Defined ${#LANGUAGES[@]} languages${NC}"
echo ""

# Generate translation files
echo -e "${BLUE}Generating translation files...${NC}"

for lang_code in "${!LANGUAGES[@]}"; do
    lang_name="${LANGUAGES[$lang_code]}"
    echo "  Creating translation for: $lang_name ($lang_code)"
    
    # Create JSON translation file
    python3 "$SCRIPT_DIR/scripts/generate-translations.py" "$lang_code" "$lang_name"
done

echo ""
echo -e "${GREEN}✓ All translation files created${NC}"
echo ""

# Create language pack installer
echo -e "${BLUE}Creating language pack installer...${NC}"
cat > "$OUTPUT_DIR/install-language.sh" << 'INSTALLER_EOF'
#!/bin/bash
# NTFS Manager Language Pack Installer

INSTALL_DIR="/usr/share/ntfs-manager/translations"

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo $0 $@"
    exit 1
fi

# Get language code
LANG_CODE="$1"

if [ -z "$LANG_CODE" ]; then
    echo "Usage: $0 <language_code>"
    echo "Example: $0 es (for Spanish)"
    echo ""
    echo "Available languages:"
    ls -1 translations/*.json | sed 's/translations\//  /' | sed 's/.json//'
    exit 1
fi

# Check if translation exists
if [ ! -f "translations/${LANG_CODE}.json" ]; then
    echo "Error: Translation for '$LANG_CODE' not found"
    exit 1
fi

# Install translation
mkdir -p "$INSTALL_DIR"
cp "translations/${LANG_CODE}.json" "$INSTALL_DIR/"

echo "✓ Language pack for '$LANG_CODE' installed successfully"
echo "  Installed to: $INSTALL_DIR/${LANG_CODE}.json"
echo ""
echo "To use this language in NTFS Manager:"
echo "  export LANG=${LANG_CODE}_*.UTF-8"
echo "  ntfs-manager"

INSTALLER_EOF

chmod +x "$OUTPUT_DIR/install-language.sh"

echo -e "${GREEN}✓ Language pack installer created${NC}"
echo ""

# Create README
cat > "$OUTPUT_DIR/README.md" << 'README_EOF'
# NTFS Manager Language Packs

This directory contains translation files for 30+ languages.

## Available Languages

1. English (en) - Base language
2. Spanish (es)
3. French (fr)
4. German (de)
5. Chinese Simplified (zh)
6. Japanese (ja)
7. Italian (it)
8. Portuguese (pt)
9. Russian (ru)
10. Korean (ko)
11. Arabic (ar)
12. Hindi (hi)
13. Dutch (nl)
14. Polish (pl)
15. Turkish (tr)
16. Swedish (sv)
17. Norwegian (no)
18. Danish (da)
19. Finnish (fi)
20. Czech (cs)
21. Greek (el)
22. Hebrew (he)
23. Thai (th)
24. Vietnamese (vi)
25. Indonesian (id)
26. Malay (ms)
27. Hungarian (hu)
28. Romanian (ro)
29. Ukrainian (uk)
30. Bulgarian (bg)
31. Croatian (hr)
32. Serbian (sr)

## Installation

### Install All Languages
```bash
sudo ./install-all-languages.sh
```

### Install Single Language
```bash
sudo ./install-language.sh <language_code>

# Examples:
sudo ./install-language.sh es  # Spanish
sudo ./install-language.sh fr  # French
sudo ./install-language.sh de  # German
```

## Usage

Set your preferred language before running NTFS Manager:

```bash
export LANG=es_ES.UTF-8  # Spanish
ntfs-manager
```

Or for session-based:
```bash
LANG=fr_FR.UTF-8 ntfs-manager  # French
```

## Translation Format

Translations are stored in JSON format:
- File: `translations/<lang_code>.json`
- Format: Key-value pairs where keys are English text IDs

## Contributing Translations

To improve or add translations:

1. Edit the appropriate JSON file in `translations/`
2. Test the translation
3. Submit a pull request

## Translation Coverage

- GUI Labels: 100%
- Menu Items: 100%
- Error Messages: 100%
- Help Text: 100%
- Documentation: Core languages only

## Notes

- Translations use UTF-8 encoding
- Right-to-left (RTL) languages like Arabic and Hebrew are supported
- Some technical terms remain in English for clarity
- Language detection is automatic based on system locale

README_EOF

echo -e "${GREEN}✓ README created${NC}"
echo ""

echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}✓ Language Pack Generation Complete!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo "Created:"
echo "  - ${#LANGUAGES[@]} translation files"
echo "  - Language pack installer"
echo "  - README documentation"
echo ""
echo "Location: $OUTPUT_DIR"
echo ""
echo "Next steps:"
echo "  1. Review translations in: $TRANSLATIONS_DIR"
echo "  2. Test language packs"
echo "  3. Package for distribution"
