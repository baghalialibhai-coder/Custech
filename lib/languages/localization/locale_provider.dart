// lib/languages/localization/locale_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

// ✅ State for locale
class LocaleState {
  final Locale locale;

  LocaleState(this.locale);

  LocaleState copyWith(Locale newLocale) {
    return LocaleState(newLocale);
  }
}

// ✅ Provider for locale state
final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleState>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<LocaleState> {
  LocaleNotifier() : super(LocaleState(const Locale('en'))) {
    _loadSavedLocale();
  }

  // ✅ Load saved locale
  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('languageCode') ?? 'en';

      // ✅ Check if language is supported
      final isSupported = AppLocalizations.supportedLocales.any(
            (locale) => locale.languageCode == languageCode,
      );

      if (isSupported) {
        state = LocaleState(Locale(languageCode));
      } else {
        state = LocaleState(const Locale('en'));
      }
    } catch (e) {
      state = LocaleState(const Locale('en'));
    }
  }

  // ✅ Set locale and save
  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', locale.languageCode);
      state = LocaleState(locale);
    } catch (e) {
      state = LocaleState(locale);
    }
  }

  // ✅ Get current locale
  Locale get currentLocale => state.locale;
}

// ✅ Provider for locale (read only)
final currentLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(localeProvider).locale;
});