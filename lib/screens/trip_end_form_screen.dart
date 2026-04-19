import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class TripEndFormScreen extends StatefulWidget {
  final int tripId;
  final String startLocation;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final String endLocation;
  final double distance;
  final int duration;
  final String? detectedMode;
  final String? modeConfidence;

  const TripEndFormScreen({
    super.key,
    required this.tripId,
    required this.startLocation,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.endLocation,
    required this.distance,
    required this.duration,
    this.detectedMode,
    this.modeConfidence,
  });

  @override
  State<TripEndFormScreen> createState() => _TripEndFormScreenState();
}

class _TripEndFormScreenState extends State<TripEndFormScreen> {
  GoogleMapController? _mapController;

  LatLng? _selectedEndPoint;
  String? _selectedEndAddress;
  final Set<Marker> _markers = {};

  bool _showForm = true; // skip map, go straight to form
  bool _isLoading = false;

  // Form controllers
  final _startLocationController = TextEditingController();
  final _endLocationController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _co2Controller = TextEditingController();
  final _modeController = TextEditingController();
  final _purposeController = TextEditingController();
  final _companionsController = TextEditingController(text: '0');
  final _fuelTypeController = TextEditingController();
  final _fuelCostController = TextEditingController();
  final _parkingController = TextEditingController();
  final _tollController = TextEditingController();
  final _ticketController = TextEditingController();
  final _totalCostController = TextEditingController();

  // ✅ NEW: Companion details storage
  List<Map<String, TextEditingController>> _companionControllers = [];
  int _companionCount = 0;

  // CO2 emission factors (kg per km)
  final Map<String, double> _co2EmissionFactors = {
    'Car - Petrol': 0.192,
    'Car - Diesel': 0.171,
    'Car - CNG': 0.157,
    'Car - Electric': 0.00,
    'Bike Petrol ': 0.105,
    'Bike Electric': 0.084,
    'Bus': 0.089,
    'Train': 0.041,
    'Metro': 0.030,
    'Auto Rickshaw': 0.085,
    'Bicycle': 0.0,
    'Walking': 0.0,
    'Other': 0.15,
  };

  final Map<String, String> _modeBackendMap = {
    'Car - Petrol': 'car',
    'Car - Diesel': 'car',
    'Car - CNG': 'car',
    'Car - Electric': 'car',
    'Bike - Petrol': 'Bike Taxi',
    'Bike - Electric': 'Bike Taxi',
    'Bus': 'bus',
    'Train': 'train',
    'Metro': 'metro',
    'Auto Rickshaw': 'auto',
    'Bicycle': 'bicycle',
    'Walking': 'walk',
    'Other': 'other',
  };

  final Map<String, String> _fuelTypeMap = {
    'Car - Petrol': 'petrol',
    'Car - Diesel': 'diesel',
    'Car - CNG': 'cng',
    'Car - Electric': 'electric',
    'Bike - Petrol': 'petrol',
    'Bike - Electric': 'electric',
    'Bus': 'diesel',
    'Train': 'electric',
    'Metro': 'electric',
    'Auto Rickshaw': 'cng',
    'Bicycle': 'none',
    'Walking': 'none',
    'Other': 'other',
  };

  final Map<String, String> _purposeBackendMap = {
    'Work': 'work',
    'Personal': 'personal',
    'Shopping': 'shopping',
    'Social': 'social',
    'Education': 'education',
    'Health': 'health',
    'Other': 'other',
  };

