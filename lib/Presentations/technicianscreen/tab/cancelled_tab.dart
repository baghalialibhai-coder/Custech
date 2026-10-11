// lib/Presentations/technicianscreen/tab/cancelled_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/job_model.dart';
import '../../../services/job_service.dart';
import '../widget/job_card.dart';
import '../../../languages/localization/app_localizations.dart';

class CancelledTab extends ConsumerStatefulWidget {
  const CancelledTab({super.key});

  @override
  ConsumerState<CancelledTab> createState() => _CancelledTabState();
}

class _CancelledTabState extends ConsumerState<CancelledTab> {
  final JobService _jobService = JobService();
  String? _technicianId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getTechnicianId();
  }

  Future<void> _getTechnicianId() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _technicianId = user?.uid;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_technicianId == null) {
      return _buildLoginRequiredState();
    }

    return StreamBuilder<List<JobModel>>(
      stream: _jobService.getTechnicianTasksByStatus(JobStatus.cancelled),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final jobs = snapshot.data ?? [];

        if (jobs.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: const Color(0xFF1A237E),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return JobCard(
                job: job,
                showActions: false,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoginRequiredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            context.tr('pleaseLogin'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('loginToViewCancelled'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              context.tr('errorLoadingCancelled'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            context.tr('noCancelledJobs'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('noCancelledJobsDesc'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}