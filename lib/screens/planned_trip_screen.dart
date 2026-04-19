import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import 'package:trackmate_app/services/location_service.dart';

class PlannedTripScreen extends StatefulWidget {
  const PlannedTripScreen({super.key});

  @override
  State<PlannedTripScreen> createState() => _PlannedTripScreenState();
}

class _PlannedTripScreenState extends State<PlannedTripScreen> {
  GoogleMapController? _mapController;

  LatLng? _startPoint;
  LatLng? _endPoint;
  String? _startAddress;
  String? _endAddress;

  final _tripNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _startLocationController = TextEditingController();
  final _endLocationController = TextEditingController();

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  String? _modeOfTravel;
  String? _tripPurpose;
  int _companions = 0;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _endDate;

  bool _isLoading = false;
  bool _isGeocodingStart = false;
  bool _isGeocodingEnd = false;

  static const String _googleApiKey = "AIzaSyAtGcgY_MayhcKQRUJRTRoV5d3vvxOYOwQ";

  final List<Map<String, dynamic>> _modes = [
    {"value": "car", "label": "🚗 Car"},
    {"value": "bike", "label": "🏍 Bike"},
    {"value": "bus", "label": "🚌 Bus"},
    {"value": "train", "label": "🚂 Train"},
    {"value": "metro", "label": "🚇 Metro"},
    {"value": "walk", "label": "🚶 Walk"},
  ];

  final List<Map<String, String>> _purposes = [
    {"value": "work", "label": "💼 Work"},
    {"value": "education", "label": "📚 Education"},
    {"value": "shopping", "label": "🛍 Shopping"},
    {"value": "social", "label": "🎉 Social"},
    {"value": "medical", "label": "🏥 Medical"},
    {"value": "personal", "label": "📋 Personal"},
    {"value": "vacation", "label": "🏖 Vacation"},
  ];

