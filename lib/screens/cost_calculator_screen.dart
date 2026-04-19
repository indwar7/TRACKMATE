// cost_calculator.dart - Part 1
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' show cos, sqrt, asin;

class CostCalculatorScreen extends StatefulWidget {
  const CostCalculatorScreen({super.key});

  @override
  State<CostCalculatorScreen> createState() => _CostCalculatorScreenState();
}

class _CostCalculatorScreenState extends State<CostCalculatorScreen>
    with SingleTickerProviderStateMixin {

  // Controllers
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  // State variables
  bool _isLoading = false;
  Map<String, dynamic>? _results;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Replace with your actual Google Places API key
  final String _placesApiKey = 'AIzaSyAtGcgY_MayhcKQRUJRTRoV5d3vvxOYOwQ';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  // cost_calculator.dart - Part 2 (Add after Part 1)

  Future<void> _calculateCost() async {
    if (_startController.text.trim().isEmpty || _endController.text.trim().isEmpty) {
      _showSnackBar('Please enter both locations', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _results = null;
    });

    try {
      final startCoords = await _getCoordinates(_startController.text.trim());
      final endCoords = await _getCoordinates(_endController.text.trim());

      if (startCoords == null || endCoords == null) {
        throw Exception('Could not find one or both locations. Please check the spelling.');
      }

      final distance = _calculateDistanceFromCoords(
        startCoords['lat']!,
        startCoords['lng']!,
        endCoords['lat']!,
        endCoords['lng']!,
      );

      if (distance <= 0) throw Exception('Cannot calculate distance');

      setState(() {
        _results = _generateTravelOptions(distance);
        _isLoading = false;
      });

      _animationController.forward(from: 0.0);
      _showSnackBar('Calculation complete!', isError: false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFFF5252) : const Color(0xFF00D9FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<Map<String, double>?> _getCoordinates(String address) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_placesApiKey',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && (data['results'] as List).isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return {
            'lat': (location['lat'] as num).toDouble(),
            'lng': (location['lng'] as num).toDouble(),
          };
        } else {
          throw Exception('Location not found: ${data['status']}');
        }
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      rethrow;
    }
  }

  double _calculateDistanceFromCoords(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Pi/180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

// Continue to Part 3 for _generateTravelOptions...// cost_calculator.dart - Part 3 (Add after Part 2)
//
  Map<String, dynamic> _generateTravelOptions(double distanceKm) {
    final fuelOptions = [
      {
        'fuel_type': 'Petrol',
        'estimated_cost': (distanceKm * 9.5).round(),
        'cost_per_km': 9.5,
        'time_hours': (distanceKm / 55).toStringAsFixed(1),
        'co2_kg': (distanceKm * 0.12).toStringAsFixed(1),
        'comfort_rating': 5,
        'icon': '⛽',
        'color': 0xFFFF6B6B,
        'pros': ['Comfortable', 'Flexible schedule', 'Door-to-door'],
        'cons': ['Long drive', 'Can be tiring'],
      },
      {
        'fuel_type': 'Diesel',
        'estimated_cost': (distanceKm * 7.0).round(),
        'cost_per_km': 7.0,
        'time_hours': (distanceKm / 55).toStringAsFixed(1),
        'co2_kg': (distanceKm * 0.10).toStringAsFixed(1),
        'comfort_rating': 5,
        'icon': '⛽',
        'color': 0xFF4ECDC4,
        'pros': ['Comfortable', 'Economical', 'Good mileage'],
        'cons': ['Long drive', 'Fuel availability'],
      },
      {
        'fuel_type': 'CNG',
        'estimated_cost': (distanceKm * 4.5).round(),
        'cost_per_km': 4.5,
        'time_hours': (distanceKm / 55).toStringAsFixed(1),
        'co2_kg': (distanceKm * 0.08).toStringAsFixed(1),
        'comfort_rating': 5,
        'icon': '🌿',
        'color': 0xFF95E1D3,
        'pros': ['Eco-friendly', 'Very cheap', 'Clean fuel'],
        'cons': ['Limited CNG stations', 'Reduced boot space'],
      },
      {
        'fuel_type': 'Electric',
        'estimated_cost': (distanceKm * 2.5).round(),
        'cost_per_km': 2.5,
        'time_hours': (distanceKm / 55).toStringAsFixed(1),
        'co2_kg': (distanceKm * 0.05).toStringAsFixed(1),
        'comfort_rating': 5,
        'icon': '⚡',
        'color': 0xFFFECA57,
        'pros': ['Most eco-friendly', 'Cheapest running', 'Silent ride'],
        'cons': ['Charging infrastructure', 'Range anxiety'],
      },
    ];

    final allOptions = [
      {'mode': 'car', 'fuel_options': fuelOptions},
      {
        'mode': 'flight',
        'estimated_cost_min': (distanceKm * 3).round(),
        'estimated_cost_max': (distanceKm * 5.5).round(),
        'time_hours': (distanceKm / 750 + 2).toStringAsFixed(1),
        'co2_kg': (distanceKm * 0.15).toStringAsFixed(1),
        'comfort_rating': 5,
        'icon': '✈️',
        'color': 0xFF6C63FF,
        'pros': ['Fastest option', 'Time-saving', 'Long distance ideal'],
        'cons': ['Most expensive', 'Airport hassle', 'Weather dependent'],
      },
      {
        'mode': 'train',
        'estimated_cost_min': (distanceKm * 0.5).round(),
        'estimated_cost_max': (distanceKm * 1.7).round(),
        'time_hours': (distanceKm / 45).toStringAsFixed(1),
        'co2_kg': (distanceKm * 0.04).toStringAsFixed(1),
        'comfort_rating': 4,
        'icon': '🚆',
        'color': 0xFF00D9FF,
        'pros': ['Most affordable', 'Comfortable', 'Very eco-friendly'],
        'cons': ['Takes longer', 'Fixed schedule'],
      },
      {
        'mode': 'bus',
        'estimated_cost_min': (distanceKm * 0.8).round(),
        'estimated_cost_max': (distanceKm * 1.2).round(),
        'time_hours': (distanceKm / 40).toStringAsFixed(1),
        'co2_kg': (distanceKm * 0.09).toStringAsFixed(1),
        'comfort_rating': 3,
        'icon': '🚌',
        'color': 0xFFFF9FF3,
        'pros': ['Budget-friendly', 'Widely available', 'No driving stress'],
        'cons': ['Less comfortable', 'Frequent stops', 'Longer journey'],
      },
    ];

    String recommendedMode = 'train';
    int minCost = (distanceKm * 0.5).round();

    return {
      'distance_km': distanceKm.toStringAsFixed(1),
      'options': allOptions,
      'recommendation': {
        'mode': recommendedMode,
        'reason': 'Best balance of cost, comfort & eco-friendliness',
        'savings': ((distanceKm * 3.0) - minCost).round(),
      },
    };
  }

  // Continue to Part 4 for build method...// cost_calculator.dart - Part 4 (Add after Part 3)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E27), Color(0xFF1E2139)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildInputCard(),
                const SizedBox(height: 24),
                _buildCalculateButton(),
                if (_isLoading) ...[
                  const SizedBox(height: 40),
                  _buildLoadingIndicator(),
                ],
                if (_results != null) ...[
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildResults(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.calculate, color: Color(0xFF6C63FF), size: 32),
        ),
        const SizedBox(height: 16),
        const Text(
          'Travel Cost\nCalculator',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Compare prices across different travel modes',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2139),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.route, color: Color(0xFF00D9FF), size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Journey Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _startController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Starting Point',
              hintText: 'e.g., Delhi, Mumbai, Bangalore',
              prefixIcon: Icon(Icons.my_location, color: Color(0xFF00D9FF)),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _endController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Destination',
              hintText: 'e.g., Goa, Jaipur, Chennai',
              prefixIcon: Icon(Icons.location_on, color: Color(0xFFFF5252)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _calculateCost,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          disabledBackgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.5),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate, size: 24),
            SizedBox(width: 12),
            Text(
              'Calculate Travel Costs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF6C63FF),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Calculating best routes...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Continue to Part 5 for results widgets...// cost_calculator.dart - Part 5 (Add after Part 4)

  Widget _buildResults() {
    final distance = _results!['distance_km'];
    final options = _results!['options'] as List;
    final recommendation = _results!['recommendation'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00D9FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Distance',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$distance km',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.route, color: Colors.white, size: 32),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF00D9FF).withValues(alpha: 0.15),
            border: Border.all(color: const Color(0xFF00D9FF), width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFF00D9FF), size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'Recommended Option',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('🚆', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation['mode'].toString().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00D9FF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation['reason'],
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.savings, color: Color(0xFF00D9FF), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Save up to ₹${recommendation['savings']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'All Travel Options',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        ...options.map((opt) => _buildOptionCard(opt)),
      ],
    );
  }

  Widget _buildOptionCard(Map<String, dynamic> option) {
    final mode = option['mode'];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2139),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          leading: Text(
            _getEmoji(mode),
            style: const TextStyle(fontSize: 32),
          ),
          title: Text(
            mode.toString().toUpperCase(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              mode == 'car'
                  ? 'Multiple fuel options available'
                  : '₹${option['estimated_cost_min']} - ₹${option['estimated_cost_max']}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          children: [
            mode == 'car' ? _buildCarOptions(option) : _buildTransportDetails(option),
          ],
        ),
      ),
    );
  }

  String _getEmoji(String mode) {
    final emojis = {
      'car': '🚗',
      'flight': '✈️',
      'train': '🚆',
      'bus': '🚌',
    };
    return emojis[mode] ?? '🚗';
  }

  // Continue to Part 6 for detailed option widgets...// cost_calculator.dart - Part 6 FINAL (Add after Part 5)

  Widget _buildCarOptions(Map<String, dynamic> option) {
    final fuels = option['fuel_options'] as List;
    return Column(
      children: fuels.map((fuel) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF252B48),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color(fuel['color'] as int).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(fuel['icon'], style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        fuel['fuel_type'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(fuel['color'] as int),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${fuel['estimated_cost']}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(Icons.access_time, '${fuel['time_hours']}h'),
                  _buildInfoChip(Icons.eco, '${fuel['co2_kg']}kg CO₂'),
                  _buildInfoChip(Icons.star, '${fuel['comfort_rating']}/5'),
                ],
              ),
              const SizedBox(height: 16),
              _buildProsCons(fuel['pros'] as List, fuel['cons'] as List),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransportDetails(Map<String, dynamic> option) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF252B48),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cost Range',
                style: TextStyle(fontSize: 14, color: Color(0xFF8F92A1), fontWeight: FontWeight.w500),
              ),
              Text(
                '₹${option['estimated_cost_min']} - ₹${option['estimated_cost_max']}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(option['color'] as int),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(Icons.access_time, '${option['time_hours']}h'),
              _buildInfoChip(Icons.eco, '${option['co2_kg']}kg CO₂'),
              _buildInfoChip(Icons.star, '${option['comfort_rating']}/5'),
            ],
          ),
          const SizedBox(height: 20),
          _buildProsCons(option['pros'] as List, option['cons'] as List),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2139),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildProsCons(List pros, List cons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00D9FF), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pros.join(', '),
                style: const TextStyle(color: Color(0xFF00D9FF), fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cancel, color: Color(0xFFFF5252), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cons.join(', '),
                style: const TextStyle(color: Color(0xFFFF5252), fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }
}