import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/models/task_model.dart';

// ✅ Provider for searching services in HomeTab
final customerSearchProvider = StateProvider<String>((ref) => "");

// ✅ StreamProvider for counting tasks by status
final customerTaskCountsProvider = StreamProvider<Map<String, int>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value({'open': 0, 'accepted': 0, 'inProgress': 0, 'completed': 0});

  return FirebaseFirestore.instance
      .collection('tasks')
      .where('customerId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
    int open = 0;
    int accepted = 0;
    int inProgress = 0;
    int completed = 0;

    for (var doc in snapshot.docs) {
      final status = doc.data()['status'] ?? '';
      switch (status) {
        case 'open': open++; break;
        case 'accepted': accepted++; break;
        case 'inProgress': inProgress++; break;
        case 'completed': completed++; break;
      }
    }
    return {
      'open': open,
      'accepted': accepted,
      'inProgress': inProgress,
      'completed': completed,
    };
  });
});

// ✅ StreamProvider for fetching tasks by status
final customerTasksProvider = StreamProvider.family<List<TaskModel>, String>((ref, status) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('tasks')
      .where('customerId', isEqualTo: user.uid)
      .where('status', isEqualTo: status)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    // ✅ Use fromFirestore instead of fromMap
    return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
  });
});

// ✅ StreamProvider for unread messages count
final unreadMessagesCountProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('chats')
      .where('participants', arrayContains: user.uid)
      .snapshots()
      .map((snapshot) {
    int totalUnread = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      dynamic unreadCount = data['unreadCount'];
      
      int count = 0;
      if (unreadCount is int) {
        count = unreadCount;
      } else if (unreadCount is String) {
        count = int.tryParse(unreadCount) ?? 0;
      } else if (unreadCount is num) {
        count = unreadCount.toInt();
      } else if (unreadCount is Map) {
        count = (unreadCount['value'] ?? 0) as int;
      }
      
      if (count > 0) {
        totalUnread += count;
      }
    }
    return totalUnread;
  });
});
