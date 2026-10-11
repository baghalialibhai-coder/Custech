// lib/Presentations/Auth_Screens/language_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../languages/localization/app_localizations.dart';
import '../../languages/localization/locale_provider.dart';
import '../../services/localization_service.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  final VoidCallback? onLanguageSelected;

  const LanguageSelectionScreen({
    super.key,
    this.onLanguageSelected,
  });

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  String _selectedCode = 'en';

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final code = await LocalizationService.getSavedLanguage();
    setState(() {
      _selectedCode = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languages = LocalizationService.getAllLanguages();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Select Language',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];
          final isSelected = lang['code'] == _selectedCode;

          return Card(
            elevation: isSelected ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? Colors.green[700]! : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              leading: Text(
                lang['flag'] ?? '🌍',
                style: const TextStyle(fontSize: 28),
              ),
              title: Text(
                lang['name'] ?? lang['code'] ?? 'Unknown',
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.green[700] : Colors.black87,
                ),
              ),
              subtitle: Text(
                '${lang['code']?.toUpperCase()} - ${lang['countryCode']}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              trailing: isSelected
                  ? Icon(
                Icons.check_circle,
                color: Colors.green[700],
              )
                  : null,
              onTap: () => _selectLanguage(lang['code']!),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectLanguage(String languageCode) async {
    final locale = Locale(languageCode);

    // ✅ Update provider
    ref.read(localeProvider.notifier).setLocale(locale);

    // ✅ Save to shared preferences
    await LocalizationService.saveLanguage(languageCode);

    setState(() {
      _selectedCode = languageCode;
    });

    // ✅ Callback if provided
    widget.onLanguageSelected?.call();

    // ✅ Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Language changed to ${LocalizationService.getLanguageName(languageCode)}',
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}