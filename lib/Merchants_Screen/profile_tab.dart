// lib/Merchants_Screen/profile_tab.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../languages/localization/app_localizations.dart';
import '../languages/widget/language_selection_screen.dart';
import '../services/firebase_storage_service.dart';
import '../Presentations/user_detail_form/merchant_info_screen.dart';
import 'add_parts/screens/add_parts_screen.dart';

class ProfileTab extends StatefulWidget {
  final Map<String, dynamic>? merchantData;
  final VoidCallback onLogout;
  final VoidCallback? onUpdate;

  const ProfileTab({
    super.key,
    this.merchantData,
    required this.onLogout,
    this.onUpdate,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isUploadingImage = false;
  Map<String, dynamic>? _liveMerchantData;

  @override
  void initState() {
    super.initState();
    _liveMerchantData = widget.merchantData;
    _fetchLatestData();
  }

  @override
  void didUpdateWidget(covariant ProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.merchantData != oldWidget.merchantData) {
      setState(() {
        _liveMerchantData = widget.merchantData;
      });
    }
  }

  Future<void> _fetchLatestData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('merchants').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _liveMerchantData = doc.data();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  Future<void> _changeProfileImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final imageUrl = await FirebaseStorageService.uploadImage(
        File(pickedFile.path),
        folder: 'merchants_profile',
      );

      if (imageUrl != null) {
        await FirebaseFirestore.instance.collection('merchants').doc(user.uid).set({
          'shopImageUrl': imageUrl,
        }, SetOptions(merge: true));

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profileImageUrl': imageUrl,
        }, SetOptions(merge: true));

