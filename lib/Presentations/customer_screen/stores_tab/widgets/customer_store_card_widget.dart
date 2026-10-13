// lib/Presentations/customer_screen/stores_tab/widgets/customer_store_card_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/merchant_model.dart';
import '../../../../services/shop_visit_tracker.dart';
import '../../../../languages/localization/app_localizations.dart';
import '../../../chat/Screens/chat_screen.dart';

class CustomerStoreCardWidget extends StatelessWidget {
  final MerchantModel merchant;
  final double distance;
  final VoidCallback onTapDetails;

  const CustomerStoreCardWidget({
    super.key,
    required this.merchant,
    required this.distance,
    required this.onTapDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                // Shop Image
                GestureDetector(
                  onTap: () {
                    ShopVisitTracker.trackVisit(merchantData: merchant.toMap());
                    onTapDetails();
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 70,
                      height: 70,
                      color: Colors.indigo.withValues(alpha: 0.1),
                      child: merchant.shopImageUrl.isNotEmpty
                          ? Image.network(merchant.shopImageUrl, fit: BoxFit.cover)
                          : const Icon(Icons.store, color: Colors.indigo, size: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Shop Details
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
                                color: Colors.indigo[900],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${distance.toStringAsFixed(1)} km",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${context.tr('type')}: ${merchant.shopType}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Availability Status Badge
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

                      // Timing
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
                    onPressed: () {
                      ShopVisitTracker.trackVisit(merchantData: merchant.toMap());
                      onTapDetails();
                    },
                    icon: const Icon(Icons.info_outline, size: 16, color: Colors.indigo),
                    label: Text(
                      context.tr('details'),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      ShopVisitTracker.trackVisit(merchantData: merchant.toMap());
                      final Uri launchUri = Uri(scheme: 'tel', path: merchant.shopPhoneNumber);
                      await launchUrl(launchUri);
                    },
                    icon: const Icon(Icons.phone, size: 16, color: Colors.green),
                    label: Text(
                      context.tr('call'),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      ShopVisitTracker.trackVisit(merchantData: merchant.toMap());
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'user';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            taskId: 'chat_${currentUserId}_${merchant.merchantId}',
                            taskTitle: merchant.shopName,
                            otherUserName: merchant.shopName,
                            otherUserId: merchant.merchantId,
                            otherUserImage: merchant.shopImageUrl,
                            otherUserRole: 'merchant',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.indigo),
                    label: Text(
                      context.tr('chat'),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
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
