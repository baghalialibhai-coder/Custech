// lib/services/task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/job_model.dart';
import '../core/models/task_model.dart';
import '../core/constants/categories.dart';
import 'one_Signal_Service.dart';
import 'location_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocationService _locationService = LocationService();

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
  // ✅ CREATE A NEW TASK + NOTIFY TECHNICIANS
  // ============================================================
  Future<String> createTask(TaskModel task) async {
    try {
      // ✅ Save task
      final docRef = await _firestore.collection('tasks').add(task.toFirestore());
      final taskId = docRef.id;

      print('✅ Task created: $taskId');
      print('📂 Category: ${task.category}');
      print('📍 Pincode: ${task.pincode}');
      print('📍 Location: ${task.latitude}, ${task.longitude}');

      // ✅ Find matching technicians and notify them
      await _notifyMatchingTechnicians(taskId, task);

      return taskId;

    } catch (e) {
      print('❌ Error creating task: $e');
      throw Exception('Failed to create task: $e');
    }
  }

  // ============================================================
  // ✅ NOTIFY MATCHING TECHNICIANS
  // ============================================================
  Future<void> _notifyMatchingTechnicians(String taskId, TaskModel task) async {
    try {
      print('🔍 Looking for technicians...');
      print('📂 Category: ${task.category}');
      print('📍 Pincode: ${task.pincode}');
      print('📍 Location: ${task.latitude}, ${task.longitude}');

      // ✅ Get technicians by category
      final techSnapshot = await _firestore
          .collection('technicians')
          .where('categories', arrayContains: task.category)
          .get();

      print('📊 Total technicians with category: ${techSnapshot.docs.length}');

      if (techSnapshot.docs.isEmpty) {
        print('❌ No technicians found with category: ${task.category}');
        return;
      }

      final List<String> matchingTechIds = [];

      for (var doc in techSnapshot.docs) {
        final data = doc.data();
        final techId = doc.id;
        final displayName = data['displayName'] ?? 'Technician';

        print('🔍 Checking technician: $displayName');

        // ✅ Check availability
        // final isAvailable = data['isAvailable'] ?? false;
        // final isOnline = data['isOnline'] ?? false;
        //
        // if (!isAvailable || !isOnline) {
        //   print('   ⏭️ Technician not available');
        //   continue;
        // }

        // ✅ Check pincode match
        final techPincode = data['pincode']?.toString() ?? '';
        final servicePinCodes = List<String>.from(data['servicePinCodes'] ?? []);

        bool pincodeMatch = false;
        if (task.pincode.isNotEmpty) {
          if (techPincode == task.pincode || servicePinCodes.contains(task.pincode)) {
            pincodeMatch = true;
            print('   ✅ Pincode match: ${task.pincode}');
          }
        }

        // ✅ Check distance match
        bool distanceMatch = false;
        final techLat = (data['latitude'] ?? 0.0).toDouble();
        final techLng = (data['longitude'] ?? 0.0).toDouble();
        final serviceRadius = (data['serviceRadius'] ?? 15.0).toDouble();

        if (techLat != 0.0 && techLng != 0.0 && task.latitude != 0.0 && task.longitude != 0.0) {
          final distance = _locationService.calculateDistanceHaversine(
            task.latitude, task.longitude,
            techLat, techLng,
          );

          if (distance <= serviceRadius) {
            distanceMatch = true;
            print('   ✅ Distance match: ${distance.toStringAsFixed(2)} km');
          }
        }

        // ✅ If either pincode or distance matches
        if (pincodeMatch || distanceMatch) {
          matchingTechIds.add(techId);
          print('   ✅ Technician added to matching list');
        }
      }

      print('✅ Found ${matchingTechIds.length} matching technicians');

      // ✅ Send notification to technicians
      if (matchingTechIds.isNotEmpty) {
        await OneSignalNotificationService.notifyTechniciansForNewTask(
          taskId: taskId,
          category: task.category,
          customerName: task.customerName,
          technicianIds: matchingTechIds,
        );
        print('📤 Sent notifications to ${matchingTechIds.length} technicians');
      } else {
        print('❌ No matching technicians found');
      }

    } catch (e) {
      print('❌ Error notifying technicians: $e');
    }
  }

  // ============================================================
  // ✅ ACCEPT TASK (Technician Accepts) + NOTIFY CUSTOMER
  // ============================================================
  Future<void> acceptTask(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // ✅ Get technician details
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final technicianName = userData['displayName'] ?? userData['name'] ?? 'Technician';

      // ✅ Get task details
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) throw Exception('Task not found');
      final taskData = taskDoc.data()!;
      final customerId = taskData['customerId'] ?? '';
      final category = taskData['category'] ?? 'Service';

      // ✅ Update task
      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'accepted',
        'technicianId': user.uid,
        'technicianName': technicianName,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Task accepted: $taskId by $technicianName');

      // ✅ Notify customer
      if (customerId.isNotEmpty) {
        await OneSignalNotificationService.notifyTaskAccepted(
          customerId: customerId,
          taskId: taskId,
          category: category,
          technicianName: technicianName,
        );
        print('📤 Notification sent to customer');
      }

      // ✅ Notify technician (confirmation)
      await OneSignalNotificationService.sendNotificationToUser(
        userId: user.uid,
        title: '✅ Task Accepted!',
        body: 'You have accepted the $category task.',
        data: {
          'type': 'task_accepted_confirm',
          'taskId': taskId,
          'category': category,
        },
      );

    } catch (e) {
      print('❌ Error accepting task: $e');
      throw Exception('Failed to accept task: $e');
    }
  }

  // ============================================================
  // ✅ REJECT TASK (Technician Rejects) + NOTIFY CUSTOMER
  // ============================================================
  Future<void> rejectTask(String taskId) async {
    try {
      final technicianId = _auth.currentUser?.uid;
      if (technicianId == null) throw Exception('Not logged in');

      // ✅ Get task details
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) throw Exception('Task not found');
      final taskData = taskDoc.data()!;
      final customerId = taskData['customerId'] ?? '';
      final category = taskData['category'] ?? 'Service';

      // ✅ Update task
      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': technicianId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Task rejected: $taskId');

      // ✅ Notify customer
      if (customerId.isNotEmpty) {
        await OneSignalNotificationService.notifyTaskRejected(
          customerId: customerId,
          taskId: taskId,
          category: category,
        );
        print('📤 Notification sent to customer');
      }

    } catch (e) {
      print('❌ Error rejecting task: $e');
      throw Exception('Failed to reject task: $e');
    }
  }

  // ============================================================
  // ✅ START TASK (Technician Starts Work) + NOTIFY CUSTOMER
  // ============================================================
  Future<void> startTask(String taskId) async {
    try {
      final technicianId = _auth.currentUser?.uid;
      if (technicianId == null) throw Exception('Not logged in');

      // ✅ Get task details
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) throw Exception('Task not found');
      final taskData = taskDoc.data()!;
      final customerId = taskData['customerId'] ?? '';
      final category = taskData['category'] ?? 'Service';
      final technicianName = taskData['technicianName'] ?? 'Technician';

      // ✅ Update task
      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'inProgress',
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Task started: $taskId');

      // ✅ Notify customer
      if (customerId.isNotEmpty) {
        await OneSignalNotificationService.notifyTaskInProgress(
          customerId: customerId,
          taskId: taskId,
          category: category,
          technicianName: technicianName,
        );
        print('📤 Notification sent to customer');
      }

    } catch (e) {
      print('❌ Error starting task: $e');
      throw Exception('Failed to start task: $e');
    }
  }

  // ============================================================
  // ✅ COMPLETE TASK (Technician Completes Work) + NOTIFY CUSTOMER
  // ============================================================
  Future<void> completeTask(
      String taskId, {
        double? rating,
        String? review,
      }) async {
    try {
      final technicianId = _auth.currentUser?.uid;
      if (technicianId == null) throw Exception('Not logged in');

      // ✅ Get task details
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) throw Exception('Task not found');
      final taskData = taskDoc.data()!;
      final customerId = taskData['customerId'] ?? '';
      final category = taskData['category'] ?? 'Service';
      final technicianName = taskData['technicianName'] ?? 'Technician';

      // ✅ Prepare update data
      Map<String, dynamic> updateData = {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (rating != null) {
        updateData['customerRating'] = rating;
      }
      if (review != null && review.isNotEmpty) {
        updateData['customerReview'] = review;
      }

      // ✅ Update task
      await _firestore.collection('tasks').doc(taskId).update(updateData);

      print('✅ Task completed: $taskId');

      // ✅ Notify customer
      if (customerId.isNotEmpty) {
        await OneSignalNotificationService.notifyTaskCompleted(
          customerId: customerId,
          taskId: taskId,
          category: category,
          technicianName: technicianName,
        );
        print('📤 Notification sent to customer');
      }

      // ✅ Notify technician (confirmation)
      await OneSignalNotificationService.sendNotificationToUser(
        userId: technicianId,
        title: '🎉 Job Completed Successfully',
        body: 'You have completed the $category job.',
        data: {
          'type': 'task_completed_tech',
          'taskId': taskId,
          'category': category,
        },
      );

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
  // ✅ CANCEL TASK (Customer or Technician) + NOTIFY BOTH
  // ============================================================
  Future<void> cancelTask(String taskId, String reason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // ✅ Get task details
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) throw Exception('Task not found');
      final taskData = taskDoc.data()!;
      final customerId = taskData['customerId'] ?? '';
      final technicianId = taskData['technicianId'] ?? '';
      final category = taskData['category'] ?? 'Service';

      // ✅ Update task
      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
        'cancelledBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Task cancelled: $taskId');

      // ✅ Notify both parties
      await OneSignalNotificationService.notifyTaskCancelled(
        customerId: customerId,
        technicianId: technicianId,
        taskId: taskId,
        category: category,
        reason: reason,
      );
      print('📤 Notification sent to both parties');

    } catch (e) {
      print('❌ Error cancelling task: $e');
      throw Exception('Failed to cancel task: $e');
    }
  }

  // ============================================================
  // ✅ RATE TECHNICIAN + NOTIFY TECHNICIAN
  // ============================================================
  Future<void> rateTechnician(String taskId, double rating, String review) async {
    try {
      // ✅ Get task details
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) throw Exception('Task not found');
      final taskData = taskDoc.data()!;
      final technicianId = taskData['technicianId'] ?? '';

      // ✅ Update task
      await _firestore.collection('tasks').doc(taskId).update({
        'customerRating': rating,
        'customerReview': review,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Rating saved: $rating★');

      // ✅ Notify technician
      if (technicianId.isNotEmpty) {
        await OneSignalNotificationService.notifyRatingReceived(
          technicianId: technicianId,
          taskId: taskId,
          rating: rating,
          review: review,
        );
        print('📤 Notification sent to technician');
      }

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