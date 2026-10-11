import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/models/merchant_model.dart';
import 'merchant_providers/journey_provider.dart';
import 'merchant_providers/merchant_nearby_provider.dart';
import '../languages/localization/app_localizations.dart';
import '../languages/widget/language_selection_screen.dart';

class JourneyScreen extends ConsumerStatefulWidget {
  final MerchantModel merchant;
  final double initialDistance;

  const JourneyScreen({
    super.key,
    required this.merchant,
    required this.initialDistance,
  });

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(journeyProvider.notifier).startJourney(
              widget.merchant.latitude,
              widget.merchant.longitude,
            );
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  void _refreshJourney() {
    ref.invalidate(userLocationProvider);
    ref.read(journeyProvider.notifier).startJourney(
          widget.merchant.latitude,
          widget.merchant.longitude,
        );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('refreshingRoute'))),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  String _getCurrentLanguageName() {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final languageNames = {
      'en': 'English', 'ur': 'اردو', 'ar': 'العربية', 'hi': 'हिन्दी', 'es': 'Español', 'fr': 'Français', 'zh': '中文', 'tr': 'Türkçe', 'id': 'Bahasa Indonesia', 'ms': 'Bahasa Melayu'
    };
    return languageNames[languageCode] ?? 'English';
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(journeyProvider);

    // Prepare markers
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(widget.merchant.latitude, widget.merchant.longitude),
        infoWindow: InfoWindow(title: widget.merchant.shopName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    if (journeyState.currentPosition != null) {
      final currentLatLng = LatLng(
        journeyState.currentPosition!.latitude,
        journeyState.currentPosition!.longitude,
      );
      
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentLatLng,
          infoWindow: InfoWindow(title: context.tr('youAreHere')),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );

      // Animate camera only if map controller is available and widget is active
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mapController != null && !journeyState.isLoading) {
          try {
            _mapController!.animateCamera(CameraUpdate.newLatLng(currentLatLng));
          } catch (e) {
            debugPrint('Map controller animation error handled: $e');
          }
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.merchant.shopName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSelectionScreen())),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.language, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(_getCurrentLanguageName(), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshJourney,
            tooltip: context.tr('refresh'),
          ),
        ],
      ),
      body: journeyState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(widget.merchant.latitude, widget.merchant.longitude),
                    zoom: 14,
                  ),
                  markers: markers,
                  onMapCreated: _onMapCreated,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                ),

                // Journey Info Panel
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('liveJourneyInfo'),
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                context.tr('inProgress'),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoColumn(
                              icon: Icons.directions_car,
                              label: context.tr('distanceLeft'),
                              value: journeyState.distanceRemaining != null
                                  ? '${journeyState.distanceRemaining!.toStringAsFixed(1)} km'
                                  : '${widget.initialDistance.toStringAsFixed(1)} km',
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.grey[300],
                            ),
                            _buildInfoColumn(
                              icon: Icons.access_time,
                              label: context.tr('timeLeft'),
                              value: journeyState.timeRemaining != null
                                  ? '${journeyState.timeRemaining!.toStringAsFixed(0)} ${context.tr('mins')}'
                                  : '-- ${context.tr('mins')}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.stop),
                            label: Text(
                              context.tr('endJourney'),
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.indigo, size: 28),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
