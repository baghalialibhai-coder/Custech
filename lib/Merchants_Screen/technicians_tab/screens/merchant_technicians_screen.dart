// lib/Merchants_Screen/technicians_tab/screens/merchant_technicians_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/merchant_technicians_provider.dart';
import '../widgets/distance_toggle_widget.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/technician_card_widget.dart';
import '../models/merchant_technician_item.dart';
import '../../../../Presentations/chat/Screens/chat_screen.dart';

class MerchantTechniciansScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? merchantData;

  const MerchantTechniciansScreen({
    super.key,
    this.merchantData,
  });

  @override
  ConsumerState<MerchantTechniciansScreen> createState() => _MerchantTechniciansScreenState();
}

class _MerchantTechniciansScreenState extends ConsumerState<MerchantTechniciansScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final double merchantLat = (widget.merchantData?['latitude'] ?? 0.0).toDouble();
    final double merchantLng = (widget.merchantData?['longitude'] ?? 0.0).toDouble();

    ref.read(merchantTechniciansProvider.notifier).loadTechnicians(
          merchantLat: merchantLat,
          merchantLng: merchantLng,
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTechnicianDetails(MerchantTechnicianItem item) {
    final tech = item.technician;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.indigo[100],
                    backgroundImage: item.profileImage.isNotEmpty ? NetworkImage(item.profileImage) : null,
                    child: item.profileImage.isEmpty ? const Icon(Icons.person, size: 36, color: Colors.indigo) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          item.address.isNotEmpty ? item.address : 'Service Technician',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text('${tech.rating.toStringAsFixed(1)} (${tech.totalReviews} reviews)',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Divider(),
              const SizedBox(height: 12),

              // Overview Tiles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildModalDetailTile('Experience', '${tech.experience} Yrs'),
                  _buildModalDetailTile('Visit Fee', 'PKR ${tech.visitingCharges.toStringAsFixed(0)}'),
                  _buildModalDetailTile('Hourly Rate', 'PKR ${tech.hourlyRate.toStringAsFixed(0)}'),
                  _buildModalDetailTile('Distance', item.distanceInKm > 0 ? '${item.distanceInKm.toStringAsFixed(1)} km' : 'Nearby'),
                ],
              ),
              const SizedBox(height: 20),

              // Categories
              Text('Categories & Services', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo[900])),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tech.categories.map((c) => Chip(
                  label: Text(c, style: GoogleFonts.poppins(fontSize: 12, color: Colors.indigo[900])),
                  backgroundColor: Colors.indigo[50],
                )).toList(),
              ),
              const SizedBox(height: 16),

              // About
              if (tech.about.isNotEmpty) ...[
                Text('About Technician', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo[900])),
                const SizedBox(height: 6),
                Text(tech.about, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[800], height: 1.4)),
                const SizedBox(height: 20),
              ],

              // Service Pincodes
              if (tech.servicePinCodes.isNotEmpty) ...[
                Text('Service Area Pincodes', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo[900])),
                const SizedBox(height: 6),
                Text(tech.servicePinCodes.join(', '), style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
                const SizedBox(height: 24),
              ],

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (item.phone.isNotEmpty) {
                          await launchUrl(Uri.parse('tel:${item.phone}'));
                        }
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('Call Technician'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green[700],
                        side: BorderSide(color: Colors.green[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              taskId: 'merchant_inquiry_${tech.userId}',
                              taskTitle: 'Merchant Inquiry',
                              otherUserName: item.name,
                              otherUserId: tech.userId,
                              otherUserImage: item.profileImage,
                              otherUserRole: 'technician',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Send Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildModalDetailTile(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(merchantTechniciansProvider);
    final notifier = ref.read(merchantTechniciansProvider.notifier);
    final list = state.filteredTechnicians;

    final double merchantLat = (widget.merchantData?['latitude'] ?? 0.0).toDouble();
    final double merchantLng = (widget.merchantData?['longitude'] ?? 0.0).toDouble();

    return RefreshIndicator(
      onRefresh: () async {
        await notifier.loadTechnicians(merchantLat: merchantLat, merchantLng: merchantLng);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    radius: 22,
                    child: Icon(Icons.build_circle, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Technicians Directory',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          state.onlyWithin10Km
                              ? 'Showing technicians within 10 km radius'
                              : 'Showing all registered technicians',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Distance Toggle (Within 10km vs All)
            DistanceToggleWidget(
              onlyWithin10Km: state.onlyWithin10Km,
              onToggle: (within10Km) => notifier.set10KmFilter(within10Km),
            ),
            const SizedBox(height: 16),

            // Search Field
            TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by technician name, category, or city...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              onChanged: (q) => notifier.setSearchQuery(q),
            ),
            const SizedBox(height: 16),

            // Category Chips Carousel
            CategoryFilterChips(
              selectedCategory: state.selectedCategory,
              onCategorySelected: (cat) => notifier.setCategory(cat),
            ),
            const SizedBox(height: 20),

            // Count Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Technicians (${list.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                  ),
                ),
                if (state.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Technicians List or Loading / Empty States
            if (state.isLoading && list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.indigo),
                      SizedBox(height: 12),
                      Text('Searching technicians near your store...'),
                    ],
                  ),
                ),
              )
            else if (list.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.build_circle_outlined, size: 56, color: Colors.indigo[200]),
                    const SizedBox(height: 12),
                    Text(
                      'No Technicians Found',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[900],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.onlyWithin10Km
                          ? 'No technicians within 10 km radius. Try switching to "All Technicians".'
                          : 'Try changing your category or search term.',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (state.onlyWithin10Km)
                      ElevatedButton.icon(
                        onPressed: () => notifier.set10KmFilter(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.public, size: 18),
                        label: const Text('Show All Technicians'),
                      ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  return TechnicianCardWidget(
                    item: item,
                    onTapDetails: () => _showTechnicianDetails(item),
                  );
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
