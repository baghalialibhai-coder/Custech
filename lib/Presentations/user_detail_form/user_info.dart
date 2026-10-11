import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../CountryCodeWidget/country_code_picker.dart';
import '../../core/models/country_model.dart';
import '../../countriesPhoneNumberCode/countries_data.dart';
import '../Auth_Screens/Auth/Widget/custom_button.dart';
import '../Auth_Screens/Auth/Widget/custom_text_field.dart';
import '../Auth_Screens/Auth/auth_providers/auth_provider.dart';
import '../customer_screen/customer_dashboard.dart';
import '../technicianscreen/technician_categories_screen.dart';
import '../User_Location/widgets/location_picker_screen.dart';
import '../../services/Location_Service.dart';
import '../../services/firebase_storage_service.dart';
import '../../languages/localization/app_localizations.dart';
import '../../languages/widget/language_selection_screen.dart';

class UserInfoScreen extends ConsumerStatefulWidget {
  final String userRole;

  const UserInfoScreen({
    super.key,
    required this.userRole,
  });

  @override
  ConsumerState<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends ConsumerState<UserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();

  // ✅ Country Selection
  CountryModel _selectedCountry = CountriesData.countries.firstWhere(
        (c) => c.code == 'PK',
    orElse: () => CountriesData.countries.first,
  );

  // ✅ Location Variables
  double _selectedLatitude = 0.0;
  double _selectedLongitude = 0.0;
  String _selectedAddress = '';
  String _selectedPincode = '';

  // ✅ Technician Radius
  double _selectedRadius = 10.0;
  final List<double> _radiusOptions = [3, 5, 7, 10, 15, 20, 25, 50];