  @override
  void initState() {
    super.initState();
    _selectedEndPoint = LatLng(widget.endLat, widget.endLng);
    _selectedEndAddress = widget.endLocation;

    _startLocationController.text = widget.startLocation;
    _endLocationController.text = widget.endLocation;
    _distanceController.text = widget.distance.toStringAsFixed(2);
    _durationController.text = widget.duration.toString();

    final now = DateTime.now();
    _dateController.text = '${now.day}/${now.month}/${now.year}';
    _timeController.text = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    if (widget.detectedMode != null &&
        widget.detectedMode!.isNotEmpty &&
        widget.detectedMode != 'Detecting...') {
      _modeController.text = widget.detectedMode!;
      _fuelTypeController.text = _fuelTypeMap[widget.detectedMode!] ?? 'petrol';
      debugPrint('✅ Using auto-detected mode: ${widget.detectedMode} (${widget.modeConfidence})');
    } else {
      _modeController.text = 'Car - Petrol';
      _fuelTypeController.text = 'petrol';
    }

    _purposeController.text = 'Work';
    _calculateCO2Emission();
    _addEndMarker();

    _fuelCostController.addListener(_calculateTotalCost);
    _parkingController.addListener(_calculateTotalCost);
    _tollController.addListener(_calculateTotalCost);
    _ticketController.addListener(_calculateTotalCost);
    _modeController.addListener(_calculateCO2Emission);
    _distanceController.addListener(_calculateCO2Emission);

    // ✅ NEW: Listen to companion count changes
    _companionsController.addListener(_onCompanionCountChanged);

    debugPrint('🎯 Form initialized');
  }

  // ✅ NEW: Handle companion count changes
  void _onCompanionCountChanged() {
    final newCount = int.tryParse(_companionsController.text) ?? 0;
    if (newCount != _companionCount && newCount >= 0) {
      setState(() {
        _companionCount = newCount;

        // Dispose old controllers if reducing count
        if (newCount < _companionControllers.length) {
          for (int i = newCount; i < _companionControllers.length; i++) {
            _companionControllers[i]['name']?.dispose();
            _companionControllers[i]['phone']?.dispose();
          }
          _companionControllers = _companionControllers.sublist(0, newCount);
        }

        // Add new controllers if increasing count
        while (_companionControllers.length < newCount) {
          _companionControllers.add({
            'name': TextEditingController(),
            'phone': TextEditingController(),
          });
        }
      });
    }
  }

  void _calculateCO2Emission() {
    final mode = _modeController.text;
    final distance = double.tryParse(_distanceController.text) ?? 0.0;
    final emissionFactor = _co2EmissionFactors[mode] ?? 0.15;
    final co2 = distance * emissionFactor;

    setState(() {
      _co2Controller.text = co2.toStringAsFixed(2);
    });
  }

  void _calculateTotalCost() {
    final fuelCost = double.tryParse(_fuelCostController.text) ?? 0.0;
    final parkingCost = double.tryParse(_parkingController.text) ?? 0.0;
    final tollCost = double.tryParse(_tollController.text) ?? 0.0;
    final ticketCost = double.tryParse(_ticketController.text) ?? 0.0;

    setState(() {
      _totalCostController.text =
          (fuelCost + parkingCost + tollCost + ticketCost).toStringAsFixed(2);
    });
  }

