// lib/Presentations/technicianscreen/tabs/home_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/job_model.dart';
import '../../../core/models/task_model.dart';
import '../../../services/job_service.dart';
import '../../../services/task_service.dart';
import '../../../services/location_service.dart';
import '../widget/job_stats_card.dart';
import '../widget/task_card_technician.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  final JobService _jobService = JobService();
  final TaskService _taskService = TaskService();
  final LocationService _locationService = LocationService();

  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _isAccepting = false;
  String? _technicianId;

  // ✅ Technician Data for Matching
  List<String> _technicianCategories = [];
  String? _technicianPincode;
  double _technicianLat = 0.0;
  double _technicianLng = 0.0;
  double _technicianRadius = 15.0;
  bool _isLoadingTechData = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _getTechnicianId();
    _loadTechnicianData();
  }

  Future<void> _getTechnicianId() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _technicianId = user?.uid;
    });
  }

  // ============================================================
  // ✅ LOAD TECHNICIAN DATA (Including Location)
  // ============================================================
  Future<void> _loadTechnicianData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingTechData = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _technicianCategories = List<String>.from(data['categories'] ?? []);
          _technicianPincode = data['pincode'] ?? '';
          _technicianLat = (data['latitude'] ?? 0.0).toDouble();
          _technicianLng = (data['longitude'] ?? 0.0).toDouble();
          _technicianRadius = (data['serviceRadius'] ?? 15.0).toDouble();
          _isLoadingTechData = false;
        });
        print('✅ Technician Data Loaded:');
        print('   Categories: ${_technicianCategories.length}');
        print('   Pincode: $_technicianPincode');
        print('   Location: $_technicianLat, $_technicianLng');
        print('   Service Radius: $_technicianRadius km');
      } else {
        setState(() => _isLoadingTechData = false);
      }
    } catch (e) {
      print('❌ Error loading technician data: $e');
      setState(() => _isLoadingTechData = false);
    }
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final stats = await _jobService.getTechnicianStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTechData) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_technicianCategories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No categories selected',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please select categories from your profile',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Stats Cards
              _buildStatsCards(),

              const SizedBox(height: 24),

              // ✅ Available Jobs Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Jobs',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      'Open',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ✅ Available Tasks with Location Matching
              _buildAvailableTasks(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ✅ BUILD STATS CARDS
  // ============================================================
  Widget _buildStatsCards() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: JobStatsCard(
                title: 'Total Jobs',
                value: '${_stats['totalJobs'] ?? 0}',
                icon: Icons.work_outline,
                color: const Color(0xFF1A237E),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: JobStatsCard(
                title: 'Completed',
                value: '${_stats['completedJobs'] ?? 0}',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: JobStatsCard(
                title: 'Earnings',
                value: 'PKR ${_stats['totalEarnings']?.toStringAsFixed(0) ?? '0'}',
                icon: Icons.attach_money_outlined,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: JobStatsCard(
                title: 'Rating',
                value: '${(_stats['averageRating'] ?? 0).toStringAsFixed(1)} ★',
                icon: Icons.star_outline,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // ✅ BUILD AVAILABLE TASKS WITH MATCHING
  // ============================================================
  Widget _buildAvailableTasks() {
    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.getOpenTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          print('❌ Stream error: ${snapshot.error}');
          return _buildErrorState(snapshot.error.toString());
        }

        final allTasks = snapshot.data ?? [];
        print('📋 Total open tasks: ${allTasks.length}');

        // ✅ Filter tasks based on technician's location and categories
        final matchingTasks = _filterMatchingTasks(allTasks);

        if (matchingTasks.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _loadTechnicianData();
            setState(() {});
          },
          color: const Color(0xFF1A237E),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matchingTasks.length,
            itemBuilder: (context, index) {
              final task = matchingTasks[index];

              // ✅ Convert TaskModel to JobModel
              final job = _convertTaskToJob(task);

              return TaskCardTechnician(
                task: job,
                onAccept: () => _acceptTask(task.id),
                onReject: () => _rejectTask(task.id),
                isLoading: _isAccepting,
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // ✅ CONVERT TASK TO JOB
  // ============================================================
  JobModel _convertTaskToJob(TaskModel task) {
    return JobModel(
      id: task.id,
      title: task.title,
      description: task.description,
      customerId: task.customerId,
      customerName: task.customerName,
      customerPhone: task.customerPhone,
      customerAddress: task.address,
      latitude: task.latitude,
      longitude: task.longitude,
      category: task.category,
      subCategories: task.subCategories,
      budget: task.budget,
      serviceCharge: task.serviceCharge ?? 0.0,
      createdAt: task.createdAt,
      scheduledDate: task.scheduledDate,
      acceptedAt: task.acceptedAt,
      startedAt: task.startedAt,
      completedAt: task.completedAt,
      cancelledAt: task.cancelledAt,
      status: _convertTaskStatusToJobStatus(task.status),
      cancellationReason: task.cancellationReason,
      technicianId: task.technicianId,
      technicianName: task.technicianName,
      technicianPhone: task.technicianPhone,
      rating: task.customerRating,
      review: task.customerReview,
      images: task.images,
      isUrgent: task.isUrgent,
      pincode: task.pincode,
      currencyCode: task.currencyCode ?? 'PKR',
      currencySymbol: task.currencySymbol ?? 'Rs',
      countryCode: task.countryCode ?? 'PK',
    );
  }

  // ✅ Convert TaskStatus to JobStatus
  JobStatus _convertTaskStatusToJobStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:
        return JobStatus.available;
      case TaskStatus.accepted:
        return JobStatus.accepted;
      case TaskStatus.inProgress:
        return JobStatus.inProgress;
      case TaskStatus.completed:
        return JobStatus.completed;
      case TaskStatus.cancelled:
        return JobStatus.cancelled;
      case TaskStatus.rejected:
        return JobStatus.rejected;
    }
  }

  // ============================================================
  // ✅ FILTER MATCHING TASKS - PINCODE + DISTANCE
  // ============================================================
  List<TaskModel> _filterMatchingTasks(List<TaskModel> tasks) {
    final matchingTasks = <TaskModel>[];

    for (var task in tasks) {
      // ✅ Check 1: Category Match
      final categoryMatch = _technicianCategories.contains(task.category);
      if (!categoryMatch) {
        print('❌ Category mismatch: ${task.category}');
        continue;
      }

      // ✅ Check 2: Location Match (Pincode OR Distance)
      final locationMatch = _isLocationMatch(task);
      if (!locationMatch) {
        print('❌ Location mismatch for task: ${task.title}');
        continue;
      }

      matchingTasks.add(task);
    }

    // ✅ Sort by distance (closest first)
    matchingTasks.sort((a, b) {
      final distanceA = _calculateDistance(
        _technicianLat, _technicianLng,
        a.latitude, a.longitude,
      );
      final distanceB = _calculateDistance(
        _technicianLat, _technicianLng,
        b.latitude, b.longitude,
      );
      return distanceA.compareTo(distanceB);
    });

    print('✅ Found ${matchingTasks.length} matching tasks');
    return matchingTasks;
  }

  // ============================================================
  // ✅ CHECK LOCATION MATCH - PINCODE OR DISTANCE
  // ============================================================
  bool _isLocationMatch(TaskModel task) {
    // ✅ Method 1: Pincode Match (Exact)
    if (_technicianPincode != null &&
        _technicianPincode!.isNotEmpty &&
        task.pincode.isNotEmpty) {
      if (_technicianPincode == task.pincode) {
        print('📍 Pincode match: ${task.pincode}');
        return true;
      }
    }

    // ✅ Method 2: Distance Match (GPS)
    if (_technicianLat != 0.0 && _technicianLng != 0.0 &&
        task.latitude != 0.0 && task.longitude != 0.0) {

      final distance = _calculateDistance(
        _technicianLat, _technicianLng,
        task.latitude, task.longitude,
      );

      if (distance <= _technicianRadius) {
        print('📍 Distance match: ${distance.toStringAsFixed(1)} km (radius: $_technicianRadius km)');
        return true;
      } else {
        print('📍 Distance too far: ${distance.toStringAsFixed(1)} km > $_technicianRadius km');
      }
    }

    return false;
  }

  // ============================================================
  // ✅ CALCULATE DISTANCE (Haversine Formula)
  // ============================================================
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    if (lat1 == 0 || lon1 == 0 || lat2 == 0 || lon2 == 0) {
      return double.infinity;
    }
    return _locationService.calculateDistanceHaversine(lat1, lon1, lat2, lon2);
  }

  // ============================================================
  // ✅ ACCEPT TASK
  // ============================================================
  Future<void> _acceptTask(String taskId) async {
    setState(() => _isAccepting = true);

    try {
      await _jobService.acceptJob(taskId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Job accepted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  // ============================================================
  // ✅ REJECT TASK
  // ============================================================
  // lib/Presentations/technicianscreen/tab/Home_Tab.dart

  Future<void> _rejectTask(String taskId) async {
    // ✅ Check if widget is mounted
    if (!mounted) return;

    // ✅ Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Reject Job',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to reject this job?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. The customer will be notified.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Reject',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    // ✅ If user cancelled, return
    if (confirm != true) return;

    // ✅ Check if widget is still mounted
    if (!mounted) return;

    // ✅ Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                SizedBox(height: 16),
                Text(
                  'Rejecting job...',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // ✅ Call reject service
      await _taskService.rejectTask(taskId);

      // ✅ Check if widget is still mounted
      if (!mounted) {
        Navigator.pop(context); // Close loading dialog
        return;
      }

      // ✅ Close loading dialog
      Navigator.pop(context);

      // ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '✅ Job rejected successfully',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );

      // ✅ Refresh stats
      await _loadStats();

    } catch (e) {
      // ✅ Check if widget is still mounted
      if (!mounted) {
        Navigator.pop(context); // Close loading dialog
        return;
      }

      // ✅ Close loading dialog
      Navigator.pop(context);

      // ✅ Parse error message
      String errorMessage = 'Failed to reject job';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Please check your account.';
      } else if (e.toString().contains('not found')) {
        errorMessage = 'Job not found or already processed.';
      } else if (e.toString().contains('already')) {
        errorMessage = 'Job is already processed.';
      } else if (e.toString().contains('completed')) {
        errorMessage = 'Cannot reject completed job.';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Job is already cancelled.';
      } else if (e.toString().contains('rejected')) {
        errorMessage = 'Job is already rejected.';
      }

      // ✅ Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '❌ $errorMessage',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ============================================================
  // ✅ BUILD ERROR STATE
  // ============================================================
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 8),
            Text(
              'Error loading jobs',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStats,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ✅ BUILD EMPTY STATE
  // ============================================================
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.work_off_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'No matching jobs available',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check back later for new jobs',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadTechnicianData,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(
              'Refresh',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}