  // ✅ Profile Image - Using Cloudinary
  String? _profileImageUrl;
  File? _profileImageFile;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isGettingLocation = false;

  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['displayName'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _addressController.text = data['address'] ?? '';
        _pincodeController.text = data['pincode'] ?? '';
        _profileImageUrl = data['profileImageUrl'];

        _selectedLatitude = (data['latitude'] ?? 0.0).toDouble();
        _selectedLongitude = (data['longitude'] ?? 0.0).toDouble();
        _selectedAddress = data['address'] ?? '';
        _selectedPincode = data['pincode'] ?? '';
        _selectedRadius = (data['serviceRadius'] ?? 10.0).toDouble();

        final countryCode = data['countryCode'];
        if (countryCode != null) {
          final savedCountry = CountriesData.countries.firstWhere(
                (c) => c.code == countryCode,
            orElse: () => _selectedCountry,
          );
          _selectedCountry = savedCountry;
        }

        setState(() {});
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isTechnician = widget.userRole == 'technician';

    // ✅ Get translations
    final profileText = context.tr('profile');
    final fullName = context.tr('fullName');
    final enterName = context.tr('enterName');
    final nameError = context.tr('nameError');
    final country = context.tr('country');
    final phoneNumber = context.tr('phoneNumber');
    final enterPhone = context.tr('enterPhone');
    final phoneError = context.tr('phoneError');
    final address = context.tr('address');
    final enterAddress = context.tr('enterAddress');
    final addressError = context.tr('addressError');
    final pincode = context.tr('pincode');
    final enterPincode = context.tr('enterPincode');
    final pincodeError = context.tr('pincodeError');
    final continueText = context.tr('continue');
    final technicianProfile = context.tr('technicianProfile');
    final customerProfile = context.tr('customerProfile');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isTechnician ? technicianProfile : customerProfile,
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========== PROFILE PICTURE ==========
                _buildProfilePicture(),

                const SizedBox(height: 30),

                // ========== FULL NAME ==========
                CustomTextField(
                  controller: _nameController,
                  label: fullName,
                  hintText: enterName,
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return nameError;
                    }
                    if (value.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ========== COUNTRY CODE PICKER ==========
                CountryCodePicker(
                  selectedCountry: _selectedCountry,
                  onCountrySelected: (country) {
                    setState(() {
                      _selectedCountry = country;
                    });
                  },
                  labelText: country,
                ),
                const SizedBox(height: 16),

                // ========== PHONE NUMBER ==========
                _buildPhoneNumberField(phoneNumber, enterPhone, phoneError),
                const SizedBox(height: 16),

                // ========== ADDRESS ==========
                CustomTextField(
                  controller: _addressController,
                  label: address,
                  hintText: enterAddress,
                  prefixIcon: Icons.location_on_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return addressError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ========== PINCODE ==========
                CustomTextField(
                  controller: _pincodeController,
                  label: pincode,
                  hintText: enterPincode,
                  prefixIcon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length < 4) {
                        return pincodeError;
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ========== TECHNICIAN LOCATION & RADIUS ==========
                if (isTechnician) ...[
                  const Divider(),
                  const SizedBox(height: 8),

                  Text(
                    context.tr('serviceLocation'),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('serviceLocationDesc'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLocationPicker(),

                  const SizedBox(height: 16),

                  _buildRadiusSelector(),

                  const SizedBox(height: 16),

                  _buildLocationPreview(),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                ],

                // ========== ROLE BADGE ==========
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isTechnician
                        ? Colors.blue[50]
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isTechnician
                          ? Colors.blue[200]!
                          : Colors.green[200]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTechnician
                            ? Icons.build_outlined
                            : Icons.person_outline,
                        color: isTechnician
                            ? Colors.blue[700]
                            : Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${context.tr('role')}: ${widget.userRole.toUpperCase()}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: isTechnician
                              ? Colors.blue[700]
                              : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // ========== CONTINUE BUTTON ==========
                CustomButton(
                  onPressed: _isLoading ? null : _saveAndContinue,
                  text: continueText,
                  isLoading: _isLoading || _isUploading || _isGettingLocation,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ✅ BUILD PROFILE PICTURE
  // ============================================================
  Widget _buildProfilePicture() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage: _profileImageFile != null
                  ? FileImage(_profileImageFile!)
                  : (_profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : null) as ImageProvider?,
              child: _profileImageFile == null &&
                  _profileImageUrl == null
                  ? Icon(
                Icons.person,
                size: 60,
                color: Colors.grey[400],
              )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A237E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ✅ BUILD PHONE NUMBER FIELD
  // ============================================================
  Widget _buildPhoneNumberField(String label, String hint, String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A237E),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                _selectedCountry.dialCode,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 30,
                width: 1,
                color: Colors.grey[300],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return error;
                    }
                    final minLength = _selectedCountry.minLength ?? 7;
                    final maxLength = _selectedCountry.maxLength ?? 15;
                    if (value.length < minLength) {
                      return 'Phone number must be at least $minLength digits';
                    }
                    if (value.length > maxLength) {
                      return 'Phone number must be at most $maxLength digits';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ✅ BUILD LOCATION PICKER (Technician Only)
  // ============================================================
  Widget _buildLocationPicker() {
    return GestureDetector(
      onTap: _openLocationPicker,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedAddress.isNotEmpty
                ? Colors.green[300]!
                : Colors.grey[300]!,
            width: _selectedAddress.isNotEmpty ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _selectedAddress.isNotEmpty
                  ? Icons.location_on
                  : Icons.location_on_outlined,
              color: _selectedAddress.isNotEmpty
                  ? Colors.green[700]
                  : Colors.grey[400],
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedAddress.isNotEmpty
                        ? _selectedAddress
                        : context.tr('tapToSelectLocation'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _selectedAddress.isNotEmpty
                          ? const Color(0xFF1A237E)
                          : Colors.grey[400],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_selectedLatitude != 0.0 || _selectedLongitude != 0.0)
                    Text(
                      '📍 ${_selectedLatitude.toStringAsFixed(6)}, ${_selectedLongitude.toStringAsFixed(6)}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ✅ BUILD RADIUS SELECTOR
  // ============================================================
  Widget _buildRadiusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.tr('serviceRadius'),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A237E),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_selectedRadius.toStringAsFixed(0)} km',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Slider(
                value: _selectedRadius,
                min: 3,
                max: 50,
                divisions: _radiusOptions.length - 1,
                activeColor: Colors.green[700],
                inactiveColor: Colors.grey[300],
                label: '${_selectedRadius.toStringAsFixed(0)} km',
                onChanged: (value) {
                  double nearest = _radiusOptions.reduce(
                        (a, b) => (a - value).abs() < (b - value).abs() ? a : b,
                  );
                  setState(() {
                    _selectedRadius = nearest;
                  });
                },
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _radiusOptions.map((radius) {
                  final isSelected = radius == _selectedRadius;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRadius = radius;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.green[700]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        '${radius.toStringAsFixed(0)} km',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ✅ BUILD LOCATION PREVIEW
  // ============================================================
  Widget _buildLocationPreview() {
    if (_selectedAddress.isEmpty && _selectedLatitude == 0.0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('serviceLocationSet'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  '📍 ${_selectedAddress.length > 40 ? _selectedAddress.substring(0, 40) + '...' : _selectedAddress}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.green[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '📌 ${context.tr('radius')}: ${_selectedRadius.toStringAsFixed(0)} km',
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
  // ✅ OPEN LOCATION PICKER
  // ============================================================
  void _openLocationPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialAddress: _selectedAddress,
          initialPincode: _selectedPincode,
          initialLat: _selectedLatitude,
          initialLng: _selectedLongitude,
          onLocationSelected: (lat, lng, address, pincode) {
            setState(() {
              _selectedLatitude = lat;
              _selectedLongitude = lng;
              _selectedAddress = address;
              _selectedPincode = pincode;
              _addressController.text = address;
              _pincodeController.text = pincode;
            });
          },
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
  // ✅ PICK IMAGE
  // ============================================================
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImageFile = File(pickedFile.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  // ============================================================
  // ✅ UPLOAD IMAGE - Firebase Storage
  // ============================================================
  Future<void> _uploadImage() async {
    if (_profileImageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final downloadUrl = await FirebaseStorageService.uploadImage(
        _profileImageFile!,
        folder: 'profile_images',
      );

      if (downloadUrl != null) {
        setState(() {
          _profileImageUrl = downloadUrl;
          _isUploading = false;
        });
        print('✅ Profile image uploaded to Firebase Storage: $downloadUrl');
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      print('❌ Upload error: $e');
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('uploadError')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ============================================================
  // ✅ SAVE AND CONTINUE
  // ============================================================
  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      if (widget.userRole == 'technician' && _selectedAddress.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('pleaseSelectLocation')),
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

        final fullPhoneNumber =
            '${_selectedCountry.dialCode}${_phoneController.text.trim()}';

        final userData = {
          'userId': user.uid,
          'displayName': _nameController.text.trim(),
          'phoneNumber': fullPhoneNumber,
          'phoneNumberRaw': _phoneController.text.trim(),
          'countryCode': _selectedCountry.code,
          'countryDialCode': _selectedCountry.dialCode,
          'countryName': _selectedCountry.name,
          'address': _selectedAddress.isNotEmpty
              ? _selectedAddress
              : _addressController.text.trim(),
          'pincode': _selectedPincode.isNotEmpty
              ? _selectedPincode
              : _pincodeController.text.trim(),
          'profileImageUrl': _profileImageUrl,
          'role': widget.userRole,
          'isProfileComplete': true,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (widget.userRole == 'technician') {
          userData['latitude'] = _selectedLatitude;
          userData['longitude'] = _selectedLongitude;
          userData['serviceRadius'] = _selectedRadius;
          userData['serviceAddress'] = _selectedAddress;
          userData['servicePincode'] = _selectedPincode.isNotEmpty
              ? _selectedPincode
              : _pincodeController.text.trim();
          userData['isAvailable'] = true;
          userData['isOnline'] = true;
          userData['isApproved'] = false;
          userData['isDocumentsVerified'] = false;
          userData['rating'] = 0.0;
          userData['totalReviews'] = 0;
          userData['completedJobs'] = 0;
          userData['experience'] = 0;
          userData['about'] = '';
          userData['hourlyRate'] = 0.0;
          userData['visitingCharges'] = 0.0;
          userData['servicePinCodes'] = [];
          userData['categories'] = [];
          userData['subCategories'] = [];
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData, SetOptions(merge: true));

        print('✅ User info saved successfully');

        if (!mounted) return;

        if (widget.userRole == 'customer') {
          await FirebaseFirestore.instance
              .collection('customers')
              .doc(user.uid)
              .set({
            'userId': user.uid,
            'displayName': _nameController.text.trim(),
            'phoneNumber': fullPhoneNumber,
            'countryCode': _selectedCountry.code,
            'address': _selectedAddress.isNotEmpty
                ? _selectedAddress
                : _addressController.text.trim(),
            'pincode': _selectedPincode.isNotEmpty
                ? _selectedPincode
                : _pincodeController.text.trim(),
            'latitude': _selectedLatitude,
            'longitude': _selectedLongitude,
            'profileImageUrl': _profileImageUrl,
            'savedTechnicians': [],
            'favoriteCategories': [],
            'addresses': [],
            'defaultAddress': '',
            'totalJobsPosted': 0,
            'completedJobs': 0,
            'cancelledJobs': 0,
            'averageRatingGiven': 0.0,
            'createdAt': FieldValue.serverTimestamp(),
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const CustomerDashboard(),
            ),
          );
        } else {
          await FirebaseFirestore.instance
              .collection('technicians')
              .doc(user.uid)
              .set({
            'userId': user.uid,
            'displayName': _nameController.text.trim(),
            'phoneNumber': fullPhoneNumber,
            'email': user.email ?? '',
            'address': _selectedAddress,
            'pincode': _selectedPincode,
            'latitude': _selectedLatitude,
            'longitude': _selectedLongitude,
            'serviceRadius': _selectedRadius,
            'profileImageUrl': _profileImageUrl,
            'countryCode': _selectedCountry.code,
            'categories': [],
            'subCategories': [],
            'experience': 0,
            'about': '',
            'servicePinCodes': [],
            'hourlyRate': 0.0,
            'visitingCharges': 0.0,
            'isAvailable': true,
            'isOnline': true,
            'rating': 0.0,
            'totalReviews': 0,
            'completedJobs': 0,
            'isApproved': false,
            'isDocumentsVerified': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TechnicianCategoriesScreen(
                userName: _nameController.text.trim(),
                phoneNumber: fullPhoneNumber,
                address: _selectedAddress,
                pincode: _selectedPincode,
                profileImageUrl: _profileImageUrl,
                latitude: _selectedLatitude,
                longitude: _selectedLongitude,
                serviceRadius: _selectedRadius,
              ),
            ),
          );
        }
      } catch (e) {
        print('❌ Error saving user info: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error')}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}