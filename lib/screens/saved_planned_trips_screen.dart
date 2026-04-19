import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class ManualTripEntryScreen extends StatefulWidget {
  const ManualTripEntryScreen({super.key});

  @override
  State<ManualTripEntryScreen> createState() => _ManualTripEntryScreenState();
}

class _ManualTripEntryScreenState extends State<ManualTripEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Location fields
  final _startLocationController = TextEditingController();
  final _endLocationController = TextEditingController();
  double? _startLat;
  double? _startLng;
  double? _endLat;
  double? _endLng;

  // Trip details
  DateTime _selectedDate = DateTime.now();
  String _selectedMode = 'car';
  String _selectedPurpose = 'work';
  int _companions = 0;

  // Cost fields
  final _tollCostController = TextEditingController(text: '0');
  final _parkingCostController = TextEditingController(text: '0');
  final _fuelExpenseController = TextEditingController(text: '0');
  final _ticketCostController = TextEditingController(text: '0');

  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _travelModes = [
    {'value': 'car', 'label': 'Car', 'icon': '🚗'},
    {'value': 'bike', 'label': 'Bike', 'icon': '🏍'},
    {'value': 'bus', 'label': 'Bus', 'icon': '🚌'},
    {'value': 'train', 'label': 'Train', 'icon': '🚂'},
    {'value': 'metro', 'label': 'Metro', 'icon': '🚇'},
    {'value': 'auto', 'label': 'Auto', 'icon': '🛺'},
    {'value': 'walk', 'label': 'Walk', 'icon': '🚶'},
  ];

  final List<String> _purposes = [
    'work',
    'shopping',
    'personal',
    'leisure',
    'education',
    'medical',
    'other',
  ];

  @override
  void dispose() {
    _startLocationController.dispose();
    _endLocationController.dispose();
    _tollCostController.dispose();
    _parkingCostController.dispose();
    _fuelExpenseController.dispose();
    _ticketCostController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFA78BFA),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitTrip() async {
    if (!_formKey.currentState!.validate()) return;

    // Simple validation for locations
    if (_startLocationController.text.isEmpty) {
      _showError('Please enter start location');
      return;
    }
    if (_endLocationController.text.isEmpty) {
      _showError('Please enter end location');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final api = context.read<ApiService>();

      // For demo purposes, using dummy coordinates
      // In production, you'd get these from a location picker/map
      final startLat = _startLat ?? 28.6328;
      final startLng = _startLng ?? 77.2197;
      final endLat = _endLat ?? 28.6129;
      final endLng = _endLng ?? 77.2295;

      final requestBody = {
        "start_location": _startLocationController.text,
        "start_latitude": startLat,
        "start_longitude": startLng,

        "end_location": _endLocationController.text,
        "end_latitude": endLat,
        "end_longitude": endLng,

        "trip_date": DateFormat('yyyy-MM-dd').format(_selectedDate),
        "mode_of_travel": _selectedMode,
        "trip_purpose": _selectedPurpose,
        "number_of_companions": _companions,

        "toll_cost": double.parse(_tollCostController.text),
        "parking_cost": double.parse(_parkingCostController.text),
        "fuel_expense": double.parse(_fuelExpenseController.text),
        "ticket_cost": double.parse(_ticketCostController.text),
      };

      debugPrint('Submitting manual trip: $requestBody');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/trips/create-manual/'),
        headers: api.headers,
        body: jsonEncode(requestBody),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip saved successfully! 🎉'),
              backgroundColor: Color(0xFF4ADE80),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        throw Exception('Failed to create trip: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error submitting trip: $e');
      _showError('Failed to save trip: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Record a Trip', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Location Details'),
              const SizedBox(height: 12),

              // Start Location
              _buildLocationField(
                controller: _startLocationController,
                label: 'From',
                hint: 'Enter start location',
                icon: Icons.location_on,
                iconColor: const Color(0xFF4ADE80),
              ),
              const SizedBox(height: 12),

              // End Location
              _buildLocationField(
                controller: _endLocationController,
                label: 'To',
                hint: 'Enter destination',
                icon: Icons.location_on,
                iconColor: const Color(0xFFFB923C),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Trip Details'),
              const SizedBox(height: 12),

              // Date Picker
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFFA78BFA), size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip Date',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(_selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Mode of Travel
              Text(
                'Mode of Travel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _travelModes.map((mode) {
                  final isSelected = _selectedMode == mode['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMode = mode['value']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFA78BFA) : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(mode['icon'], style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            mode['label'],
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Purpose
              Text(
                'Trip Purpose',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPurpose,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                    items: _purposes.map((purpose) {
                      return DropdownMenuItem(
                        value: purpose,
                        child: Text(purpose[0].toUpperCase() + purpose.substring(1)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedPurpose = value);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Companions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Color(0xFFA78BFA), size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Companions',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        if (_companions > 0) {
                          setState(() => _companions--);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
                    ),
                    Text(
                      '$_companions',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _companions++),
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFFA78BFA)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Expenses (Optional)'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildCostField(
                      controller: _tollCostController,
                      label: 'Toll',
                      icon: Icons.local_parking,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCostField(
                      controller: _parkingCostController,
                      label: 'Parking',
                      icon: Icons.local_parking,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCostField(
                      controller: _fuelExpenseController,
                      label: 'Fuel',
                      icon: Icons.local_gas_station,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCostField(
                      controller: _ticketCostController,
                      label: 'Ticket',
                      icon: Icons.confirmation_number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA78BFA),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                      : const Text(
                    'Save Trip',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: iconColor, size: 20),
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCostField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Color(0xFFA78BFA), size: 18),
          labelText: label,
          prefixText: '₹ ',
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          prefixStyle: const TextStyle(color: Colors.white),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}