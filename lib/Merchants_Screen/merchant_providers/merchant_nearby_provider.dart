import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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

// Provider for nearby merchants with 15km radius
final nearbyMerchantsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userPositionAsync = ref.watch(userLocationProvider);
  
  return userPositionAsync.when(
    data: (position) async {
      final nearbyService = ref.read(merchantNearbyServiceProvider);
      return await nearbyService.getNearbyMerchants(
        userLat: position.latitude,
        userLng: position.longitude,
        radiusInKm: 15.0,
      );
    },
    loading: () => [],
    error: (err, stack) => throw err,
  );
});
