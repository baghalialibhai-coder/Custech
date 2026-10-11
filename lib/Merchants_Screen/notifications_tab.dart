// lib/Merchants_Screen/notifications_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../languages/localization/app_localizations.dart';
import '../Presentations/chat/Screens/chat_screen.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'seenAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead(String merchantId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('merchantId', isEqualTo: merchantId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true, 'seenAt': FieldValue.serverTimestamp()});
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> _clearOldNotifications(String merchantId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _firestore
          .collection('notifications')
          .where('merchantId', isEqualTo: merchantId)
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No notifications older than 30 days found')),
          );
        }
        return;
      }

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cleared ${snapshot.docs.length} old notifications')),
        );
      }
    } catch (e) {
      debugPrint('Error clearing old notifications: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) async {
    final String notificationId = data['notificationId'] ?? '';
    final String visitorId = data['visitorId'] ?? '';
    final String visitorName = data['visitorName'] ?? 'Visitor';
    final String visitorPhoto = data['visitorPhoto'] ?? '';
    final String visitorRole = data['visitorRole'] ?? 'User';

    if (notificationId.isNotEmpty) {
      await _markAsRead(notificationId);
    }

    if (!mounted) return;

    // Navigate to Chat or Details
    if (visitorId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            taskId: 'inquiry_visit_$visitorId',
            taskTitle: 'Visitor Inquiry',
            otherUserName: visitorName,
            otherUserId: visitorId,
            otherUserImage: visitorPhoto,
            otherUserRole: visitorRole,
          ),
        ),
      );
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d, h:mm a').format(date);
    }
    return 'Just now';
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'technician':
        return Colors.indigo;
      case 'merchant':
        return Colors.green[800]!;
      case 'customer':
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: Text('Please log in to view notifications', style: GoogleFonts.poppins()),
      );
    }

    final String merchantId = user.uid;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('notifications')
          .where('merchantId', isEqualTo: merchantId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.indigo));
        }

        if (snapshot.hasError) {
          debugPrint("Notification stream error: ${snapshot.error}");
        }

        final docs = snapshot.data?.docs ?? [];
        final unreadCount = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['isRead'] == false;
        }).length;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Column(
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF283593)],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Store Notifications',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unreadCount New',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          'Showing last 30 days visitors & alerts',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (unreadCount > 0)
                          TextButton.icon(
                            onPressed: () => _markAllAsRead(merchantId),
                            icon: const Icon(Icons.done_all, color: Colors.white, size: 16),
                            label: Text(
                              'Mark Read',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep, color: Colors.white70, size: 20),
                          tooltip: 'Clear Old Notifications (>30 Days)',
                          onPressed: () => _clearOldNotifications(merchantId),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Notifications List
              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_active_outlined,
                              size: 70,
                              color: Colors.indigo.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.tr('noNewNotifications'),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Notifications automatically clear after 30 days.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final bool isRead = data['isRead'] == true;
                          final String visitorRole = data['visitorRole'] ?? 'Customer';
                          final String visitorPhoto = data['visitorPhoto'] ?? '';
                          final String title = data['title'] ?? 'New Notification';
                          final String body = data['body'] ?? '';
                          final String timeText = _formatTimestamp(data['createdAt']);

                          return GestureDetector(
                            onTap: () => _handleNotificationTap(data),
                            child: Card(
                              elevation: isRead ? 0.5 : 3,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isRead
                                      ? Colors.grey[200]!
                                      : Colors.indigo.withValues(alpha: 0.3),
                                  width: isRead ? 1 : 1.5,
                                ),
                              ),
                              color: isRead ? Colors.white : Colors.indigo[50]?.withValues(alpha: 0.3),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Visitor Avatar
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.indigo[100],
                                          backgroundImage: visitorPhoto.isNotEmpty
                                              ? NetworkImage(visitorPhoto)
                                              : null,
                                          child: visitorPhoto.isEmpty
                                              ? const Icon(Icons.person, color: Colors.indigo, size: 24)
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.store,
                                              size: 12,
                                              color: Colors.green[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),

                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Visitor Role Badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _getRoleColor(visitorRole).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  visitorRole.toUpperCase(),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getRoleColor(visitorRole),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                timeText,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),

                                          Text(
                                            title,
                                            style: GoogleFonts.poppins(
                                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                              fontSize: 14,
                                              color: isRead ? Colors.black87 : Colors.indigo[900],
                                            ),
                                          ),
                                          const SizedBox(height: 2),

                                          Text(
                                            body,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Unread indicator dot
                                    if (!isRead)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 6, top: 4),
                                        child: CircleAvatar(
                                          radius: 5,
                                          backgroundColor: Colors.indigo[700],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
