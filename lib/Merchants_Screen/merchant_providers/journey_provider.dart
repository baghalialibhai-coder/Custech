import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/journey_service.dart';

class JourneyState {
  final Position? currentPosition;
  final double? distanceRemaining;
  final double? timeRemaining;
  final String? polylinePoints;
  final bool isLoading;

  JourneyState({
    this.currentPosition,
    this.distanceRemaining,
    this.timeRemaining,
    this.polylinePoints,
    this.isLoading = false,
  });

  JourneyState copyWith({
    Position? currentPosition,
    double? distanceRemaining,
    double? timeRemaining,
    String? polylinePoints,
    bool? isLoading,
  }) {
    return JourneyState(
      currentPosition: currentPosition ?? this.currentPosition,
      distanceRemaining: distanceRemaining ?? this.distanceRemaining,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class JourneyNotifier extends StateNotifier<JourneyState> {
  final JourneyService _journeyService;
  StreamSubscription<Position>? _positionSubscription;

  JourneyNotifier(this._journeyService) : super(JourneyState());

  void startJourney(double destLat, double destLng) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final pos = await Geolocator.getCurrentPosition();
      final route = await _journeyService.fetchRouteDetails(
        startLat: pos.latitude,
        startLng: pos.longitude,
        endLat: destLat,
        endLng: destLng,
      );

      if (route != null) {
        state = state.copyWith(
          currentPosition: pos,
          distanceRemaining: (route['distance'] as num?)?.toDouble(),
          timeRemaining: (route['duration'] as num?)?.toDouble(),
          polylinePoints: route['polyline'] as String?,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }

    _positionSubscription?.cancel();
    _positionSubscription = _journeyService.getUserLocationStream().listen((newPos) async {
      final updatedRoute = await _journeyService.fetchRouteDetails(
        startLat: newPos.latitude,
        startLng: newPos.longitude,
        endLat: destLat,
        endLng: destLng,
      );

      if (updatedRoute != null) {
        state = state.copyWith(
          currentPosition: newPos,
          distanceRemaining: (updatedRoute['distance'] as num?)?.toDouble(),
          timeRemaining: (updatedRoute['duration'] as num?)?.toDouble(),
        );
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

final journeyServiceProvider = Provider<JourneyService>((ref) => JourneyService());

final journeyProvider = StateNotifierProvider<JourneyNotifier, JourneyState>((ref) {
  final service = ref.watch(journeyServiceProvider);
  return JourneyNotifier(service);
});
