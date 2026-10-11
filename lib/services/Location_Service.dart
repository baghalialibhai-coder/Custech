// lib/services/Location_Service.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'Google_Map_Service.dart';

class LocationService {
  final GoogleMapsService _googleMaps = GoogleMapsService();

  // ============================================================
  // ✅ REQUEST LOCATION PERMISSION (With User-Friendly Dialogs)
  // ============================================================
  Future<bool> requestLocationPermission(BuildContext context) async {
    try {
      // ✅ Step 1: Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final result = await _showEnableLocationDialog(context);
        if (result == false) {
          return false;
        }
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return false;
        }
      }

      // ✅ Step 2: Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          final result = await _showPermissionDialog(context);
          if (result == false) {
            return false;
          }
          permission = await Geolocator.requestPermission();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await _showSettingsDialog(context);
        return false;
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

    } catch (e) {
      print('❌ Location permission error: $e');
      return false;
    }
  }

  // ============================================================
  // ✅ GET CURRENT LOCATION - FIXED
  // ============================================================
  Future<Position> getCurrentLocation({BuildContext? context}) async {
    try {
      // ✅ If context provided, check permission with dialog
      if (context != null) {
        final hasPermission = await requestLocationPermission(context);
        if (!hasPermission) {
          throw Exception('Location permission denied');
        }
      } else {
        // ✅ Simple permission check without dialog
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Location permission denied');
          }
        }
        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permission permanently denied');
        }
      }

      // ✅ Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // ✅ Try multiple times with retry
      Position? position;
      int retryCount = 3;

      for (int i = 0; i < retryCount; i++) {
        try {
          print('📍 Location attempt ${i + 1} of $retryCount...');

          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 30), // ✅ Increased timeout
          );

          if (position != null) {
            print('✅ Location found: ${position.latitude}, ${position.longitude}');
            break;
          }
        } catch (e) {
          print('❌ Attempt ${i + 1} failed: $e');
          if (i < retryCount - 1) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }

      if (position == null) {
        throw Exception('Failed to get location after $retryCount attempts');
      }

      return position;

    } catch (e) {
      print('❌ Error getting location: $e');
      throw Exception('Failed to get location: $e');
    }
  }

  // ============================================================
  // ✅ GET LOCATION WITH RETRY - NEW METHOD
  // ============================================================
  Future<Position?> getLocationWithRetry({
    BuildContext? context,
    int maxAttempts = 3,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    // ✅ Check permissions
    if (context != null) {
      final hasPermission = await requestLocationPermission(context);
      if (!hasPermission) {
        return null;
      }
    } else {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;
    }

    // ✅ Check if GPS is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context != null) {
        final enabled = await _showEnableLocationDialog(context);
        if (!enabled) return null;
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return null;
      } else {
        return null;
      }
    }

    // ✅ Retry logic with fallback
    for (int i = 0; i < maxAttempts; i++) {
      try {
        print('📍 Location attempt ${i + 1} of $maxAttempts...');

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: timeout,
        );

        print('✅ Location found: ${position.latitude}, ${position.longitude}');
        return position;

      } catch (e) {
        print('❌ Attempt ${i + 1} failed: $e');

        // Fallback to medium accuracy
        try {
          final medPos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          );
          if (medPos != null) {
            print('✅ Location found (medium accuracy): ${medPos.latitude}, ${medPos.longitude}');
            return medPos;
          }
        } catch (_) {}

        if (i < maxAttempts - 1) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    // Ultimate fallback: Last Known Position
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        print('✅ Using last known position: ${lastKnown.latitude}, ${lastKnown.longitude}');
        return lastKnown;
      }
    } catch (e) {
      print('❌ Last known location error: $e');
    }

    if (context != null && context.mounted) {
      _showSnackBar(context, 'Unable to get location. Please try again.');
    }

    return null;
  }

  // ============================================================
  // ✅ SHOW ENABLE LOCATION DIALOG
  // ============================================================
  static Future<bool> _showEnableLocationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange, size: 28),
            const SizedBox(width: 4),
            Text(
              'Location Services Disabled',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        content: Text(
          'Please enable location services to use this feature.',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ============================================================
  // ✅ SHOW PERMISSION DIALOG
  // ============================================================
  static Future<bool> _showPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue[700], size: 28),
            const SizedBox(width: 8),
            Text(
              'Location Permission Required',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'We need location access to find technicians near you.\n\n'
              'This helps us show you the most relevant service providers.',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Allow Access'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ============================================================
  // ✅ SHOW SETTINGS DIALOG (Permanently Denied)
  // ============================================================
  static Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.red[700], size: 28),
            const SizedBox(width: 8),
            Text(
              'Permission Permanently Denied',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Location permission is permanently denied.\n\n'
              'Please enable it from app settings to use this feature.',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ SHOW SNACKBAR
  // ============================================================
  static void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // ✅ GET LOCATION STATUS
  // ============================================================
  Future<LocationStatus> getLocationStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationStatus(
          hasPermission: false,
          message: 'Location services are disabled',
          status: LocationStatusType.serviceDisabled,
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        return LocationStatus(
          hasPermission: false,
          message: 'Location permission not granted',
          status: LocationStatusType.permissionDenied,
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationStatus(
          hasPermission: false,
          message: 'Location permission permanently denied',
          status: LocationStatusType.permanentlyDenied,
        );
      }

      return LocationStatus(
        hasPermission: true,
        message: 'Location permission granted',
        status: LocationStatusType.granted,
      );

    } catch (e) {
      return LocationStatus(
        hasPermission: false,
        message: 'Error checking location: $e',
        status: LocationStatusType.error,
      );
    }
  }

  // ============================================================
  // ✅ GEOCODING: Address to Coordinates (Google Maps)
  // ============================================================
  Future<Position?> getCoordinatesFromAddress(String address) async {
    return await _googleMaps.geocodeAddress(address);
  }

  // ============================================================
  // ✅ REVERSE GEOCODING: Coordinates to Address (Google Maps)
  // ============================================================
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    return await _googleMaps.reverseGeocode(lat, lng);
  }

  // ============================================================
  // ✅ SEARCH PLACES (Google Maps Autocomplete)
  // ============================================================
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    return await _googleMaps.searchPlaces(query);
  }

  // ============================================================
  // ✅ GET PLACE DETAILS (Google Maps Place Details)
  // ============================================================
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    return await _googleMaps.getPlaceDetails(placeId);
  }

  // ============================================================
  // ✅ CALCULATE DISTANCE (Google Maps Distance Matrix)
  // ============================================================
  Future<double?> calculateDistance(
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      ) async {
    return await _googleMaps.calculateDistance(startLat, startLng, endLat, endLng);
  }

  // ============================================================
  // ✅ GET ROUTE (Google Maps Directions)
  // ============================================================
  Future<Map<String, dynamic>?> getRoute(
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      ) async {
    return await _googleMaps.getRoute(startLat, startLng, endLat, endLng);
  }

  // ============================================================
  // ✅ GET NEARBY PLACES (Google Maps Nearby Search)
  // ============================================================
  Future<List<Map<String, dynamic>>> getNearbyPlaces(
      double lat,
      double lng, {
        double radius = 5000,
        int limit = 10,
      }) async {
    return await _googleMaps.getNearbyPlaces(lat, lng, radius: radius, limit: limit);
  }

  // ============================================================
  // ✅ BATCH DISTANCE CALCULATION (Google Maps Distance Matrix)
  // ============================================================
  Future<List<Map<String, dynamic>>> calculateDistancesBatch(
      double startLat,
      double startLng,
      List<Map<String, double>> destinations,
      ) async {
    return await _googleMaps.calculateDistancesBatch(startLat, startLng, destinations);
  }

  // ============================================================
  // ✅ STATIC MAP IMAGE (Google Maps Static API)
  // ============================================================
  String getStaticMapImage({
    required double lat,
    required double lng,
    int width = 400,
    int height = 200,
    int zoom = 14,
    List<Map<String, dynamic>>? markers,
    double? radius,
  }) {
    return _googleMaps.getStaticMapImage(
      lat: lat,
      lng: lng,
      width: width,
      height: height,
      zoom: zoom,
      markers: markers,
      radius: radius,
    );
  }

  // ============================================================
  // ✅ HAVERSINE DISTANCE (Fallback - No API call)
  // ============================================================
  double calculateDistanceHaversine(
      double lat1,
      double lng1,
      double lat2,
      double lng2,
      ) {
    return GoogleMapsService.haversineDistance(lat1, lng1, lat2, lng2);
  }

  // ============================================================
  // ✅ CHECK WITHIN RADIUS
  // ============================================================
  bool isWithinRadius(
      double customerLat,
      double customerLng,
      double technicianLat,
      double technicianLng,
      double radiusKm,
      ) {
    double distance = calculateDistanceHaversine(
      customerLat,
      customerLng,
      technicianLat,
      technicianLng,
    );
    return distance <= radiusKm;
  }

  // ============================================================
  // ✅ VALIDATE GOOGLE MAPS API KEY
  // ============================================================
  Future<bool> validateGoogleMapsKey() async {
    return await _googleMaps.validateApiKey();
  }

  // ============================================================
  // ✅ CHECK IF GOOGLE MAPS IS INITIALIZED
  // ============================================================
  bool get isGoogleMapsInitialized => _googleMaps.isInitialized;

  // ============================================================
  // ✅ HELPER: Degrees to Radians
  // ============================================================
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}

// ============================================================
// ✅ LOCATION STATUS MODELS
// ============================================================

enum LocationStatusType {
  granted,
  denied,
  serviceDisabled,
  permissionDenied,
  permanentlyDenied,
  error,
}

class LocationStatus {
  final bool hasPermission;
  final String message;
  final LocationStatusType status;

  LocationStatus({
    required this.hasPermission,
    required this.message,
    required this.status,
  });
}