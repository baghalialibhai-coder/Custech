// lib/Merchants_Screen/technicians_tab/services/merchant_technicians_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/models/technician_model.dart';
import '../../../../services/Location_Service.dart';
import '../models/merchant_technician_item.dart';

class MerchantTechniciansService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  Future<List<MerchantTechnicianItem>> fetchTechniciansForMerchant({
    required double merchantLat,
    required double merchantLng,
  }) async {
    try {
      final techDocs = await _firestore.collection('technicians').get();
      if (techDocs.docs.isEmpty) return [];

      final List<MerchantTechnicianItem> result = [];

      for (var doc in techDocs.docs) {
        final tech = TechnicianModel.fromMap(doc.data());

        String name = 'Technician';
        String phone = '';
        String profileImage = '';
        String address = '';

        try {
          final userDoc = await _firestore.collection('users').doc(tech.userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            name = userData['displayName'] ?? userData['name'] ?? 'Technician';
            phone = userData['phoneNumber'] ?? userData['phone'] ?? '';
            profileImage = userData['profileImageUrl'] ?? userData['profileImage'] ?? '';
            address = userData['address'] ?? '';
          }
        } catch (e) {
          debugPrint('Error fetching user info for tech ${tech.userId}: $e');
        }

        double distance = 0.0;
        if (merchantLat != 0.0 && merchantLng != 0.0 && tech.latitude != 0.0 && tech.longitude != 0.0) {
          distance = _locationService.calculateDistanceHaversine(
            merchantLat,
            merchantLng,
            tech.latitude,
            tech.longitude,
          );
        }

        result.add(
          MerchantTechnicianItem(
            technician: tech,
            name: name,
            phone: phone,
            profileImage: profileImage,
            address: address,
            distanceInKm: distance,
          ),
        );
      }

      // Sort by distance (closest first)
      result.sort((a, b) => a.distanceInKm.compareTo(b.distanceInKm));
      return result;
    } catch (e) {
      debugPrint('Error fetching technicians: $e');
      return [];
    }
  }
}
