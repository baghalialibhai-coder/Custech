// lib/Presentations/technicianscreen/Technician_dashboard.dart

import 'package:custech/Presentations/chat/Screens/chat_list_screen.dart';
import 'package:custech/Presentations/technicianscreen/tab/Home_Tab.dart';
import 'package:custech/Presentations/technicianscreen/tab/My_Jobs_Tab.dart';
import 'package:custech/Presentations/technicianscreen/tab/message_tab.dart';
import 'package:custech/Presentations/technicianscreen/tab/notification_tab.dart';
import 'package:custech/Presentations/technicianscreen/tab/profile_tab.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../languages/localization/app_localizations.dart';
import '../../languages/widget/language_selection_screen.dart';
import '../../services/job_service.dart';
import '../Auth_Screens/login_screen.dart';

class TechnicianDashboard extends ConsumerStatefulWidget {
  const TechnicianDashboard({super.key});

  @override
  ConsumerState<TechnicianDashboard> createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends ConsumerState<TechnicianDashboard> {
  int _currentIndex = 0;
  String? _technicianName;
  final JobService _jobService = JobService();

  // ✅ Counts for badges
  int _unreadMessagesCount = 0;
  int _acceptedJobsCount = 0;
  int _inProgressJobsCount = 0;
  int _completedJobsCount = 0;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _getUserData();
    _listenToUnreadMessages();
    _listenToJobCounts();
    _listenToNotifications();
  }

