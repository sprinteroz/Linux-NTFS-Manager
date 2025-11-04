#!/usr/bin/env python3
"""
Internationalization (i18n) module for NTFS Manager
Provides translation support for 30+ languages
"""

import json
import os
import locale
from pathlib import Path
from typing import Dict, Optional

class TranslationManager:
    """Manages translations for the NTFS Manager application"""
    
    def __init__(self, translation_dir: Optional[str] = None):
        """
        Initialize the translation manager
        
        Args:
            translation_dir: Directory containing translation JSON files
                           If None, uses default locations
        """
        self.translations: Dict[str, str] = {}
        self.current_language = "en"
        self.fallback_language = "en"
        
        # Determine translation directory
        if translation_dir:
            self.translation_dir = Path(translation_dir)
        else:
            # Try multiple locations
            possible_dirs = [
                Path("/usr/share/ntfs-manager/translations"),
                Path.home() / ".local/share/ntfs-manager/translations",
                Path(__file__).parent.parent.parent / "translations",
            ]
            
            self.translation_dir = None
            for dir_path in possible_dirs:
                if dir_path.exists():
                    self.translation_dir = dir_path
                    break
            
            if not self.translation_dir:
                # Use first path as default
                self.translation_dir = possible_dirs[0]
        
        # Auto-detect system language
        self._detect_system_language()
        
        # Load translations
        self._load_translations()
    
    def _detect_system_language(self):
        """Auto-detect system language from locale"""
        try:
            # Get system locale
            system_locale = locale.getdefaultlocale()[0]
            
            if system_locale:
                # Extract language code (e.g., 'en_US' -> 'en')
                lang_code = system_locale.split('_')[0].lower()
                self.set_language(lang_code)
            else:
                self.current_language = "en"
        except Exception:
            self.current_language = "en"
    
    def _load_translations(self):
        """Load translations for current language"""
        translation_file = self.translation_dir / f"{self.current_language}.json"
        
        if not translation_file.exists():
            # Fallback to English
            translation_file = self.translation_dir / f"{self.fallback_language}.json"
        
        if translation_file.exists():
            try:
                with open(translation_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    self.translations = data.get('translations', {})
            except Exception as e:
                print(f"Error loading translations: {e}")
                self.translations = {}
        else:
            print(f"Translation file not found: {translation_file}")
            self.translations = {}
    
    def set_language(self, lang_code: str):
        """
        Set the current language
        
        Args:
            lang_code: ISO 639-1 language code (e.g., 'en', 'es', 'fr')
        """
        if lang_code != self.current_language:
            self.current_language = lang_code
            self._load_translations()
    
    def get_available_languages(self) -> Dict[str, str]:
        """
        Get list of available languages
        
        Returns:
            Dictionary mapping language codes to language names
        """
        languages = {}
        
        if not self.translation_dir.exists():
            return {"en": "English"}
        
        for translation_file in self.translation_dir.glob("*.json"):
            try:
                with open(translation_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    metadata = data.get('_metadata', {})
                    lang_code = metadata.get('language_code', translation_file.stem)
                    lang_name = metadata.get('language_name', lang_code)
                    languages[lang_code] = lang_name
            except Exception:
                continue
        
        return languages
    
    def translate(self, key: str, **kwargs) -> str:
        """
        Get translated string for a key
        
        Args:
            key: Translation key
            **kwargs: Format arguments for string formatting
        
        Returns:
            Translated string, or the key itself if not found
        """
        translated = self.translations.get(key, key)
        
        # Apply string formatting if arguments provided
        if kwargs:
            try:
                translated = translated.format(**kwargs)
            except KeyError:
                pass  # Some format keys might not be provided
        
        return translated
    
    def _(self, key: str, **kwargs) -> str:
        """
        Shorthand for translate()
        
        Args:
            key: Translation key
            **kwargs: Format arguments
        
        Returns:
            Translated string
        """
        return self.translate(key, **kwargs)

# Global translation manager instance
_translation_manager = None

def get_translation_manager() -> TranslationManager:
    """Get the global translation manager instance"""
    global _translation_manager
    if _translation_manager is None:
        _translation_manager = TranslationManager()
    return _translation_manager

def set_language(lang_code: str):
    """Set the global language"""
    manager = get_translation_manager()
    manager.set_language(lang_code)

def translate(key: str, **kwargs) -> str:
    """Translate a string using the global translation manager"""
    manager = get_translation_manager()
    return manager.translate(key, **kwargs)

# Convenience alias
_ = translate

# Example usage:
if __name__ == "__main__":
    # Test translation manager
    manager = TranslationManager()
    
    print(f"Current language: {manager.current_language}")
    print(f"Available languages: {list(manager.get_available_languages().keys())}")
    print()
    
    # Test translations
    print("English translations:")
    manager.set_language("en")
    print(f"  app_title: {manager._('app_title')}")
    print(f"  mount: {manager._('mount')}")
    print(f"  unmount: {manager._('unmount')}")
    print()
    
    print("Spanish translations:")
    manager.set_language("es")
    print(f"  app_title: {manager._('app_title')}")
    print(f"  mount: {manager._('mount')}")
    print(f"  unmount: {manager._('unmount')}")
    print()
    
    print("French translations:")
    manager.set_language("fr")
    print(f"  app_title: {manager._('app_title')}")
    print(f"  mount: {manager._('mount')}")
    print(f"  unmount: {manager._('unmount')}")
