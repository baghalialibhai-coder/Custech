// lib/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/message_model.dart';
import 'one_Signal_Service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // ✅ SEND MESSAGE WITH NOTIFICATION
  // ============================================================
  Future<void> sendMessage({
    required String taskId,
    required String message,
    required String receiverId,
    required String receiverName,
    String? repliedToId,
    String? repliedToMessage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // ✅ Get sender details
      final userRole = await _getUserRole(user.uid);
      final senderName = await _getUserName(user.uid) ?? 'User';

      // ✅ Get task details
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      final taskData = taskDoc.data() ?? {};
      final customerId = taskData['customerId'] ?? '';
      final technicianId = taskData['technicianId'] ?? '';
      final category = taskData['category'] ?? 'Service';

      final messageModel = MessageModel(
        id: '',
        taskId: taskId,
        senderId: user.uid,
        senderName: senderName,
        senderRole: userRole,
        receiverId: receiverId,
        receiverName: receiverName,
        message: message,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        repliedToId: repliedToId,
        repliedToMessage: repliedToMessage,
        isReadByCustomer: userRole == 'customer' ? true : false,
        isReadByTechnician: userRole == 'technician' ? true : false,
      );

      // ✅ Save message
      final docRef = await _firestore.collection('messages').add(
        messageModel.toFirestore(),
      );

      // ✅ Update message ID
      await docRef.update({'id': docRef.id});

      print('✅ Message sent successfully: $message');

      // ✅ Create/Update chat
      await _createOrUpdateChat(
        taskId: taskId,
        lastMessage: message,
        senderId: user.uid,
        senderName: senderName,
        senderRole: userRole,
        receiverId: receiverId,
        receiverName: receiverName,
        customerId: customerId,
        technicianId: technicianId,
        taskTitle: taskData['title'] ?? category,
      );

      // ✅ ============================================================
      // ✅ SEND NOTIFICATION TO RECEIVER
      // ✅ ============================================================

      // ✅ Get receiver's role
      final receiverRole = await _getUserRole(receiverId);

      // ✅ Send notification based on receiver role
      final notificationSent = await OneSignalNotificationService.sendNotificationToUser(
        userId: receiverId,
        title: '💬 New Message from $senderName',
        body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
        data: {
          'type': 'new_message',
          'taskId': taskId,
          'conversationId': taskId,
          'senderId': user.uid,
          'senderName': senderName,
          'senderRole': userRole,
          'receiverRole': receiverRole,
          'message': message,
          'category': category,
        },
      );

      if (notificationSent) {
        print('📤 Notification sent to $receiverRole: $receiverName');
      } else {
        print('⚠️ Notification not sent to $receiverName');
      }

    } catch (e) {
      print('❌ Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // ============================================================
  // ✅ CREATE OR UPDATE CHAT
  // ============================================================
  Future<void> _createOrUpdateChat({
    required String taskId,
    required String lastMessage,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String receiverId,
    required String receiverName,
    required String customerId,
    required String technicianId,
    required String taskTitle,
  }) async {
    try {
      final chatRef = _firestore.collection('chats').doc(taskId);
      final doc = await chatRef.get();

      // ✅ Build participants list
      final List<String> participants = [];
      if (customerId.isNotEmpty) participants.add(customerId);
      if (technicianId.isNotEmpty) participants.add(technicianId);

      // ✅ Fallback
      if (participants.isEmpty) {
        if (senderId.isNotEmpty) participants.add(senderId);
        if (receiverId.isNotEmpty && !participants.contains(receiverId)) {
          participants.add(receiverId);
        }
      }

      // ✅ Get current unread count
      int unreadCount = 0;
      if (doc.exists) {
        final data = doc.data() ?? {};
        final unreadMap = Map<String, dynamic>.from(data['unreadCount'] ?? {});
        unreadCount = (unreadMap[receiverId] ?? 0) + 1;
      } else {
        unreadCount = 1;
      }

      if (doc.exists) {
        // ✅ Update existing chat
        await chatRef.update({
          'lastMessage': lastMessage,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': senderId,
          'lastMessageSenderName': senderName,
          'lastMessageSenderRole': senderRole,
          'unreadCount.${senderId}': 0,
          'unreadCount.${receiverId}': unreadCount,
          'participants': participants,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // ✅ Create new chat
        await chatRef.set({
          'taskId': taskId,
          'taskTitle': taskTitle,
          'customerId': customerId,
          'technicianId': technicianId,
          'participants': participants,
          'lastMessage': lastMessage,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': senderId,
          'lastMessageSenderName': senderName,
          'lastMessageSenderRole': senderRole,
          'unreadCount': {
            senderId: 0,
            receiverId: unreadCount,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ Chat updated: $taskId');
    } catch (e) {
      print('❌ Error creating/updating chat: $e');
    }
  }

  // ============================================================
  // ✅ GET MESSAGES FOR A TASK
  // ============================================================
  Stream<List<MessageModel>> getMessages(String taskId) {
    return _firestore
        .collection('messages')
        .where('taskId', isEqualTo: taskId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  // ============================================================
  // ✅ MARK MESSAGE AS READ
  // ============================================================
  Future<void> markMessageAsRead(String messageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userRole = await _getUserRole(user.uid);
      final updateField = userRole == 'customer'
          ? 'isReadByCustomer'
          : 'isReadByTechnician';

      final docRef = _firestore.collection('messages').doc(messageId);
      await docRef.update({
        updateField: true,
      });

      // ✅ Check if both have read
      final doc = await docRef.get();
      final data = doc.data() ?? {};

      if (data['isReadByCustomer'] == true && data['isReadByTechnician'] == true) {
        await docRef.update({'status': 'read'});
      } else if (data['isReadByCustomer'] == true || data['isReadByTechnician'] == true) {
        await docRef.update({'status': 'delivered'});
      }
    } catch (e) {
      print('❌ Error marking message as read: $e');
    }
  }

  // ============================================================
  // ✅ MARK ALL MESSAGES AS READ
  // ============================================================
  Future<void> markAllMessagesAsRead(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userRole = await _getUserRole(user.uid);
      final updateField = userRole == 'customer'
          ? 'isReadByCustomer'
          : 'isReadByTechnician';

      // ✅ Mark all messages as read
      final messages = await _firestore
          .collection('messages')
          .where('taskId', isEqualTo: taskId)
          .where('senderId', isNotEqualTo: user.uid)
          .where(updateField, isEqualTo: false)
          .get();

      for (var doc in messages.docs) {
        await doc.reference.update({
          updateField: true,
        });
      }

      // ✅ Reset unread count for current user
      await _firestore.collection('chats').doc(taskId).update({
        'unreadCount.${user.uid}': 0,
      });

      print('✅ Marked all messages as read for task: $taskId');
    } catch (e) {
      print('❌ Error marking all messages as read: $e');
    }
  }

  // ============================================================
  // ✅ GET UNREAD COUNT FOR CURRENT USER
  // ============================================================
  Future<int> getUnreadCount(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final chatDoc = await _firestore
          .collection('chats')
          .doc(taskId)
          .get();

      if (chatDoc.exists) {
        final data = chatDoc.data() ?? {};
        return data['unreadCount']?[user.uid] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ============================================================
  // ✅ GET UNREAD COUNT FOR SPECIFIC USER
  // ============================================================
  Future<int> getUnreadCountForUser(String taskId, String userId) async {
    try {
      final chatDoc = await _firestore
          .collection('chats')
          .doc(taskId)
          .get();

      if (chatDoc.exists) {
        final data = chatDoc.data() ?? {};
        return data['unreadCount']?[userId] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ============================================================
  // ✅ GET UNREAD COUNTS FOR BOTH USERS
  // ============================================================
  Future<Map<String, int>> getUnreadCounts(String taskId) async {
    try {
      final chatDoc = await _firestore
          .collection('chats')
          .doc(taskId)
          .get();

      if (chatDoc.exists) {
        final data = chatDoc.data() ?? {};
        final unreadCount = Map<String, dynamic>.from(data['unreadCount'] ?? {});

        final result = <String, int>{};
        unreadCount.forEach((key, value) {
          result[key] = (value as int?) ?? 0;
        });
        return result;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // ============================================================
  // ✅ GET ALL CHATS FOR USER
  // ============================================================
  Stream<List<Map<String, dynamic>>> getChatList() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Map<String, dynamic>> chatList = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final taskId = data['taskId'] ?? '';
          final taskTitle = data['taskTitle'] ?? 'Task';
          final lastMessage = data['lastMessage'] ?? '';
          final lastMessageTime = data['lastMessageTime'];
          final lastMessageSender = data['lastMessageSender'] ?? '';

          // ✅ Get other participant
          final participants = List<String>.from(data['participants'] ?? []);
          final otherUserId = participants.firstWhere(
                (id) => id != user.uid,
            orElse: () => '',
          );

          if (otherUserId.isEmpty) continue;

          // ✅ Fetch user details
          final userDoc = await _firestore
              .collection('users')
              .doc(otherUserId)
              .get();

          final userData = userDoc.data() ?? {};

          final role = userData['role'] ?? 'user';
          final profileImage = userData['profileImageUrl'] ?? '';
          final displayName = userData['displayName'] ??
              userData['name'] ??
              'User';

          final unreadCount = data['unreadCount']?[user.uid] ?? 0;

          // ✅ Get last message status
          String messageStatus = 'sent';
          if (lastMessage.isNotEmpty) {
            final lastMsgSnapshot = await _firestore
                .collection('messages')
                .where('taskId', isEqualTo: taskId)
                .orderBy('timestamp', descending: true)
                .limit(1)
                .get();

            if (lastMsgSnapshot.docs.isNotEmpty) {
              final lastMsgData = lastMsgSnapshot.docs.first.data();
              messageStatus = lastMsgData['status'] ?? 'sent';
            }
          }

          chatList.add({
            'taskId': taskId,
            'taskTitle': taskTitle,
            'lastMessage': lastMessage,
            'lastMessageTime': lastMessageTime,
            'lastMessageSender': lastMessageSender,
            'messageStatus': messageStatus,
            'otherUserId': otherUserId,
            'otherUserName': displayName,
            'otherUserImage': profileImage,
            'role': role,
            'isOnline': userData['isOnline'] ?? false,
            'unreadCount': unreadCount,
          });
        } catch (e) {
          print('❌ Error processing chat: $e');
        }
      }

      return chatList;
    });
  }

  // ============================================================
  // ✅ GET USER NAME
  // ============================================================
  Future<String?> _getUserName(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        return data['displayName'] ?? data['name'] ?? null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // ✅ GET USER ROLE
  // ============================================================
  Future<String> _getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        return data['role'] ?? 'customer';
      }
      return 'customer';
    } catch (e) {
      return 'customer';
    }
  }

  // ============================================================
  // ✅ GET USER DETAILS
  // ============================================================
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() ?? {};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // ============================================================
  // ✅ DELETE MESSAGE
  // ============================================================
  Future<void> deleteMessage(String messageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final doc = await _firestore.collection('messages').doc(messageId).get();
      if (!doc.exists) return;

      final data = doc.data() ?? {};
      if (data['senderId'] != user.uid) {
        throw Exception('You can only delete your own messages');
      }

      await _firestore.collection('messages').doc(messageId).delete();
      print('✅ Message deleted: $messageId');
    } catch (e) {
      print('❌ Error deleting message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }

  // ============================================================
  // ✅ GET CHAT DETAILS
  // ============================================================
  Future<Map<String, dynamic>?> getChatDetails(String taskId) async {
    try {
      final doc = await _firestore.collection('chats').doc(taskId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // ✅ UPDATE MESSAGE STATUS
  // ============================================================
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'status': _statusToString(status),
      });
    } catch (e) {
      print('❌ Error updating message status: $e');
    }
  }

  // ============================================================
  // ✅ STATUS TO STRING
  // ============================================================
  String _statusToString(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
      case MessageStatus.failed:
        return 'failed';
    }
  }

  // ============================================================
  // ✅ DELETE CHAT
  // ============================================================
  Future<void> deleteChat(String taskId) async {
    try {
      await _firestore.collection('chats').doc(taskId).delete();
      print('✅ Chat deleted: $taskId');
    } catch (e) {
      print('❌ Error deleting chat: $e');
      throw Exception('Failed to delete chat: $e');
    }
  }

  // ============================================================
  // ✅ GET TOTAL UNREAD COUNT (For Badge)
  // ============================================================
  Future<int> getTotalUnreadCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['unreadCount']?[user.uid] ?? 0) as int;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  // ============================================================
  // ✅ GET CHAT BY TASK ID
  // ============================================================
  Future<Map<String, dynamic>?> getChatByTaskId(String taskId) async {
    try {
      final doc = await _firestore.collection('chats').doc(taskId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // ✅ CHECK IF CHAT EXISTS
  // ============================================================
  Future<bool> chatExists(String taskId) async {
    try {
      final doc = await _firestore.collection('chats').doc(taskId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // ✅ GET LAST MESSAGE FOR TASK
  // ============================================================
  Future<MessageModel?> getLastMessage(String taskId) async {
    try {
      final snapshot = await _firestore
          .collection('messages')
          .where('taskId', isEqualTo: taskId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return MessageModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // ✅ SEND NOTIFICATION MANUALLY (For Testing)
  // ============================================================
  Future<bool> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String message,
    required String taskId,
    required String category,
  }) async {
    try {
      return await OneSignalNotificationService.sendNotificationToUser(
        userId: receiverId,
        title: '💬 New Message from $senderName',
        body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
        data: {
          'type': 'new_message',
          'taskId': taskId,
          'senderName': senderName,
          'message': message,
          'category': category,
        },
      );
    } catch (e) {
      print('❌ Error sending notification: $e');
      return false;
    }
  }
}