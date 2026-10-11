import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../core/models/merchant_model.dart';
import 'Location_Service.dart';

class MerchantNearbyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  Future<List<Map<String, dynamic>>> getNearbyMerchants({
    required double userLat,
    required double userLng,
    double radiusInKm = 15.0,
  }) async {
    try {
      // 1. Fetch all merchants (For production, consider GeoFirestore or GeoHashing)
      final snapshot = await _firestore.collection('merchants').get();

      List<Map<String, dynamic>> nearbyMerchants = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final merchant = MerchantModel.fromMap(data);

        // 2. Calculate distance using Haversine formula from LocationService
        double distance = _locationService.calculateDistanceHaversine(
          userLat,
          userLng,
          merchant.latitude,
          merchant.longitude,
        );

        // 3. Filter by radius
        if (distance <= radiusInKm) {
          nearbyMerchants.add({
            'merchant': merchant,
            'distance': distance,
          });
        }
      }

      // 4. Sort by distance (nearest first)
      nearbyMerchants.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      return nearbyMerchants;
    } catch (e) {
      print('❌ Error fetching nearby merchants: $e');
      return [];
    }
  }
}
