import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_fonts/google_fonts.dart';

import 'accepted_tab.dart';
import 'cancelled_tab.dart';
import 'completed_tab.dart';
import 'in_progress_tab.dart';

// ✅ Provider for tab index
final technicianTabIndexProvider = StateProvider<int>((ref) => 0);

class MyJobsTab extends ConsumerStatefulWidget {
  const MyJobsTab({super.key});

  @override
  ConsumerState<MyJobsTab> createState() => _MyJobsTabState();
}

class _MyJobsTabState extends ConsumerState<MyJobsTab>
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
    // ✅ Listen to tab index changes from provider
    final tabIndex = ref.watch(technicianTabIndexProvider);

    // ✅ Update tab controller when provider changes
    if (_tabController.index != tabIndex) {
      _tabController.animateTo(tabIndex);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.blue[700],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.blue[700],
              labelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              onTap: (index) {
                // ✅ Update provider when user taps
                ref.read(technicianTabIndexProvider.notifier).state = index;
              },
              tabs: const [
                Tab(text: 'Accepted'),
                Tab(text: 'In Progress'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                AcceptedTab(),
                InProgressTab(),
                CompletedTab(),
                CancelledTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}