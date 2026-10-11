// lib/core/models/message_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum MessageStatus {
  sent,      // Single tick (sent)
  delivered, // Double tick (delivered)
  read,      // Blue double tick (read)
  failed,    // Failed to send
}

class MessageModel {
  final String id;
  final String taskId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'customer' or 'technician'
  final String receiverId;
  final String receiverName;
  final String message;
  final DateTime timestamp;
  final MessageStatus status;
  final String? repliedToId;
  final String? repliedToMessage;
  final List<String> attachments; // For future use (images, etc.)

  // ✅ Unread tracking
  final bool isReadByCustomer;
  final bool isReadByTechnician;

  MessageModel({
    required this.id,
    required this.taskId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.receiverId,
    required this.receiverName,
    required this.message,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.repliedToId,
    this.repliedToMessage,
    this.attachments = const [],
    this.isReadByCustomer = false,
    this.isReadByTechnician = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // ✅ Parse status from string
    final statusValue = data['status'] ?? 'sent';
    final MessageStatus status = _parseStatus(statusValue);

    return MessageModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? '',
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: status,
      repliedToId: data['repliedToId'],
      repliedToMessage: data['repliedToMessage'],
      attachments: List<String>.from(data['attachments'] ?? []),
      isReadByCustomer: data['isReadByCustomer'] ?? false,
      isReadByTechnician: data['isReadByTechnician'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': _statusToString(status),
      'repliedToId': repliedToId,
      'repliedToMessage': repliedToMessage,
      'attachments': attachments,
      'isReadByCustomer': isReadByCustomer,
      'isReadByTechnician': isReadByTechnician,
    };
  }

  // ✅ Helper: Parse status
  static MessageStatus _parseStatus(String value) {
    switch (value) {
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  // ✅ Helper: Status to string
  static String _statusToString(MessageStatus status) {
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
  // ✅ HELPER GETTERS
  // ============================================================

  bool get isSent => status == MessageStatus.sent;
  bool get isDelivered => status == MessageStatus.delivered;
  bool get isRead => status == MessageStatus.read;
  bool get isFailed => status == MessageStatus.failed;

  // ✅ Check if message is read by receiver
  bool isReadByReceiver(String currentUserId) {
    if (senderId == currentUserId) {
      // I sent this message, check if receiver read it
      return isReadByCustomer || isReadByTechnician;
    } else {
      // I received this message
      return true; // Already read if we're viewing it
    }
  }

  // ✅ Check if message is unread
  bool isUnread(String currentUserId) {
    if (senderId == currentUserId) {
      // Message sent by me
      if (senderRole == 'customer') {
        return !isReadByTechnician;
      } else {
        return !isReadByCustomer;
      }
    } else {
      // Message received by me
      if (senderRole == 'customer') {
        return !isReadByCustomer;
      } else {
        return !isReadByTechnician;
      }
    }
  }

  // ✅ Get status icon
  IconData getStatusIcon({bool isMe = true}) {
    if (!isMe) return Icons.check;

    switch (status) {
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  // ✅ Get status color
  Color getStatusColor({bool isMe = true}) {
    if (!isMe) return Colors.transparent;

    switch (status) {
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.blue;
      case MessageStatus.read:
        return Colors.green;
      case MessageStatus.failed:
        return Colors.red;
    }
  }

  // ✅ Get status label
  String get statusLabel {
    switch (status) {
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
      case MessageStatus.failed:
        return 'Failed';
    }
  }

  // ✅ Copy with method
  MessageModel copyWith({
    String? id,
    String? taskId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? receiverId,
    String? receiverName,
    String? message,
    DateTime? timestamp,
    MessageStatus? status,
    String? repliedToId,
    String? repliedToMessage,
    List<String>? attachments,
    bool? isReadByCustomer,
    bool? isReadByTechnician,
  }) {
    return MessageModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      repliedToId: repliedToId ?? this.repliedToId,
      repliedToMessage: repliedToMessage ?? this.repliedToMessage,
      attachments: attachments ?? this.attachments,
      isReadByCustomer: isReadByCustomer ?? this.isReadByCustomer,
      isReadByTechnician: isReadByTechnician ?? this.isReadByTechnician,
    );
  }

  // ✅ Empty message (for testing)
  static MessageModel empty() {
    return MessageModel(
      id: '',
      taskId: '',
      senderId: '',
      senderName: '',
      senderRole: '',
      receiverId: '',
      receiverName: '',
      message: '',
      timestamp: DateTime.now(),
    );
  }

  // ✅ From JSON (for testing)
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      taskId: json['taskId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderRole: json['senderRole'] ?? '',
      receiverId: json['receiverId'] ?? '',
      receiverName: json['receiverName'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      status: _parseStatus(json['status'] ?? 'sent'),
      repliedToId: json['repliedToId'],
      repliedToMessage: json['repliedToMessage'],
      attachments: List<String>.from(json['attachments'] ?? []),
      isReadByCustomer: json['isReadByCustomer'] ?? false,
      isReadByTechnician: json['isReadByTechnician'] ?? false,
    );
  }

  // ✅ To JSON (for testing)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'status': _statusToString(status),
      'repliedToId': repliedToId,
      'repliedToMessage': repliedToMessage,
      'attachments': attachments,
      'isReadByCustomer': isReadByCustomer,
      'isReadByTechnician': isReadByTechnician,
    };
  }

  // ✅ Compare two messages
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}