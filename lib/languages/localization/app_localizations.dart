// lib/languages/localization/app_localizations.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  // ✅ Helper to load language
  static Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations._loadLanguage();
    return localizations;
  }

  // ✅ Load language JSON
  Future<void> _loadLanguage() async {
    try {
      String jsonString = await rootBundle.loadString(
        'language/translation/${locale.languageCode}.json',
      );
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      // ✅ Fallback to English
      String jsonString = await rootBundle.loadString(
        'language/translation/en.json',
      );
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    }
  }

  // ✅ Get translated string
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // ✅ Static method for MaterialApp
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // ✅ Delegate
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // ✅ Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('ur'), // Urdu
    Locale('ar'), // Arabic
    Locale('hi'), // Hindi
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('zh'), // Chinese
    Locale('tr'), // Turkish
    Locale('id'), // Indonesian
    Locale('ms'), // Malay
  ];

  // ✅ Get country code from locale
  static String getCountryCode(String languageCode) {
    final map = {
      'en': 'PK',
      'ur': 'PK',
      'ar': 'SA',
      'hi': 'IN',
      'es': 'ES',
      'fr': 'FR',
      'zh': 'CN',
      'tr': 'TR',
      'id': 'ID',
      'ms': 'MY',
    };
    return map[languageCode] ?? 'PK';
  }
}

// ============================================================
// ✅ LOCALIZATION DELEGATE
// ============================================================
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
          (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return await AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}

// ============================================================
// ✅ EXTENSION FOR EASY ACCESS
// ============================================================
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  String tr(String key) => AppLocalizations.of(this)?.translate(key) ?? key;
}