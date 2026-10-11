// lib/services/localization_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../languages/localization/app_localizations.dart';

class LocalizationService {
  static const String _languageKey = 'languageCode';

  // ✅ Get saved language
  static Future<String> getSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey) ?? 'en';
    } catch (e) {
      return 'en';
    }
  }

  // ✅ Save language
  static Future<void> saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      print('❌ Error saving language: $e');
    }
  }

  // ✅ Get language by country code
  static String getLanguageByCountry(String countryCode) {
    final map = {
      'PK': 'ur',
      'IN': 'hi',
      'SA': 'ar',
      'ES': 'es',
      'FR': 'fr',
      'CN': 'zh',
      'TR': 'tr',
      'ID': 'id',
      'MY': 'ms',
    };
    return map[countryCode] ?? 'en';
  }

  // ✅ Get country by language code
  static String getCountryByLanguage(String languageCode) {
    final map = {
      'en': 'PK',
      'ur': 'PK',
      'hi': 'IN',
      'ar': 'SA',
      'es': 'ES',
      'fr': 'FR',
      'zh': 'CN',
      'tr': 'TR',
      'id': 'ID',
      'ms': 'MY',
    };
    return map[languageCode] ?? 'PK';
  }

  // ✅ Get language name in native language
  static String getLanguageName(String languageCode) {
    final map = {
      'en': 'English',
      'ur': 'اردو',
      'ar': 'العربية',
      'hi': 'हिन्दी',
      'es': 'Español',
      'fr': 'Français',
      'zh': '中文',
      'tr': 'Türkçe',
      'id': 'Bahasa Indonesia',
      'ms': 'Bahasa Melayu',
    };
    return map[languageCode] ?? languageCode;
  }

  // ✅ Get flag emoji
  static String getFlagEmoji(String languageCode) {
    final map = {
      'en': '🇬🇧',
      'ur': '🇵🇰',
      'ar': '🇸🇦',
      'hi': '🇮🇳',
      'es': '🇪🇸',
      'fr': '🇫🇷',
      'zh': '🇨🇳',
      'tr': '🇹🇷',
      'id': '🇮🇩',
      'ms': '🇲🇾',
    };
    return map[languageCode] ?? '🌍';
  }

  // ✅ Get all languages with details
  static List<Map<String, String>> getAllLanguages() {
    final languages = AppLocalizations.supportedLocales;
    return languages.map((locale) {
      final code = locale.languageCode;
      return {
        'code': code,
        'name': getLanguageName(code),
        'flag': getFlagEmoji(code),
        'countryCode': getCountryByLanguage(code),
      };
    }).toList();
  }
}