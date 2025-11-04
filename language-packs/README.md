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

