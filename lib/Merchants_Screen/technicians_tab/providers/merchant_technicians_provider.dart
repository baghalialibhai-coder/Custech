// lib/Merchants_Screen/technicians_tab/providers/merchant_technicians_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/merchant_technician_item.dart';
import '../services/merchant_technicians_service.dart';

class MerchantTechniciansState {
  final bool isLoading;
  final List<MerchantTechnicianItem> allTechnicians;
  final String selectedCategory;
  final bool onlyWithin10Km;
  final String searchQuery;
  final String? error;

  MerchantTechniciansState({
    this.isLoading = true,
    this.allTechnicians = const [],
    this.selectedCategory = 'All',
    this.onlyWithin10Km = true,
    this.searchQuery = '',
    this.error,
  });

  MerchantTechniciansState copyWith({
    bool? isLoading,
    List<MerchantTechnicianItem>? allTechnicians,
    String? selectedCategory,
    bool? onlyWithin10Km,
    String? searchQuery,
    String? error,
  }) {
    return MerchantTechniciansState(
      isLoading: isLoading ?? this.isLoading,
      allTechnicians: allTechnicians ?? this.allTechnicians,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      onlyWithin10Km: onlyWithin10Km ?? this.onlyWithin10Km,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }

  // Filtered Technicians
  List<MerchantTechnicianItem> get filteredTechnicians {
    return allTechnicians.where((item) {
      // 10km Filter
      if (onlyWithin10Km && item.distanceInKm > 10.0 && item.distanceInKm > 0.0) {
        return false;
      }

      // Category Filter
      if (selectedCategory != 'All') {
        final matchesCategory = item.technician.categories.any((c) =>
            c.toLowerCase().contains(selectedCategory.toLowerCase()));
        if (!matchesCategory) return false;
      }

      // Search Query Filter
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final nameMatch = item.name.toLowerCase().contains(q);
        final addressMatch = item.address.toLowerCase().contains(q);
        final catMatch = item.technician.categories.any((c) => c.toLowerCase().contains(q));
        if (!nameMatch && !addressMatch && !catMatch) return false;
      }

      return true;
    }).toList();
  }
}

class MerchantTechniciansNotifier extends Notifier<MerchantTechniciansState> {
  final _service = MerchantTechniciansService();

  @override
  MerchantTechniciansState build() {
    return MerchantTechniciansState();
  }

  Future<void> loadTechnicians({
    required double merchantLat,
    required double merchantLng,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _service.fetchTechniciansForMerchant(
        merchantLat: merchantLat,
        merchantLng: merchantLng,
      );
      state = state.copyWith(isLoading: false, allTechnicians: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void set10KmFilter(bool within10Km) {
    state = state.copyWith(onlyWithin10Km: within10Km);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final merchantTechniciansProvider =
    NotifierProvider<MerchantTechniciansNotifier, MerchantTechniciansState>(() {
  return MerchantTechniciansNotifier();
});
