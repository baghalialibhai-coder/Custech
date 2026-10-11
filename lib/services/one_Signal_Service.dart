// lib/services/one_signal_notification_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class OneSignalNotificationService {
  static bool _isInitialized = false;

  // ✅ READ FROM .env
  static String get _oneSignalAppId => dotenv.env['OneSignal_App_ID'] ?? '';
  static String get _oneSignalApiKey => dotenv.env['one_Signal_Api_Key'] ?? '';

  // ✅ CUSTOM SOUND
  static const String _customSound = 'custech_notification';
  static const String _channelId = 'bc9466e7-c9b6-4afb-8b1e-09ffbfd9b029';
  static const String _channelName = 'notifications';

  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static bool get _hasCredentials {
    return _oneSignalAppId.isNotEmpty && _oneSignalApiKey.isNotEmpty;
  }

  // ============================================================
  // ✅ INITIALIZE
  // ============================================================
  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (!_hasCredentials) {
      print('❌ OneSignal credentials not found in .env');
      return;
    }

    try {
      print('🔍 Initializing OneSignal...');
      OneSignal.initialize(_oneSignalAppId);
      await OneSignal.Notifications.requestPermission(true);
      await _initializeLocalNotifications();

      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        _showLocalNotification(event.notification);
        event.notification.display();
      });

      OneSignal.Notifications.addClickListener((event) {
        final data = event.notification.additionalData ?? {};
        print('📱 Notification Clicked: $data');
        _handleNotificationTap(Map<String, dynamic>.from(data));
      });

      OneSignal.User.pushSubscription.addObserver((state) {
        final subscriptionId = state.current.id;
        if (subscriptionId != null && subscriptionId.isNotEmpty) {
          print('📱 Push Subscription ID: $subscriptionId');
          _saveSubscriptionId(subscriptionId);
        }
      });

      _isInitialized = true;
      print('✅ OneSignal initialized successfully');
      print('📱 App ID: ${_oneSignalAppId.substring(0, 8)}...');

      await saveCurrentUserOneSignalId();

    } catch (e) {
      print('❌ OneSignal initialization error: $e');
    }
  }

  // ============================================================
  // ✅ LOCAL NOTIFICATIONS
  // ============================================================
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleLocalNotificationTap(payload);
        }
      },
    );
  }

  // ============================================================
  // ✅ SHOW LOCAL NOTIFICATION WITH CUSTOM SOUND
  // ============================================================
  static Future<void> _showLocalNotification(OSNotification notification) async {
    try {
      final AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Task updates, messages and alerts',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(_customSound),
        enableVibration: true,
        enableLights: true,
        playSound: true,
        vibrationPattern:  Int64List.fromList([0, 500, 200, 500]),
      );

      final DarwinNotificationDetails iosDetails =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: '$_customSound.wav',
      );

      final id = DateTime.now().millisecondsSinceEpoch.hashCode;
      await _localNotifications.show(
        id,
        notification.title,
        notification.body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: notification.additionalData?['taskId'] ?? '',
      );

      print('🔊 Custom sound played: $_customSound');
    } catch (e) {
      print('❌ Local notification error: $e');
    }
  }

  static void _handleLocalNotificationTap(String payload) {
    print('🔔 Local notification tapped: $payload');
    navigatorKey.currentState?.pushNamed('/customer-dashboard');
  }

  // ============================================================
  // ✅ SAVE SUBSCRIPTION ID
  // ============================================================
  static Future<void> _saveSubscriptionId(String subscriptionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'oneSignalId': subscriptionId,
        'notificationsEnabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data()?['role'] == 'technician') {
        await FirebaseFirestore.instance
            .collection('technicians')
            .doc(user.uid)
            .set({
          'oneSignalId': subscriptionId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      print('✅ OneSignal ID saved: $subscriptionId');
    } catch (e) {
      print('❌ Save subscription error: $e');
    }
  }

  // ============================================================
  // ✅ SAVE CURRENT USER ONE SIGNAL ID
  // ============================================================
  static Future<void> saveCurrentUserOneSignalId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ No user logged in');
      return;
    }

    String? oneSignalId;
    for (int i = 0; i < 10; i++) {
      oneSignalId = OneSignal.User.pushSubscription.id;
      if (oneSignalId != null && oneSignalId.isNotEmpty) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (oneSignalId == null || oneSignalId.isEmpty) {
      print('❌ OneSignal ID not available');
      return;
    }

    await _saveSubscriptionId(oneSignalId);
    print('✅ OneSignal ID saved for user: ${user.uid}');
  }

  // ============================================================
  // ✅ GET USER'S ONESIGNAL ID
  // ============================================================
  static Future<String?> getOneSignalId(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final oneSignalId = userData['oneSignalId'] as String?;
        if (oneSignalId != null && oneSignalId.isNotEmpty) {
          return oneSignalId;
        }
      }

      final techDoc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(userId)
          .get();

      if (techDoc.exists) {
        final techData = techDoc.data()!;
        final oneSignalId = techData['oneSignalId'] as String?;
        if (oneSignalId != null && oneSignalId.isNotEmpty) {
          return oneSignalId;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting OneSignal ID: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ SEND NOTIFICATION TO USER
  // ============================================================
  static Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? imageUrl,
  }) async {
    try {
      if (!_hasCredentials) {
        print('❌ OneSignal credentials not configured');
        return false;
      }

      final String? oneSignalId = await getOneSignalId(userId);

      if (oneSignalId == null || oneSignalId.isEmpty) {
        print('❌ No OneSignal ID for user: $userId');
        return false;
      }

      print('📤 Sending notification to: $oneSignalId');
      print('📝 Title: $title');

      final payload = {
        'app_id': _oneSignalAppId,
        'include_player_ids': [oneSignalId],
        'headings': {'en': title},
        'contents': {'en': body},
        'data': data,
        'priority': 10,
        'android_priority': 'high',
        'android_channel_id': _channelId,
        'android_sound': _customSound,
        'ios_sound': '$_customSound.wav',
        'large_icon': imageUrl ?? 'https://your-app-icon.png',
      };

      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_oneSignalApiKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ Notification sent successfully with custom sound');
        await _saveNotificationHistory(userId, title, body, data);
        return true;
      } else {
        print('❌ Failed: ${response.statusCode}');
        print('📄 Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Send notification error: $e');
      return false;
    }
  }

  // ============================================================
  // ✅ SEND MESSAGE NOTIFICATION - ADDED
  // ============================================================
  static Future<bool> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String message,
    required String conversationId,
    required String requestId,
    required String senderId,
    required String senderRole,
  }) async {
    return sendNotificationToUser(
      userId: receiverId,
      title: '💬 New Message from $senderName',
      body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
      data: {
        'type': 'new_message',
        'conversationId': conversationId,
        'requestId': requestId,
        'senderName': senderName,
        'senderId': senderId,
        'senderRole': senderRole,
        'message': message,
      },
    );
  }

  // ============================================================
  // ✅ SAVE NOTIFICATION HISTORY
  // ============================================================
  static Future<void> _saveNotificationHistory(
      String userId,
      String title,
      String body,
      Map<String, dynamic> data,
      ) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': data['type'] ?? 'general',
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Save history error: $e');
    }
  }

  // ============================================================
  // ✅ TASK NOTIFICATIONS - CUSTECH
  // ============================================================

  // 🔔 1. TASK CREATED - Notify Technicians
  static Future<void> notifyTechniciansForNewTask({
    required String taskId,
    required String category,
    required String customerName,
    required List<String> technicianIds,
  }) async {
    if (technicianIds.isEmpty) {
      print('⚠️ No technicians to notify');
      return;
    }

    print('📤 Notifying ${technicianIds.length} technicians...');

    for (var techId in technicianIds) {
      try {
        final success = await sendNotificationToUser(
          userId: techId,
          title: '🔔 New Task Available!',
          body: '$customerName needs $category service. Tap to view.',
          data: {
            'type': 'new_task',
            'taskId': taskId,
            'category': category,
            'customerName': customerName,
            'status': 'open',
          },
        );

        if (success) {
          print('✅ Notification sent to technician: $techId');
        } else {
          print('❌ Failed to send to technician: $techId');
        }
      } catch (e) {
        print('❌ Error sending to technician $techId: $e');
      }
    }
  }

  // ✅ 2. TASK ACCEPTED - Notify Customer
  static Future<void> notifyTaskAccepted({
    required String customerId,
    required String taskId,
    required String category,
    required String technicianName,
  }) async {
    await sendNotificationToUser(
      userId: customerId,
      title: '✅ Task Accepted!',
      body: '$technicianName has accepted your $category task.',
      data: {
        'type': 'task_accepted',
        'taskId': taskId,
        'category': category,
        'technicianName': technicianName,
        'status': 'accepted',
      },
    );
  }

  // 🚗 3. TASK IN PROGRESS - Notify Customer
  static Future<void> notifyTaskInProgress({
    required String customerId,
    required String taskId,
    required String category,
    required String technicianName,
  }) async {
    await sendNotificationToUser(
      userId: customerId,
      title: '🚗 Technician is on the way!',
      body: '$technicianName has started your $category task.',
      data: {
        'type': 'task_in_progress',
        'taskId': taskId,
        'category': category,
        'technicianName': technicianName,
        'status': 'inProgress',
      },
    );
  }

  // 🎉 4. TASK COMPLETED - Notify Customer
  static Future<void> notifyTaskCompleted({
    required String customerId,
    required String taskId,
    required String category,
    required String technicianName,
  }) async {
    await sendNotificationToUser(
      userId: customerId,
      title: '🎉 Task Completed!',
      body: '$technicianName has completed your $category task. Please rate your experience.',
      data: {
        'type': 'task_completed',
        'taskId': taskId,
        'category': category,
        'technicianName': technicianName,
        'status': 'completed',
      },
    );
  }

  // ❌ 5. TASK REJECTED - Notify Customer
  static Future<void> notifyTaskRejected({
    required String customerId,
    required String taskId,
    required String category,
  }) async {
    await sendNotificationToUser(
      userId: customerId,
      title: '❌ Task Rejected',
      body: 'Your $category task has been rejected by the technician.',
      data: {
        'type': 'task_rejected',
        'taskId': taskId,
        'category': category,
        'status': 'rejected',
      },
    );
  }

  // ❌ 6. TASK CANCELLED - Notify Both
  static Future<void> notifyTaskCancelled({
    required String customerId,
    required String technicianId,
    required String taskId,
    required String category,
    required String reason,
  }) async {
    final title = '❌ Task Cancelled';
    final body = 'Your $category task has been cancelled. Reason: $reason';

    await sendNotificationToUser(
      userId: customerId,
      title: title,
      body: body,
      data: {
        'type': 'task_cancelled',
        'taskId': taskId,
        'category': category,
        'reason': reason,
        'status': 'cancelled',
      },
    );

    if (technicianId.isNotEmpty) {
      await sendNotificationToUser(
        userId: technicianId,
        title: title,
        body: 'The $category task has been cancelled. Reason: $reason',
        data: {
          'type': 'task_cancelled_tech',
          'taskId': taskId,
          'category': category,
          'reason': reason,
          'status': 'cancelled',
        },
      );
    }
  }

  // ⭐ 7. RATING RECEIVED - Notify Technician
  static Future<void> notifyRatingReceived({
    required String technicianId,
    required String taskId,
    required double rating,
    required String review,
  }) async {
    await sendNotificationToUser(
      userId: technicianId,
      title: '⭐ New Rating Received!',
      body: 'You received a $rating★ rating for task #${taskId.substring(0, 8)}.',
      data: {
        'type': 'rating_received',
        'taskId': taskId,
        'rating': rating.toString(),
        'review': review,
      },
    );
  }

  // ============================================================
  // ✅ NAVIGATION HANDLER
  // ============================================================
  static void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final taskId = data['taskId']?.toString() ?? '';

    print('🔍 Notification type: $type');
    print('📦 TaskId: $taskId');

    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (type == 'new_message') {
      final conversationId = data['conversationId']?.toString() ?? taskId;
      final senderId = data['senderId']?.toString() ?? '';
      final senderName = data['senderName']?.toString() ?? 'User';
      final senderRole = data['senderRole']?.toString() ?? 'customer';

      navigatorKey.currentState?.pushNamed(
        '/chat',
        arguments: {
          'taskId': taskId,
          'conversationId': conversationId,
          'otherUserId': senderId,
          'otherUserName': senderName,
          'otherUserRole': senderRole,
        },
      );
    } else if (type == 'new_task') {
      navigatorKey.currentState?.pushNamed('/technician-dashboard');
    } else if (type == 'task_accepted' ||
        type == 'task_in_progress' ||
        type == 'task_completed' ||
        type == 'task_rejected' ||
        type == 'task_cancelled') {
      navigatorKey.currentState?.pushNamed('/customer-dashboard');
    } else {
      _navigateToDefaultDashboard();
    }
  }

  static void _navigateToDefaultDashboard() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      navigatorKey.currentState?.pushNamed('/login');
      return;
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get()
        .then((doc) {
      if (doc.exists) {
        final role = doc.data()?['role'] ?? 'customer';
        if (role == 'technician') {
          navigatorKey.currentState?.pushNamed('/technician-dashboard');
        } else {
          navigatorKey.currentState?.pushNamed('/customer-dashboard');
        }
      }
    });
  }

  // ============================================================
  // ✅ NOTIFICATION COUNTS
  // ============================================================
  static Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Mark as read error: $e');
    }
  }

  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('❌ Mark all as read error: $e');
    }
  }

  // ============================================================
  // ✅ STREAM NOTIFICATIONS
  // ============================================================
  static Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}