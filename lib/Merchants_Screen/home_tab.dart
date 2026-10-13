// lib/Merchants_Screen/home_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../languages/localization/app_localizations.dart';
import '../services/shop_visit_tracker.dart';
import 'merchant_providers/merchant_search_provider.dart';
import 'merchant_providers/merchant_nearby_provider.dart';
import '../core/models/merchant_model.dart';
import 'journey_screen.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(merchantSearchProvider).toLowerCase();
    final nearbyMerchantsAsync = ref.watch(nearbyMerchantsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          context.tr('nearbyShops'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.indigo),
            onPressed: () {
              ref.invalidate(userLocationProvider);
              ref.invalidate(nearbyMerchantsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar Widget
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  ref.read(merchantSearchProvider.notifier).state = value;
                },
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: context.tr('searchHint'),
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            ref.read(merchantSearchProvider.notifier).state = "";
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // Radius Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.near_me, color: Colors.indigo, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          context.tr('nearbyStores'),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[900],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<double>(
                      value: ref.watch(selectedRadiusProvider),
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[900],
                      ),
                      items: [
                        DropdownMenuItem(value: 5.0, child: Text('5 km 📍', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 10.0, child: Text('10 km 📍 (${context.tr('defaultLabel')})', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 15.0, child: Text('15 km 📍', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 20.0, child: Text('20 km 📍', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 0.0, child: Text('${context.tr('allStores')} 🌐', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(selectedRadiusProvider.notifier).state = val;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          
          // Stores List
          Expanded(
            child: nearbyMerchantsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Error: $err',
                  style: GoogleFonts.poppins(),
                ),
              ),
              data: (merchantsList) {
                final filteredMerchants = merchantsList.where((item) {
                  final merchant = item['merchant'] as MerchantModel;
                  return merchant.shopName.toLowerCase().contains(searchQuery) ||
                      merchant.userName.toLowerCase().contains(searchQuery) ||
                      merchant.shopType.toLowerCase().contains(searchQuery);
                }).toList();

                if (filteredMerchants.isEmpty) {
                  return Center(
                    child: Text(
                      context.tr('noStoresFound'),
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredMerchants.length,
                  itemBuilder: (context, index) {
                    final item = filteredMerchants[index];
                    final merchant = item['merchant'] as MerchantModel;
                    final distance = item['distance'] as double;

                    return _MerchantCard(
                      merchant: merchant,
                      distance: distance,
                      onSeeLocation: () {
                        ShopVisitTracker.trackVisit(merchantData: merchant.toMap());
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JourneyScreen(
                              merchant: merchant,
                              initialDistance: distance,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  final MerchantModel merchant;
  final double distance;
  final VoidCallback onSeeLocation;

  const _MerchantCard({
    required this.merchant,
    required this.distance,
    required this.onSeeLocation,
  });

  void _showFullImage(BuildContext context) {
    if (merchant.shopImageUrl.isEmpty) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  merchant.shopImageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsSheet(BuildContext context) {
    ShopVisitTracker.trackVisit(merchantData: merchant.toMap());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _MerchantDetailsSheet(
        merchant: merchant,
        distance: distance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Image (Tappable to zoom)
                GestureDetector(
                  onTap: () => _showFullImage(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 70,
                      height: 70,
                      color: Colors.indigo.withValues(alpha: 0.1),
                      child: merchant.shopImageUrl.isNotEmpty
                          ? Hero(
                              tag: 'shop_image_${merchant.merchantId}',
                              child: Image.network(merchant.shopImageUrl, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.store, color: Colors.indigo, size: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              merchant.shopName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${distance.toStringAsFixed(1)} km",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${context.tr('owner')}: ${merchant.userName}",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () async {
                          final Uri launchUri = Uri(scheme: 'tel', path: merchant.shopPhoneNumber);
                          await launchUrl(launchUri);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.phone, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              merchant.shopPhoneNumber,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              merchant.address,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: merchant.isAvailableInShop
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: merchant.isAvailableInShop ? Colors.green[300]! : Colors.red[300]!,
                          ),
                        ),
                        child: Text(
                          merchant.isAvailableInShop
                              ? context.tr('availableInShop')
                              : context.tr('notAvailableInShop'),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: merchant.isAvailableInShop ? Colors.green[800] : Colors.red[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled, size: 13, color: Colors.indigo),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${context.tr('shopTiming')}: ${merchant.openingTime} - ${merchant.closingTime}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.indigo[900],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Action Buttons
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onSeeLocation,
                    icon: const Icon(Icons.directions, size: 18),
                    label: Text(
                      context.tr('seeLocation'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                VerticalDivider(width: 1, color: Colors.grey[200], indent: 8, endIndent: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showDetailsSheet(context),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: Text(
                      context.tr('details'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantDetailsSheet extends StatefulWidget {
  final MerchantModel merchant;
  final double distance;

  const _MerchantDetailsSheet({
    required this.merchant,
    required this.distance,
  });

  @override
  State<_MerchantDetailsSheet> createState() => _MerchantDetailsSheetState();
}

class _MerchantDetailsSheetState extends State<_MerchantDetailsSheet> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.merchant;
    final mapData = m.toMap();
    final description = (mapData['storeDescription'] ?? mapData['productsOverview'] ?? '').toString().trim();
    final effectiveDesc = description.isNotEmpty
        ? description
        : 'Welcome to ${m.shopName}! We provide top quality ${m.shopType} products and items.';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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

            // Header Banner
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: Colors.indigo.withValues(alpha: 0.1),
                    child: m.shopImageUrl.isNotEmpty
                        ? Image.network(m.shopImageUrl, fit: BoxFit.cover)
                        : const Icon(Icons.store, color: Colors.indigo, size: 36),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.shopName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        m.shopType,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${widget.distance.toStringAsFixed(1)} km away 📍",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Owner & Contact Info
            Text(
              context.tr('ownerContactInfo'),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailTile(
              m.isAvailableInShop ? Icons.check_circle : Icons.cancel,
              context.tr('shopAvailabilityStatus'),
              m.isAvailableInShop
                  ? context.tr('availableInShop')
                  : context.tr('notAvailableInShop'),
            ),
            _buildDetailTile(Icons.person, context.tr('owner'), m.userName),
            _buildDetailTile(
              Icons.phone,
              'Shop Phone',
              m.shopPhoneNumber,
              onTap: () async {
                final Uri launchUri = Uri(scheme: 'tel', path: m.shopPhoneNumber);
                await launchUrl(launchUri);
              },
            ),
            if (m.userPhoneNumber.isNotEmpty && m.userPhoneNumber != m.shopPhoneNumber)
              _buildDetailTile(
                Icons.phone_android,
                'Personal Phone',
                m.userPhoneNumber,
                onTap: () async {
                  final Uri launchUri = Uri(scheme: 'tel', path: m.userPhoneNumber);
                  await launchUrl(launchUri);
                },
              ),
            _buildDetailTile(Icons.location_on, 'Address', m.address),
            _buildDetailTile(
              Icons.access_time,
              'Shop Timing',
              '${m.openingTime} - ${m.closingTime} (Off: ${m.shopOffDay})',
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Store Description / Products Overview Section with 4-line Expandable logic!
            Text(
              'Store Description & Products',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    effectiveDesc,
                    maxLines: _isExpanded ? null : 4,
                    overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _isExpanded ? 'Show Less 🔼' : 'Show More 🔽',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final Uri launchUri = Uri(scheme: 'tel', path: m.shopPhoneNumber);
                      await launchUrl(launchUri);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.call),
                    label: const Text('Call Shop'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[800],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String value, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.indigo[50],
        child: Icon(icon, color: Colors.indigo, size: 16),
      ),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
      subtitle: Text(
        value.isNotEmpty ? value : 'N/A',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: onTap != null ? Colors.green[800] : Colors.black87,
        ),
      ),
      trailing: onTap != null ? const Icon(Icons.phone_forwarded, size: 16, color: Colors.green) : null,
    );
  }
}