  Future<void> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _technicianName = user.displayName ?? 'Technician';
      });
    }
  }

  // ============================================================
  // ✅ LISTEN TO UNREAD MESSAGES
  // ============================================================
  void _listenToUnreadMessages() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) {
      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = data['unreadCount'] as int? ?? 0;
        if (unreadCount > 0) {
          totalUnread += unreadCount;
        }
      }
      if (mounted) {
        setState(() {
          _unreadMessagesCount = totalUnread;
        });
      }
    });
  }

  // ============================================================
  // ✅ LISTEN TO JOB COUNTS
  // ============================================================
  void _listenToJobCounts() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('tasks')
        .where('technicianId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      int accepted = 0;
      int inProgress = 0;
      int completed = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';

        switch (status) {
          case 'accepted':
            accepted++;
            break;
          case 'inProgress':
            inProgress++;
            break;
          case 'completed':
            completed++;
            break;
          default:
            break;
        }
      }

      if (mounted) {
        setState(() {
          _acceptedJobsCount = accepted;
          _inProgressJobsCount = inProgress;
          _completedJobsCount = completed;
        });
      }
    });
  }

  // ============================================================
  // ✅ LISTEN TO NOTIFICATIONS
  // ============================================================
  void _listenToNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _notificationCount = snapshot.docs.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  final List<Widget> _pages = [
    const HomeTab(),
    const MyJobsTab(),
    const ChatListScreen(),
    const NotificationsPlaceholder(),
    const ProfileTab(),
  ];

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('welcome'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
          Text(
            _technicianName ?? context.tr('technician'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1A237E),
      elevation: 0,
      foregroundColor: Colors.white,
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
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.language,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _getCurrentLanguageName(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        // ✅ Notification Button with Badge
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                setState(() {
                  _currentIndex = 3;
                });
              },
            ),
            if (_notificationCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    _notificationCount > 99 ? '99+' : _notificationCount.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        // ✅ Menu Button
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuTap(context, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 20, color: Colors.black),
                  const SizedBox(width: 12),
                  Text(context.tr('profile')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'earnings',
              child: Row(
                children: [
                  const Icon(Icons.attach_money_outlined, size: 20, color: Colors.black),
                  const SizedBox(width: 12),
                  Text(context.tr('earnings')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined, size: 20, color: Colors.black),
                  const SizedBox(width: 12),
                  Text(context.tr('settings')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'language',
              child: Row(
                children: [
                  const Icon(Icons.language, size: 20, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(context.tr('language')),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 20, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(
                    context.tr('logout'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // ✅ GET CURRENT LANGUAGE NAME
  // ============================================================
  String _getCurrentLanguageName() {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;

    final languageNames = {
      'en': 'EN',
      'ur': 'اردو',
      'ar': 'العربية',
      'hi': 'हिन्दी',
      'es': 'ES',
      'fr': 'FR',
      'zh': '中文',
      'tr': 'TR',
      'id': 'ID',
      'ms': 'MS',
    };

    return languageNames[languageCode] ?? 'EN';
  }

  // ============================================================
  // ✅ BOTTOM NAVIGATION BAR WITH COLORED BADGES
  // ============================================================
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1A237E),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          // ✅ Home Tab - No Badge
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: context.tr('home'),
          ),

          // ✅ My Jobs Tab - Colored Badges
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.work_outline),
                // ✅ Show total jobs badge
                if (_acceptedJobsCount > 0 ||
                    _inProgressJobsCount > 0 ||
                    _completedJobsCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          _getTotalJobsCount() > 99
                              ? '99+'
                              : _getTotalJobsCount().toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: _getJobLabelWithBadges(),
          ),

          // ✅ Messages Tab - Red Badge
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.chat_outlined),
                if (_unreadMessagesCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          _unreadMessagesCount > 99
                              ? '99+'
                              : _unreadMessagesCount.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: _getMessageLabelWithBadge(),
          ),

          // ✅ Notifications Tab - Badge
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (_notificationCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          _notificationCount > 99
                              ? '99+'
                              : _notificationCount.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: context.tr('alerts'),
          ),

          // ✅ Profile Tab - No Badge
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: context.tr('profile'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ GET TOTAL JOBS COUNT
  // ============================================================
  int _getTotalJobsCount() {
    return _acceptedJobsCount + _inProgressJobsCount + _completedJobsCount;
  }

  // ============================================================
  // ✅ GET JOB LABEL WITH COLORED BADGES
  // ============================================================
  String _getJobLabelWithBadges() {
    String label = context.tr('myJobs');

    List<String> badges = [];

    if (_acceptedJobsCount > 0) {
      badges.add('🟡${_acceptedJobsCount}');
    }
    if (_inProgressJobsCount > 0) {
      badges.add('🟣${_inProgressJobsCount}');
    }
    if (_completedJobsCount > 0) {
      badges.add('✅${_completedJobsCount}');
    }

    if (badges.isNotEmpty) {
      return '$label ${badges.join(' ')}';
    }

    return label;
  }

  // ============================================================
  // ✅ GET MESSAGE LABEL WITH RED BADGE
  // ============================================================
  String _getMessageLabelWithBadge() {
    String label = context.tr('messages');

    if (_unreadMessagesCount > 0) {
      return '$label 🔴${_unreadMessagesCount}';
    }

    return label;
  }

  void _handleMenuTap(BuildContext context, String value) {
    switch (value) {
      case 'profile':
        setState(() {
          _currentIndex = 4;
        });
        break;
      case 'earnings':
        _showEarningsDialog(context);
        break;
      case 'settings':
      // Navigate to settings
        break;
      case 'language':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LanguageSelectionScreen(),
          ),
        );
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
    }
  }

  void _showEarningsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.tr('earningsOverview'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A237E),
          ),
        ),
        content: FutureBuilder(
          future: _jobService.getTechnicianStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final stats = snapshot.data ?? {};
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '€${stats['totalEarnings']?.toStringAsFixed(0) ?? '0'}',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        context.tr('totalEarnings'),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildEarningRow(
                  context.tr('totalJobs'),
                  '${stats['totalJobs'] ?? 0}',
                ),
                _buildEarningRow(
                  context.tr('completedJobs'),
                  '${stats['completedJobs'] ?? 0}',
                ),
                _buildEarningRow(
                  context.tr('averageRating'),
                  '${(stats['averageRating'] ?? 0).toStringAsFixed(1)} ★',
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('close'),
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A237E),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ LOGOUT WITH NAVIGATION
  // ============================================================
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.tr('logout'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          context.tr('logoutConfirmation'),
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('cancel'),
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                await FirebaseAuth.instance.signOut();

                if (!mounted) return;

                Navigator.pop(context);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('logoutSuccess')),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${context.tr('logoutFailed')}: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              context.tr('logout'),
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}