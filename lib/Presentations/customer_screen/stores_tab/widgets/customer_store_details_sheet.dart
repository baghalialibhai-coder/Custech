// lib/Presentations/customer_screen/stores_tab/widgets/customer_store_details_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/merchant_model.dart';
import '../../../../services/shop_visit_tracker.dart';
import '../../../../languages/localization/app_localizations.dart';
import '../../../chat/Screens/chat_screen.dart';

class CustomerStoreDetailsSheet extends StatefulWidget {
  final MerchantModel merchant;
  final double distance;

  const CustomerStoreDetailsSheet({
    super.key,
    required this.merchant,
    required this.distance,
  });

  @override
  State<CustomerStoreDetailsSheet> createState() => _CustomerStoreDetailsSheetState();
}

class _CustomerStoreDetailsSheetState extends State<CustomerStoreDetailsSheet> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Track visit as soon as details sheet is opened
    ShopVisitTracker.trackVisit(merchantData: widget.merchant.toMap());
  }

  void _showFullImage(BuildContext context) {
    if (widget.merchant.shopImageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.merchant.shopImageUrl,
                fit: BoxFit.contain,
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
    final m = widget.merchant;
    final String description = m.toMap()['storeDescription'] ??
        'Welcome to ${m.shopName}! We offer premium ${m.shopType} products, parts, and excellent customer service.';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
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
                GestureDetector(
                  onTap: () => _showFullImage(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: Colors.indigo.withValues(alpha: 0.1),
                      child: m.shopImageUrl.isNotEmpty
                          ? Image.network(m.shopImageUrl, fit: BoxFit.cover)
                          : const Icon(Icons.store, color: Colors.indigo, size: 36),
                    ),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[900],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${widget.distance.toStringAsFixed(1)} km ${context.tr('away')} 📍",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: m.isAvailableInShop
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              m.isAvailableInShop
                                  ? context.tr('availableInShop')
                                  : context.tr('notAvailableInShop'),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: m.isAvailableInShop ? Colors.green[800] : Colors.red[800],
                              ),
                            ),
                          ),
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
              context.tr('shopPhone'),
              m.shopPhoneNumber,
              onTap: () async {
                ShopVisitTracker.trackVisit(merchantData: m.toMap());
                final Uri launchUri = Uri(scheme: 'tel', path: m.shopPhoneNumber);
                await launchUrl(launchUri);
              },
            ),
            _buildDetailTile(Icons.location_on, context.tr('shopAddress'), m.address),
            _buildDetailTile(
              Icons.access_time_filled,
              context.tr('shopTiming'),
              "${m.openingTime} - ${m.closingTime} (${context.tr('off')}: ${m.shopOffDay})",
            ),
            const SizedBox(height: 16),

            // Store Description (Expandable 4 Lines)
            Text(
              context.tr('storeDescriptionProducts'),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            const SizedBox(height: 8),
            AnimatedCrossFade(
              firstChild: Text(
                description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              secondChild: Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Text(
                _isExpanded
                    ? "${context.tr('showLess')} 🔼"
                    : "${context.tr('showMore')} 🔽",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons Row: Call & Chat
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      ShopVisitTracker.trackVisit(merchantData: m.toMap());
                      final Uri launchUri = Uri(scheme: 'tel', path: m.shopPhoneNumber);
                      await launchUrl(launchUri);
                    },
                    icon: const Icon(Icons.call),
                    label: Text(context.tr('callShop')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green[700],
                      side: BorderSide(color: Colors.green[700]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ShopVisitTracker.trackVisit(merchantData: m.toMap());
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'user';
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            taskId: 'chat_${currentUserId}_${m.merchantId}',
                            taskTitle: m.shopName,
                            otherUserName: m.shopName,
                            otherUserId: m.merchantId,
                            otherUserImage: m.shopImageUrl,
                            otherUserRole: 'merchant',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: Text(context.tr('chat')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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

  Widget _buildDetailTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.indigo[50],
        child: Icon(icon, color: Colors.indigo, size: 18),
      ),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: onTap != null ? Colors.green[800] : Colors.black87,
        ),
      ),
      trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey) : null,
    );
  }
}
