import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../languages/localization/app_localizations.dart';
import '../services/shop_visit_tracker.dart';
import 'add_parts/screens/add_parts_screen.dart';

class MyStoreTab extends StatefulWidget {
  final Map<String, dynamic>? merchantData;
  final VoidCallback onUpdate;

  const MyStoreTab({super.key, this.merchantData, required this.onUpdate});

  @override
  State<MyStoreTab> createState() => _MyStoreTabState();
}

class _MyStoreTabState extends State<MyStoreTab> {
  bool _isEditing = false;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _pincodeController;
  late TextEditingController _openTimeController;
  late TextEditingController _closeTimeController;

  @override
  void initState() {
    super.initState();
    _initControllers();
    if (widget.merchantData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShopVisitTracker.trackVisit(merchantData: widget.merchantData!);
      });
    }
  }

  @override
  void didUpdateWidget(covariant MyStoreTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.merchantData != widget.merchantData && !_isEditing) {
      _initControllers();
    }
  }

  void _initControllers() {
    _nameController = TextEditingController(text: widget.merchantData?['shopName'] ?? '');
    _typeController = TextEditingController(text: widget.merchantData?['shopType'] ?? '');
    _phoneController = TextEditingController(
        text: widget.merchantData?['shopPhoneNumber'] ?? widget.merchantData?['userPhoneNumber'] ?? '');
    _addressController = TextEditingController(text: widget.merchantData?['address'] ?? '');
    _pincodeController = TextEditingController(text: widget.merchantData?['pincode'] ?? '');
    _openTimeController = TextEditingController(text: widget.merchantData?['openingTime'] ?? '09:00 AM');
    _closeTimeController = TextEditingController(text: widget.merchantData?['closingTime'] ?? '09:00 PM');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveStoreDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('merchants').doc(user.uid).update({
          'shopName': _nameController.text.trim(),
          'shopType': _typeController.text.trim(),
          'shopPhoneNumber': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'pincode': _pincodeController.text.trim(),
          'openingTime': _openTimeController.text.trim(),
          'closingTime': _closeTimeController.text.trim(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('profileUpdated'))),
          );
          setState(() => _isEditing = false);
          widget.onUpdate();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome / Header banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.indigo, Color(0xFF3949AB)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _isEditing
                              ? TextFormField(
                                  controller: _nameController,
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    hintText: context.tr('shopName'),
                                    hintStyle: const TextStyle(color: Colors.white70),
                                    enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white70)),
                                    focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white)),
                                  ),
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                )
                              : Text(
                                  widget.merchantData?['shopName'] ?? context.tr('yourShop'),
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                        ),
                        IconButton(
                          icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              if (_isEditing) _initControllers(); // revert changes
                              _isEditing = !_isEditing;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _isEditing
                        ? TextFormField(
                            controller: _typeController,
                            style: GoogleFonts.poppins(color: Colors.indigo[50], fontSize: 14),
                            decoration: InputDecoration(
                              hintText: context.tr('type'),
                              hintStyle: const TextStyle(color: Colors.white70),
                              enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white30)),
                              focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white)),
                            ),
                          )
                        : Text(
                            "${context.tr('type')}: ${widget.merchantData?['shopType'] ?? 'N/A'}",
                            style: GoogleFonts.poppins(color: Colors.indigo[50], fontSize: 14),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('overviewDetails'),
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  if (_isEditing)
                    _isSaving
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : TextButton.icon(
                            onPressed: _saveStoreDetails,
                            icon: const Icon(Icons.save, size: 18, color: Colors.indigo),
                            label: Text(
                              context.tr('save'),
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                          ),
                ],
              ),
              const SizedBox(height: 12),

              _buildDetailTile(Icons.phone, context.tr('phoneNumber'), _phoneController),
              _buildDetailTile(Icons.location_on, context.tr('shopLocation'), _addressController),
              _buildDetailTile(Icons.pin_drop, context.tr('pincode'), _pincodeController),
              
              if (_isEditing) ...[
                _buildDetailTile(Icons.access_time, "${context.tr('timingSchedule')} (${context.tr('openingTime')})", _openTimeController),
                _buildDetailTile(Icons.access_time_filled, "${context.tr('timingSchedule')} (${context.tr('closingTime')})", _closeTimeController),
              ] else ...[
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.access_time, color: Colors.indigo),
                    title: Text(context.tr('timingSchedule'),
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                    subtitle: Text(
                        "${widget.merchantData?['openingTime'] ?? '09:00 AM'} - ${widget.merchantData?['closingTime'] ?? '09:00 PM'}",
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ),
                ),
              ],

              const SizedBox(height: 25),
              Text(context.tr('quickActions'),
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      Icons.add_shopping_cart,
                      context.tr('addParts'),
                      Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddPartsScreen(
                              merchantData: widget.merchantData,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      Icons.list_alt,
                      context.tr('manageOrders'),
                      Colors.orange,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, TextEditingController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        subtitle: _isEditing
            ? TextFormField(
                controller: controller,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 6),
                  border: InputBorder.none,
                ),
              )
            : Text(
                controller.text.isEmpty ? 'N/A' : controller.text,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
            const SizedBox(height: 10),
            Text(title,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
