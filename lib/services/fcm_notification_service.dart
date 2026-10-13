// lib/services/fcm_notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize FCM permissions and save the current user's token to Firestore
  static Future<void> initialize() async {
    try {
      // 1. Request Notification Permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('✅ FCM Notification Permission Granted');
        await saveCurrentUserFcmToken();
      } else {
        debugPrint('⚠️ FCM Notification Permission Denied');
      }

      // 2. Listen for Token Refresh
      _messaging.onTokenRefresh.listen((newToken) {
        saveCurrentUserFcmToken();
      });
    } catch (e) {
      debugPrint('❌ FCM Initialization Error: $e');
    }
  }

  /// Save current logged-in user's FCM token to users, merchants, or technicians collection
  static Future<void> saveCurrentUserFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      final batch = _firestore.batch();

      // Save token in users collection
      final userRef = _firestore.collection('users').doc(user.uid);
      batch.set(userRef, {
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Save token in merchants collection if doc exists
      final merchantRef = _firestore.collection('merchants').doc(user.uid);
      batch.set(merchantRef, {
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      // Save token in technicians collection if doc exists
      final techRef = _firestore.collection('technicians').doc(user.uid);
      batch.set(techRef, {
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      await batch.commit();
      debugPrint('✅ FCM Token saved for user ${user.uid}: $token');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }
}
