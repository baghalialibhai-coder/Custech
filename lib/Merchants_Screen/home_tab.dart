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
                    onPressed: () {
                      // Navigate to details or start chat
                    },
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
