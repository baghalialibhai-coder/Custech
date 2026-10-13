// lib/services/job_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/job_model.dart';
import '../core/constants/categories.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // ✅ GET AVAILABLE TASKS (For Technicians)
  // ============================================================
  Stream<List<JobModel>> getAvailableTasks() {
    return _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => JobModel.fromFirestore(doc)).toList();
    });
  }

  // ============================================================
  // ✅ GET AVAILABLE JOBS (Filtered by Categories + Pincode)
  // ============================================================
  Stream<List<JobModel>> getAvailableJobs(
    List<String> categories,
    String? pincode,
  ) {
    if (categories.isEmpty) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'open')
        .where('category', whereIn: categories);

    if (pincode != null && pincode.isNotEmpty) {
      query = query.where('pincode', isEqualTo: pincode);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => JobModel.fromFirestore(doc)).toList();
    });
  }

  // ============================================================
  // ✅ GET JOBS BY STATUS (For Technicians)
  // ============================================================
  Stream<List<JobModel>> getJobsByStatus(JobStatus status) {
    final technicianId = _auth.currentUser?.uid;
    if (technicianId == null) {
      return Stream.value([]);
    }

    String statusString;
    switch (status) {
      case JobStatus.available:
        statusString = 'open';
        break;
      case JobStatus.accepted:
        statusString = 'accepted';
        break;
      case JobStatus.inProgress:
        statusString = 'inProgress';
        break;
      case JobStatus.completed:
        statusString = 'completed';
        break;
      case JobStatus.cancelled:
        statusString = 'cancelled';
        break;
      case JobStatus.rejected:
        statusString = 'rejected';
        break;
    }

    Query query = _firestore
        .collection('tasks')
        .where('status', isEqualTo: statusString)
        .orderBy('createdAt', descending: true);

    if (status != JobStatus.available) {
      query = query.where('technicianId', isEqualTo: technicianId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => JobModel.fromFirestore(doc)).toList();
    });
  }

  // ============================================================
  // ✅ ACCEPT JOB
  // ============================================================
  Future<void> acceptJob(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final technicianName = userData['displayName'] ?? userData['name'] ?? 'Technician';

    await _firestore.collection('tasks').doc(jobId).update({
      'status': 'accepted',
      'technicianId': user.uid,
      'technicianName': technicianName,
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Job accepted: $jobId by $technicianName');
  }

  // ============================================================
  // ✅ REJECT JOB
  // ============================================================
  Future<void> rejectJob(String jobId) async {
    final technicianId = _auth.currentUser?.uid;
    if (technicianId == null) throw Exception('Not logged in');

    await _firestore.collection('tasks').doc(jobId).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': technicianId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Job rejected: $jobId');
  }

  // ============================================================
  // ✅ START JOB
  // ============================================================
  Future<void> startJob(String jobId) async {
    final technicianId = _auth.currentUser?.uid;
    if (technicianId == null) throw Exception('Not logged in');

    await _firestore.collection('tasks').doc(jobId).update({
      'status': 'inProgress',
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Job started: $jobId');
  }

  // ============================================================
  // ✅ COMPLETE JOB
  // ============================================================
  Future<void> completeJob(
    String jobId, {
    double? rating,
    String? review,
  }) async {
    final technicianId = _auth.currentUser?.uid;
    if (technicianId == null) throw Exception('Not logged in');

    Map<String, dynamic> updateData = {
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (rating != null) updateData['customerRating'] = rating;
    if (review != null && review.isNotEmpty) updateData['customerReview'] = review;

    await _firestore.collection('tasks').doc(jobId).update(updateData);
    print('✅ Job completed: $jobId');
  }

  // ============================================================
  // ✅ CANCEL JOB
  // ============================================================
  Future<void> cancelJob(String jobId, String reason) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _firestore.collection('tasks').doc(jobId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancellationReason': reason,
      'cancelledBy': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Job cancelled: $jobId');
  }

  // ============================================================
  // ✅ GET JOB COUNT BY STATUS
  // ============================================================
  Future<Map<JobStatus, int>> getJobCounts() async {
    final technicianId = _auth.currentUser?.uid;
    if (technicianId == null) return {};

    final snapshot = await _firestore
        .collection('tasks')
        .where('technicianId', isEqualTo: technicianId)
        .get();

    final counts = <JobStatus, int>{};
    for (var status in JobStatus.values) {
      if (status == JobStatus.available) continue;

      String statusString;
      switch (status) {
        case JobStatus.accepted:
          statusString = 'accepted';
          break;
        case JobStatus.inProgress:
          statusString = 'inProgress';
          break;
        case JobStatus.completed:
          statusString = 'completed';
          break;
        case JobStatus.cancelled:
          statusString = 'cancelled';
          break;
        case JobStatus.rejected:
          statusString = 'rejected';
          break;
        default:
          continue;
      }

      counts[status] = snapshot.docs
          .where((doc) => doc['status'] == statusString)
          .length;
    }
    return counts;
  }

  // ============================================================
  // ✅ GET TECHNICIAN STATS
  // ============================================================
  Future<Map<String, dynamic>> getTechnicianStats() async {
    final technicianId = _auth.currentUser?.uid;
    if (technicianId == null) return {};

    final jobsSnapshot = await _firestore
        .collection('tasks')
        .where('technicianId', isEqualTo: technicianId)
        .get();

    int totalJobs = jobsSnapshot.docs.length;
    int completedJobs = jobsSnapshot.docs
        .where((doc) => doc['status'] == 'completed')
        .length;

    double totalEarnings = 0;
    double totalRating = 0;
    int ratingCount = 0;

    for (var doc in jobsSnapshot.docs) {
      final data = doc.data();

      if (data['status'] == 'completed') {
        final budget = (data['budget'] ?? 0.0).toDouble();
        final serviceCharge = (data['serviceCharge'] ?? 0.0).toDouble();
        totalEarnings += budget + serviceCharge;
      }

      if (data['customerRating'] != null) {
        totalRating += (data['customerRating'] as num).toDouble();
        ratingCount++;
      }
    }

    return {
      'totalJobs': totalJobs,
      'completedJobs': completedJobs,
      'totalEarnings': totalEarnings,
      'averageRating': ratingCount > 0 ? totalRating / ratingCount : 0.0,
    };
  }

  // ============================================================
  // ✅ GET JOB BY ID
  // ============================================================
  Future<JobModel?> getJobById(String jobId) async {
    final doc = await _firestore.collection('tasks').doc(jobId).get();
    if (!doc.exists) return null;
    return JobModel.fromFirestore(doc);
  }

  // ============================================================
  // ✅ CREATE JOB (Customer Creates)
  // ============================================================
  Future<String> createJob(JobModel job) async {
    final docRef = await _firestore.collection('tasks').add(job.toFirestore());
    await docRef.update({'id': docRef.id});
    print('✅ Job created: ${docRef.id}');
    return docRef.id;
  }

  // ============================================================
  // ✅ GET ALL CATEGORIES
  // ============================================================
  List<String> getAllCategories() {
    return AppCategories.allCategories;
  }

  // ============================================================
  // ✅ CHECK IF TECHNICIAN HAS MATCHING CATEGORY + PINCODE
  // ============================================================
  Future<bool> hasMatchingTechnician({
    required String category,
    required String pincode,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('technicians')
          .where('categories', arrayContains: category)
          .where('pincode', isEqualTo: pincode)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking technician: $e');
      return false;
    }
  }
}
