// lib/Presentations/customer_screen/tabs/my_tasks_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../languages/localization/app_localizations.dart';
import '../providers/customer_providers.dart';

import 'customer_accepted_tab.dart';
import 'customer_completed_tab.dart';
import 'customer_in_progress_tab.dart';
import 'customer_open_tab.dart';

class MyTasksTab extends ConsumerStatefulWidget {
  const MyTasksTab({super.key});

  @override
  ConsumerState<MyTasksTab> createState() => _MyTasksTabState();
}

class _MyTasksTabState extends ConsumerState<MyTasksTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskCountsAsync = ref.watch(customerTaskCountsProvider);

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.green[700],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.green[700],
            labelStyle: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            tabs: [
              _buildTab(context, '⏳ ${context.tr('open')}', 'open', taskCountsAsync),
              _buildTab(context, '✅ ${context.tr('accepted')}', 'accepted', taskCountsAsync),
              _buildTab(context, '🚗 ${context.tr('inProgress')}', 'inProgress', taskCountsAsync),
              Tab(child: Text('🎉 ${context.tr('completed')}')),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              CustomerOpenTab(),
              CustomerAcceptedTab(),
              CustomerInProgressTab(),
              CustomerCompletedTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(BuildContext context, String label, String statusKey, AsyncValue<Map<String, int>> countsAsync) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          countsAsync.when(
            data: (counts) {
              final count = counts[statusKey] ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getBadgeColor(statusKey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor(String statusKey) {
    switch (statusKey) {
      case 'open': return Colors.blue[700]!;
      case 'accepted': return Colors.orange[700]!;
      case 'inProgress': return Colors.purple[700]!;
      default: return Colors.grey;
    }
  }
}
