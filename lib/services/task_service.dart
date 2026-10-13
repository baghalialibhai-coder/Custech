// lib/services/task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/task_model.dart';
import '../core/constants/categories.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // ✅ GET OPEN TASKS (For Technicians)
  // ============================================================
  Stream<List<TaskModel>> getOpenTasks() {
    return _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    });
  }

  // ============================================================
  // ✅ GET OPEN TASKS BY CATEGORY
  // ============================================================
  Stream<List<TaskModel>> getOpenTasksByCategory(String category) {
    return _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'open')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    });
  }

  // ============================================================
  // ✅ GET TASKS BY STATUS (For Customer)
  // ============================================================
  Stream<List<TaskModel>> getTasksByStatus(TaskStatus status) {
    final customerId = _auth.currentUser?.uid;
    if (customerId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('tasks')
        .where('customerId', isEqualTo: customerId)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    });
  }

  // ============================================================
  // ✅ GET TASKS BY CUSTOMER ID
  // ============================================================
  Stream<List<TaskModel>> getTasksByCustomerId(String customerId) {
    return _firestore
        .collection('tasks')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    });
  }

  // ============================================================
  // ✅ CREATE A NEW TASK (Triggers Node.js onTaskCreated Function)
  // ============================================================
  Future<String> createTask(TaskModel task) async {
    try {
      final docRef = await _firestore.collection('tasks').add(task.toFirestore());
      final taskId = docRef.id;

      // Ensure doc ID is saved
      await docRef.update({'id': taskId});

      print('✅ Task created: $taskId in category ${task.category}');
      return taskId;
    } catch (e) {
      print('❌ Error creating task: $e');
      throw Exception('Failed to create task: $e');
    }
  }

  // ============================================================
  // ✅ ACCEPT TASK (Technician Accepts - Triggers Node.js onTaskUpdated)
  // ============================================================
  Future<void> acceptTask(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Get technician details
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final technicianName = userData['displayName'] ?? userData['name'] ?? 'Technician';

      // Update task in Firestore
      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'accepted',
        'technicianId': user.uid,
        'technicianName': technicianName,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Task accepted: $taskId by $technicianName');
    } catch (e) {
      print('❌ Error accepting task: $e');
      throw Exception('Failed to accept task: $e');
    }
  }

  // ============================================================
  // ✅ REJECT TASK (Technician Rejects - Triggers Node.js onTaskUpdated)
  // ============================================================
  Future<void> rejectTask(String taskId) async {
    try {
      final technicianId = _auth.currentUser?.uid;
      if (technicianId == null) throw Exception('Not logged in');

      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': technicianId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Task rejected: $taskId');
    } catch (e) {
      print('❌ Error rejecting task: $e');
      throw Exception('Failed to reject task: $e');
    }
  }

  // ============================================================
  // ✅ START TASK (Technician Starts Work - Triggers Node.js onTaskUpdated)
  // ============================================================
  Future<void> startTask(String taskId) async {
    try {
      final technicianId = _auth.currentUser?.uid;
      if (technicianId == null) throw Exception('Not logged in');

      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'inProgress',
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Task started: $taskId');
    } catch (e) {
      print('❌ Error starting task: $e');
      throw Exception('Failed to start task: $e');
    }
  }

  // ============================================================
  // ✅ COMPLETE TASK (Technician Completes Work - Triggers Node.js onTaskUpdated)
  // ============================================================
  Future<void> completeTask(
    String taskId, {
    double? rating,
    String? review,
  }) async {
    try {
      final technicianId = _auth.currentUser?.uid;
      if (technicianId == null) throw Exception('Not logged in');

      Map<String, dynamic> updateData = {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (rating != null) updateData['customerRating'] = rating;
      if (review != null && review.isNotEmpty) updateData['customerReview'] = review;

      await _firestore.collection('tasks').doc(taskId).update(updateData);
      print('✅ Task completed: $taskId');
    } catch (e) {
      print('❌ Error completing task: $e');
      throw Exception('Failed to complete task: $e');
    }
  }

  // ============================================================
  // ✅ UPDATE TASK STATUS
  // ============================================================
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    try {
      final updateData = {
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      switch (newStatus) {
        case TaskStatus.accepted:
          updateData['acceptedAt'] = FieldValue.serverTimestamp();
          break;
        case TaskStatus.inProgress:
          updateData['startedAt'] = FieldValue.serverTimestamp();
          break;
        case TaskStatus.completed:
          updateData['completedAt'] = FieldValue.serverTimestamp();
          break;
        case TaskStatus.cancelled:
          updateData['cancelledAt'] = FieldValue.serverTimestamp();
          break;
        default:
          break;
      }

      await _firestore.collection('tasks').doc(taskId).update(updateData);
      print('✅ Task status updated: ${newStatus.name}');
    } catch (e) {
      print('❌ Error updating task status: $e');
      throw Exception('Failed to update task status: $e');
    }
  }

  // ============================================================
  // ✅ CANCEL TASK (Customer or Technician)
  // ============================================================
  Future<void> cancelTask(String taskId, String reason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
        'cancelledBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Task cancelled: $taskId');
    } catch (e) {
      print('❌ Error cancelling task: $e');
      throw Exception('Failed to cancel task: $e');
    }
  }

  // ============================================================
  // ✅ RATE TECHNICIAN
  // ============================================================
  Future<void> rateTechnician(String taskId, double rating, String review) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'customerRating': rating,
        'customerReview': review,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Rating saved: $rating★');
    } catch (e) {
      print('❌ Error rating technician: $e');
      throw Exception('Failed to rate technician: $e');
    }
  }

  // ============================================================
  // ✅ GET TASK COUNT BY STATUS
  // ============================================================
  Future<Map<TaskStatus, int>> getTaskCounts() async {
    final customerId = _auth.currentUser?.uid;
    if (customerId == null) return {};

    final snapshot = await _firestore
        .collection('tasks')
        .where('customerId', isEqualTo: customerId)
        .get();

    final counts = <TaskStatus, int>{};
    for (var status in TaskStatus.values) {
      counts[status] = snapshot.docs
          .where((doc) => doc['status'] == status.name)
          .length;
    }
    return counts;
  }

  // ============================================================
  // ✅ GET ALL CATEGORIES
  // ============================================================
  List<String> getAllCategories() {
    return AppCategories.allCategories;
  }

  // ============================================================
  // ✅ GET TASK BY ID
  // ============================================================
  Future<TaskModel?> getTaskById(String taskId) async {
    final doc = await _firestore.collection('tasks').doc(taskId).get();
    if (!doc.exists) return null;
    return TaskModel.fromFirestore(doc);
  }

  // ============================================================
  // ✅ GET TECHNICIAN'S TASKS
  // ============================================================
  Stream<List<TaskModel>> getTechnicianTasks() {
    final technicianId = _auth.currentUser?.uid;
    if (technicianId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('tasks')
        .where('technicianId', isEqualTo: technicianId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    });
  }

  // ============================================================
  // ✅ GET TECHNICIAN TASKS BY STATUS
  // ============================================================
  Stream<List<TaskModel>> getTechnicianTasksByStatus(TaskStatus status) {
    final technicianId = _auth.currentUser?.uid;
    if (technicianId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('tasks')
        .where('technicianId', isEqualTo: technicianId)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    });
  }
}
