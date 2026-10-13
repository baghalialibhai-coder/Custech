// lib/Presentations/customer_screen/stores_tab/providers/customer_stores_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/models/merchant_model.dart';
import '../../../../services/Location_Service.dart';

class CustomerStoresState {
  final String searchQuery;
  final String selectedCategory;
  final double selectedRadius;
  final bool isLoading;

  CustomerStoresState({
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.selectedRadius = 10.0, // Default 10km
    this.isLoading = false,
  });

  CustomerStoresState copyWith({
    String? searchQuery,
    String? selectedCategory,
    double? selectedRadius,
    bool? isLoading,
  }) {
    return CustomerStoresState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedRadius: selectedRadius ?? this.selectedRadius,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CustomerStoresNotifier extends Notifier<CustomerStoresState> {
  @override
  CustomerStoresState build() {
    return CustomerStoresState();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setRadius(double radius) {
    state = state.copyWith(selectedRadius: radius);
  }
}

final customerStoresNotifierProvider =
    NotifierProvider<CustomerStoresNotifier, CustomerStoresState>(() {
  return CustomerStoresNotifier();
});

// Customer GPS Location Provider
final customerLocationProvider = FutureProvider<Position?>((ref) async {
  final locationService = LocationService();
  return await locationService.getCurrentLocation();
});

// Real-time StreamProvider for Customer Stores
final customerStoresStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final locationAsync = ref.watch(customerLocationProvider);
  final storeState = ref.watch(customerStoresNotifierProvider);
  final locationService = LocationService();

  final position = locationAsync.value;
  final double userLat = position?.latitude ?? 0.0;
  final double userLng = position?.longitude ?? 0.0;

  return FirebaseFirestore.instance
      .collection('merchants')
      .snapshots()
      .map((snapshot) {
    List<Map<String, dynamic>> storesList = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final merchant = MerchantModel.fromMap(data);

      double distance = 0.0;
      if (userLat != 0.0 && userLng != 0.0 && merchant.latitude != 0.0 && merchant.longitude != 0.0) {
        distance = locationService.calculateDistanceHaversine(
          userLat,
          userLng,
          merchant.latitude,
          merchant.longitude,
        );
      }

      // 1. Radius Filter (0.0 means All)
      if (storeState.selectedRadius > 0.0 && distance > storeState.selectedRadius) {
        continue;
      }

      // 2. Category Filter
      if (storeState.selectedCategory != 'All' &&
          !merchant.shopType.toLowerCase().contains(storeState.selectedCategory.toLowerCase())) {
        continue;
      }

      // 3. Search Query Filter
      final query = storeState.searchQuery.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchName = merchant.shopName.toLowerCase().contains(query);
        final matchOwner = merchant.userName.toLowerCase().contains(query);
        final matchType = merchant.shopType.toLowerCase().contains(query);
        final matchAddress = merchant.address.toLowerCase().contains(query);
        if (!matchName && !matchOwner && !matchType && !matchAddress) {
          continue;
        }
      }

      storesList.add({
        'merchant': merchant,
        'distance': distance,
      });
    }

    // Sort by distance (nearest first)
    storesList.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    return storesList;
  });
});
