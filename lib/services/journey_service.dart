import 'package:geolocator/geolocator.dart';
import 'Google_Map_Service.dart';

class JourneyService {
  final GoogleMapsService _googleMapsService = GoogleMapsService();

  Stream<Position> getUserLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  Future<Map<String, dynamic>?> fetchRouteDetails({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    return await _googleMapsService.getRoute(startLat, startLng, endLat, endLng);
  }
}