        await _fetchLatestData();
        widget.onUpdate?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('profilePictureUpdated')),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.indigo),
              title: Text(context.tr('gallery')),
              onTap: () {
                Navigator.pop(context);
                _changeProfileImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.indigo),
              title: Text(context.tr('camera')),
              onTap: () {
                Navigator.pop(context);
                _changeProfileImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final userName = _liveMerchantData?['userName'] ?? user?.displayName ?? context.tr('merchantPartner');
    final userPhone = _liveMerchantData?['userPhoneNumber'] ?? user?.phoneNumber ?? context.tr('notAvailable');
    final shopName = _liveMerchantData?['shopName'] ?? context.tr('yourShop');
    final shopType = _liveMerchantData?['shopType'] ?? context.tr('generalStore');
    final shopPhone = _liveMerchantData?['shopPhoneNumber'] ?? userPhone;
    final address = _liveMerchantData?['address'] ?? context.tr('addressNotSet');
    final shopImageUrl = _liveMerchantData?['shopImageUrl'] ?? user?.photoURL ?? '';
    final openTime = _liveMerchantData?['openingTime'] ?? '09:00 AM';
    final closeTime = _liveMerchantData?['closingTime'] ?? '09:00 PM';
    final shopOffDay = _liveMerchantData?['shopOffDay'] ?? 'Sunday';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // ============================================================
          // 1. TOP HEADER PROFILE CARD (GRADIENT + AVATAR + BADGE)
          // ============================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF303F9F), Color(0xFF3F51B5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.indigo[100],
                        backgroundImage: shopImageUrl.isNotEmpty ? NetworkImage(shopImageUrl) : null,
                        child: shopImageUrl.isEmpty
                            ? const Icon(Icons.store, size: 46, color: Colors.indigo)
                            : null,
                      ),
                    ),
                    if (_isUploadingImage)
                      const Positioned.fill(
                        child: CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageOptions,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Name & Verified Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        userName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, color: Colors.amber, size: 20),
                  ],
                ),
                const SizedBox(height: 4),

                // Shop Name & Type Badge
                Text(
                  '$shopName • $shopType',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_filled, color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${context.tr('open')}: $openTime - $closeTime (${context.tr('off')}: $shopOffDay)',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ============================================================
          // 1.5 SHOP AVAILABILITY TOGGLE SWITCH
          // ============================================================
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              activeThumbColor: Colors.green,
              value: _liveMerchantData?['isAvailableInShop'] ?? true,
              title: Text(
                context.tr('shopAvailabilityStatus'),
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                (_liveMerchantData?['isAvailableInShop'] ?? true)
                    ? context.tr('availableInShop')
                    : context.tr('notAvailableInShop'),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: (_liveMerchantData?['isAvailableInShop'] ?? true) ? Colors.green[800] : Colors.red,
                ),
              ),
              secondary: CircleAvatar(
                backgroundColor: (_liveMerchantData?['isAvailableInShop'] ?? true)
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                child: Icon(
                  (_liveMerchantData?['isAvailableInShop'] ?? true) ? Icons.storefront : Icons.store_sharp,
                  color: (_liveMerchantData?['isAvailableInShop'] ?? true) ? Colors.green : Colors.red,
                ),
              ),
              onChanged: (val) async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                setState(() {
                  if (_liveMerchantData == null) {
                    _liveMerchantData = {'isAvailableInShop': val};
                  } else {
                    _liveMerchantData!['isAvailableInShop'] = val;
                  }
                });

                try {
                  await FirebaseFirestore.instance
                      .collection('merchants')
                      .doc(user.uid)
                      .set({'isAvailableInShop': val}, SetOptions(merge: true));

                  widget.onUpdate?.call();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val
                            ? context.tr('availableInShop')
                            : context.tr('notAvailableInShop')),
                        backgroundColor: val ? Colors.green : Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Error updating availability: $e');
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // ============================================================
          // 2. QUICK STATS ROW
          // ============================================================
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.storefront,
                  label: context.tr('storeStatus'),
                  value: context.tr('activeStatus'),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star_rate_rounded,
                  label: context.tr('storeRating'),
                  value: '4.9 ★',
                  color: Colors.amber[800]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.verified_user,
                  label: context.tr('role'),
                  value: 'Merchant',
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ============================================================
          // 3. STORE DETAILS & CONTACT CARD
          // ============================================================
          _buildSectionHeader(context.tr('shopInformation')),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildInfoListTile(
                  icon: Icons.phone_android,
                  title: context.tr('personalPhone'),
                  subtitle: userPhone,
                ),
                const Divider(height: 1, indent: 56),
                _buildInfoListTile(
                  icon: Icons.store,
                  title: context.tr('shopPhone'),
                  subtitle: shopPhone,
                ),
                const Divider(height: 1, indent: 56),
                _buildInfoListTile(
                  icon: Icons.location_on,
                  title: context.tr('shopAddress'),
                  subtitle: address,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ============================================================
          // 4. QUICK STORE ACTIONS
          // ============================================================
          _buildSectionHeader(context.tr('storeQuickActions')),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.edit_note,
                  color: Colors.indigo,
                  title: context.tr('editMerchantDetails'),
                  subtitle: context.tr('updateShopDetailsDesc'),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MerchantInfoScreen(initialMerchantData: _liveMerchantData),
                      ),
                    );
                    _fetchLatestData();
                    widget.onUpdate?.call();
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildActionTile(
                  icon: Icons.auto_awesome,
                  color: Colors.green[700]!,
                  title: context.tr('addPartsAiCatalog'),
                  subtitle: context.tr('addPartsAiCatalogDesc'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddPartsScreen(merchantData: _liveMerchantData),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ============================================================
          // 5. APP SETTINGS & ACCOUNT
          // ============================================================
          _buildSectionHeader(context.tr('appPreferences')),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.language,
                  color: Colors.blue,
                  title: context.tr('appLanguage'),
                  subtitle: context.tr('changeLanguageDesc'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildActionTile(
                  icon: Icons.help_outline,
                  color: Colors.teal,
                  title: context.tr('helpSupport'),
                  subtitle: context.tr('helpSupportDesc'),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildActionTile(
                  icon: Icons.privacy_tip_outlined,
                  color: Colors.deepPurple,
                  title: context.tr('privacy'),
                  subtitle: context.tr('privacyPolicyDesc'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ============================================================
          // 6. LOGOUT BUTTON
          // ============================================================
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red[700],
                elevation: 0,
                side: BorderSide(color: Colors.red[200]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout),
              label: Text(
                context.tr('logout'),
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: widget.onLogout,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.indigo[900],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoListTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.indigo[50],
        child: Icon(icon, color: Colors.indigo, size: 18),
      ),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }
}
