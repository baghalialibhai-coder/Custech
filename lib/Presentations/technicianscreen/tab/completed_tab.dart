// lib/Presentations/technicianscreen/tab/completed_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/job_model.dart';
import '../../../services/job_service.dart';
import '../widget/job_card.dart';
import '../../../languages/localization/app_localizations.dart';

class CompletedTab extends ConsumerStatefulWidget {
  const CompletedTab({super.key});

  @override
  ConsumerState<CompletedTab> createState() => _CompletedTabState();
}

class _CompletedTabState extends ConsumerState<CompletedTab> {
  final JobService _jobService = JobService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JobModel>>(
      stream: _jobService.getJobsByStatus(JobStatus.completed),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final jobs = snapshot.data ?? [];

        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  context.tr('noCompletedJobs'),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('noCompletedJobsDesc'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return JobCard(
              job: job,
              showActions: false,
            );
          },
        );
      },
    );
  }
}