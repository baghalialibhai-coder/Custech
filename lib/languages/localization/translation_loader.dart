import 'dart:convert';
import 'package:flutter/services.dart';

class TranslationLoader {
  static Map<String, Map<String, String>> _translations = {};

  static Future<void> loadTranslations() async {
    final languages = ['en', 'ur', 'ar', 'hi', 'es', 'fr', 'zh', 'tr', 'id', 'ms'];

    for (var lang in languages) {
      try {
        final jsonString = await rootBundle.loadString(
          'assets/translations/$lang.json',
        );
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _translations[lang] = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      } catch (e) {
        print('Error loading $lang translations: $e');
        // Fallback to empty map
        _translations[lang] = {};
      }
    }
  }

  static Map<String, String> getTranslations(String languageCode) {
    return _translations[languageCode] ?? _translations['en'] ?? {};
  }

  static String translate(String key, String languageCode) {
    final translations = getTranslations(languageCode);
    return translations[key] ?? key; // Fallback to key if not found
  }

  static List<String> getSupportedLanguages() {
    return _translations.keys.toList();
  }

  static Map<String, String> getLanguageNames() {
    return {
      'en': 'English 🇺🇸',
      'ur': 'اردو 🇵🇰',
      'ar': 'العربية 🇸🇦',
      'hi': 'हिन्दी 🇮🇳',
      'es': 'Español 🇪🇸',
      'fr': 'Français 🇫🇷',
      'zh': '中文 🇨🇳',
      'tr': 'Türkçe 🇹🇷',
      'id': 'Bahasa Indonesia 🇮🇩',
      'ms': 'Bahasa Melayu 🇲🇾',
    };
  }
}