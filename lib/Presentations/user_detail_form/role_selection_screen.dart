// lib/Presentations/user_detail_form/role_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Auth_Screens/Auth/Widget/custom_button.dart';
import 'user_info.dart';
import 'merchant_info_screen.dart';
import '../../Merchants_Screen/merchant_dashboard.dart';
import '../../languages/localization/app_localizations.dart';
import '../../languages/widget/language_selection_screen.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // ✅ Get translations
    final chooseRole = context.tr('chooseYourRole');
    final selectHowToUse = context.tr('selectHowToUse');
    final roleSelectError = context.tr('roleSelectError');
    final customer = context.tr('customer');
    final technician = context.tr('technician');
    final customerDesc = context.tr('customerDesc');
    final technicianDesc = context.tr('technicianDesc');
    final continueText = context.tr('continue');
    final pleaseSelectRole = context.tr('pleaseSelectRole');

    // Merchant translations for 10 languages
    final languageCode = Localizations.localeOf(context).languageCode;

    final Map<String, String> merchantTitleTranslations = {
      'en': "Shop / Store Owner (Merchant)",
      'ur': "دکان / اسٹور کا مالک (مرچنٹ)",
      'ar': "صاحب متجر / دكان (تاجر)",
      'hi': "दुकान / स्टोर मालिक (व्यापारी)",
      'es': "Propietario de Tienda (Comerciante)",
      'fr': "Propriétaire de Magasin (Commerçant)",
      'zh': "商店/店铺所有者（商家）",
      'tr': "Mağaza Sahibi (Tüccar)",
      'id': "Pemilik Toko / Warung (Pedagang)",
      'ms': "Pemilik Kedai / Stor (Peniaga)",
    };

    final Map<String, String> merchantDescTranslations = {
      'en': "Supplier of parts or local store owner",
      'ur': "پرزوں کا سپلائر یا مقامی اسٹور کا مالک",
      'ar': "مورد قطع غيار أو صاحب متجر محلي",
      'hi': "पुर्जों के आपूर्तिकर्ता या स्थानीय दुकान के मालिक",
      'es': "Proveedor de repuestos o propietario de tienda local",
      'fr': "Fournisseur de pièces ou propriétaire de magasin local",
      'zh': "零件供应商或当地店主",
      'tr': "Parça tedarikçisi veya yerel mağaza sahibi",
      'id': "Pemasok suku cadang atau pemilik toko lokal",
      'ms': "Pembekal alat ganti atau pemilik kedai tempatan",
    };

    final String merchantTitle = merchantTitleTranslations[languageCode] ?? merchantTitleTranslations['en']!;
    final String merchantDesc = merchantDescTranslations[languageCode] ?? merchantDescTranslations['en']!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          chooseRole,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          // ✅ Language Selection Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LanguageSelectionScreen(),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green[200]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getCurrentLanguageName(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.green[700],
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ✅ Header - Using translation
              Text(
                chooseRole,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                selectHowToUse,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),

              // ⚠️ Warning Message - Using translation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        roleSelectError,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ✅ 1. Customer Card
              _buildRoleCard(
                role: 'customer',
                title: customer,
                icon: Icons.person_outline,
                description: customerDesc,
                color: Colors.green,
              ),
              const SizedBox(height: 16),

              // ✅ 2. Technician Card
              _buildRoleCard(
                role: 'technician',
                title: technician,
                icon: Icons.build_outlined,
                description: technicianDesc,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),

              // ✅ 3. Merchant Card
              _buildRoleCard(
                role: 'merchant',
                title: merchantTitle,
                icon: Icons.store_mall_directory_outlined,
                description: merchantDesc,
                color: Colors.indigo,
              ),
              const SizedBox(height: 30),

              // ✅ Continue Button
              CustomButton(
                onPressed: _selectedRole == null || _isLoading
                    ? null
                    : _continueToUserInfo,
                text: continueText,
                isLoading: _isLoading,
              ),
              if (_selectedRole == null && !_isLoading) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    pleaseSelectRole,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.red[400],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required IconData icon,
    required String description,
    required Color color,
  }) {
    final bool isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ✅ GET CURRENT LANGUAGE NAME
  // ============================================================
  String _getCurrentLanguageName() {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;

    final languageNames = {
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

    return languageNames[languageCode] ?? 'English';
  }

  // ============================================================
  // ✅ CONTINUE TO USER INFO OR MERCHANT INFO
  // ============================================================
  Future<void> _continueToUserInfo() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('pleaseSelectRole')),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // ✅ Save selected role to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'role': _selectedRole,
        'isProfileComplete': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Role saved: $_selectedRole');

      if (!mounted) return;

      if (_selectedRole == 'merchant') {
        final merchantDoc = await FirebaseFirestore.instance
            .collection('merchants')
            .doc(user.uid)
            .get();

        if (!mounted) return;

        if (merchantDoc.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MerchantDashboard(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MerchantInfoScreen(),
            ),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UserInfoScreen(
              userRole: _selectedRole!,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving role: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error')}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
