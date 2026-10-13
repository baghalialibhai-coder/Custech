// lib/services/one_Signal_Service.dart

import 'package:flutter/foundation.dart';
import 'fcm_notification_service.dart';

class OneSignalNotificationService {
  static Future<void> initialize() async {
    debugPrint('⚡ Delegating Notification Service initialization to FcmNotificationService...');
    await FcmNotificationService.initialize();
  }

  static Future<void> saveCurrentUserOneSignalId() async {
    await FcmNotificationService.saveCurrentUserFcmToken();
  }

  static Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    debugPrint('⚡ Node.js Cloud Function triggers notification automatically for $userId');
    return true;
  }

  static Future<void> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String message,
    required String conversationId,
    required String requestId,
    required String senderId,
    required String senderRole,
  }) async {
    debugPrint('⚡ Node.js Cloud Function triggers message notification automatically');
  }

  static Future<void> notifyTaskAccepted({required String taskId, required String customerId, required String taskTitle, category, technicianName}) async {}
  static Future<void> notifyTaskRejected({required String taskId, required String customerId, required String taskTitle, category}) async {}
  static Future<void> notifyTaskInProgress({required String taskId, required String customerId, required String taskTitle, category, technicianName}) async {}
  static Future<void> notifyTaskCompleted({required String taskId, required String customerId, required String taskTitle, category, technicianName}) async {}
  static Future<void> notifyTaskCancelled({required String taskId, required String recipientId, required String taskTitle, required String reason, category, technicianId, customerId}) async {}
  static Future<void> notifyTechniciansForNewTask({required String taskId, required String taskTitle, required String category, required List<String> technicianIds, required String customerName}) async {}
  static Future<void> notifyRatingReceived({required String userId, required double rating, required String reviewerName, required String review, required String taskId, technicianId}) async {}
}
