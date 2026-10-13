// lib/Merchants_Screen/technicians_tab/widgets/technician_card_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/merchant_technician_item.dart';
import '../../../../Presentations/chat/Screens/chat_screen.dart';
import '../../../../languages/localization/app_localizations.dart';

class TechnicianCardWidget extends StatelessWidget {
  final MerchantTechnicianItem item;
  final VoidCallback? onTapDetails;

  const TechnicianCardWidget({
    super.key,
    required this.item,
    this.onTapDetails,
  });

  Future<void> _makeCall(BuildContext context) async {
    if (item.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('phoneError'))),
      );
      return;
    }
    final url = Uri.parse('tel:${item.phone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('error'))),
        );
      }
    }
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          taskId: 'merchant_inquiry_${item.technician.userId}',
          taskTitle: 'Merchant Inquiry',
          otherUserName: item.name,
          otherUserId: item.technician.userId,
          otherUserImage: item.profileImage,
          otherUserRole: 'technician',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tech = item.technician;
    final isOnline = tech.isOnline;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name + Rating + Distance
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with Online indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.indigo[100],
                      backgroundImage: item.profileImage.isNotEmpty
                          ? NetworkImage(item.profileImage)
                          : null,
                      child: item.profileImage.isEmpty
                          ? const Icon(Icons.person, color: Colors.indigo, size: 28)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey[400],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Name & Rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.indigo, size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            '${tech.rating.toStringAsFixed(1)} ',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '(${tech.completedJobs} ${context.tr('jobsCompleted')})',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Distance Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.green, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        item.distanceInKm > 0
                            ? '${item.distanceInKm.toStringAsFixed(1)} km'
                            : context.tr('currentLocation'),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Categories Chips
            if (tech.categories.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tech.categories.take(3).map((cat) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.indigo[900],
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 8),

            // Experience & Hourly Rate Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${tech.experience} ${context.tr('yrsExp')} • ${context.tr('visitingCharges')}: PKR ${tech.visitingCharges.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  tech.isAvailable ? '${context.tr('available')} 🟢' : '${context.tr('notAvailable')} 🔴',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tech.isAvailable ? Colors.green[700] : Colors.red,
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            // Action Buttons Row: Call, Message, Details
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makeCall(context),
                    icon: const Icon(Icons.call, size: 16),
                    label: Text(context.tr('call')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green[700],
                      side: BorderSide(color: Colors.green[700]!),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openChat(context),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: Text(context.tr('chat')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onTapDetails,
                  icon: const Icon(Icons.info_outline, color: Colors.grey),
                  tooltip: context.tr('fullDetails'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
