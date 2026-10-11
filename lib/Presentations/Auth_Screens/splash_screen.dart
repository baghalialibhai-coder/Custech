// lib/Presentations/Auth_Screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../customer_screen/customer_dashboard.dart';
import '../technicianscreen/Technician_dashboard.dart';
import '../technicianscreen/technician_categories_screen.dart';
import '../user_detail_form/role_selection_screen.dart';
import '../user_detail_form/user_info.dart';
import '../user_detail_form/merchant_info_screen.dart';
import '../../Merchants_Screen/merchant_dashboard.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    await _navigateBasedOnUserData(user.uid);
  }

  Future<void> _navigateBasedOnUserData(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          );
        }
        return;
      }

      final userData = userDoc.data()!;
      final String role = (userData['role'] ?? '').toString().toLowerCase();
      final bool isProfileComplete = userData['isProfileComplete'] ?? false;

      print('Splash Logic: User Role is $role');

      // 1. If Role is empty
      if (role.isEmpty) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          );
        }
        return;
      }

      // 2. MERCHANT Logic
      if (role == 'merchant') {
        final merchantDoc = await FirebaseFirestore.instance
            .collection('merchants')
            .doc(userId)
            .get();

        if (merchantDoc.exists && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MerchantDashboard()),
          );
        } else {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MerchantInfoScreen()),
            );
          }
        }
        return;
      }

      // 3. Customer / Technician Profile Completion check
      if (!isProfileComplete) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => UserInfoScreen(userRole: role)),
          );
        }
        return;
      }

      // 4. Dashboards based on role
      if (role == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerDashboard()),
        );
      } else if (role == 'technician') {
        final techDoc = await FirebaseFirestore.instance.collection('technicians').doc(userId).get();
        if (techDoc.exists && (techDoc.data()?['categories'] as List?)?.isNotEmpty == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TechnicianDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TechnicianCategoriesScreen(
                userName: userData['displayName'] ?? '',
                phoneNumber: userData['phoneNumber'] ?? '',
                address: userData['address'] ?? '',
                pincode: userData['pincode'] ?? '',
                profileImageUrl: userData['profileImageUrl'],
                latitude: (userData['latitude'] ?? 0.0).toDouble(),
                longitude: (userData['longitude'] ?? 0.0).toDouble(),
                serviceRadius: (userData['serviceRadius'] ?? 10.0).toDouble(),
              ),
            ),
          );
        }
      } else {
        // Fallback
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      }

    } catch (e) {
      print('Navigation error: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.build_rounded, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 30),
              const Text(
                'Custech',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
