// lib/services/google_maps_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

class GoogleMapsService {
  static final GoogleMapsService _instance = GoogleMapsService._internal();
  factory GoogleMapsService() => _instance;
  GoogleMapsService._internal();

  // ✅ Get API key from .env
  String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // ✅ Check if API key is available
  bool get isInitialized => _apiKey.isNotEmpty && _apiKey != 'AIzaSy';

  // ============================================================
  // ✅ BASE URLS
  // ============================================================
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  static const String _geocodingUrl = '$_baseUrl/geocode/json';
  static const String _directionsUrl = '$_baseUrl/directions/json';
  static const String _distanceMatrixUrl = '$_baseUrl/distancematrix/json';
  static const String _placesAutocompleteUrl = '$_baseUrl/place/autocomplete/json';
  static const String _placesDetailsUrl = '$_baseUrl/place/details/json';
  static const String _nearbySearchUrl = '$_baseUrl/place/nearbysearch/json';

  // ============================================================
  // ✅ GEOCODING: Address to Coordinates
  // ============================================================
  Future<Position?> geocodeAddress(String address) async {
    try {
      if (_apiKey.isEmpty || _apiKey == 'AIzaSy') {
        print('❌ Google Maps API Key not configured');
        return null;
      }

      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse(
          '$_geocodingUrl?address=$encodedAddress&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            final location = results[0]['geometry']['location'];
            return Position(
              latitude: location['lat'],
              longitude: location['lng'],
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
          }
        } else {
          print('❌ Geocoding API error: ${data['status']}');
        }
      }
      return null;
    } catch (e) {
      print('❌ Geocoding error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ REVERSE GEOCODING: Coordinates to Address
  // ============================================================
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      if (_apiKey.isEmpty || _apiKey == 'AIzaSy') {
        print('❌ Google Maps API Key not configured');
        return null;
      }

      final url = Uri.parse(
          '$_geocodingUrl?latlng=$lat,$lng&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            return results[0]['formatted_address'];
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ Reverse geocoding error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ SEARCH PLACES (Autocomplete)
  // ============================================================
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    try {
      if (_apiKey.isEmpty || _apiKey == 'AIzaSy') {
        print('❌ Google Maps API Key not configured');
        return [];
      }

      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
          '$_placesAutocompleteUrl?input=$encodedQuery&key=$_apiKey&types=address&components=country:pk'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final predictions = data['predictions'] as List? ?? [];

          return predictions.map((item) {
            return {
              'id': item['place_id'],
              'name': item['description'],
              'address': item['description'],
              'fullAddress': item['description'],
              'placeId': item['place_id'],
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Search error: $e');
      return [];
    }
  }

  // ============================================================
  // ✅ GET PLACE DETAILS (for full address)
  // ============================================================
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      if (_apiKey.isEmpty || _apiKey == 'AIzaSy') {
        print('❌ Google Maps API Key not configured');
        return null;
      }

      final url = Uri.parse(
          '$_placesDetailsUrl?place_id=$placeId&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];

          // Extract address components
          String pincode = '';
          String city = '';
          String area = '';

          final components = result['address_components'] as List? ?? [];
          for (var component in components) {
            final types = component['types'] as List;
            if (types.contains('postal_code')) {
              pincode = component['long_name'] ?? '';
            }
            if (types.contains('locality')) {
              city = component['long_name'] ?? '';
            }
            if (types.contains('sublocality') || types.contains('neighborhood')) {
              area = component['long_name'] ?? '';
            }
          }

          return {
            'latitude': location['lat'],
            'longitude': location['lng'],
            'address': result['formatted_address'],
            'pincode': pincode,
            'city': city,
            'area': area,
            'fullAddress': result['formatted_address'],
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ Place details error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ CALCULATE DISTANCE (Distance Matrix API)
  // ============================================================
  Future<double?> calculateDistance(
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      ) async {
    try {
      if (_apiKey.isEmpty || _apiKey == 'AIzaSy') {
        print('❌ Google Maps API Key not configured');
        return null;
      }

      final url = Uri.parse(
          '$_distanceMatrixUrl?origins=$startLat,$startLng&destinations=$endLat,$endLng&key=$_apiKey&units=metric'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final rows = data['rows'] as List;
          if (rows.isNotEmpty) {
            final elements = rows[0]['elements'] as List;
            if (elements.isNotEmpty && elements[0]['status'] == 'OK') {
              final distance = elements[0]['distance']['value'] / 1000; // Convert to km
              return distance;
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ Distance calculation error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ GET ROUTE (Directions API)
  // ============================================================
  Future<Map<String, dynamic>?> getRoute(
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      ) async {
    try {
      if (_apiKey.isEmpty || _apiKey == 'AIzaSy') {
        print('❌ Google Maps API Key not configured');
        return null;
      }

      final url = Uri.parse(
          '$_directionsUrl?origin=$startLat,$startLng&destination=$endLat,$endLng&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final route = routes[0];
            final leg = route['legs'][0];
            return {
              'distance': leg['distance']['value'] / 1000, // km
              'duration': leg['duration']['value'] / 60, // minutes
              'durationText': leg['duration']['text'],
              'distanceText': leg['distance']['text'],
              'steps': leg['steps'],
              'polyline': route['overview_polyline']['points'],
            };
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ Route error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ GET NEARBY PLACES
  // ============================================================
  Future<List<Map<String, dynamic>>> getNearbyPlaces(
      double lat,
      double lng, {
        String type = 'address',
        double radius = 5000,
        int limit = 10,
      }) async {
    try {
      if (_apiKey.isEmpty || _apiKey == 'AIzaSy') {
        print('❌ Google Maps API Key not configured');
        return [];
      }

      final url = Uri.parse(
          '$_nearbySearchUrl?location=$lat,$lng&radius=$radius&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;

          return results.take(limit).map((item) {
            return {
              'id': item['place_id'],
              'name': item['name'],
              'address': item['vicinity'],
              'latitude': item['geometry']['location']['lat'],
              'longitude': item['geometry']['location']['lng'],
              'type': item['types']?.first ?? 'unknown',
              'rating': item['rating'],
              'photos': item['photos'],
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Nearby places error: $e');
      return [];
    }
  }

  // ============================================================
  // ✅ BATCH DISTANCE CALCULATION (Multiple Destinations)
  // ============================================================
  Future<List<Map<String, dynamic>>> calculateDistancesBatch(
      double startLat,
      double startLng,
      List<Map<String, double>> destinations,
      ) async {
    try {
      if (_apiKey.isEmpty || _apiKey == 'AIzaSy' || destinations.isEmpty) {
        return [];
      }

      // Build destinations string
      final destStr = destinations
          .map((d) => '${d['lat']},${d['lng']}')
          .join('|');

      final url = Uri.parse(
          '$_distanceMatrixUrl?origins=$startLat,$startLng&destinations=$destStr&key=$_apiKey&units=metric'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final rows = data['rows'] as List;
          if (rows.isNotEmpty) {
            final elements = rows[0]['elements'] as List;
            final results = <Map<String, dynamic>>[];

            for (int i = 0; i < elements.length && i < destinations.length; i++) {
              final element = elements[i];
              if (element['status'] == 'OK') {
                results.add({
                  'index': i,
                  'destinationLat': destinations[i]['lat'],
                  'destinationLng': destinations[i]['lng'],
                  'distanceKm': element['distance']['value'] / 1000,
                  'distanceMeters': element['distance']['value'],
                  'durationMinutes': element['duration']['value'] / 60,
                  'durationText': element['duration']['text'],
                  'distanceText': element['distance']['text'],
                });
              } else {
                results.add({
                  'index': i,
                  'destinationLat': destinations[i]['lat'],
                  'destinationLng': destinations[i]['lng'],
                  'error': element['status'],
                });
              }
            }
            return results;
          }
        }
      }
      return [];
    } catch (e) {
      print('❌ Batch distance error: $e');
      return [];
    }
  }

  // ============================================================
  // ✅ GET STATIC MAP IMAGE URL
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
    if (_apiKey.isEmpty || _apiKey == 'AIzaSy') {
      return '';
    }

    String url = 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=$zoom&size=${width}x$height&key=$_apiKey';

    // Add markers
    if (markers != null && markers.isNotEmpty) {
      for (var marker in markers) {
        final markerLat = marker['lat'] ?? lat;
        final markerLng = marker['lng'] ?? lng;
        final color = marker['color'] ?? 'red';
        final label = marker['label'] ?? '';
        url += '&markers=color:$color%7Clabel:$label%7C$markerLat,$markerLng';
      }
    }

    // Add radius circle
    if (radius != null && radius > 0) {
      url += '&path=color:0x0000FF80%7Cweight:2%7Cenc:';
    }

    return url;
  }

  // ============================================================
  // ✅ HAVERSINE DISTANCE (Fallback - No API call)
  // ============================================================
  static double haversineDistance(
      double lat1,
      double lng1,
      double lat2,
      double lng2,
      ) {
    const double earthRadius = 6371; // km

    double dLat = _toRadians(lat2 - lat1);
    double dLng = _toRadians(lng2 - lng1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
            cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
                sin(dLng / 2) * sin(dLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // ============================================================
  // ✅ VALIDATE API KEY
  // ============================================================
  Future<bool> validateApiKey() async {
    try {
      if (_apiKey.isEmpty || _apiKey == 'AIzaSy') {
        return false;
      }

      final url = Uri.parse(
          '$_geocodingUrl?address=Islamabad&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}