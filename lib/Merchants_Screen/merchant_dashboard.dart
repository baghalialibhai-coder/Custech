// lib/Merchants_Screen/merchant_dashboard.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Presentations/Auth_Screens/login_screen.dart';
import '../Presentations/chat/Screens/chat_list_screen.dart';
import '../languages/localization/app_localizations.dart';
import '../languages/widget/language_selection_screen.dart';
import 'merchant_bottom_navigation.dart';
import 'home_tab.dart';
import 'my_store_tab.dart';
import 'notifications_screen.dart';
import 'profile_tab.dart';
import 'technicians_tab/screens/merchant_technicians_screen.dart';

class MerchantDashboard extends StatefulWidget {
  const MerchantDashboard({super.key});

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  Map<String, dynamic>? merchantData;
  bool _isLoading = true;
  int _currentIndex = 0; // 0: Home, 1: My Store, 2: Technicians, 3: Chat/Messages, 4: Profile

  @override
  void initState() {
    super.initState();
    _fetchMerchantDetails();
  }

  Future<void> _fetchMerchantDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('merchants')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            merchantData = doc.data();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching merchant data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('logout'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(context.tr('logoutConfirmation'), style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel'), style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: Text(context.tr('logout'), style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  String _getCurrentLanguageName() {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final languageNames = {
      'en': 'English', 'ur': 'اردو', 'ar': 'العربية', 'hi': 'हिन्दी', 'es': 'Español', 'fr': 'Français', 'zh': '中文', 'tr': 'Türkçe', 'id': 'Bahasa Indonesia', 'ms': 'Bahasa Melayu'
    };
    return languageNames[languageCode] ?? 'English';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_getAppBarTitle(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // ✅ Alert (Notification) Button in AppBar opens Notifications Screen
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: context.tr('storeNotifications'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          // ✅ Language Selection Pill Button
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSelectionScreen())),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(_getCurrentLanguageName(), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          // ✅ More Options Popup Menu Button (Includes Logout)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('logout'),
                        style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : _buildBodyContent(),
      bottomNavigationBar: MerchantBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0: return context.tr('allStores');
      case 1: return context.tr('myStore');
      case 2: return context.tr('technicians');
      case 3: return context.tr('messages');
      case 4: return context.tr('profile');
      default: return context.tr('merchantDashboard');
    }
  }

  Widget _buildBodyContent() {
    switch (_currentIndex) {
      case 0: return const HomeTab();
      case 1: return MyStoreTab(
        merchantData: merchantData,
        onUpdate: _fetchMerchantDetails,
      );
      case 2: return MerchantTechniciansScreen(
        merchantData: merchantData,
      );
      case 3: return const ChatListScreen();
      case 4: return ProfileTab(
        merchantData: merchantData,
        onLogout: _showLogoutDialog,
        onUpdate: _fetchMerchantDetails,
      );
      default: return const HomeTab();
    }
  }
}
