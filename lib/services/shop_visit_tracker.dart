// lib/services/shop_visit_tracker.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ShopVisitTracker {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tracks a visit when a customer, technician, or merchant views a shop profile.
  /// Automatically filters out self-visits (store owner visiting their own shop).
  static Future<void> trackVisit({
    required Map<String, dynamic> merchantData,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final String visitorId = user.uid;
      final String merchantId = merchantData['merchantId'] ?? merchantData['userId'] ?? '';
      final String shopName = merchantData['shopName'] ?? 'Store';

      if (merchantId.isEmpty) return;

      // RULE 1: Self-Visit Filter (No notification if merchant visits their own shop)
      if (visitorId == merchantId) {
        debugPrint('ℹ️ Self-visit detected for store $shopName. Skipping visit tracking.');
        return;
      }

      // Fetch visitor details from Firestore 'users'
      String visitorName = user.displayName ?? 'Customer';
      String visitorRole = 'customer';
      String visitorPhoto = user.photoURL ?? '';

      try {
        final visitorUserDoc = await _firestore.collection('users').doc(visitorId).get();
        if (visitorUserDoc.exists) {
          final data = visitorUserDoc.data()!;
          visitorName = data['displayName'] ?? data['name'] ?? visitorName;
          visitorRole = data['role'] ?? 'customer';
          visitorPhoto = data['profileImageUrl'] ?? data['profileImage'] ?? visitorPhoto;
        }
      } catch (e) {
        debugPrint('Error getting visitor user details: $e');
      }

      // Check if visit was recorded in the last 1 hour to prevent rapid spamming
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final recentVisits = await _firestore
          .collection('shop_visits')
          .where('visitorId', isEqualTo: visitorId)
          .where('merchantId', isEqualTo: merchantId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(oneHourAgo))
          .limit(1)
          .get();

      if (recentVisits.docs.isNotEmpty) {
        debugPrint('ℹ️ Recent visit already recorded for $visitorName at $shopName within 1 hour.');
        return;
      }

      // Create shop visit record
      final visitRef = _firestore.collection('shop_visits').doc();
      final visitData = {
        'visitId': visitRef.id,
        'visitorId': visitorId,
        'visitorName': visitorName,
        'visitorRole': visitorRole,
        'visitorPhoto': visitorPhoto,
        'merchantId': merchantId,
        'shopName': shopName,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await visitRef.set(visitData);
      debugPrint('✅ Shop visit logged for $visitorName ($visitorRole) at shop $shopName');

      // Create notification directly in Firestore for instant real-time app update
      final notificationRef = _firestore.collection('notifications').doc();
      await notificationRef.set({
        'notificationId': notificationRef.id,
        'merchantId': merchantId,
        'userId': merchantId,
        'title': 'New Shop Visitor! 🏪',
        'body': '$visitorName (${_capitalize(visitorRole)}) visited your shop "$shopName"',
        'visitorId': visitorId,
        'visitorName': visitorName,
        'visitorRole': visitorRole,
        'visitorPhoto': visitorPhoto,
        'shopName': shopName,
        'type': 'shop_visit',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Real-time notification document created for merchant $merchantId');

    } catch (e) {
      debugPrint('❌ Error in trackVisit: $e');
    }
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
