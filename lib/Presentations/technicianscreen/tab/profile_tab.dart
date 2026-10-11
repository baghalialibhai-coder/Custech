// lib/Presentations/main_screen/tabs/profile_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../../core/widgets/image_picker_widget.dart';
import '../../../services/firebase_storage_service.dart';
import '../../../languages/localization/app_localizations.dart';
import '../../Auth_Screens/Auth/auth_providers/user_data_provider.dart';
import '../../Auth_Screens/login_screen.dart';
import '../../../core/constants/categories.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isImageUploading = false;

  // ✅ Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  // ✅ User Data
  String? _profileImageUrl;
  String? _role;
  String? _email;
  String? _userId;

  // ✅ Stats
  Map<String, dynamic> _stats = {};
  bool _isStatsLoading = true;

  // ✅ Technician Data
  Map<String, dynamic> _technicianData = {};
  bool _isTechnicianDataLoading = true;

  // ✅ Customer Data
  Map<String, dynamic> _customerData = {};
  bool _isCustomerDataLoading = true;

  // ✅ Selected Categories (for editing)
  List<String> _selectedCategories = [];
  bool _isCategoryEditing = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadUserData();
    await _loadStats();
    await _loadTechnicianData();
    await _loadCustomerData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await ref.read(userDataProvider.future);
      if (userData != null) {
        setState(() {
          _nameController.text = userData.displayName;
          _phoneController.text = userData.phoneNumber;
          _addressController.text = userData.address;
          _pincodeController.text = userData.pincode;
          _profileImageUrl = userData.profileImageUrl;
          _role = userData.role;
          _email = userData.email;
          _userId = userData.uid;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isStatsLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final technicianDoc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .get();

      if (technicianDoc.exists) {
        final data = technicianDoc.data()!;
        setState(() {
          _stats = {
            'totalJobs': data['completedJobs'] ?? 0,
            'rating': data['rating'] ?? 0.0,
            'reviews': data['totalReviews'] ?? 0,
            'experience': data['experience'] ?? 0,
          };
          _isStatsLoading = false;
        });
      } else {
        final customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .get();

        if (customerDoc.exists) {
          final data = customerDoc.data()!;
          setState(() {
            _stats = {
              'totalJobs': data['totalJobsPosted'] ?? 0,
              'rating': data['averageRatingGiven'] ?? 0.0,
              'reviews': 0,
              'experience': 0,
            };
            _isStatsLoading = false;
          });
        } else {
          setState(() => _isStatsLoading = false);
        }
      }
    } catch (e) {
      print('Error loading stats: $e');
      setState(() => _isStatsLoading = false);
    }
  }

  Future<void> _loadTechnicianData() async {
    setState(() => _isTechnicianDataLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _technicianData = data;
          // ✅ FIX: Get categories from Firestore
          final storedCategories = List<String>.from(data['categories'] ?? []);
          _selectedCategories = List.from(storedCategories);
          _isTechnicianDataLoading = false;
        });
      } else {
        setState(() => _isTechnicianDataLoading = false);
      }
    } catch (e) {
      print('Error loading technician data: $e');
      setState(() => _isTechnicianDataLoading = false);
    }
  }

  Future<void> _loadCustomerData() async {
    setState(() => _isCustomerDataLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _customerData = doc.data()!;
          _isCustomerDataLoading = false;
        });
      } else {
        setState(() => _isCustomerDataLoading = false);
      }
    } catch (e) {
      print('Error loading customer data: $e');
      setState(() => _isCustomerDataLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(userDataProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: userDataAsync.when(
          data: (userData) {
            if (userData == null) {
              return _buildErrorState(context.tr('pleaseCompleteProfile'));
            }
            return _buildContent(userData, user);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          error: (error, stack) => _buildErrorState('${context.tr('errorLoadingProfile')}: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(UserData userData, User? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ✅ Profile Header
          _buildProfileHeader(userData, user),
          const SizedBox(height: 16),

          // ✅ Stats Cards
          _buildStatsCards(),
          const SizedBox(height: 16),

          // ✅ Role Specific Data
          if (_role == 'technician')
            _buildTechnicianData(),
          if (_role == 'customer')
            _buildCustomerData(),
          const SizedBox(height: 16),

          // ✅ Privacy Policy & Contact Support
          _buildSupportButtons(),
          const SizedBox(height: 16),

          // ✅ Edit/ Save Button
          _buildEditButton(),
          const SizedBox(height: 16),

          // ✅ Profile Details
          _buildProfileDetails(userData),
          const SizedBox(height: 16),

          // ✅ Action Buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ SUPPORT BUTTONS (Privacy Policy & Contact Support)
  // ============================================================
  Widget _buildSupportButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ Privacy Policy Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showComingSoonDialog(context, context.tr('privacyPolicy')),
              icon: Icon(Icons.privacy_tip_outlined, color: Colors.blue[700]),
              label: Text(
                context.tr('privacyPolicy'),
                style: GoogleFonts.poppins(
                  color: Colors.blue[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue[200]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ✅ Contact Support Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showComingSoonDialog(context, context.tr('contactSupport')),
              icon: Icon(Icons.support_agent_outlined, color: Colors.green[700]),
              label: Text(
                context.tr('contactSupport'),
                style: GoogleFonts.poppins(
                  color: Colors.green[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.green[200]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ COMING SOON DIALOG
  // ============================================================
  void _showComingSoonDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A237E),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 60,
              color: Colors.orange[300],
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('comingSoon'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('featureComingSoonDesc'),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('gotIt'),
              style: GoogleFonts.poppins(
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ PROFILE HEADER
  // ============================================================
  Widget _buildProfileHeader(UserData userData, User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ Profile Image
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue[700]!,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                      ? Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey[400],
                  )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isEditing ? _uploadProfileImage : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isEditing ? Colors.blue[700] : Colors.grey[400],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              if (_isImageUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ Name
          Text(
            userData.displayName,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 2),

          // ✅ Email
          Text(
            user?.email ?? context.tr('noEmail'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),

          // ✅ Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: _role == 'technician'
                  ? Colors.blue[50]
                  : Colors.green[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _role == 'technician'
                    ? Colors.blue[200]!
                    : Colors.green[200]!,
              ),
            ),
            child: Text(
              _role == 'technician'
                  ? '🔧 ${context.tr('technician').toUpperCase()}'
                  : '👤 ${context.tr('customer').toUpperCase()}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: _role == 'technician'
                    ? Colors.blue[700]
                    : Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ UPLOAD PROFILE IMAGE
  // ============================================================
  Future<void> _uploadProfileImage() async {
    if (!_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('enableEditModeFirst')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isImageUploading = true);

    try {
      final File? imageFile = await FirebaseStorageService.pickImageFromGallery();

      if (imageFile == null) {
        setState(() => _isImageUploading = false);
        return;
      }

      final String? imageUrl = await FirebaseStorageService.uploadImage(imageFile, folder: 'profile_images');

      if (imageUrl == null) {
        throw Exception('Cloudinary upload failed');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _profileImageUrl = imageUrl;
        _isImageUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('profilePictureUpdated')),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadUserData();

    } catch (e) {
      setState(() => _isImageUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('uploadFailed')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // ✅ STATS CARDS
  // ============================================================
  Widget _buildStatsCards() {
    if (_isStatsLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            height: 30,
            width: 30,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            value: '${_stats['totalJobs'] ?? 0}',
            label: context.tr('jobs'),
            icon: Icons.work_outline,
            color: Colors.blue,
          ),
          _buildDivider(),
          _buildStatItem(
            value: _stats['rating'] != null
                ? '${(_stats['rating'] as num).toStringAsFixed(1)}★'
                : '0.0★',
            label: context.tr('rating'),
            icon: Icons.star_outline,
            color: Colors.amber,
          ),
          _buildDivider(),
          _buildStatItem(
            value: '${_stats['reviews'] ?? 0}',
            label: context.tr('reviews'),
            icon: Icons.reviews_outlined,
            color: Colors.green,
          ),
          _buildDivider(),
          _buildStatItem(
            value: '${_stats['experience'] ?? 0}y',
            label: context.tr('experience'),
            icon: Icons.timer_outlined,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A237E),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 35,
      width: 1,
      color: Colors.grey[200],
    );
  }

  // ============================================================
  // ✅ TECHNICIAN DATA WITH EDITABLE CATEGORIES (FIXED)
  // ============================================================
  Widget _buildTechnicianData() {
    if (_isTechnicianDataLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            height: 25,
            width: 25,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        ),
      );
    }

    final data = _technicianData;
    // ✅ Get categories from stored data
    final storedCategories = List<String>.from(data['categories'] ?? []);
    final servicePinCodes = List<String>.from(data['servicePinCodes'] ?? []);
    final latitude = (data['latitude'] ?? 0.0).toDouble();
    final longitude = (data['longitude'] ?? 0.0).toDouble();
    final serviceRadius = (data['serviceRadius'] ?? 0.0).toDouble();
    final isAvailable = data['isAvailable'] ?? false;
    final isOnline = data['isOnline'] ?? false;
    final isApproved = data['isApproved'] ?? false;
    final hourlyRate = (data['hourlyRate'] ?? 0.0).toDouble();
    final visitingCharges = (data['visitingCharges'] ?? 0.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                context.tr('technicianDetails'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ Editable Categories - FIXED
          _buildEditableCategories(storedCategories),

          _buildInfoRow(context.tr('status'), isOnline ? '🟢 ${context.tr('online')}' : '🔴 ${context.tr('offline')}'),
          _buildInfoRow(context.tr('availability'), isAvailable ? '✅ ${context.tr('available')}' : '❌ ${context.tr('notAvailable')}'),
          _buildInfoRow(context.tr('verified'), isApproved ? '✅ ${context.tr('verified')}' : '⏳ ${context.tr('pending')}'),
          _buildInfoRow(context.tr('serviceRadius'), '${serviceRadius.toStringAsFixed(0)} km'),
          _buildInfoRow(context.tr('latitude'), latitude.toStringAsFixed(6)),
          _buildInfoRow(context.tr('longitude'), longitude.toStringAsFixed(6)),
          if (servicePinCodes.isNotEmpty)
            _buildInfoRow(context.tr('servicePincodes'), servicePinCodes.join(', ')),
          _buildInfoRow(context.tr('hourlyRate'), 'PKR ${hourlyRate.toStringAsFixed(0)}'),
          _buildInfoRow(context.tr('visitingCharges'), 'PKR ${visitingCharges.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ EDITABLE CATEGORIES - FIXED
  // ============================================================
  Widget _buildEditableCategories(List<String> currentCategories) {
    final allCategories = AppCategories.allCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${context.tr('categories')} (${currentCategories.length})',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            if (_isEditing)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isCategoryEditing = !_isCategoryEditing;
                    if (_isCategoryEditing) {
                      _selectedCategories = List.from(currentCategories);
                    }
                  });
                },
                child: Text(
                  _isCategoryEditing ? context.tr('cancel') : context.tr('editCategories'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _isCategoryEditing ? Colors.red : Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // ✅ Display Mode - Show translated category names
        if (!_isCategoryEditing)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: currentCategories.isEmpty
                ? [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.tr('noCategoriesSelected'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ]
                : currentCategories.map((category) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  context.tr(category), // ✅ Show translated
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              );
            }).toList(),
          ),

        // ✅ Edit Mode
        if (_isCategoryEditing) ...[
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: allCategories.length,
              itemBuilder: (context, index) {
                final category = allCategories[index];
                final isSelected = _selectedCategories.contains(category);
                return CheckboxListTile(
                  value: isSelected,
                  title: Text(
                    context.tr(category), // ✅ Show translated
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: Colors.blue[700],
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCategories,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    context.tr('saveCategories'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isCategoryEditing = false;
                      _selectedCategories = List.from(currentCategories);
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    context.tr('cancel'),
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ============================================================
  // ✅ SAVE CATEGORIES
  // ============================================================
  Future<void> _saveCategories() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .update({
        'categories': _selectedCategories,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _technicianData['categories'] = _selectedCategories;
        _isCategoryEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('categoriesUpdated')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // ✅ CUSTOMER DATA
  // ============================================================
  Widget _buildCustomerData() {
    if (_isCustomerDataLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            height: 25,
            width: 25,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        ),
      );
    }

    final data = _customerData;
    final savedTechnicians = List<String>.from(data['savedTechnicians'] ?? []);
    final favoriteCategories = List<String>.from(data['favoriteCategories'] ?? []);
    final totalJobsPosted = data['totalJobsPosted'] ?? 0;
    final completedJobs = data['completedJobs'] ?? 0;
    final cancelledJobs = data['cancelledJobs'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text(
                context.tr('customerDetails'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(context.tr('totalJobsPosted'), totalJobsPosted.toString()),
          _buildInfoRow(context.tr('completedJobs'), completedJobs.toString()),
          _buildInfoRow(context.tr('cancelledJobs'), cancelledJobs.toString()),
          if (favoriteCategories.isNotEmpty)
            _buildInfoRow(context.tr('favoriteCategories'), favoriteCategories.join(', ')),
          if (savedTechnicians.isNotEmpty)
            _buildInfoRow(context.tr('savedTechnicians'), '${savedTechnicians.length}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF1A237E),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ EDIT BUTTON
  // ============================================================
  Widget _buildEditButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () {
              setState(() {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  _isEditing = true;
                }
              });
            },
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            label: Text(_isEditing ? context.tr('saveProfile') : context.tr('editProfile')),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isEditing ? Colors.blue[700] : const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_isEditing) ...[
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadUserData();
                });
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.tr('cancel'),
                style: GoogleFonts.poppins(
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // ✅ PROFILE DETAILS
  // ============================================================
  Widget _buildProfileDetails(UserData userData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('profileDetails'),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),

          _buildEditableField(
            label: context.tr('fullName'),
            controller: _nameController,
            icon: Icons.person_outline,
            enabled: _isEditing,
          ),
          _buildEditableField(
            label: context.tr('phoneNumber'),
            controller: _phoneController,
            icon: Icons.phone_outlined,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
          ),
          _buildEditableField(
            label: context.tr('address'),
            controller: _addressController,
            icon: Icons.location_on_outlined,
            enabled: _isEditing,
          ),
          _buildEditableField(
            label: context.tr('pincode'),
            controller: _pincodeController,
            icon: Icons.pin_drop_outlined,
            enabled: _isEditing,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Container(
            decoration: BoxDecoration(
              color: enabled ? Colors.white : Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: enabled ? Colors.blue[700]! : Colors.grey[300]!,
                width: enabled ? 2 : 1,
              ),
            ),
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: enabled ? const Color(0xFF1A237E) : Colors.grey[600],
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: enabled ? Colors.blue[700] : Colors.grey[400], size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ SAVE PROFILE
  // ============================================================
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final userNotifier = ref.read(userNotifierProvider.notifier);

      await userNotifier.updateUserData(
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        pincode: _pincodeController.text.trim(),
        profileImageUrl: _profileImageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('profileUpdated')),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================
  // ✅ ACTION BUTTONS
  // ============================================================
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: Text(
              context.tr('logout'),
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _isLoading ? null : () => _showDeleteAccountDialog(context),
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: Text(
              context.tr('deleteAccount'),
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 13,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ✅ LOGOUT DIALOG
  // ============================================================
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          context.tr('logout'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          context.tr('logoutConfirmation'),
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel'), style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${context.tr('logoutFailed')}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              context.tr('logout'),
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ DELETE ACCOUNT DIALOG
  // ============================================================
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          context.tr('deleteAccount'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('deleteAccountConfirmation'),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel'), style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .delete();
                  await user.delete();
                }
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${context.tr('errorDeletingAccount')}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              context.tr('deleteAccount'),
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ ERROR STATE
  // ============================================================
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: Text(context.tr('retry')),
            ),
          ],
        ),
      ),
    );
  }
}