  @override
  void dispose() {
    _mapController?.dispose();
    _tripNameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _startLocationController.dispose();
    _endLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text("Plan a Trip"),
        backgroundColor: const Color(0xFF0A0A0A),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PlannedTripScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLocationInputs(),
          const SizedBox(height: 16),
          if (_startPoint != null && _endPoint != null) _buildMapPreview(),
          const SizedBox(height: 16),

          _field(
            controller: _tripNameController,
            label: "Trip Name *",
            icon: Icons.label,
          ),
          const SizedBox(height: 12),

          _field(
            controller: _descriptionController,
            label: "Description",
            icon: Icons.description,
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          _sectionTitle("Mode of Travel *"),
          const SizedBox(height: 8),
          _optionSelector(_modes, (v) => setState(() => _modeOfTravel = v)),

          const SizedBox(height: 16),
          _sectionTitle("Purpose *"),
          const SizedBox(height: 8),
          _optionSelector(_purposes, (v) => setState(() => _tripPurpose = v)),

          const SizedBox(height: 16),
          _sectionTitle("Companions"),
          const SizedBox(height: 8),
          _buildCompanionsSelector(),

          const SizedBox(height: 16),
          _sectionTitle("Budget (Optional)"),
          const SizedBox(height: 8),
          _field(
            controller: _budgetController,
            label: "Estimated Budget",
            icon: Icons.account_balance_wallet,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 26),

          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFf39c12),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ))
                : const Text(
              "Save Trip Plan",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanionsSelector() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (_companions > 0) {
              setState(() => _companions--);
            }
          },
          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFf39c12)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$_companions',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _companions++),
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFFf39c12)),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFf39c12)),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF16213e),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
  );

  Widget _optionSelector(
      List<Map<String, dynamic>> list, Function(String) onSelect) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: list.map((e) {
        final selected =
        (_modeOfTravel == e["value"] || _tripPurpose == e["value"]);
        return GestureDetector(
          onTap: () => onSelect(e["value"]),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFf39c12).withValues(alpha: 0.2)
                  : const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? const Color(0xFFf39c12) : Colors.white24,
              ),
            ),
            child: Text(
              e["label"],
              style: TextStyle(
                color: selected ? const Color(0xFFf39c12) : Colors.white70,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationInputs() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle("Locations *"),
      const SizedBox(height: 8),

      // Start Location
      TextField(
        controller: _startLocationController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: "Start Location",
          prefixIcon: const Icon(Icons.location_on, color: Color(0xFFf39c12)),
          suffixIcon: _isGeocodingStart
              ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.my_location, color: Color(0xFFf39c12)),
            onPressed: _useCurrentLocation,
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF16213e),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (_) => _geocodeStartLocation(),
      ),
      const SizedBox(height: 10),

      // End Location
      TextField(
        controller: _endLocationController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: "Destination",
          prefixIcon: const Icon(Icons.flag, color: Color(0xFFf39c12)),
          suffixIcon: _isGeocodingEnd
              ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : null,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF16213e),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (_) => _geocodeEndLocation(),
      ),
      const SizedBox(height: 10),

      // Geocode Button
      ElevatedButton.icon(
        onPressed: (_isGeocodingStart || _isGeocodingEnd)
            ? null
            : () {
          _geocodeStartLocation();
          _geocodeEndLocation();
        },
        icon: const Icon(Icons.search),
        label: const Text("Find Locations"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16213e),
          foregroundColor: const Color(0xFFf39c12),
        ),
      ),
    ],
  );

  // ✅ Use Current Location
  Future<void> _useCurrentLocation() async {
    setState(() => _isGeocodingStart = true);

    try {
      final position = await LocationService.getCurrentLocation();
      final address = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _startPoint = LatLng(position.latitude, position.longitude);
        _startAddress = address;
        _startLocationController.text = address;
        _isGeocodingStart = false;
      });

      _updateMap();
    } catch (e) {
      setState(() => _isGeocodingStart = false);
      _show("Failed to get current location: $e");
    }
  }

  // ✅ Geocode Start Location
  Future<void> _geocodeStartLocation() async {
    if (_startLocationController.text.isEmpty) return;

    setState(() => _isGeocodingStart = true);

    try {
      final coords = await _geocodeAddress(_startLocationController.text);
      if (coords != null) {
        setState(() {
          _startPoint = coords;
          _startAddress = _startLocationController.text;
        });
        _updateMap();
      } else {
        _show("Could not find start location");
      }
    } catch (e) {
      _show("Error: $e");
    } finally {
      setState(() => _isGeocodingStart = false);
    }
  }

  // ✅ Geocode End Location
  Future<void> _geocodeEndLocation() async {
    if (_endLocationController.text.isEmpty) return;

    setState(() => _isGeocodingEnd = true);

    try {
      final coords = await _geocodeAddress(_endLocationController.text);
      if (coords != null) {
        setState(() {
          _endPoint = coords;
          _endAddress = _endLocationController.text;
        });
        _updateMap();
      } else {
        _show("Could not find destination");
      }
    } catch (e) {
      _show("Error: $e");
    } finally {
      setState(() => _isGeocodingEnd = false);
    }
  }

  // ✅ Google Geocoding API
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

  // ✅ Update Map with Markers
  void _updateMap() {
    _markers.clear();

    if (_startPoint != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: _startPoint!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Start', snippet: _startAddress),
        ),
      );
    }

    if (_endPoint != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: _endPoint!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Destination', snippet: _endAddress),
        ),
      );
    }

    if (_startPoint != null && _endPoint != null) {
      _drawRoute();
    }

    setState(() {});
  }

  // ✅ Draw Route using Directions API
  Future<void> _drawRoute() async {
    if (_startPoint == null || _endPoint == null) return;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${_startPoint!.latitude},${_startPoint!.longitude}&destination=${_endPoint!.latitude},${_endPoint!.longitude}&key=$_googleApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final points = _decodePolyline(
              data['routes'][0]['overview_polyline']['points']);
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: const Color(0xFFf39c12),
                width: 5,
              ),
            );
          });

          // Move camera to show both markers
          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(
                  _startPoint!.latitude < _endPoint!.latitude
                      ? _startPoint!.latitude
                      : _endPoint!.latitude,
                  _startPoint!.longitude < _endPoint!.longitude
                      ? _startPoint!.longitude
                      : _endPoint!.longitude,
                ),
                northeast: LatLng(
                  _startPoint!.latitude > _endPoint!.latitude
                      ? _startPoint!.latitude
                      : _endPoint!.latitude,
                  _startPoint!.longitude > _endPoint!.longitude
                      ? _startPoint!.longitude
                      : _endPoint!.longitude,
                ),
              ),
              50,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Route drawing error: $e');
    }
  }

  // ✅ Decode Polyline
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

  Widget _buildMapPreview() => Container(
    height: 300,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Colors.black,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _startPoint ?? const LatLng(28.7041, 77.1025),
          zoom: 14,
        ),
        onMapCreated: (controller) => _mapController = controller,
        markers: _markers,
        polylines: _polylines,
        zoomControlsEnabled: true,
        myLocationButtonEnabled: true,
      ),
    ),
  );

  // ✅ Submit Form - FIXED
  Future<void> _submitForm() async {
    final api = context.read<ApiService>();
    // Validation
    if (_tripNameController.text.trim().isEmpty) {
      _show("Please enter trip name");
      return;
    }

    if (_startLocationController.text.trim().isEmpty) {
      _show("Please enter start location");
      return;
    }

    if (_endLocationController.text.trim().isEmpty) {
      _show("Please enter destination");
      return;
    }

    if (_modeOfTravel == null) {
      _show("Please select mode of travel");
      return;
    }

    if (_tripPurpose == null) {
      _show("Please select trip purpose");
      return;
    }

    // Geocode if not already done
    if (_startPoint == null) {
      await _geocodeStartLocation();
    }
    if (_endPoint == null) {
      await _geocodeEndLocation();
    }

    if (_startPoint == null || _endPoint == null) {
      _show("Could not find locations. Please check addresses.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await api.loadTokens();

      if (api.accessToken == null || api.accessToken!.isEmpty) {
        _show("Please login first");
        setState(() => _isLoading = false);
        return;
      }

      // Build request body
      final body = {
        "trip_name": _tripNameController.text.trim(),
        "start_latitude": _startPoint!.latitude.toString(),
        "start_longitude": _startPoint!.longitude.toString(),
        "start_location_name": _startAddress ?? _startLocationController.text.trim(),
        "end_latitude": _endPoint!.latitude.toString(),
        "end_longitude": _endPoint!.longitude.toString(),
        "end_location_name": _endAddress ?? _endLocationController.text.trim(),
        "mode_of_travel": _modeOfTravel,
        "trip_purpose": _tripPurpose,
        "companions": _companions,
      };

      if (_descriptionController.text.trim().isNotEmpty) {
        body["description"] = _descriptionController.text.trim();
      }

      if (_budgetController.text.trim().isNotEmpty) {
        body["estimated_budget"] = _budgetController.text.trim();
      }

      debugPrint('📤 Sending planned trip: $body');

      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/planned-trips/"),
        headers: {
          "Authorization": "Token ${api.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      debugPrint('📥 Response status: ${res.statusCode}');
      debugPrint('📥 Response body: ${res.body}');

      setState(() => _isLoading = false);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _show("Trip plan saved successfully!");

        // Clear form
        _tripNameController.clear();
        _descriptionController.clear();
        _budgetController.clear();
        _startLocationController.clear();
        _endLocationController.clear();

        setState(() {
          _startPoint = null;
          _endPoint = null;
          _startAddress = null;
          _endAddress = null;
          _modeOfTravel = null;
          _tripPurpose = null;
          _companions = 0;
          _markers.clear();
          _polylines.clear();
        });

        // Navigate to saved trips
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const PlannedTripScreen(),
            ),
          );
        }
      } else {
        final errorData = jsonDecode(res.body);
        _show("Failed to save: ${errorData.toString()}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ Error: $e');
      _show("Error: $e");
    }
  }

  void _show(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: msg.contains("success") ? Colors.green : Colors.red,
      duration: const Duration(seconds: 3),
    ),
  );
}