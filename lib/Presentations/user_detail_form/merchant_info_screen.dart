// lib/Presentations/user_detail_form/merchant_info_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/merchant_model.dart';
import '../../services/firebase_storage_service.dart';
import '../Auth_Screens/Auth/Widget/custom_button.dart';
import '../Auth_Screens/Auth/Widget/custom_text_field.dart';
import '../User_Location/widgets/location_picker_screen.dart';
import '../../languages/localization/app_localizations.dart';
import '../../languages/widget/language_selection_screen.dart';
import '../../Merchants_Screen/merchant_dashboard.dart';

// ✅ Country Code Imports
import '../../CountryCodeWidget/country_code_picker.dart';
import '../../core/models/country_model.dart';
import '../../countriesPhoneNumberCode/countries_data.dart';

class MerchantInfoScreen extends StatefulWidget {
  final Map<String, dynamic>? initialMerchantData;

  const MerchantInfoScreen({
    super.key,
    this.initialMerchantData,
  });

  @override
  State<MerchantInfoScreen> createState() => _MerchantInfoScreenState();
}

class _MerchantInfoScreenState extends State<MerchantInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _userNameController = TextEditingController();
  final _userPhoneController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _shopTypeController = TextEditingController();

  // FocusNodes to manage active styling
  final FocusNode _personalPhoneFocus = FocusNode();
  final FocusNode _shopPhoneFocus = FocusNode();

  // Country Selection State
  CountryModel _selectedCountry = CountriesData.countries.firstWhere(
    (c) => c.code == 'PK',
    orElse: () => CountriesData.countries.first,
  );

  CountryModel _selectedShopCountry = CountriesData.countries.firstWhere(
    (c) => c.code == 'PK',
    orElse: () => CountriesData.countries.first,
  );

  double _latitude = 0.0;
  double _longitude = 0.0;
  String _pincode = '';
  File? _shopImage;
  String? _shopImageUrl;

  TimeOfDay _openingTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 21, minute: 0);

  String _shopOffDay = 'Sunday';
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final List<String> _selectedWorkingDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _personalPhoneFocus.addListener(() => setState(() {}));
    _shopPhoneFocus.addListener(() => setState(() {}));
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic>? data = widget.initialMerchantData;

      // Fetch from Firestore if initialMerchantData wasn't passed
      if (data == null) {
        final doc = await FirebaseFirestore.instance.collection('merchants').doc(user.uid).get();
        if (doc.exists) {
          data = doc.data();
        }
      }

      if (data != null && mounted) {
        setState(() {
          _userNameController.text = data!['userName'] ?? user.displayName ?? '';

          final rawUserPhone = (data['userPhoneNumber'] ?? user.phoneNumber ?? '').toString();
          _userPhoneController.text = _extractPhoneNumber(rawUserPhone);

          _shopNameController.text = data['shopName'] ?? '';

          final rawShopPhone = (data['shopPhoneNumber'] ?? '').toString();
          _shopPhoneController.text = _extractPhoneNumber(rawShopPhone);

          _shopTypeController.text = data['shopType'] ?? '';
          _addressController.text = data['address'] ?? '';
          _pincode = data['pincode'] ?? '';
          _latitude = (data['latitude'] ?? 0.0).toDouble();
          _longitude = (data['longitude'] ?? 0.0).toDouble();
          _shopImageUrl = data['shopImageUrl'] ?? '';

          if (data['openingTime'] != null) {
            _openingTime = _parseTimeOfDay(data['openingTime'].toString());
          }
          if (data['closingTime'] != null) {
            _closingTime = _parseTimeOfDay(data['closingTime'].toString());
          }
          if (data['shopOffDay'] != null) {
            _shopOffDay = data['shopOffDay'].toString();
          }
          if (data['workingDays'] != null) {
            _selectedWorkingDays.clear();
            _selectedWorkingDays.addAll(List<String>.from(data['workingDays']));
          }
        });
      } else if (mounted) {
        _userNameController.text = user.displayName ?? '';
      }
    } catch (e) {
      debugPrint("Error prefilling merchant info: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _extractPhoneNumber(String rawPhone) {
    if (rawPhone.startsWith('+')) {
      if (rawPhone.length > 3) {
        return rawPhone.substring(3);
      }
    }
    return rawPhone;
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPm = clean.contains('PM');
      final isAm = clean.contains('AM');
      final parts = clean.replaceAll('AM', '').replaceAll('PM', '').trim().split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0].trim());
        int minute = int.parse(parts[1].trim());
        if (isPm && hour < 12) hour += 12;
        if (isAm && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      debugPrint("Error parsing time $timeStr: $e");
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _userPhoneController.dispose();
    _shopNameController.dispose();
    _shopPhoneController.dispose();
    _addressController.dispose();
    _shopTypeController.dispose();
    _personalPhoneFocus.dispose();
    _shopPhoneFocus.dispose();
    super.dispose();
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

  Widget _buildPhoneNumberField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required CountryModel selectedCountry,
    required Function(CountryModel) onCountrySelected,
  }) {
    final bool isFocused = focusNode.hasFocus;

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
        GestureDetector(
          onTap: () => focusNode.requestFocus(),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(
                color: isFocused ? const Color(0xFF1A237E) : Colors.grey[300]!,
                width: isFocused ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isFocused ? Colors.white : Colors.grey[50],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => CountryPickerSheet(
                        selectedCountry: selectedCountry,
                        onCountrySelected: (country) {
                          Navigator.pop(context);
                          onCountrySelected(country);
                        },
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Text(selectedCountry.flag, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 6),
                      Text(
                        selectedCountry.dialCode,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 24,
                  width: 1.5,
                  color: Colors.grey[300],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: hint,
                      border: InputBorder.none,
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 15,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? context.tr('required') : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) setState(() => _shopImage = File(pickedFile.path));
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.indigo),
              title: Text(context.tr('gallery')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.indigo),
              title: Text(context.tr('camera')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingTime : _closingTime,
    );
    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialAddress: _addressController.text,
          initialPincode: _pincode,
          initialLat: _latitude != 0.0 ? _latitude : null,
          initialLng: _longitude != 0.0 ? _longitude : null,
          onLocationSelected: (lat, lng, address, pincode) {
            setState(() {
              _latitude = lat;
              _longitude = lng;
              _addressController.text = address;
              _pincode = pincode;
            });
          },
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final period = tod.period == DayPeriod.am ? "AM" : "PM";
    return "${hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')} $period";
  }

  Future<void> _saveMerchantData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('tapToSelectLocation'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (_shopImage != null) {
        setState(() => _isUploading = true);
        final uploaded = await FirebaseStorageService.uploadImage(_shopImage!, folder: 'shops');
        if (uploaded != null) {
          _shopImageUrl = uploaded;
        }
        setState(() => _isUploading = false);
      }

      final fullPersonalPhone = '${_selectedCountry.dialCode}${_userPhoneController.text.trim()}';
      final fullShopPhone = '${_selectedShopCountry.dialCode}${_shopPhoneController.text.trim()}';

      final Map<String, dynamic> updateData = {
        'merchantId': user.uid,
        'userName': _userNameController.text.trim(),
        'userPhoneNumber': fullPersonalPhone,
        'shopName': _shopNameController.text.trim(),
        'shopPhoneNumber': fullShopPhone,
        'address': _addressController.text.trim(),
        'shopType': _shopTypeController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'pincode': _pincode,
        'shopImageUrl': _shopImageUrl ?? '',
        'openingTime': _formatTimeOfDay(_openingTime),
        'closingTime': _formatTimeOfDay(_closingTime),
        'shopOffDay': _shopOffDay,
        'workingDays': _selectedWorkingDays,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('merchants')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isProfileComplete': true,
        'role': 'merchant',
        'displayName': _userNameController.text.trim(),
        'phoneNumber': fullPersonalPhone,
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile details updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MerchantDashboard()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${context.tr('required')}: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          context.tr('merchantDetails'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _getCurrentLanguageName(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.green[700], size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('completeShopProfile'),
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _shopImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(_shopImage!, fit: BoxFit.cover),
                                )
                              : (_shopImageUrl != null && _shopImageUrl!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(_shopImageUrl!, fit: BoxFit.cover),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_a_photo, size: 40, color: Colors.indigo),
                                        const SizedBox(height: 8),
                                        Text(
                                          context.tr('uploadShopImage'),
                                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildSectionTitle(context.tr('personalDetails')),
                    CustomTextField(
                      controller: _userNameController,
                      label: context.tr('merchantName'),
                      hintText: context.tr('merchantName'),
                      prefixIcon: Icons.person,
                      validator: (v) => v!.isEmpty ? context.tr('required') : null,
                    ),
                    const SizedBox(height: 15),

                    _buildPhoneNumberField(
                      label: context.tr('personalPhone'),
                      hint: context.tr('enterPhone'),
                      controller: _userPhoneController,
                      focusNode: _personalPhoneFocus,
                      selectedCountry: _selectedCountry,
                      onCountrySelected: (country) => setState(() => _selectedCountry = country),
                    ),

                    const SizedBox(height: 25),
                    _buildSectionTitle(context.tr('shopDetails')),
                    CustomTextField(
                      controller: _shopNameController,
                      label: context.tr('shopName'),
                      hintText: context.tr('enterShopName'),
                      prefixIcon: Icons.store,
                      validator: (v) => v!.isEmpty ? context.tr('required') : null,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: _shopTypeController,
                      label: context.tr('businessType'),
                      hintText: context.tr('businessTypeHint'),
                      prefixIcon: Icons.category,
                      validator: (v) => v!.isEmpty ? context.tr('required') : null,
                    ),
                    const SizedBox(height: 15),

                    _buildPhoneNumberField(
                      label: context.tr('shopPhone'),
                      hint: context.tr('enterPhone'),
                      controller: _shopPhoneController,
                      focusNode: _shopPhoneFocus,
                      selectedCountry: _selectedShopCountry,
                      onCountrySelected: (country) => setState(() => _selectedShopCountry = country),
                    ),

                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: _openMap,
                      child: AbsorbPointer(
                        child: CustomTextField(
                          controller: _addressController,
                          label: context.tr('shopAddress'),
                          hintText: context.tr('tapToSelectLocation'),
                          prefixIcon: Icons.location_on,
                          validator: (v) => v!.isEmpty ? context.tr('tapToSelectLocation') : null,
                        ),
                      ),
                    ),
                    if (_latitude != 0.0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                        child: Text(
                          "${context.tr('locationSet')}: $_latitude, $_longitude",
                          style: const TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ),

                    const SizedBox(height: 25),
                    _buildSectionTitle(context.tr('timingSchedule')),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimePickerTile(
                            context.tr('openingTime'),
                            _openingTime,
                            () => _selectTime(context, true),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTimePickerTile(
                            context.tr('closingTime'),
                            _closingTime,
                            () => _selectTime(context, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text(
                      context.tr('shopOffDay'),
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _shopOffDay,
                          isExpanded: true,
                          items: _days.map((day) => DropdownMenuItem(
                            value: day,
                            child: Text(context.tr(day.toLowerCase())),
                          )).toList(),
                          onChanged: (val) => setState(() => _shopOffDay = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      context.tr('workingDays'),
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _days.map((day) {
                        final isSelected = _selectedWorkingDays.contains(day);
                        return FilterChip(
                          label: Text(
                            context.tr(day.toLowerCase()),
                            style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.indigo,
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedWorkingDays.add(day);
                              } else {
                                _selectedWorkingDays.remove(day);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 40),
                    CustomButton(
                      onPressed: (_isLoading || _isUploading) ? null : _saveMerchantData,
                      text: context.tr('saveContinue'),
                      isLoading: _isLoading || _isUploading,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
      ),
    );
  }

  Widget _buildTimePickerTile(String label, TimeOfDay time, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(_formatTimeOfDay(time), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
