// lib/Presentations/User_Location/widgets/location_picker_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/Location_Service.dart';
import '../../../languages/localization/app_localizations.dart';
import '../../../languages/widget/language_selection_screen.dart';

class LocationPickerScreen extends StatefulWidget {
  final Function(double lat, double lng, String address, String pincode) onLocationSelected;
  final String? initialAddress;
  final String? initialPincode;
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({
    super.key,
    required this.onLocationSelected,
    this.initialAddress,
    this.initialPincode,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _searchController = TextEditingController();
  final _mapSearchController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();

  bool _isLoading = false;
  String _selectedAddress = '';
  String _selectedPincode = '';
  double _selectedLat = 0.0;
  double _selectedLng = 0.0;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _mapSearchResults = [];

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  int _selectedTab = 0;
  final LocationService _locationService = LocationService();

  String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _initializeFields();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedLat == 0.0 && _selectedLng == 0.0) {
        _getCurrentLocation();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapSearchController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeFields() {
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _selectedAddress = widget.initialAddress!;
      _addressController.text = widget.initialAddress!;
    }
    if (widget.initialPincode != null && widget.initialPincode!.isNotEmpty) {
      _selectedPincode = widget.initialPincode!;
      _pincodeController.text = widget.initialPincode!;
    }
    if (widget.initialLat != null && widget.initialLng != null && widget.initialLat != 0.0) {
      _selectedLat = widget.initialLat!;
      _selectedLng = widget.initialLng!;
      _addMarker(_selectedLat, _selectedLng);
    }
  }

  String _getCurrentLanguageName() {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final languageNames = {
      'en': 'English', 'ur': 'اردو', 'ar': 'العربية', 'hi': 'हिन्दी', 'es': 'Español', 'fr': 'Français', 'zh': '中文', 'tr': 'Türkçe', 'id': 'Bahasa Indonesia', 'ms': 'Bahasa Melayu'
    };
    return languageNames[languageCode] ?? 'English';
  }

  String _getLoc(String key) {
    final lang = Localizations.localeOf(context).languageCode;
    final Map<String, Map<String, String>> values = {
      'streetHint': { 'en': 'House #, Street, Shop #, Main Road', 'ur': 'مکان نمبر، دکان نمبر، گلی، مین روڈ', 'ar': 'رقم المنزل، الشارع، المنطقة', 'hi': 'मकान नंबर, दुकान नंबर, गली, मेन रोड', 'es': 'Casa #, Calle, Tienda #', 'fr': 'Maison #, Rue, Boutique #', 'zh': '门牌号，街道，铺号', 'tr': 'Ev No, Sokak, Dükkan No', 'id': 'No Rumah, Jalan, Toko', 'ms': 'No Rumah, Jalan, Kedai' },
      'areaHint': { 'en': 'e.g., G-11, Model Town', 'ur': 'مثلاً جی الیون، ماڈل ٹاؤن', 'ar': 'مثلاً جي ١١، موديل تاون', 'hi': 'जैसे, जी-11, मॉडल टाउन', 'es': 'ej., G-11, Model Town', 'fr': 'ex., G-11, Model Town', 'zh': '例如：G-11, 模范镇', 'tr': 'örn., G-11, Model Town', 'id': 'misal, G-11, Model Town', 'ms': 'cth., G-11, Model Town' },
      'cityHint': { 'en': 'e.g., Islamabad, Lahore', 'ur': 'مثلاً اسلام آباد، لاہور', 'ar': 'مثلاً إسلام آباد، لاهور', 'hi': 'जैसे, इस्लामाबाद, लाहौर', 'es': 'ej., Islamabad, Lahore', 'fr': 'ex., Islamabad, Paris', 'zh': '例如：北京，上海', 'tr': 'örn., Ankara, İstanbul', 'id': 'misal, Jakarta, Bandung', 'ms': 'cth., Kuala Lumpur, Ipoh' },
      'confirmLocation': { 'en': 'Confirm Location', 'ur': 'مقام کی تصدیق کریں', 'ar': 'تأكيد الموقع', 'hi': 'स्थान की पुष्टि करें', 'es': 'Confirmar ubicación', 'fr': 'Confirmer l\'emplacement', 'zh': '确认位置', 'tr': 'Konumu Onayla', 'id': 'Konfirmasi Lokasi', 'ms': 'Sahkan Lokasi' },
      'saveLocation': { 'en': 'Save Location', 'ur': 'مقام محفوظ کریں', 'ar': 'حفظ الموقع', 'hi': 'स्थान सहेजें', 'es': 'Guardar ubicación', 'fr': 'Enregistrer l\'emplacement', 'zh': '保存位置', 'tr': 'Konumu Kaydet', 'id': 'Simpan Lokasi', 'ms': 'Simpan Lokasi' }
    };
    return values[key]?[lang] ?? values[key]?['en'] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          context.tr('selectLocation'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSelectionScreen())),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
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
          if (_selectedAddress.isNotEmpty)
            IconButton(
              onPressed: _saveLocation,
              icon: const Icon(Icons.check, color: Colors.white),
              tooltip: context.tr('save'),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTabButton(context.tr('manualEntry'), 0),
                _buildTabButton(context.tr('selectOnMap'), 1),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedTab == 0 ? _buildManualEntry() : _buildMapSelection(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.green[700]! : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.green[700] : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: context.tr('searchLocation'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.my_location, color: Colors.green),
                      onPressed: _getCurrentLocation,
                      tooltip: context.tr('useCurrentLocation'),
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: _searchLocation,
          ),
          if (_searchResults.isNotEmpty)
            Container(
              height: 200,
              color: Colors.white,
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(_searchResults[i]['name']),
                  onTap: () => _fillAddressFromSearch(_searchResults[i]),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            context.tr('enterAddressManually'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildTextField(_addressController, context.tr('streetAddress'), _getLoc('streetHint')),
          const SizedBox(height: 12),
          _buildTextField(_areaController, context.tr('areaSector'), _getLoc('areaHint')),
          const SizedBox(height: 12),
          _buildTextField(_cityController, context.tr('city'), _getLoc('cityHint')),
          const SizedBox(height: 12),
          _buildTextField(_pincodeController, context.tr('pincodeZip'), "44000", TextInputType.number),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _getLoc('saveLocation'),
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, [TextInputType type = TextInputType.text]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: type,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.green[700]!, width: 2),
            ),
          ),
          onChanged: (v) {
            setState(() {
              _selectedAddress = _addressController.text;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMapSelection() {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final LatLng initialTarget = LatLng(
      _selectedLat != 0.0 ? _selectedLat : 31.5204,
      _selectedLng != 0.0 ? _selectedLng : 74.3587,
    );

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (c) {
            _mapController = c;
            if (_selectedLat != 0.0 && _selectedLng != 0.0) {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(LatLng(_selectedLat, _selectedLng), 16),
              );
            }
          },
          initialCameraPosition: CameraPosition(target: initialTarget, zoom: 15),
          markers: _markers,
          onTap: (pos) {
            FocusScope.of(context).unfocus();
            _onMapTap(pos);
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
        ),

        // Floating Sleek Search Bar Overlay on Top of Map
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search, color: Colors.green[700], size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _mapSearchController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: context.tr('searchLocation'),
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: _searchMapLocation,
                        onSubmitted: (q) {
                          FocusScope.of(context).unfocus();
                          _searchMapLocation(q);
                        },
                      ),
                    ),
                    if (_mapSearchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                        onPressed: () {
                          _mapSearchController.clear();
                          setState(() => _mapSearchResults = []);
                        },
                      ),
                    GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        if (_mapSearchController.text.isNotEmpty) {
                          _searchMapLocation(_mapSearchController.text);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              context.tr('search'),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),

              // Search Results Dropdown Overlay on Map (Flexible Height)
              if (_mapSearchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _mapSearchResults.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, i) {
                      final item = _mapSearchResults[i];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.green[50],
                          child: Icon(Icons.location_on, color: Colors.green[700], size: 16),
                        ),
                        title: Text(
                          item['name'],
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          _fillAddressFromMapSearch(item);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // FAB to re-center to current GPS location (Hidden when Keyboard is Open)
        if (!isKeyboardOpen)
          Positioned(
            bottom: _selectedAddress.isNotEmpty ? 150 : 20,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'map_my_location_fab',
              backgroundColor: Colors.white,
              foregroundColor: Colors.green[700],
              onPressed: _getCurrentLocation,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.green),
                    )
                  : const Icon(Icons.my_location, size: 28),
            ),
          ),

