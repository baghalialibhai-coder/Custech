// lib/Presentations/customer_screen/tabs/home_tab.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../languages/localization/app_localizations.dart';
import '../../../core/constants/categories.dart';
import '../widgets/AnimatedImageScroller.dart';
import '../widgets/ScrollerImages.dart';
import '../widgets/category_card.dart';
import '../screens/service_detail_screen.dart';
import '../providers/customer_providers.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(customerSearchProvider);
    final imagePaths = ScrollerImages.getFeaturedImages();
    
    // ✅ Filter categories based on search
    final categories = AppCategories.allCategories;
    final filteredCategories = categories.where((categoryKey) {
      if (searchQuery.isEmpty) return true;
      final query = searchQuery.toLowerCase().trim();
      final keyMatch = categoryKey.toLowerCase().contains(query);
      final translated = context.tr(categoryKey);
      final translatedMatch = translated.toLowerCase().contains(query);
      return keyMatch || translatedMatch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Search Bar using Provider
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                ref.read(customerSearchProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: context.tr('searchServices'),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => ref.read(customerSearchProvider.notifier).state = "",
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          AnimatedImageScroller(
            imagePaths: imagePaths,
            height: 150,
            animationDuration: const Duration(milliseconds: 50000),
          ),

          const SizedBox(height: 16),

          Text(
            '${filteredCategories.length} ${context.tr('servicesAvailable')}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),

          filteredCategories.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('noServicesFound'),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, index) {
                    final categoryKey = filteredCategories[index];
                    return CategoryCard(
                      categoryKey: categoryKey,
                      displayName: context.tr(categoryKey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServiceDetailScreen(
                              category: categoryKey,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}
