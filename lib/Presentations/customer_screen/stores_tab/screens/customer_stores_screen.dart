// lib/Presentations/customer_screen/stores_tab/screens/customer_stores_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/merchant_model.dart';
import '../../../../languages/localization/app_localizations.dart';
import '../providers/customer_stores_provider.dart';
import '../widgets/customer_store_card_widget.dart';
import '../widgets/customer_store_details_sheet.dart';

class CustomerStoresScreen extends ConsumerStatefulWidget {
  const CustomerStoresScreen({super.key});

  @override
  ConsumerState<CustomerStoresScreen> createState() => _CustomerStoresScreenState();
}

class _CustomerStoresScreenState extends ConsumerState<CustomerStoresScreen> {
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Mobile Parts',
    'Grocery',
    'Electronics',
    'Auto Spare Parts',
    'Plumbing',
    'Electrician',
    'General Store',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStoreDetails(MerchantModel merchant, double distance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => CustomerStoreDetailsSheet(
        merchant: merchant,
        distance: distance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(customerStoresNotifierProvider);
    final notifier = ref.read(customerStoresNotifierProvider.notifier);
    final storesAsync = ref.watch(customerStoresStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerLocationProvider);
          ref.invalidate(customerStoresStreamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[800]!, Colors.green[600]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 22,
                      child: Icon(Icons.storefront, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('nearbyStores'),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            context.tr('findTechnicians'),
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Search & Radius Dropdown Row
              Row(
                children: [
                  // Search Field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: context.tr('searchHint'),
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.green),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  notifier.setSearchQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      onChanged: (q) => notifier.setSearchQuery(q),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Radius Dropdown Filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<double>(
                        value: storeState.selectedRadius,
                        isDense: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                        items: [
                          DropdownMenuItem(value: 5.0, child: Text('5 km 📍')),
                          DropdownMenuItem(value: 10.0, child: Text('10 km 📍 (${context.tr('defaultLabel')})')),
                          DropdownMenuItem(value: 15.0, child: Text('15 km 📍')),
                          DropdownMenuItem(value: 20.0, child: Text('20 km 📍')),
                          DropdownMenuItem(value: 0.0, child: Text('${context.tr('allStores')} 🌐')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            notifier.setRadius(val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Category Chips Horizontal Carousel
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = storeState.selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          cat == 'All' ? context.tr('allStores') : cat,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.green[700],
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.green[700]! : Colors.grey[300]!,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            notifier.setCategory(cat);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // 4. Stores List or Loading / Empty States
              storesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(child: CircularProgressIndicator(color: Colors.green)),
                ),
                error: (err, stack) => Center(
                  child: Text('Error: $err', style: GoogleFonts.poppins()),
                ),
                data: (storesList) {
                  if (storesList.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.storefront_outlined, size: 56, color: Colors.green[200]),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('noStoresFound'),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr('tryChangingSearchCategory'),
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.tr('nearbyStores')} (${storesList.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[900],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: storesList.length,
                        itemBuilder: (context, index) {
                          final item = storesList[index];
                          final merchant = item['merchant'] as MerchantModel;
                          final distance = (item['distance'] as num).toDouble();

                          return CustomerStoreCardWidget(
                            merchant: merchant,
                            distance: distance,
                            onTapDetails: () => _showStoreDetails(merchant, distance),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
