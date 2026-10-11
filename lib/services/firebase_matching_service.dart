// lib/services/firebase_matching_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'location_service.dart';

class FirebaseMatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocationService _locationService = LocationService();

  // ✅ HELPER: Safely get data
  Map<String, dynamic> _getData(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) return {};
    return data as Map<String, dynamic>;
  }

  // ============================================================
  // ✅ CHECK: CATEGORY + PINCODE OR GPS LOCATION
  // ============================================================
  Future<bool> hasMatchingTechnician({
    required String category,
    required String pincode,
    required double customerLat,
    required double customerLng,
  }) async {
    try {
      print('🔍 Checking technician match...');
      print('📌 Category: $category');
      print('📍 Pincode: $pincode');
      print('📍 Customer Location: $customerLat, $customerLng');

      // ✅ Get all technicians in this category
      final snapshot = await _firestore
          .collection('technicians')
          .where('categories', arrayContains: category)
          .where('isAvailable', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        print('❌ No technicians in this category');
        return false;
      }

      print('📊 Found ${snapshot.docs.length} technicians');

      for (var doc in snapshot.docs) {
        final data = _getData(doc);
        final techPincode = data['pincode']?.toString() ?? '';
        final techServicePincode = data['servicePincode']?.toString() ?? '';
        final techPinCodes = List<String>.from(data['servicePinCodes'] ?? []);
        final techLat = (data['latitude'] ?? 0.0).toDouble();
        final techLng = (data['longitude'] ?? 0.0).toDouble();
        final technicianRadius = (data['serviceRadius'] ?? 15.0).toDouble();

        // ✅ METHOD 1: Pincode Match (If pincode is available)
        bool pincodeMatch = false;
        if (pincode.isNotEmpty) {
          if (techPincode == pincode ||
              techServicePincode == pincode ||
              techPinCodes.contains(pincode)) {
            pincodeMatch = true;
            print('✅ Pincode match found: $pincode');
            return true;
          }
        }

        // ✅ METHOD 2: GPS Distance Match (If pincode doesn't match OR pincode is empty)
        // ✅ This is the key fix - Use GPS even if pincode is empty!
        if (!pincodeMatch || pincode.isEmpty) {
          if (techLat != 0.0 && techLng != 0.0 && customerLat != 0.0 && customerLng != 0.0) {

            final distance = _locationService.calculateDistanceHaversine(
              customerLat, customerLng,
              techLat, techLng,
            );

            if (distance <= technicianRadius) {
              print('✅ GPS Distance match found: ${distance.toStringAsFixed(1)} km (radius: $technicianRadius km)');
              print('   Technician: $techLat, $techLng');
              print('   Customer: $customerLat, $customerLng');
              return true;
            } else {
              print('   Distance: ${distance.toStringAsFixed(1)} km > $technicianRadius km');
            }
          } else {
            print('⚠️ Missing GPS location for technician or customer');
          }
        }
      }

      print('❌ No matching technician found');
      return false;

    } catch (e) {
      print('❌ Error checking match: $e');
      return false;
    }
  }

  // ============================================================
  // ✅ GET MATCHING TECHNICIANS (With Both Methods)
  // ============================================================
  Future<List<Map<String, dynamic>>> getMatchingTechnicians({
    required String category,
    required String pincode,
    required double customerLat,
    required double customerLng,
  }) async {
    try {
      final List<Map<String, dynamic>> matchingTechnicians = [];

      final snapshot = await _firestore
          .collection('technicians')
          .where('categories', arrayContains: category)
          .where('isAvailable', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) return [];

      for (var doc in snapshot.docs) {
        final data = _getData(doc);
        final techPincode = data['pincode']?.toString() ?? '';
        final techServicePincode = data['servicePincode']?.toString() ?? '';
        final techPinCodes = List<String>.from(data['servicePinCodes'] ?? []);
        final techLat = (data['latitude'] ?? 0.0).toDouble();
        final techLng = (data['longitude'] ?? 0.0).toDouble();
        final technicianRadius = (data['serviceRadius'] ?? 15.0).toDouble();

        bool pincodeMatch = false;
        bool distanceMatch = false;
        double distance = 0;
        String matchType = '';

        // ✅ Check pincode match
        if (pincode.isNotEmpty) {
          if (techPincode == pincode ||
              techServicePincode == pincode ||
              techPinCodes.contains(pincode)) {
            pincodeMatch = true;
            matchType = 'pincode';
          }
        }

        // ✅ Check GPS distance match (Always check if location available)
        if (techLat != 0.0 && techLng != 0.0 && customerLat != 0.0 && customerLng != 0.0) {
          distance = _locationService.calculateDistanceHaversine(
            customerLat, customerLng,
            techLat, techLng,
          );
          if (distance <= technicianRadius) {
            distanceMatch = true;
            matchType = matchType.isEmpty ? 'gps' : 'pincode+gps';
          }
        }

        if (pincodeMatch || distanceMatch) {
          matchingTechnicians.add({
            'id': doc.id,
            'userId': data['userId'] ?? '',
            'displayName': data['displayName'] ?? 'Technician',
            'phoneNumber': data['phoneNumber'] ?? '',
            'address': data['address'] ?? '',
            'pincode': techPincode,
            'latitude': techLat,
            'longitude': techLng,
            'serviceRadius': technicianRadius,
            'distance': distance,
            'distanceKm': distance.toStringAsFixed(1),
            'rating': data['rating'] ?? 0.0,
            'categories': data['categories'] ?? [],
            'profileImageUrl': data['profileImageUrl'],
            'isAvailable': data['isAvailable'] ?? true,
            'isOnline': data['isOnline'] ?? false,
            'isApproved': data['isApproved'] ?? false,
            'matchType': matchType,  // ✅ Shows how matched
            'pincodeMatch': pincodeMatch,
            'distanceMatch': distanceMatch,
          });
        }
      }

      // ✅ Sort by distance (closest first)
      matchingTechnicians.sort((a, b) {
        return (a['distance'] as double).compareTo(b['distance'] as double);
      });

      print('✅ Found ${matchingTechnicians.length} matching technicians');
      return matchingTechnicians;

    } catch (e) {
      print('❌ Error getting matching technicians: $e');
      return [];
    }
  }
}