  void _addEndMarker() {
    if (_selectedEndPoint != null) {
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: _selectedEndPoint!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'End Location'),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _startLocationController.dispose();
    _endLocationController.dispose();
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

    // ✅ NEW: Dispose companion controllers
    for (var controllers in _companionControllers) {
      controllers['name']?.dispose();
      controllers['phone']?.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      appBar: AppBar(
        title: const Text('Complete Trip'),
        centerTitle: true,
        backgroundColor: const Color(0xFF16213e),
        automaticallyImplyLeading: false,
      ),
      body: _showForm ? _buildForm() : _buildMapView(),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _selectedEndPoint!,
            zoom: 15,
          ),
          onMapCreated: (controller) => _mapController = controller,
          onTap: _onMapTap,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Tap on map to adjust END location',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Positioned(
          bottom: 30,
          left: 16,
          right: 16,
          child: ElevatedButton(
            onPressed: () => setState(() => _showForm = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00adb5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _onMapTap(LatLng position) async {
    final address = await LocationService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    setState(() {
      _selectedEndPoint = position;
      _selectedEndAddress = address;
      _endLocationController.text = address;
    });

    _addEndMarker();
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  Widget _buildForm() {
    return Container(
      color: const Color(0xFF0f0f1e),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFormField('Start Location', _startLocationController, Icons.trip_origin, readOnly: true),
            _buildFormField('End Location', _endLocationController, Icons.location_on, readOnly: true),
            _buildFormField('Day/Time', _dateController, Icons.calendar_today, onTap: () => _selectDate(context)),
            _buildFormField('Duration (minutes)', _durationController, Icons.timer, keyboardType: TextInputType.number),
            _buildFormField('Distance (km)', _distanceController, Icons.straighten, keyboardType: TextInputType.number),
            _buildModeDropdown(),
            _buildFormField(
              'CO2 emitted (kg)',
              _co2Controller,
              Icons.cloud,
              readOnly: true,
              fillColor: const Color(0xFF1a2942),
            ),
            _buildPurposeDropdown(),
            _buildFormField('Number of companions', _companionsController, Icons.people, keyboardType: TextInputType.number),

            // ✅ NEW: Dynamic companion details fields
            ..._buildCompanionFields(),

            _buildFormField('Fuel Type', _fuelTypeController, Icons.local_gas_station, readOnly: true),
            _buildFormField('Fuel cost (₹)', _fuelCostController, Icons.attach_money, keyboardType: TextInputType.number),
            _buildFormField('Parking cost (₹)', _parkingController, Icons.local_parking, keyboardType: TextInputType.number),
            _buildFormField('Toll cost (₹)', _tollController, Icons.toll, keyboardType: TextInputType.number),
            _buildFormField('Ticket cost (₹)', _ticketController, Icons.confirmation_number, keyboardType: TextInputType.number),
            _buildFormField(
              'Total Cost (₹)',
              _totalCostController,
              Icons.account_balance_wallet,
              readOnly: true,
              fillColor: const Color(0xFF1a2942),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showForm = false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF00adb5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Back to Map', style: TextStyle(color: Color(0xFF00adb5))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00adb5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: const Color(0xFF00adb5).withValues(alpha: 0.5),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('Save Trip', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Build companion detail fields
  List<Widget> _buildCompanionFields() {
    if (_companionCount == 0) return [];

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 8),
        child: Row(
          children: [
            const Icon(Icons.person_add, color: Color(0xFF00adb5), size: 20),
            const SizedBox(width: 8),
            Text(
              'Companion Details (Optional)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      ...List.generate(_companionCount, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00adb5).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Companion ${index + 1}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _companionControllers[index]['name'],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter companion name',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF00adb5), size: 20),
                  filled: true,
                  fillColor: const Color(0xFF0f0f1e),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _companionControllers[index]['phone'],
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF00adb5), size: 20),
                  filled: true,
                  fillColor: const Color(0xFF0f0f1e),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        );
      }),
    ];
  }

  Widget _buildModeDropdown() {
    final isDetected = widget.detectedMode != null &&
        widget.detectedMode!.isNotEmpty &&
        widget.detectedMode != 'Detecting...';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDetected)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00adb5).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00adb5).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF00adb5), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Auto-detected: ${widget.detectedMode}',
                        style: const TextStyle(
                          color: Color(0xFF00adb5),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          DropdownButtonFormField<String>(
            value: _modeController.text,
            dropdownColor: const Color(0xFF16213e),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Mode of Travel',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              prefixIcon: const Icon(Icons.directions_car, color: Color(0xFF00adb5)),
              filled: true,
              fillColor: isDetected
                  ? const Color(0xFF00adb5).withValues(alpha: 0.1)
                  : const Color(0xFF16213e),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: _co2EmissionFactors.keys.map((String mode) {
              return DropdownMenuItem<String>(
                value: mode,
                child: Text(mode),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _modeController.text = newValue ?? '';
                _fuelTypeController.text = _fuelTypeMap[newValue] ?? '';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _purposeController.text,
        dropdownColor: const Color(0xFF16213e),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Trip Purpose',
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon: const Icon(Icons.work, color: Color(0xFF00adb5)),
          filled: true,
          fillColor: const Color(0xFF16213e),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        items: _purposeBackendMap.keys.map((String purpose) {
          return DropdownMenuItem<String>(
            value: purpose,
            child: Text(purpose),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _purposeController.text = newValue ?? 'Work';
          });
        },
      ),
    );
  }

  Widget _buildFormField(
      String label,
      TextEditingController controller,
      IconData? icon, {
        TextInputType? keyboardType,
        VoidCallback? onTap,
        bool readOnly = false,
        Color? fillColor,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly || onTap != null,
        onTap: onTap,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF00adb5)) : null,
          filled: true,
          fillColor: fillColor ?? const Color(0xFF16213e),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext ctx) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _dateController.text =
          '${picked.day}/${picked.month}/${picked.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    // Build trip record from form data
    final now = DateTime.now();
    final tripRecord = {
      'local_id': now.millisecondsSinceEpoch,
      'trip_id': widget.tripId,
      'start_location_name': widget.startLocation,
      'end_location_name': _selectedEndAddress ?? widget.endLocation,
      'start_latitude': widget.startLat,
      'start_longitude': widget.startLng,
      'end_latitude': _selectedEndPoint?.latitude ?? widget.endLat,
      'end_longitude': _selectedEndPoint?.longitude ?? widget.endLng,
      'distance_km': double.tryParse(_distanceController.text) ?? widget.distance,
      'duration_minutes': int.tryParse(_durationController.text) ?? widget.duration,
      'mode_of_travel': _modeBackendMap[_modeController.text] ?? _modeController.text,
      'trip_purpose': _purposeBackendMap[_purposeController.text] ?? _purposeController.text,
      'number_of_companions': int.tryParse(_companionsController.text) ?? 0,
      'co2_kg': double.tryParse(_co2Controller.text) ?? 0.0,
      'fuel_expense': double.tryParse(_fuelCostController.text) ?? 0.0,
      'parking_cost': double.tryParse(_parkingController.text) ?? 0.0,
      'toll_cost': double.tryParse(_tollController.text) ?? 0.0,
      'ticket_cost': double.tryParse(_ticketController.text) ?? 0.0,
      'total_cost': double.tryParse(_totalCostController.text) ?? 0.0,
      'start_time': now.subtract(Duration(minutes: widget.duration)).toIso8601String(),
      'end_time': now.toIso8601String(),
      'source': 'local',
    };

    // Always save locally first — guaranteed trip history entry
    _saveLocalTrip(tripRecord);

    try {
      // Also try to save to backend if we have a valid trip ID
      if (widget.tripId > 0) {
        final api = context.read<ApiService>();
        List<Map<String, String>> companionData = [];
        for (final c in _companionControllers) {
          final name = c['name']?.text.trim() ?? '';
          final phone = c['phone']?.text.trim() ?? '';
          if (name.isNotEmpty || phone.isNotEmpty) {
            companionData.add({'name': name, 'phone': phone});
          }
        }
        await api.endTrip(
          tripId: widget.tripId,
          endLat: tripRecord['end_latitude'] as double,
          endLng: tripRecord['end_longitude'] as double,
          endLocationName: tripRecord['end_location_name'] as String,
          modeOfTravel: tripRecord['mode_of_travel'] as String,
          tripPurpose: tripRecord['trip_purpose'] as String,
          companions: tripRecord['number_of_companions'] as int,
          companionDetails: companionData.isEmpty ? null : companionData,
          fuelExpense: (tripRecord['fuel_expense'] as double) > 0 ? tripRecord['fuel_expense'] as double : null,
          parkingCost: (tripRecord['parking_cost'] as double) > 0 ? tripRecord['parking_cost'] as double : null,
          tollCost: (tripRecord['toll_cost'] as double) > 0 ? tripRecord['toll_cost'] as double : null,
          ticketCost: (tripRecord['ticket_cost'] as double) > 0 ? tripRecord['ticket_cost'] as double : null,
        );
        debugPrint('✅ Trip also saved to backend');
      }
    } catch (e) {
      debugPrint('⚠️ Backend save failed (local copy saved): $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip saved!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Get.offAllNamed('/home');
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _saveLocalTrip(Map<String, dynamic> trip) {
    try {
      final box = GetStorage();
      final List existing = box.read<List>('local_trips') ?? [];
      existing.insert(0, trip); // newest first
      box.write('local_trips', existing);
      debugPrint('✅ Trip saved locally (${existing.length} total)');
    } catch (e) {
      debugPrint('❌ Local save failed: $e');
    }
  }

}