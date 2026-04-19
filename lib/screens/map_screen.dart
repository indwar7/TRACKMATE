import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../screens/live_tracking_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;

  final _destinationController = TextEditingController();

  LatLng? _startPoint;
  LatLng? _destinationPoint;
  String? _startAddress;
  String? _destinationAddress;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  bool _isLoadingRoute = false;
  bool _showRoutePreview = false;

  // Route info
  double? _distanceKm;
  int? _durationMinutes;
  double? _estimatedCost;
  String? _selectedMode = 'car';

  static const String _googleApiKey = "AIzaSyAtGcgY_MayhcKQRUJRTRoV5d3vvxOYOwQ";

  final List<Map<String, dynamic>> _modes = [
    {"value": "car", "label": "🚗 Car", "icon": Icons.directions_car},
    {"value": "bike", "label": "🏍️ Bike", "icon": Icons.two_wheeler},
    {"value": "bus", "label": "🚌 Bus", "icon": Icons.directions_bus},
    {"value": "walk", "label": "🚶 Walk", "icon": Icons.directions_walk},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final hasPermission = await LocationService.checkPermissions();
      if (!hasPermission) {
        _showError("Location permission required");
        return;
      }

      final position = await LocationService.getCurrentLocation();
      final address = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = position;
        _startPoint = LatLng(position.latitude, position.longitude);
        _startAddress = address;

        // Add current location marker
        _markers.add(
          Marker(
            markerId: const MarkerId('current'),
            position: _startPoint!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(title: 'Your Location', snippet: address),
          ),
        );
      });

      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_startPoint!, 15),
      );
    } catch (e) {
      _showError("Failed to get location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(28.7041, 77.1025),
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),

          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),

          // My Location Button
          Positioned(
            bottom: _showRoutePreview ? 260 : 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'location',
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Color(0xFF00adb5)),
              onPressed: _getCurrentLocation,
            ),
          ),

          // Route Preview Card
          if (_showRoutePreview) _buildRoutePreviewCard(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Destination Input
          Row(
            children: [
              const Icon(Icons.search, color: Color(0xFF00adb5)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _destinationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Where to?',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _searchDestination(),
                ),
              ),
              if (_destinationController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    setState(() {
                      _destinationController.clear();
                      _destinationPoint = null;
                      _destinationAddress = null;
                      _showRoutePreview = false;
                      _markers.removeWhere((m) => m.markerId.value == 'destination');
                      _polylines.clear();
                    });
                  },
                ),
            ],
          ),

          // Mode Selector (only show when route is available)
          if (_showRoutePreview) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _modes.map((mode) {
                final isSelected = _selectedMode == mode['value'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedMode = mode['value']);
                    _previewRoute();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00adb5).withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00adb5)
                            : Colors.white24,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          mode['icon'],
                          color: isSelected ? const Color(0xFF00adb5) : Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mode['label'],
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF00adb5) : Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoutePreviewCard() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF16213e),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Route Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: _distanceKm != null
                      ? '${_distanceKm!.toStringAsFixed(1)} km'
                      : '--',
                ),
                _buildStatCard(
                  icon: Icons.access_time,
                  label: 'Duration',
                  value: _durationMinutes != null
                      ? '${_durationMinutes} min'
                      : '--',
                ),
                _buildStatCard(
                  icon: Icons.account_balance_wallet,
                  label: 'Est. Cost',
                  value: _estimatedCost != null
                      ? '₹${_estimatedCost!.toStringAsFixed(0)}'
                      : '--',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Start Trip Button
            ElevatedButton(
              onPressed: _isLoadingRoute ? null : _startTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00adb5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoadingRoute
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.navigation, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Start Navigation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00adb5), size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _searchDestination() async {
    if (_destinationController.text.trim().isEmpty) {
      _showError("Please enter a destination");
      return;
    }

    setState(() => _isLoadingRoute = true);

    try {
      // Geocode destination
      final coords = await _geocodeAddress(_destinationController.text);

      if (coords == null) {
        _showError("Could not find destination");
        setState(() => _isLoadingRoute = false);
        return;
      }

      setState(() {
        _destinationPoint = coords;
        _destinationAddress = _destinationController.text;

        // Add destination marker
        _markers.removeWhere((m) => m.markerId.value == 'destination');
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: coords,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: 'Destination',
              snippet: _destinationAddress,
            ),
          ),
        );
      });

      // Preview route
      await _previewRoute();

      // Fit bounds to show both markers
      if (_startPoint != null && _destinationPoint != null) {
        final bounds = LatLngBounds(
          southwest: LatLng(
            _startPoint!.latitude < _destinationPoint!.latitude
                ? _startPoint!.latitude
                : _destinationPoint!.latitude,
            _startPoint!.longitude < _destinationPoint!.longitude
                ? _startPoint!.longitude
                : _destinationPoint!.longitude,
          ),
          northeast: LatLng(
            _startPoint!.latitude > _destinationPoint!.latitude
                ? _startPoint!.latitude
                : _destinationPoint!.latitude,
            _startPoint!.longitude > _destinationPoint!.longitude
                ? _startPoint!.longitude
                : _destinationPoint!.longitude,
          ),
        );

        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      }

      setState(() => _isLoadingRoute = false);
    } catch (e) {
      setState(() => _isLoadingRoute = false);
      _showError("Error: $e");
    }
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_googleApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    return null;
  }

  Future<void> _previewRoute() async {
    if (_startPoint == null || _destinationPoint == null) return;

    setState(() => _isLoadingRoute = true);

    try {
      final apiService = context.read<ApiService>();
      await apiService.loadTokens();

      debugPrint('🔑 Token status: ${apiService.accessToken != null ? "Present" : "NULL"}');
      debugPrint('🔑 Token value: ${apiService.accessToken}');

      if (apiService.accessToken == null || apiService.accessToken!.isEmpty) {
        _showError("Please login first");
        setState(() => _isLoadingRoute = false);
        return;
      }

      // Call preview route API
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/trips/preview-route/'),
        headers: {
          'Authorization': 'Token ${apiService.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'start_latitude': _startPoint!.latitude,
          'start_longitude': _startPoint!.longitude,
          'start_location_name': _startAddress ?? 'Current Location',
          'end_latitude': _destinationPoint!.latitude,
          'end_longitude': _destinationPoint!.longitude,
          'end_location_name': _destinationAddress ?? 'Destination',
          'mode_of_travel': _selectedMode,
        }),
      );

      debugPrint('📥 Preview Route Response: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _distanceKm = double.tryParse(data['distance_km']?.toString() ?? '0');
          _durationMinutes = int.tryParse(data['duration_minutes']?.toString() ?? '0');
          _estimatedCost = double.tryParse(data['estimated_cost']?.toString() ?? '0');
          _showRoutePreview = true;
        });

        // Draw route on map
        await _drawRouteOnMap();
      } else {
        _showError("Failed to get route: ${response.body}");
      }
    } catch (e) {
      debugPrint('❌ Preview route error: $e');
      _showError("Error: $e");
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }

  Future<void> _drawRouteOnMap() async {
    if (_startPoint == null || _destinationPoint == null) return;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${_startPoint!.latitude},${_startPoint!.longitude}&'
          'destination=${_destinationPoint!.latitude},${_destinationPoint!.longitude}&'
          'mode=${_getGoogleMode(_selectedMode!)}&'
          'key=$_googleApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final points = _decodePolyline(
            data['routes'][0]['overview_polyline']['points'],
          );

          setState(() {
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: const Color(0xFF00adb5),
                width: 5,
              ),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Route drawing error: $e');
    }
  }

  String _getGoogleMode(String mode) {
    switch (mode) {
      case 'car':
        return 'driving';
      case 'bike':
        return 'bicycling';
      case 'walk':
        return 'walking';
      case 'bus':
        return 'transit';
      default:
        return 'driving';
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> _startTrip() async {
    if (_startPoint == null || _destinationPoint == null) {
      _showError("Please select a destination first");
      return;
    }

    setState(() => _isLoadingRoute = true);

    try {
      final apiService = context.read<ApiService>();
      await apiService.loadTokens();

      debugPrint('🔑 Start Trip - Token status: ${apiService.accessToken != null ? "Present" : "NULL"}');

      if (apiService.accessToken == null || apiService.accessToken!.isEmpty) {
        _showError("Please login first");
        setState(() => _isLoadingRoute = false);
        return;
      }

      // Start trip via API
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/trips/start/'),
        headers: {
          'Authorization': 'Token ${apiService.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'start_latitude': _startPoint!.latitude,
          'start_longitude': _startPoint!.longitude,
          'start_location_name': _startAddress ?? 'Current Location',
        }),
      );

      debugPrint('📥 Start Trip Response: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final tripId = data['trip']['id'];

        // Navigate to live tracking
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LiveTrackingScreen(
                tripId: tripId,
                startLocation: _startAddress,
              ),
            ),
          );
        }
      } else {
        _showError("Failed to start trip: ${response.body}");
      }
    } catch (e) {
      debugPrint('❌ Start trip error: $e');
      _showError("Error: $e");
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}