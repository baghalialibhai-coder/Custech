// lib/Presentations/chat/Screens/chat_list_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/chat_service.dart';
import '../../../core/models/message_model.dart';
import '../../../languages/localization/app_localizations.dart';
import 'chat_screen.dart';
import 'full_screen_image_viewer.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final ChatService _chatService = ChatService();
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _currentUserId = user?.uid;
      _isLoading = false;
    });
    print('🔍 Current User ID: $_currentUserId');
    _debugCheckChats();
  }

  // ✅ Debug Method
  Future<void> _debugCheckChats() async {
    if (_currentUserId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: _currentUserId!)
          .get();

      print('📊 Total chats found: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('📄 Chat:');
        print('   - taskId: ${data['taskId']}');
        print('   - lastMessage: ${data['lastMessage']}');
        print('   - participants: ${data['participants']}');
        print('   - unreadCount: ${data['unreadCount']}');

        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(_currentUserId)) {
          print('   ✅ Current user found in participants');
        } else {
          print('   ❌ Current user NOT in participants');
        }
      }
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
        ),
      );
    }

    if (_currentUserId == null) {
      return _buildLoginRequiredState();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          context.tr('messages'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
              _debugCheckChats();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getChatList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('errorLoadingMessages'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: Text(context.tr('retry')),
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data ?? [];
          print('📊 Chat list count: ${chats.length}');

          if (chats.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _buildChatItem(chat);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoginRequiredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            context.tr('pleaseLogin'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('loginToViewMessages'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('noMessages'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('noMessagesDesc'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${context.tr('currentUser')}: $_currentUserId',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final taskId = chat['taskId'] ?? '';
    final taskTitle = chat['taskTitle'] ?? 'Task';
    final lastMessage = chat['lastMessage'] ?? context.tr('startChatting');
    final lastMessageTime = chat['lastMessageTime'] as Timestamp?;
    final date = lastMessageTime?.toDate();

    // ✅ Get other user details
    final otherUserId = chat['otherUserId'] ?? '';
    final otherUserName = chat['otherUserName'] ?? context.tr('user');
    final otherUserImage = chat['otherUserImage'] ?? '';

    // ✅ Get message status
    final messageStatus = chat['messageStatus'] ?? 'sent';
    final isSentByMe = chat['lastMessageSender'] == _currentUserId;

    print('📄 Building chat item:');
    print('   - otherUserId: $otherUserId');
    print('   - otherUserName: $otherUserName');
    print('   - lastMessage: $lastMessage');

    return FutureBuilder<int>(
      future: _chatService.getUnreadCount(taskId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  taskId: taskId,
                  taskTitle: taskTitle,
                  otherUserName: otherUserName,
                  otherUserId: otherUserId,
                  otherUserImage: otherUserImage,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // ✅ User Avatar
                GestureDetector(
                  onTap: () {
                    _showFullScreenImage(
                      context,
                      imageUrl: otherUserImage,
                      userName: otherUserName,
                    );
                  },
                  child: _buildAvatar(
                    imageUrl: otherUserImage,
                    name: otherUserName,
                    isOnline: chat['isOnline'] ?? false,
                  ),
                ),
                const SizedBox(width: 14),

                // ✅ Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherUserName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A237E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // ✅ Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: chat['role'] == 'technician'
                                  ? Colors.blue[50]
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              chat['role'] == 'technician'
                                  ? context.tr('tech')
                                  : context.tr('customer'),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: chat['role'] == 'technician'
                                    ? Colors.blue[700]
                                    : Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // ✅ Last Message Preview with Status
                      Row(
                        children: [
                          if (unreadCount > 0)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1A237E),
                                shape: BoxShape.circle,
                              ),
                            ),
                          // ✅ Message Status Icon
                          if (isSentByMe)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: _buildStatusIcon(messageStatus),
                            ),
                          Expanded(
                            child: Text(
                              lastMessage,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: unreadCount > 0
                                    ? Colors.black87
                                    : Colors.grey[500],
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
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

                // ✅ Time & Unread Count
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      date != null ? DateFormat('hh:mm a').format(date) : '',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A237E),
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ Build Status Icon
  Widget _buildStatusIcon(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'read':
        color = Colors.green[700]!;
        icon = Icons.done_all;
        break;
      case 'delivered':
        color = Colors.blue[700]!;
        icon = Icons.done_all;
        break;
      case 'failed':
        color = Colors.red[400]!;
        icon = Icons.error_outline;
        break;
      default:
        color = Colors.grey[500]!;
        icon = Icons.check;
        break;
    }

    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }

  // ✅ Show Full Screen Image
  void _showFullScreenImage(
      BuildContext context, {
        required String imageUrl,
        required String userName,
      }) {
    if (imageUrl.isEmpty) {
      _showUserDetailsPopup(context, userName);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrl: imageUrl,
          userName: userName,
        ),
      ),
    );
  }

  // ✅ Show User Details Popup
  void _showUserDetailsPopup(BuildContext context, String userName) {
    final String initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
    final Color color = _getAvatarColor(userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: color,
              child: Text(
                initial,
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('noProfileImage'),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('close'),
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Build Avatar
  Widget _buildAvatar({
    required String imageUrl,
    required String name,
    bool isOnline = false,
  }) {
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final Color backgroundColor = _getAvatarColor(name);

    return Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: backgroundColor,
          backgroundImage: imageUrl.isNotEmpty
              ? NetworkImage(imageUrl)
              : null,
          child: imageUrl.isEmpty
              ? Text(
            initial,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          )
              : null,
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ✅ Get Avatar Color
  Color _getAvatarColor(String name) {
    final List<Color> colors = [
      Colors.blue[700]!,
      Colors.green[700]!,
      Colors.red[700]!,
      Colors.purple[700]!,
      Colors.orange[700]!,
      Colors.teal[700]!,
      Colors.pink[700]!,
      Colors.indigo[700]!,
      Colors.brown[700]!,
      Colors.cyan[700]!,
    ];

    if (name.isEmpty) return colors[0];

    final int index = name.codeUnitAt(0) % colors.length;
    return colors[index];
  }
}