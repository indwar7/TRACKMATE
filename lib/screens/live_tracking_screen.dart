import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/travel_mode_detector.dart';
import 'trip_end_form_screen.dart';

class LiveTrackingScreen extends StatefulWidget {
  final int tripId;
  final String? startLocation;

  const LiveTrackingScreen({
    super.key,
    required this.tripId,
    this.startLocation,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _trackingTimer;
  Timer? _inactivityTimer;

  Position? _currentPosition;
  Position? _startPosition;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final List<LatLng> _routePoints = [];

  double _totalDistance = 0.0;
  DateTime? _startTime;
  String _elapsedTime = '00:00:00';
  String _startLocationAddress = 'Getting location...';

  bool _isTracking = true;
  bool _isLoadingAddress = true;
  bool _isLocating = true;
  bool _tripInitialized = false; // API called once per trip
  int? _actualTripId;

  final TravelModeDetector _modeDetector = TravelModeDetector();
  String _detectedMode = 'Stationary';
  String _confidence = 'High';
  double _currentSpeed = 0.0;

  DateTime? _lastSignificantMovement;
  static const double _movementThreshold = 50.0;
  static const Duration _inactivityDuration = Duration(minutes: 5);
  Position? _lastMovementPosition;

  final List<double> _speedBuffer = [];
  static const int _speedBufferSize = 5;
  Position? _lastValidPosition;
  DateTime? _lastValidPositionTime;

  static const LatLng _defaultLatLng = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _lastSignificantMovement = DateTime.now();
    _startTimeCounter();
    _startInactivityMonitor();
    _startTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _trackingTimer?.cancel();
    _inactivityTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ─── START TRACKING ──────────────────────────────────────────────────────

  void _startTracking() async {
    // 1. Check permissions
    final ok = await LocationService.checkPermissions();
    if (!ok) {
      if (mounted) {
        setState(() => _isLocating = false);
        _showError('Location permission denied. Enable it in settings.');
      }
      return;
    }

    // 2. Start stream immediately — use first position to initialise trip
    //    No getCurrentPosition() call that can hang waiting for GPS fix.
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      (Position pos) {
        if (!_tripInitialized) {
          _tripInitialized = true;
          _initTripWithFirstPosition(pos);
        }
        _onLocationUpdate(pos);
      },
      onError: (e) {
        debugPrint('❌ GPS stream error: $e');
        if (mounted && _isLocating) {
          setState(() => _isLocating = false);
          _showError('GPS error: $e');
        }
      },
    );
  }

  // ─── CURRENT LOCATION MARKER ─────────────────────────────────────────────

  void _updateCurrentMarker(Position position) {
    _markers
      ..removeWhere((m) => m.markerId.value == 'current')
      ..add(Marker(
        markerId: const MarkerId('current'),
        position: LatLng(position.latitude, position.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'You are here'),
        zIndexInt: 2,
      ));
  }

  // Called exactly once when the first GPS position arrives
  void _initTripWithFirstPosition(Position position) {
    debugPrint('📍 First position: ${position.latitude}, ${position.longitude}');

    _startPosition = position;
    _lastMovementPosition = position;
    _lastSignificantMovement = DateTime.now();
    _lastValidPosition = position;
    _lastValidPositionTime = DateTime.now();

    if (!mounted) return;
    _updateCurrentMarker(position);
    setState(() {
      _currentPosition = position;
      _isLocating = false;
      _routePoints.add(LatLng(position.latitude, position.longitude));
    });

    // Fly map to real position
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
        ),
      ),
    );

    // Reverse geocode — non-blocking
    LocationService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    ).then((addr) {
      if (mounted) {
        setState(() {
          _startLocationAddress = addr;
          _isLoadingAddress = false;
        });
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _startLocationAddress = widget.startLocation ?? 'Unknown';
          _isLoadingAddress = false;
        });
      }
    });

    // Call startTrip API — non-blocking, tracking works without it
    final apiService = context.read<ApiService>();
    apiService.startTrip(
      startLat: position.latitude,
      startLng: position.longitude,
      locationName: widget.startLocation,
    ).then((tripData) {
      debugPrint('📦 startTrip: $tripData');
      int? id;
      if (tripData['ongoing_trip'] == true) {
        final v = tripData['id'];
        id = v is int ? v : int.tryParse(v.toString());
      } else if (tripData['trip'] is Map) {
        final v = (tripData['trip'] as Map)['id'];
        id = v is int ? v : int.tryParse(v.toString());
      } else if (tripData['id'] != null) {
        final v = tripData['id'];
        id = v is int ? v : int.tryParse(v.toString());
      }
      if (id != null && id > 0) {
        _actualTripId = id;
        debugPrint('✅ Trip ID: $_actualTripId');
      }
    }).catchError((e) {
      debugPrint('⚠️ startTrip error (tracking continues): $e');
      if (widget.tripId > 0) _actualTripId = widget.tripId;
    });
  }

  // ─── GPS UPDATE ──────────────────────────────────────────────────────────

  void _onLocationUpdate(Position position) async {
    if (!_isTracking || !mounted) return;

    final isReal = _isRealMovement(position);
    double effectiveSpeed = 0.0;

    if (isReal) {
      effectiveSpeed = _calculateSmoothedSpeed(position);
      _checkForSignificantMovement(position);
      _modeDetector.addSpeedSample(effectiveSpeed, position.accuracy);
      if (_currentPosition != null) {
        _totalDistance += Geolocator.distanceBetween(
          _currentPosition!.latitude, _currentPosition!.longitude,
          position.latitude, position.longitude,
        ) / 1000;
      }
    } else {
      _modeDetector.addSpeedSample(0.0, position.accuracy);
    }

    final analysis = _modeDetector.getModeAnalysis();
    if (!mounted) return;

    _updateCurrentMarker(position);
    setState(() {
      _currentPosition = position;
      _currentSpeed = effectiveSpeed * 3.6;
      _detectedMode = analysis['predicted_mode'];
      _confidence = analysis['confidence'];
      if (isReal) {
        _routePoints.add(LatLng(position.latitude, position.longitude));
        _polylines
          ..clear()
          ..add(Polyline(
            polylineId: const PolylineId('route'),
            points: _routePoints,
            color: const Color(0xFF00adb5),
            width: 5,
          ));
      }
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );

    // Send tracking point to API
    if (isReal) {
      try {
        final tripIdToUse = _actualTripId ?? widget.tripId;
        if (tripIdToUse <= 0) return;
        await context.read<ApiService>().addTrackingPoint(
          tripId: tripIdToUse,
          lat: position.latitude,
          lng: position.longitude,
          accuracy: position.accuracy,
          speed: effectiveSpeed,
        );
      } catch (e) {
        debugPrint('⚠️ Tracking point failed: $e');
      }
    }
  }

  // ─── MOVEMENT HELPERS ────────────────────────────────────────────────────

  bool _isRealMovement(Position p) {
    if (_lastValidPosition == null) {
      _lastValidPosition = p;
      _lastValidPositionTime = DateTime.now();
      return false;
    }
    final dist = Geolocator.distanceBetween(
      _lastValidPosition!.latitude, _lastValidPosition!.longitude,
      p.latitude, p.longitude,
    );
    final t = DateTime.now().difference(_lastValidPositionTime!).inSeconds;
    final minDist = (p.accuracy + _lastValidPosition!.accuracy) / 2 * 1.5;
    if (dist > minDist && p.accuracy < 50 && t >= 2) {
      _lastValidPosition = p;
      _lastValidPositionTime = DateTime.now();
      return true;
    }
    return false;
  }

  double _calculateSmoothedSpeed(Position p) {
    double speed = 0.0;
    if (_lastValidPosition != null && _lastValidPositionTime != null) {
      final d = Geolocator.distanceBetween(
        _lastValidPosition!.latitude, _lastValidPosition!.longitude,
        p.latitude, p.longitude,
      );
      final t = DateTime.now().difference(_lastValidPositionTime!).inSeconds;
      if (t > 0 && d > 0) speed = d / t;
    }
    _speedBuffer.add(speed);
    if (_speedBuffer.length > _speedBufferSize) _speedBuffer.removeAt(0);
    return _speedBuffer.isEmpty ? 0.0 : _speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length;
  }

  void _checkForSignificantMovement(Position p) {
    if (_lastMovementPosition == null) {
      _lastMovementPosition = p;
      _lastSignificantMovement = DateTime.now();
      return;
    }
    final d = Geolocator.distanceBetween(
      _lastMovementPosition!.latitude, _lastMovementPosition!.longitude,
      p.latitude, p.longitude,
    );
    if (d >= _movementThreshold) {
      _lastMovementPosition = p;
      _lastSignificantMovement = DateTime.now();
    }
  }

  // ─── INACTIVITY ──────────────────────────────────────────────────────────

  void _startInactivityMonitor() {
    _inactivityTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!_isTracking || _lastSignificantMovement == null) return;
      if (DateTime.now().difference(_lastSignificantMovement!) >= _inactivityDuration) {
        _autoEndTrip();
      }
    });
  }

  Future<void> _autoEndTrip() async {
    if (!mounted || !_isTracking) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Trip auto-ended: 5 minutes of no movement'),
      backgroundColor: Colors.orange,
      duration: Duration(seconds: 5),
    ));
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _onEndTripPressed(autoEnded: true);
  }

  // ─── TIMER ───────────────────────────────────────────────────────────────

  void _startTimeCounter() {
    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null && mounted) {
        setState(() => _elapsedTime = _formatDuration(DateTime.now().difference(_startTime!)));
      }
    });
  }

  String _formatDuration(Duration d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.inHours)}:${p(d.inMinutes.remainder(60))}:${p(d.inSeconds.remainder(60))}';
  }

  // ─── END TRIP ─────────────────────────────────────────────────────────────

  void _onEndTripPressed({bool autoEnded = false}) async {
    if (_currentPosition == null || _startPosition == null) {
      _showError('Cannot end trip: waiting for first GPS fix');
      return;
    }
    setState(() => _isTracking = false);
    _positionSubscription?.cancel();
    _trackingTimer?.cancel();
    _inactivityTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final endAddress = await LocationService.getAddressFromCoordinates(
        _currentPosition!.latitude, _currentPosition!.longitude,
      );
      final modeAnalysis = _modeDetector.getModeAnalysis();
      if (mounted) Navigator.pop(context);

      final tripIdToUse = _actualTripId ?? widget.tripId;

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TripEndFormScreen(
              tripId: tripIdToUse,
              startLocation: _startLocationAddress,
              startLat: _startPosition!.latitude,
              startLng: _startPosition!.longitude,
              endLat: _currentPosition!.latitude,
              endLng: _currentPosition!.longitude,
              endLocation: endAddress,
              distance: _totalDistance,
              duration: DateTime.now().difference(_startTime!).inMinutes,
              detectedMode: modeAnalysis['predicted_mode'],
              modeConfidence: modeAnalysis['confidence'],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ End trip error: $e');
      if (mounted) {
        Navigator.pop(context);
        _showError('Failed to end trip: $e');
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  // ─── UI HELPERS ──────────────────────────────────────────────────────────

  IconData _getModeIcon(String mode) {
    if (mode.contains('Stationary') || mode.contains('Idle')) return Icons.pause_circle_outline;
    if (mode.contains('Walking')) return Icons.directions_walk;
    if (mode.contains('Bicycle')) return Icons.directions_bike;
    if (mode.contains('Motorcycle')) return Icons.two_wheeler;
    if (mode.contains('Car')) return Icons.directions_car;
    if (mode.contains('Bus') || mode.contains('Train')) return Icons.directions_bus;
    return Icons.help_outline;
  }

  Color _getConfidenceColor(String c) {
    switch (c) {
      case 'High': return Colors.green;
      case 'Medium': return Colors.orange;
      case 'Low': return Colors.red;
      default: return Colors.grey;
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final inactiveMin = _lastSignificantMovement != null
        ? DateTime.now().difference(_lastSignificantMovement!).inMinutes
        : 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final stop = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF16213e),
            title: const Text('Stop Tracking?', style: TextStyle(color: Colors.white)),
            content: const Text('Stop tracking this trip?', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Stop', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (stop == true) {
          _positionSubscription?.cancel();
          _trackingTimer?.cancel();
          _inactivityTimer?.cancel();
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [

            // ── MAP: always visible ───────────────────────────────────────
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : _defaultLatLng,
                zoom: _currentPosition != null ? 16 : 5,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                if (_currentPosition != null) {
                  controller.animateCamera(CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      zoom: 16,
                    ),
                  ));
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              polylines: _polylines,
              mapType: MapType.normal,
            ),

            // ── INFO CARD: always visible ─────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213e),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Timer + status
                    Row(
                      children: [
                        const Icon(Icons.timer, color: Color(0xFF00adb5), size: 20),
                        const SizedBox(width: 8),
                        Text(_elapsedTime,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Spacer(),
                        if (_isLocating)
                          const Row(
                            children: [
                              SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    color: Color(0xFF00adb5), strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Getting GPS...',
                                  style: TextStyle(color: Color(0xFF00adb5), fontSize: 12)),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00adb5).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Color(0xFF00adb5), size: 16),
                                const SizedBox(width: 4),
                                Text(_isTracking ? 'Tracking' : 'Paused',
                                    style: const TextStyle(
                                        color: Color(0xFF00adb5),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Inactivity warning
                    if (inactiveMin >= 3) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No movement for $inactiveMin min. Auto-end at 5 min.',
                                style: const TextStyle(color: Colors.orange, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Speed + mode
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Icon(Icons.speed, color: Color(0xFF00adb5), size: 20),
                                const SizedBox(height: 4),
                                Text('Speed',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withValues(alpha: 0.6))),
                                const SizedBox(height: 4),
                                Text('${_currentSpeed.toStringAsFixed(1)} km/h',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                          Container(
                              width: 1, height: 50,
                              color: Colors.white.withValues(alpha: 0.2)),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(_getModeIcon(_detectedMode),
                                        color: const Color(0xFF00adb5), size: 20),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getConfidenceColor(_confidence)
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border:
                                            Border.all(color: _getConfidenceColor(_confidence)),
                                      ),
                                      child: Text(_confidence,
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: _getConfidenceColor(_confidence),
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Travel Mode',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withValues(alpha: 0.6))),
                                const SizedBox(height: 4),
                                Text(
                                  _detectedMode.split(' - ')[0],
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Distance + start
                    Row(
                      children: [
                        Expanded(
                          child: _statItem(
                            icon: Icons.straighten,
                            label: 'Distance',
                            value: '${_totalDistance.toStringAsFixed(2)} km',
                          ),
                        ),
                        Container(
                            width: 1, height: 40,
                            color: Colors.white.withValues(alpha: 0.2)),
                        Expanded(
                          flex: 2,
                          child: _statItem(
                            icon: Icons.location_city,
                            label: 'Start',
                            value: _isLoadingAddress
                                ? 'Loading...'
                                : (_startLocationAddress.length > 25
                                    ? '${_startLocationAddress.substring(0, 25)}...'
                                    : _startLocationAddress),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── END TRIP BUTTON: always visible ───────────────────────────
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: _currentPosition == null ? null : () => _onEndTripPressed(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe94560),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade800,
                ),
                child: _isLocating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Waiting for GPS...',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stop_circle, size: 24),
                          SizedBox(width: 8),
                          Text('End Trip',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 16),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
