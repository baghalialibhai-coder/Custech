// lib/Presentations/Auth_Screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../user_detail_form/role_selection_screen.dart';
import '../user_detail_form/merchant_info_screen.dart';
import 'Auth/Widget/custom_button.dart';
import 'Auth/Widget/custom_text_field.dart';
import 'Auth/auth_providers/auth_provider.dart';
import 'Auth/auth_providers/auth_state_provider.dart';
import 'login_screen.dart';
import '../../languages/localization/app_localizations.dart';
import '../../languages/widget/language_selection_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;
  bool _isLoading = false;
  String? _selectedRole;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);
    final authOps = ref.read(authOperationsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================================
              // ✅ TOP ROW: Back Button + Language Selector
              // ============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
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

              const SizedBox(height: 5),

              // ============================================================
              // ✅ WELCOME TEXT
              // ============================================================
              Text(
                context.tr('createAccount'),
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('signUpToGetStarted'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),

              // ============================================================
              // ✅ FORM
              // ============================================================
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      label: context.tr('fullName'),
                      hintText: context.tr('enterName'),
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('nameError');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    CustomTextField(
                      controller: _emailController,
                      label: context.tr('email'),
                      hintText: context.tr('Enter your email'),
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('emailError');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    CustomTextField(
                      controller: _passwordController,
                      label: context.tr('password'),
                      hintText: context.tr('Enter your password'),
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('Please enter a password');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: context.tr('confirmPassword'),
                      hintText: context.tr('Enter confirm password'),
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('Please confirm your password');
                        }
                        if (value != _passwordController.text) {
                          return context.tr('passwordMatchError');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ============================================================
                    // ✅ MERCHANT INFO NOTICE / NOTE
                    // ============================================================
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                      child: Text(
                        _getMerchantNoticeText(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo[700],
                        ),
                      ),
                    ),

                    // ============================================================
                    // ✅ MERCHANT ROLE SELECTION CARD
                    // ============================================================
                    _buildMerchantCard(),

                    const SizedBox(height: 10),

                    // ✅ Terms & Conditions
                    Row(
                      children: [
                        Checkbox(
                          value: _agreeTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreeTerms = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF1A237E),
                        ),
                        Expanded(
                          child: Text(
                            context.tr('agreeTerms'),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ============================================================
              // ✅ CREATE ACCOUNT BUTTON
              // ============================================================
              CustomButton(
                onPressed: authState.isLoading || _isLoading || !_agreeTerms
                    ? null
                    : () {
                  if (_formKey.currentState!.validate()) {
                    _performSignUp(authOps);
                  }
                },
                text: context.tr('createAccount'),
                isLoading: authState.isLoading || _isLoading,
              ),

              if (authState.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[400]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.error!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 15),

              // ============================================================
              // ✅ SIGN IN LINK
              // ============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.tr('alreadyHaveAccount'),
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: Text(
                      context.tr('signIn'),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1A237E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Get translated text for the merchant announcement notice
  String _getMerchantNoticeText() {
    final languageCode = Localizations.localeOf(context).languageCode;
    final Map<String, String> noticeTranslations = {
      'en': "If you are a shop or store owner, you must select this card:",
      'ur': "اگر آپ دکان یا اسٹور کے مالک ہیں، تو اس کارڈ کو لازمی منتخب کریں:",
      'ar': "إذا كنت صاحب محل أو متجر، يجب عليك تحديد هذه البطاقة:",
      'hi': "यदि आप एक दुकान या स्टोर के मालिक हैं, तो इस कार्ड को अवश्य चुनें:",
      'es': "Si eres propietario de una tienda o almacén, debes seleccionar esta tarjeta:",
      'fr': "Si vous êtes propriétaire d'un magasin ou d'une boutique, vous devez sélectionner cette carte:",
      'zh': "如果您是商店或店铺所有者，您必须选择此卡：",
      'tr': "Bir dükkan veya mağaza sahibiyseniz, bu kartı mutlaka seçmelisiniz:",
      'id': "Jika Anda pemilik toko atau warung, Anda wajib memilih kartu ini:",
      'ms': "Jika anda pemilik kedai atau stor, anda mesti memilih kad ini:",
    };
    return noticeTranslations[languageCode] ?? noticeTranslations['en']!;
  }

  // ✅ UI for Merchant Card with full 10 Language Support
  Widget _buildMerchantCard() {
    final bool isSelected = _selectedRole == 'merchant';
    final languageCode = Localizations.localeOf(context).languageCode;

    // 10 Languages text mapping for "Register your Shop / Store"
    final Map<String, String> titleTranslations = {
      'en': "Register your Shop / Store",
      'ur': "اپنی دکان / اسٹور رجسٹر کریں",
      'ar': "سجل متجرك / دكانك",
      'hi': "अपनी दुकान / स्टोर पंजीकृत करें",
      'es': "Registre su Tienda / Almacén",
      'fr': "Enregistrez votre Boutique / Magasin",
      'zh': "注册您的商店/店铺",
      'tr': "Mağazanızı / Dükkanınızı Kaydedin",
      'id': "Daftarkan Toko / Warung Anda",
      'ms': "Daftar Kedai / Stor Anda",
    };

    // 10 Languages text mapping for "Supplier of parts or local store owner"
    final Map<String, String> descTranslations = {
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

    final String titleText = titleTranslations[languageCode] ?? titleTranslations['en']!;
    final String descText = descTranslations[languageCode] ?? descTranslations['en']!;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = isSelected ? null : 'merchant';
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.indigo : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store_mall_directory,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? Colors.indigo : Colors.black87,
                    ),
                  ),
                  Text(
                    descText,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.indigo, size: 24),
          ],
        ),
      ),
    );
  }

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
  // ✅ SIGN UP WITH NAVIGATION LOGIC
  // ============================================================
  Future<void> _performSignUp(AuthStateNotifier authOps) async {
    setState(() => _isLoading = true);

    try {
      await authOps.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Signup failed");

      if (!mounted) return;

      if (_selectedRole == 'merchant') {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'role': 'merchant',
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MerchantInfoScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RoleSelectionScreen(),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-up failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
