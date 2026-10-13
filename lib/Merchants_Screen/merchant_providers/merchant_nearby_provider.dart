// lib/Merchants_Screen/merchant_providers/merchant_nearby_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/models/merchant_model.dart';
import '../../services/Location_Service.dart';
import '../../services/merchant_nearby_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final merchantNearbyServiceProvider = Provider<MerchantNearbyService>((ref) {
  return MerchantNearbyService();
});

// Provider to get current user position
final userLocationProvider = FutureProvider<Position>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return await locationService.getCurrentLocation();
});

// Provider for selected radius in km (Default: 10.0 km)
final selectedRadiusProvider = StateProvider<double>((ref) => 10.0);

// Real-time StreamProvider for nearby merchants filtered by selected radius
final nearbyMerchantsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userPositionAsync = ref.watch(userLocationProvider);
  final locationService = ref.read(locationServiceProvider);
  final selectedRadius = ref.watch(selectedRadiusProvider);

  final position = userPositionAsync.value;
  final double userLat = position?.latitude ?? 0.0;
  final double userLng = position?.longitude ?? 0.0;

  return FirebaseFirestore.instance
      .collection('merchants')
      .snapshots()
      .map((snapshot) {
    List<Map<String, dynamic>> nearbyMerchants = [];

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

      // Filter by selected radius (0.0 means All)
      if (selectedRadius == 0.0 || distance <= selectedRadius) {
        nearbyMerchants.add({
          'merchant': merchant,
          'distance': distance,
        });
      }
    }

    // Sort by distance (nearest first)
    nearbyMerchants.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    return nearbyMerchants;
  });
});
