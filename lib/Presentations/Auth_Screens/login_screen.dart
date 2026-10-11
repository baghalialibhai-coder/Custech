// lib/Presentations/Auth_Screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../customer_screen/customer_dashboard.dart';
import '../technicianscreen/Technician_dashboard.dart';
import '../technicianscreen/technician_categories_screen.dart';
import '../user_detail_form/role_selection_screen.dart';
import '../user_detail_form/user_info.dart';
import '../user_detail_form/merchant_info_screen.dart';
import '../../Merchants_Screen/merchant_dashboard.dart';
import 'Auth/Widget/custom_button.dart';
import 'Auth/Widget/custom_text_field.dart';
import 'Auth/auth_providers/auth_state_provider.dart';
import 'forget_password_screen.dart';
import 'signup_screen.dart';
import '../../languages/widget/language_selection_screen.dart';
import '../../languages/localization/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);
    final authOps = ref.read(authOperationsProvider);

    final bool isAnyLoading =
        authState.isLoading || _isEmailLoading || _isGoogleLoading || _isAppleLoading;

    final bool showApple = Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language and Back button header...
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSelectionScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green[200]!)),
                      child: Row(
                        children: [
                          const Icon(Icons.language, color: Colors.green, size: 18),
                          const SizedBox(width: 4),
                          Text(_getCurrentLanguageName(), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green[700])),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(context.tr('welcomeBack'), style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
              const SizedBox(height: 8),
              Text(context.tr('signInToContinue'), style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 40),
              
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _emailController,
                      label: context.tr('email'),
                      hintText: context.tr('Enter your email'),
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => (value == null || value.isEmpty) ? context.tr('emailError') : null,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      label: context.tr('password'),
                      hintText: context.tr('Enter your password'),
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? context.tr('Please enter your password') : null,
                    ),
                  ],
                ),
              ),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                  child: Text(context.tr('forgotPassword'), style: GoogleFonts.poppins(color: const Color(0xFF1A237E), fontWeight: FontWeight.w600)),
                ),
              ),
              
              const SizedBox(height: 30),
              CustomButton(
                onPressed: isAnyLoading ? null : () => _performLogin(authOps),
                text: context.tr('signIn'),
                isLoading: _isEmailLoading,
              ),
              
              const SizedBox(height: 20),
              // Social Login UI...
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(context.tr('or'), style: GoogleFonts.poppins(color: Colors.grey[500]))),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      onPressed: isAnyLoading ? null : () => _performGoogleSignIn(authOps),
                      text: context.tr('signInWithGoogle'),
                      isLoading: _isGoogleLoading,
                      isGoogle: true,
                    ),
                  ),
                  if (showApple) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        onPressed: isAnyLoading ? null : () => _performAppleSignIn(authOps),
                        text: context.tr('signInWithApple'),
                        isLoading: _isAppleLoading,
                        isApple: true,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(context.tr('dontHaveAccount'), style: GoogleFonts.poppins(color: Colors.grey[600])),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: Text(context.tr('signUp'), style: GoogleFonts.poppins(color: const Color(0xFF1A237E), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrentLanguageName() {
    final languageCode = Localizations.localeOf(context).languageCode;
    final languageNames = {'en': 'English', 'ur': 'اردو', 'ar': 'العربية', 'hi': 'हिन्दी', 'es': 'Español', 'fr': 'Français', 'zh': '中文', 'tr': 'Türkçe', 'id': 'Bahasa Indonesia', 'ms': 'Bahasa Melayu'};
    return languageNames[languageCode] ?? 'English';
  }

  Future<void> _performLogin(AuthStateNotifier authOps) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isEmailLoading = true);
      try {
        await authOps.signIn(email: _emailController.text.trim(), password: _passwordController.text.trim());
        await _navigateBasedOnUserData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isEmailLoading = false);
      }
    }
  }

  Future<void> _performGoogleSignIn(AuthStateNotifier authOps) async {
    setState(() => _isGoogleLoading = true);
    try {
      await authOps.signInWithGoogle();
      await Future.delayed(const Duration(milliseconds: 500));
      await _navigateBasedOnUserData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google sign-in failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _performAppleSignIn(AuthStateNotifier authOps) async {
    setState(() => _isAppleLoading = true);
    try {
      await authOps.signInWithApple();
      await Future.delayed(const Duration(milliseconds: 500));
      await _navigateBasedOnUserData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Apple sign-in failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  Future<void> _navigateBasedOnUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Force fetch from server to get latest role
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
        return;
      }

      final data = userDoc.data()!;
      final String role = (data['role'] ?? '').toString().trim().toLowerCase();
      final bool isProfileComplete = data['isProfileComplete'] ?? false;

      debugPrint('Navigation Debug: Role detected as: $role');

      // 1. Check Merchant Role First
      if (role == 'merchant') {
        final merchantDoc = await FirebaseFirestore.instance.collection('merchants').doc(user.uid).get();
        if (mounted) {
          if (merchantDoc.exists) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MerchantDashboard()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MerchantInfoScreen()));
          }
        }
        return;
      }

      // 2. Role Check for others
      if (role.isEmpty) {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
        return;
      }

      // 3. Profile Completion for Customer/Technician
      if (!isProfileComplete) {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UserInfoScreen(userRole: role)));
        return;
      }

      // 4. Navigate to respective dashboards
      if (mounted) {
        if (role == 'customer') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerDashboard()));
        } else if (role == 'technician') {
          final techDoc = await FirebaseFirestore.instance.collection('technicians').doc(user.uid).get();
          if (!mounted) return;
          if (techDoc.exists && (techDoc.data()?['categories'] as List?)?.isNotEmpty == true) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TechnicianDashboard()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TechnicianCategoriesScreen(
              userName: data['displayName'] ?? '',
              phoneNumber: data['phoneNumber'] ?? '',
              address: data['address'] ?? '',
              pincode: data['pincode'] ?? '',
              profileImageUrl: data['profileImageUrl'],
              latitude: (data['latitude'] ?? 0.0).toDouble(),
              longitude: (data['longitude'] ?? 0.0).toDouble(),
              serviceRadius: (data['serviceRadius'] ?? 10.0).toDouble(),
            )));
          }
        }
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
    }
  }
}