        if (_isLoading)
          Container(
            color: Colors.black12,
            child: const Center(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.green),
                      SizedBox(width: 12),
                      Text("Detecting current location..."),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Bottom Confirm Location Card (Hidden when Keyboard is Open)
        if ((_selectedAddress.isNotEmpty || _addressController.text.isNotEmpty) && !isKeyboardOpen)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.green[50],
                          child: Icon(Icons.location_on, color: Colors.green[700], size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('selectedLocation'),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            TextField(
                              controller: _addressController,
                              maxLines: 2,
                              minLines: 1,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: context.tr('streetAddress'),
                                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _selectedAddress = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: _saveLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        _getLoc('confirmLocation'),
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _onMapTap(LatLng pos) async {
    _addMarker(pos.latitude, pos.longitude);
    await _updateAddressFromCoordinates(pos.latitude, pos.longitude);
  }

  void _addMarker(double lat, double lng) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: LatLng(lat, lng),
        ),
      );
    });
  }

  Future<void> _updateAddressFromCoordinates(double lat, double lng) async {
    try {
      final places = await placemarkFromCoordinates(lat, lng);
      if (places.isNotEmpty) {
        final p = places.first;
        final street = (p.street ?? '').isNotEmpty ? p.street! : '';
        final subLoc = (p.subLocality ?? '').isNotEmpty ? p.subLocality! : '';
        final loc = (p.locality ?? '').isNotEmpty ? p.locality! : '';
        final country = (p.country ?? '').isNotEmpty ? p.country! : '';
        final pincode = p.postalCode ?? '';

        final addressParts = [street, subLoc, loc, country].where((s) => s.trim().isNotEmpty).toList();
        final fullAddr = addressParts.join(', ');

        if (mounted) {
          setState(() {
            _selectedLat = lat;
            _selectedLng = lng;
            _selectedAddress = fullAddr.isNotEmpty ? fullAddr : '$lat, $lng';
            _selectedPincode = pincode;
            _addressController.text = street.isNotEmpty ? street : _selectedAddress;
            _pincodeController.text = _selectedPincode;
            _cityController.text = loc;
            _areaController.text = subLoc;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Placemark error: $e');
    }

    // Fallback: Google Maps API Reverse Geocode
    try {
      final address = await _locationService.getAddressFromCoordinates(lat, lng);
      if (mounted && address != null && address.isNotEmpty) {
        setState(() {
          _selectedLat = lat;
          _selectedLng = lng;
          _selectedAddress = address;
          _addressController.text = address;
        });
      }
    } catch (e) {
      debugPrint('Reverse geocode fallback error: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final pos = await _locationService.getLocationWithRetry(context: context);

      if (pos != null) {
        _selectedLat = pos.latitude;
        _selectedLng = pos.longitude;
        _addMarker(pos.latitude, pos.longitude);

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16),
        );

        await _updateAddressFromCoordinates(pos.latitude, pos.longitude);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('errorGettingLocation')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchLocation(String q) async {
    if (q.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    final url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$q&key=$_apiKey";
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _searchResults = (data['predictions'] as List)
                .map((e) => {'name': e['description'], 'id': e['place_id']})
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Search location error: $e');
    }
  }

  void _fillAddressFromSearch(Map<String, dynamic> res) async {
    final url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=${res['id']}&key=$_apiKey";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final loc = data['result']['geometry']['location'];
        final double lat = (loc['lat'] as num).toDouble();
        final double lng = (loc['lng'] as num).toDouble();

        _onMapTap(LatLng(lat, lng));
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
        );
        if (mounted) {
          setState(() => _searchResults = []);
        }
      }
    } catch (e) {
      debugPrint('Fill address error: $e');
    }
  }

  Future<void> _searchMapLocation(String q) async {
    if (q.length < 3) {
      setState(() => _mapSearchResults = []);
      return;
    }
    final url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$q&key=$_apiKey";
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _mapSearchResults = (data['predictions'] as List)
                .map((e) => {'name': e['description'], 'id': e['place_id']})
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Map search location error: $e');
    }
  }

  void _fillAddressFromMapSearch(Map<String, dynamic> res) async {
    final url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=${res['id']}&key=$_apiKey";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final loc = data['result']['geometry']['location'];
        final double lat = (loc['lat'] as num).toDouble();
        final double lng = (loc['lng'] as num).toDouble();

        _addMarker(lat, lng);

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
        );

        await _updateAddressFromCoordinates(lat, lng);

        if (mounted) {
          setState(() {
            _mapSearchResults = [];
            _mapSearchController.text = res['name'];
          });
        }
      }
    } catch (e) {
      debugPrint('Fill address from map search error: $e');
    }
  }

  void _saveLocation() {
    final userTyped = _addressController.text.trim();

    if (_selectedTab == 0) {
      // Manual Entry Mode
      final street = _addressController.text.trim();
      final area = _areaController.text.trim();
      final city = _cityController.text.trim();
      final pincode = _pincodeController.text.trim();

      final List<String> addressParts = [];
      if (street.isNotEmpty) addressParts.add(street);
      if (area.isNotEmpty) addressParts.add(area);
      if (city.isNotEmpty) addressParts.add(city);

      if (addressParts.isNotEmpty) {
        _selectedAddress = addressParts.join(', ');
      }
      if (pincode.isNotEmpty) {
        _selectedPincode = pincode;
      }
    } else {
      // Select on Map Mode
      if (userTyped.isNotEmpty) {
        _selectedAddress = userTyped;
      }
    }

    if (_selectedAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('pleaseSelectLocation'))),
      );
      return;
    }

    widget.onLocationSelected(_selectedLat, _selectedLng, _selectedAddress, _selectedPincode);
    Navigator.pop(context);
  }
}
