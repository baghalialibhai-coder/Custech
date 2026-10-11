// lib/Presentations/technicianscreen/technician_categories_screen.dart

import 'package:custech/Presentations/technicianscreen/widget/category_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/categories.dart';
import '../Auth_Screens/Auth/Widget/custom_button.dart';
import 'Technician_dashboard.dart';
import '../../languages/localization/app_localizations.dart';
import '../../languages/widget/language_selection_screen.dart';

class TechnicianCategoriesScreen extends ConsumerStatefulWidget {
  final String userName;
  final String phoneNumber;
  final String address;
  final String pincode;
  final String? profileImageUrl;
  final double latitude;
  final double longitude;
  final double serviceRadius;

  const TechnicianCategoriesScreen({
    super.key,
    required this.userName,
    required this.phoneNumber,
    required this.address,
    required this.pincode,
    this.profileImageUrl,
    required this.latitude,
    required this.longitude,
    required this.serviceRadius,
  });

  @override
  ConsumerState<TechnicianCategoriesScreen> createState() =>
      _TechnicianCategoriesScreenState();
}

class _TechnicianCategoriesScreenState
    extends ConsumerState<TechnicianCategoriesScreen> {
  final List<String> _selectedCategories = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ✅ Get all categories from AppCategories
  List<String> get _allCategories => AppCategories.allCategories;

  // ✅ Get filtered categories based on search
  List<String> get _filteredCategories {
    if (_searchQuery.trim().isEmpty) {
      return _allCategories;
    }

    final query = _searchQuery.toLowerCase().trim();

    return _allCategories.where((categoryKey) {
      // ✅ Check English name
      final englishMatch = categoryKey.toLowerCase().contains(query);

      // ✅ Check Translated name
      final translated = context.tr(categoryKey);
      final translatedMatch = translated.toLowerCase().contains(query);

      return englishMatch || translatedMatch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Get translations
    final selectCategories = context.tr('selectCategories');
    final clearAll = context.tr('clearAll');
    final searchCategories = context.tr('searchCategories');
    final selectedText = context.tr('selected');
    final categoriesAvailable = context.tr('categoriesAvailable');
    final noCategoriesFound = context.tr('noCategoriesFound');
    final tryDifferentSearch = context.tr('tryDifferentSearch');
    final clearSearch = context.tr('clearSearch');
    final selectAtLeastOne = context.tr('selectAtLeastOne');
    final continueText = context.tr('continue');
    final infoText = context.tr('categoryInfoText');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          selectCategories,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
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
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
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
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getCurrentLanguageName(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.green[700],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          // ✅ Clear All Button
          TextButton(
            onPressed: _selectedCategories.isEmpty
                ? null
                : () {
              setState(() {
                _selectedCategories.clear();
              });
            },
            child: Text(
              clearAll,
              style: GoogleFonts.poppins(
                color: _selectedCategories.isEmpty
                    ? Colors.grey[400]
                    : Colors.red[400],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildSearchBar(searchCategories),
          ),
        ),
      ),
      body: Column(
        children: [
          // ✅ Info Banner
          _buildInfoBanner(infoText),

          // ✅ Stats Row
          _buildStatsRow(selectedText, categoriesAvailable),

          // ✅ Categories Grid
          Expanded(
            child: _filteredCategories.isEmpty
                ? _buildEmptyState(noCategoriesFound, tryDifferentSearch, clearSearch)
                : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {


                final categoryKey = _filteredCategories[index];
               final isSelected = _selectedCategories.contains(categoryKey);

                return CategoryCard(
                  category: context.tr(categoryKey),

                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(categoryKey);
                      } else {
                        _selectedCategories.add(categoryKey);
                      }
                    });
                  },
                );
              },
            ),
          ),

          // ✅ Location Preview
          _buildLocationPreview(),

          // ✅ Continue Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomButton(
              onPressed: _selectedCategories.isEmpty || _isLoading
                  ? null
                  : _saveCategoriesAndContinue,
              text: '$continueText (${_selectedCategories.length} $selectedText)',
              isLoading: _isLoading,
            ),
          ),
        ],
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
  // ✅ BUILD INFO BANNER
  // ============================================================
  Widget _buildInfoBanner(String infoText) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[700],
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              infoText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blue[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ BUILD STATS ROW
  // ============================================================
  Widget _buildStatsRow(String selectedText, String categoriesAvailable) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '${_selectedCategories.length}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                selectedText,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Text(
            '${_filteredCategories.length} $categoriesAvailable',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ BUILD EMPTY STATE
  // ============================================================
  Widget _buildEmptyState(String noCategories, String trySearch, String clearSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            noCategories,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            trySearch,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue[700]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              clearSearch,
              style: GoogleFonts.poppins(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ SEARCH BAR
  // ============================================================
  Widget _buildSearchBar(String searchCategories) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: searchCategories,
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear,
              color: Colors.grey[600],
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  // ============================================================
  // ✅ LOCATION PREVIEW
  // ============================================================
  Widget _buildLocationPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.green[700], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📍 ${context.tr('serviceLocationSet')}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  '📌 ${context.tr('radius')}: ${widget.serviceRadius.toStringAsFixed(0)} km',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ SAVE CATEGORIES AND CONTINUE
  // ============================================================
  Future<void> _saveCategoriesAndContinue() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('selectAtLeastOne')),
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

      // ✅ Get user data from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      // ✅ Complete technician data with ALL fields
      final technicianData = {
        'userId': user.uid,
        'displayName': widget.userName,
        'phoneNumber': widget.phoneNumber,
        'email': userData['email'] ?? '',
        'address': widget.address,
        'pincode': widget.pincode,
        'profileImageUrl': widget.profileImageUrl ?? userData['profileImageUrl'] ?? '',
        'countryCode': userData['countryCode'] ?? 'PK',
        'countryDialCode': userData['countryDialCode'] ?? '+92',
        'countryName': userData['countryName'] ?? 'Pakistan',

        // ✅ Location - From UserInfoScreen
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'serviceRadius': widget.serviceRadius,
        'serviceAddress': widget.address,
        'servicePincode': widget.pincode,

        // ✅ Categories
        'categories': _selectedCategories,
        'subCategories': [],
        'servicePinCodes': [],

        // ✅ Professional Info
        'experience': 0,
        'about': '',
        'hourlyRate': 0.0,
        'visitingCharges': 0.0,

        // ✅ Availability
        'isAvailable': true,
        'isOnline': true,

        // ✅ Stats
        'rating': 0.0,
        'totalReviews': 0,
        'completedJobs': 0,

        // ✅ Verification
        'isApproved': false,
        'isDocumentsVerified': false,
        'verificationStatus': 'pending',

        // ✅ Role
        'role': 'technician',
        'isProfileComplete': true,

        // ✅ Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('📍 Saving technician with all data:');
      print('   UserId: ${user.uid}');
      print('   Latitude: ${widget.latitude}');
      print('   Longitude: ${widget.longitude}');
      print('   Service Radius: ${widget.serviceRadius}');
      print('   Categories: ${_selectedCategories.length}');
      print('   Profile Image: ${widget.profileImageUrl ?? userData['profileImageUrl']}');

      // ✅ Save to technicians collection
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .set(technicianData, SetOptions(merge: true));

      // ✅ Update user role and categories in users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'role': 'technician',
        'categories': _selectedCategories,
        'isProfileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Technician saved successfully');
      print('📋 Selected Categories: ${_selectedCategories.length}');

      if (!mounted) return;

      // ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${context.tr('welcome')}! ${_selectedCategories.length} ${context.tr('categoriesSelected')}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // ✅ Navigate to Technician Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const TechnicianDashboard(),
        ),
      );

    } catch (e) {
      print('❌ Error saving technician: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('${context.tr('error')}: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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