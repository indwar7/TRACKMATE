import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';

class ManualTripScreen extends StatefulWidget {
  const ManualTripScreen({super.key});

  @override
  State<ManualTripScreen> createState() => _ManualTripScreenState();
}

class _ManualTripScreenState extends State<ManualTripScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(28.6139, 77.2090); // Default Delhi

  // Location markers
  LatLng? _startLocation;
  LatLng? _endLocation;

  // Text controllers
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  // Search state
  bool _isSearchingStart = false;
  bool _isSearchingEnd = false;
  List<dynamic> _startSuggestions = [];
  List<dynamic> _endSuggestions = [];

  // Form display
  bool _showForm = false;

  // Form controllers
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _co2Controller = TextEditingController();
  final _modeController = TextEditingController(text: 'Car');
  final _purposeController = TextEditingController();
  final _companionsController = TextEditingController(text: '0');
  final _fuelTypeController = TextEditingController(text: 'Petrol');
  final _fuelCostController = TextEditingController();
  final _parkingController = TextEditingController();
  final _tollController = TextEditingController();
  final _ticketController = TextEditingController();
  final _totalCostController = TextEditingController();

  bool _isLoading = false;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // ADD YOUR GOOGLE PLACES API KEY HERE
  static const String _placesApiKey = 'AIzaSyAtGcgY_MayhcKQRUJRTRoV5d3vvxOYOwQ';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool hasPermission = await LocationService.checkPermissions();
      if (!hasPermission) return;

      Position position = await LocationService.getCurrentLocation();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 14),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  // NEW: Direct Places Autocomplete API call
  Future<void> _searchStartLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _startSuggestions = [];
        _isSearchingStart = false;
      });
      return;
    }

    setState(() => _isSearchingStart = true);

    try {
      final suggestions = await _getPlaceSuggestions(query);
      setState(() {
        _startSuggestions = suggestions;
        _isSearchingStart = false;
      });
    } catch (e) {
      setState(() => _isSearchingStart = false);
      debugPrint('Error searching location: $e');
    }
  }

  // NEW: Direct Places Autocomplete API call
  Future<void> _searchEndLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _endSuggestions = [];
        _isSearchingEnd = false;
      });
      return;
    }

    setState(() => _isSearchingEnd = true);

    try {
      final suggestions = await _getPlaceSuggestions(query);
      setState(() {
        _endSuggestions = suggestions;
        _isSearchingEnd = false;
      });
    } catch (e) {
      setState(() => _isSearchingEnd = false);
      debugPrint('Error searching location: $e');
    }
  }

  // NEW: Get place suggestions from Google Places API
  Future<List<dynamic>> _getPlaceSuggestions(String input) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_placesApiKey&components=country:in';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['predictions'];
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
      return [];
    }
  }

  // NEW: Get place details (lat/lng) from place_id
  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_placesApiKey&fields=geometry,formatted_address';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching place details: $e');
      return null;
    }
  }

  void _selectStartLocation(dynamic place) async {
    // Get place_id from the suggestion
    final placeId = place['place_id'];

    // Fetch full place details to get lat/lng
    final placeDetails = await _getPlaceDetails(placeId);

    if (placeDetails != null) {
      final lat = placeDetails['geometry']['location']['lat'];
      final lng = placeDetails['geometry']['location']['lng'];
      final address = placeDetails['formatted_address'] ?? place['description'];

      setState(() {
        _startLocation = LatLng(lat, lng);
        _startController.text = address;
        _startSuggestions = [];

        _markers.removeWhere((m) => m.markerId.value == 'start');
        _markers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: _startLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Start'),
          ),
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_startLocation!, 14),
      );

      if (_endLocation != null) {
        _drawRoute();
        setState(() => _showForm = true);
      }
    }
  }

  void _selectEndLocation(dynamic place) async {
    // Get place_id from the suggestion
    final placeId = place['place_id'];

    // Fetch full place details to get lat/lng
    final placeDetails = await _getPlaceDetails(placeId);

    if (placeDetails != null) {
      final lat = placeDetails['geometry']['location']['lat'];
      final lng = placeDetails['geometry']['location']['lng'];
      final address = placeDetails['formatted_address'] ?? place['description'];

      setState(() {
        _endLocation = LatLng(lat, lng);
        _endController.text = address;
        _endSuggestions = [];

        _markers.removeWhere((m) => m.markerId.value == 'end');
        _markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: _endLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'End'),
          ),
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_endLocation!, 14),
      );

      if (_startLocation != null) {
        _drawRoute();
        setState(() => _showForm = true);
      }
    }
  }

  double _calculateCO2() {
    if (_distanceController.text.isEmpty || _modeController.text.isEmpty) {
      return 0;
    }

    final distance = double.tryParse(_distanceController.text) ?? 0;
    final mode = _modeController.text.toLowerCase();

    // CO2 emission factors (kg CO2 per km)
    const Map<String, double> emissionFactors = {
      'car': 0.21,
      'bike': 0.0,
      'bus': 0.089,
      'train': 0.041,
      'walk': 0.0,
      'metro': 0.028,
      'auto': 0.15,
    };

    final factor = emissionFactors[mode] ?? 0.21;
    return distance * factor;
  }

  void _updateCO2() {
    final co2 = _calculateCO2();
    _co2Controller.text = co2.toStringAsFixed(2);
  }

  void _calculateTotalCost() {
    double total = 0;

    if (_fuelCostController.text.isNotEmpty) {
      total += double.tryParse(_fuelCostController.text) ?? 0;
    }
    if (_parkingController.text.isNotEmpty) {
      total += double.tryParse(_parkingController.text) ?? 0;
    }
    if (_tollController.text.isNotEmpty) {
      total += double.tryParse(_tollController.text) ?? 0;
    }
    if (_ticketController.text.isNotEmpty) {
      total += double.tryParse(_ticketController.text) ?? 0;
    }

    _totalCostController.text = total.toStringAsFixed(2);
  }

  void _onMapTap(LatLng position) async {
    if (_startLocation == null) {
      // Set start location
      setState(() {
        _startLocation = position;
        _markers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Start'),
          ),
        );
      });

      // Get address for start location
      String address = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      _startController.text = address;
    } else if (_endLocation == null) {
      // Set end location
      setState(() {
        _endLocation = position;
        _markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'End'),
          ),
        );
      });

      // Get address for end location
      String address = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      _endController.text = address;

      // Draw route line
      _drawRoute();

      // Show the form
      setState(() {
        _showForm = true;
      });
    }
  }

  void _drawRoute() {
    if (_startLocation != null && _endLocation != null) {
      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [_startLocation!, _endLocation!],
            color: const Color(0xFF00adb5),
            width: 4,
          ),
        );
      });

      // Calculate distance
      double distanceInMeters = Geolocator.distanceBetween(
        _startLocation!.latitude,
        _startLocation!.longitude,
        _endLocation!.latitude,
        _endLocation!.longitude,
      );

      _distanceController.text = (distanceInMeters / 1000).toStringAsFixed(2);
      _updateCO2();
    }
  }

  void _resetLocations() {
    setState(() {
      _startLocation = null;
      _endLocation = null;
      _markers.clear();
      _polylines.clear();
      _startController.clear();
      _endController.clear();
      _startSuggestions = [];
      _endSuggestions = [];
      _showForm = false;
    });
  }

  Future<void> _saveTrip() async {
    if (_startLocation == null || _endLocation == null) {
      _showError('Please select both start and end locations');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final tripDate = _dateController.text.isNotEmpty
          ? _dateController.text
          : '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Build start_time from date + time fields
      final timePart = _timeController.text.isNotEmpty ? _timeController.text : '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final startTime = DateTime.tryParse('${tripDate}T$timePart:00') ?? now;

      final durationMins = int.tryParse(_durationController.text) ?? 0;
      final distance = double.tryParse(_distanceController.text) ?? 0.0;
      final fuelCost = double.tryParse(_fuelCostController.text) ?? 0.0;
      final parkingCost = double.tryParse(_parkingController.text) ?? 0.0;
      final tollCost = double.tryParse(_tollController.text) ?? 0.0;
      final ticketCost = double.tryParse(_ticketController.text) ?? 0.0;
      final totalCost = double.tryParse(_totalCostController.text) ?? (fuelCost + parkingCost + tollCost + ticketCost);

      final tripRecord = {
        'local_id': now.millisecondsSinceEpoch,
        'trip_id': 0,
        'start_location_name': _startController.text,
        'end_location_name': _endController.text,
        'start_latitude': _startLocation!.latitude,
        'start_longitude': _startLocation!.longitude,
        'end_latitude': _endLocation!.latitude,
        'end_longitude': _endLocation!.longitude,
        'distance_km': distance,
        'duration_minutes': durationMins,
        'mode_of_travel': _modeController.text.toLowerCase(),
        'trip_purpose': _purposeController.text.toLowerCase(),
        'number_of_companions': int.tryParse(_companionsController.text) ?? 0,
        'co2_kg': double.tryParse(_co2Controller.text) ?? 0.0,
        'fuel_expense': fuelCost,
        'parking_cost': parkingCost,
        'toll_cost': tollCost,
        'ticket_cost': ticketCost,
        'total_cost': totalCost,
        'start_time': startTime.toIso8601String(),
        'end_time': startTime.add(Duration(minutes: durationMins)).toIso8601String(),
        'source': 'local',
      };

      // Always save locally first
      final box = GetStorage();
      final List existing = box.read<List>('local_trips') ?? [];
      existing.insert(0, tripRecord);
      box.write('local_trips', existing);
      debugPrint('✅ Manual trip saved locally (${existing.length} total)');

      // Try backend silently
      try {
        final api = context.read<ApiService>();
        if (api.accessToken != null && api.accessToken!.isNotEmpty) {
          await http.post(
            Uri.parse("${ApiService.baseUrl}/trips/create-manual/"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer ${api.accessToken}",
            },
            body: jsonEncode({
              "start_location": _startController.text,
              "start_latitude": double.parse(_startLocation!.latitude.toStringAsFixed(6)),
              "start_longitude": double.parse(_startLocation!.longitude.toStringAsFixed(6)),
              "end_location": _endController.text,
              "end_latitude": double.parse(_endLocation!.latitude.toStringAsFixed(6)),
              "end_longitude": double.parse(_endLocation!.longitude.toStringAsFixed(6)),
              "trip_date": tripDate,
              "mode_of_travel": _modeController.text.toLowerCase(),
              if (_purposeController.text.isNotEmpty) "trip_purpose": _purposeController.text.toLowerCase(),
              if ((int.tryParse(_companionsController.text) ?? 0) > 0)
                "number_of_companions": int.tryParse(_companionsController.text),
              if (fuelCost > 0) "fuel_expense": fuelCost,
              if (parkingCost > 0) "parking_cost": parkingCost,
              if (tollCost > 0) "toll_cost": tollCost,
              if (ticketCost > 0) "ticket_cost": ticketCost,
            }),
          ).timeout(const Duration(seconds: 5));
        }
      } catch (e) {
        debugPrint('⚠️ Backend save failed (local copy saved): $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip saved!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to save trip: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        title: const Text('Save Untracked Trip'),
        backgroundColor: const Color(0xFF16213e),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetLocations,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: _showForm ? 2 : 3,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: _onMapTap,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                ),

                // Instructions overlay
                if (!_showForm)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _startLocation == null
                            ? 'Tap on map to select START location or type below'
                            : 'Tap on map to select END location or type below',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Location Display with Search
          Container(
            color: const Color(0xFF16213e),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Start Location Search
                _buildSearchableLocationField(
                  icon: Icons.trip_origin,
                  label: 'Start Location',
                  controller: _startController,
                  color: Colors.green,
                  suggestions: _startSuggestions,
                  isSearching: _isSearchingStart,
                  onChanged: _searchStartLocation,
                  onSuggestionSelected: _selectStartLocation,
                ),
                const SizedBox(height: 8),
                // End Location Search
                _buildSearchableLocationField(
                  icon: Icons.location_on,
                  label: 'End Location',
                  controller: _endController,
                  color: Colors.red,
                  suggestions: _endSuggestions,
                  isSearching: _isSearchingEnd,
                  onChanged: _searchEndLocation,
                  onSuggestionSelected: _selectEndLocation,
                ),
              ],
            ),
          ),

          // Form Section
          if (_showForm)
            Expanded(
              flex: 3,
              child: Container(
                color: const Color(0xFF0f0f1e),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildFormField(
                        'Date',
                        _dateController,
                        icon: Icons.calendar_today,
                        onTap: () => _selectDate(context),
                      ),
                      _buildFormField(
                        'Time',
                        _timeController,
                        icon: Icons.access_time,
                        onTap: () => _selectTime(context),
                      ),
                      _buildFormField(
                        'Duration (mins)',
                        _durationController,
                        icon: Icons.timer,
                        keyboardType: TextInputType.number,
                      ),
                      _buildFormField(
                        'Distance (km)',
                        _distanceController,
                        icon: Icons.straighten,
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _updateCO2(),
                      ),
                      _buildFormField(
                        'CO2 Emitted (kg)',
                        _co2Controller,
                        icon: Icons.cloud,
                        keyboardType: TextInputType.number,
                        readOnly: true,
                      ),
                      _buildFormField(
                        'Mode of Travel',
                        _modeController,
                        icon: Icons.directions_car,
                        onChanged: (value) => _updateCO2(),
                      ),
                      _buildFormField(
                        'Trip Purpose',
                        _purposeController,
                        icon: Icons.description,
                      ),
                      _buildFormField(
                        'Number of Companions',
                        _companionsController,
                        icon: Icons.people,
                        keyboardType: TextInputType.number,
                      ),
                      _buildFormField(
                        'Fuel Type',
                        _fuelTypeController,
                        icon: Icons.local_gas_station,
                      ),
                      _buildFormField(
                        'Fuel Cost',
                        _fuelCostController,
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _calculateTotalCost(),
                      ),
                      _buildFormField(
                        'Parking Cost',
                        _parkingController,
                        icon: Icons.local_parking,
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _calculateTotalCost(),
                      ),
                      _buildFormField(
                        'Toll Cost',
                        _tollController,
                        icon: Icons.toll,
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _calculateTotalCost(),
                      ),
                      _buildFormField(
                        'Ticket Cost',
                        _ticketController,
                        icon: Icons.confirmation_number,
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _calculateTotalCost(),
                      ),
                      _buildFormField(
                        'Total Cost',
                        _totalCostController,
                        icon: Icons.account_balance_wallet,
                        keyboardType: TextInputType.number,
                        readOnly: true,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00adb5),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'Save Trip',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchableLocationField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required Color color,
    required List<dynamic> suggestions,
    required bool isSearching,
    required Function(String) onChanged,
    required Function(dynamic) onSuggestionSelected,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0f0f1e),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: label,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (isSearching)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00adb5),
                  ),
                ),
            ],
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00adb5).withValues(alpha: 0.3),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: suggestions.length > 5 ? 5 : suggestions.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.white.withValues(alpha: 0.1),
                  height: 1,
                  thickness: 0.5,
                ),
                itemBuilder: (context, index) {
                  final place = suggestions[index];
                  final String placeDescription = place['description'] ?? 'Unknown location';

                  return InkWell(
                    onTap: () => onSuggestionSelected(place),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              placeDescription,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFormField(
      String label,
      TextEditingController controller, {
        IconData? icon,
        TextInputType? keyboardType,
        VoidCallback? onTap,
        Function(String)? onChanged,
        bool readOnly = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly || onTap != null,
        onTap: onTap,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon:
          icon != null ? Icon(icon, color: const Color(0xFF00adb5)) : null,
          filled: true,
          fillColor:
          readOnly ? const Color(0xFF16213e).withValues(alpha: 0.5) : const Color(0xFF16213e),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF00adb5)),
          ),
        ),
      ),
    );
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00adb5),
              surface: Color(0xFF16213e),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Store in strict YYYY-MM-DD format as backend requires
      final year = picked.year.toString().padLeft(4, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final day = picked.day.toString().padLeft(2, '0');
      _dateController.text = '$year-$month-$day';
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00adb5),
              surface: Color(0xFF16213e),
            ),
          ),
          child: child!,
        );
      });
    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      _timeController.text = '$hour:$minute';
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _startController.dispose();
    _endController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _co2Controller.dispose();
    _modeController.dispose();
    _purposeController.dispose();
    _companionsController.dispose();
    _fuelTypeController.dispose();
    _fuelCostController.dispose();
    _parkingController.dispose();
    _tollController.dispose();
    _ticketController.dispose();
    _totalCostController.dispose();
    super.dispose();
  }
}
