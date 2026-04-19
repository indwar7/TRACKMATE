import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:get_storage/get_storage.dart';
import '../services/api_service.dart';
import 'package:trackmate_app/widgets/edit_trip_dialog.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _trips = [];

  String _filterMode = 'all';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // ------------------------------------------------------------------
  // FETCH HISTORY
  // ------------------------------------------------------------------
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    // 1. Load local trips from GetStorage
    final box = GetStorage();
    final List localRaw = box.read<List>('local_trips') ?? [];
    final List<Map<String, dynamic>> localTrips =
        localRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // 2. Try loading from API (silent on failure, 5s timeout)
    List<Map<String, dynamic>> apiTrips = [];
    try {
      final api = context.read<ApiService>();
      final res = await http
          .get(
            Uri.parse("${ApiService.baseUrl}/trips/history/"),
            headers: api.headers,
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          apiTrips = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data["trips"] is List) {
          apiTrips = List<Map<String, dynamic>>.from(data["trips"]);
        }
      }
    } catch (e) {
      debugPrint("Trip history API error (using local only): $e");
    }

    // 3. Merge: local trips first, skip API duplicates already in local
    final seenTripIds = <int>{};
    for (final t in localTrips) {
      final tid = t['trip_id'];
      if (tid != null && tid is int && tid > 0) seenTripIds.add(tid);
    }

    for (final t in apiTrips) {
      final tid = t['id'];
      if (tid != null && tid is int && seenTripIds.contains(tid)) continue;
      localTrips.add(t);
    }

    // 4. Sort newest first
    localTrips.sort((a, b) {
      final da = DateTime.tryParse(a['start_time'] ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['start_time'] ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });

    setState(() {
      _trips = localTrips;
      _isLoading = false;
    });
  }

  // ------------------------------------------------------------------
  // FILTER TRIPS
  // ------------------------------------------------------------------
  List<Map<String, dynamic>> get _filteredTrips {
    var list = _trips;

    if (_filterMode != "all") {
      list = list.where((t) {
        final mode = t["mode_of_travel"]?.toString().toLowerCase();
        return mode == _filterMode;
      }).toList();
    }

    if (_filterStartDate != null) {
      list = list.where((t) {
        final date = DateTime.tryParse(t["start_time"] ?? "");
        if (date == null) return false;
        return date.isAfter(_filterStartDate!) ||
            date.isAtSameMomentAs(_filterStartDate!);
      }).toList();
    }

    if (_filterEndDate != null) {
      list = list.where((t) {
        final date = DateTime.tryParse(t["start_time"] ?? "");
        if (date == null) return false;
        return date.isBefore(_filterEndDate!.add(const Duration(days: 1)));
      }).toList();
    }

    return list;
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("Trip History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, size: 26),
            onPressed: _showFilterDialog,
          )
        ],
      ),

      body: Column(
        children: [
          if (_trips.isNotEmpty) _buildStatsCard(),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTrips.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredTrips.length,
                itemBuilder: (_, i) =>
                    _buildTripCard(_filteredTrips[i]),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // STATS SUMMARY
  // ------------------------------------------------------------------
  Widget _buildStatsCard() {
    final totalTrips = _trips.length;

    final totalDistance = _trips.fold<double>(
        0,
            (sum, t) =>
        sum + (double.tryParse(t["distance_km"].toString()) ?? 0));

    final totalCost = _trips.fold<double>(
        0,
            (sum, t) =>
        sum + (double.tryParse(t["total_cost"].toString()) ?? 0));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00ADB5), Color(0xFF0F3460)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statTile(Icons.local_activity, "$totalTrips", "Trips"),
          _statTile(Icons.straighten, "${totalDistance.toStringAsFixed(1)} km",
              "Distance"),
          _statTile(Icons.currency_rupee, "₹${totalCost.toStringAsFixed(0)}",
              "Total Cost"),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style:
            TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
      ],
    );
  }

  // ------------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "No trips found",
        style:
        TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18),
      ),
    );
  }

  // ------------------------------------------------------------------
  // TRIP CARD - UPDATED WITH EDIT BUTTON
  // ------------------------------------------------------------------
  Widget _buildTripCard(Map<String, dynamic> t) {
    final dt = DateTime.tryParse(t["start_time"] ?? "");
    final date = dt != null ? DateFormat("MMM dd, yyyy").format(dt) : "Unknown";
    final time = dt != null ? DateFormat("hh:mm a").format(dt) : "Unknown";

    return InkWell(
      onTap: () => _showTripDetails(t),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Edit Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _routeRow(Icons.location_on, Colors.teal, t["start_location_name"]),
                      const SizedBox(height: 6),
                      const Icon(Icons.arrow_downward, color: Colors.white30, size: 16),
                      const SizedBox(height: 6),
                      _routeRow(Icons.location_on, Colors.red, t["end_location_name"]),
                    ],
                  ),
                ),
                // Edit Button (only for backend trips)
                if (t['source'] != 'local' && t['id'] != null)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF00adb5)),
                    onPressed: () {
                      showEditTripDialog(
                        context: context,
                        tripId: t['id'] as int,
                        currentFuelExpense: t['fuel_expense'] != null
                            ? double.tryParse(t['fuel_expense'].toString())
                            : null,
                        currentParkingCost: t['parking_cost'] != null
                            ? double.tryParse(t['parking_cost'].toString())
                            : null,
                        currentTollCost: t['toll_cost'] != null
                            ? double.tryParse(t['toll_cost'].toString())
                            : null,
                        onSuccess: _loadHistory,
                      );
                    },
                    tooltip: 'Edit Expenses',
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Row(children: [
              _tripStat(Icons.calendar_today, date),
              const SizedBox(width: 16),
              _tripStat(Icons.access_time, time),
            ]),

            const Divider(color: Colors.white24, height: 22),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _tripStat(Icons.straighten, "${t['distance_km']} km"),
                _tripStat(Icons.timer, "${t['duration_minutes']} min"),
                _tripStat(Icons.currency_rupee, "₹${t['total_cost']}"),
              ],
            ),

            // Show expense breakdown if available
            if (t['fuel_expense'] != null ||
                t['parking_cost'] != null ||
                t['toll_cost'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00adb5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00adb5).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    if (t['fuel_expense'] != null)
                      _buildCostBreakdown(
                        'Fuel',
                        t['fuel_expense'],
                        Icons.local_gas_station,
                      ),
                    if (t['parking_cost'] != null)
                      _buildCostBreakdown(
                        'Parking',
                        t['parking_cost'],
                        Icons.local_parking,
                      ),
                    if (t['toll_cost'] != null)
                      _buildCostBreakdown(
                        'Toll',
                        t['toll_cost'],
                        Icons.toll,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _routeRow(IconData icon, Color color, String? text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text ?? "Unknown",
            style: const TextStyle(color: Colors.white, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _tripStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildCostBreakdown(String label, dynamic amount, IconData icon) {
    if (amount == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white54),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const Spacer(),
          Text(
            '₹ $amount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // TRIP DETAILS BOTTOM SHEET
  // ------------------------------------------------------------------
  void _showTripDetails(Map<String, dynamic> trip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.92,

        builder: (_, controller) {
          return SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Trip Details",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    if (trip['source'] != 'local' && trip['id'] != null)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF00adb5)),
                        onPressed: () {
                          Navigator.pop(context);
                          showEditTripDialog(
                            context: context,
                            tripId: trip['id'] as int,
                            currentFuelExpense: trip['fuel_expense'] != null
                                ? double.tryParse(trip['fuel_expense'].toString())
                                : null,
                            currentParkingCost: trip['parking_cost'] != null
                                ? double.tryParse(trip['parking_cost'].toString())
                                : null,
                            currentTollCost: trip['toll_cost'] != null
                                ? double.tryParse(trip['toll_cost'].toString())
                                : null,
                            onSuccess: _loadHistory,
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                _detailRow("Start", trip["start_location_name"]),
                _detailRow("Destination", trip["end_location_name"]),
                _detailRow("Distance", "${trip['distance_km']} km"),
                _detailRow("Duration", "${trip['duration_minutes']} min"),
                _detailRow("Mode", trip["mode_of_travel"]),
                _detailRow("Purpose", trip["trip_purpose"]),
                _detailRow("Companions",
                    trip["number_of_companions"]?.toString()),
                _detailRow("Fuel", "₹${trip["fuel_expense"] ?? 0}"),
                _detailRow("Parking", "₹${trip["parking_cost"] ?? 0}"),
                _detailRow("Toll", "₹${trip["toll_cost"] ?? 0}"),

                const Divider(color: Colors.white24),
                _detailRow("Total Cost", "₹${trip['total_cost']}", bold: true),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String? value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(
            value ?? "N/A",
            style: TextStyle(
              color: Colors.white,
              fontSize: bold ? 18 : 15,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // FILTER DIALOG
  // ------------------------------------------------------------------
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return StatefulBuilder(
          builder: (_, setSheet) {
            return Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text("Filter Trips",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  const Text("Mode of Travel",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    children: [
                      _filterChip("all", "All", setSheet),
                      _filterChip("car", "Car", setSheet),
                      _filterChip("bike", "Bike", setSheet),
                      _filterChip("bus", "Bus", setSheet),
                      _filterChip("train", "Train", setSheet),
                      _filterChip("metro", "Metro", setSheet),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text("Date Range",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDate: _filterStartDate ?? DateTime.now(),
                            );

                            if (picked != null) {
                              setSheet(() => _filterStartDate = picked);
                            }
                          },
                          child: Text(
                            _filterStartDate != null
                                ? DateFormat("MMM dd").format(_filterStartDate!)
                                : "Start Date",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                      const Text("to ", style: TextStyle(color: Colors.white70)),

                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate:
                              _filterStartDate ?? DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDate: _filterEndDate ?? DateTime.now(),
                            );

                            if (picked != null) {
                              setSheet(() => _filterEndDate = picked);
                            }
                          },
                          child: Text(
                            _filterEndDate != null
                                ? DateFormat("MMM dd").format(_filterEndDate!)
                                : "End Date",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _filterMode = "all";
                              _filterStartDate = null;
                              _filterEndDate = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("Clear"),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal),
                          child: const Text("Apply"),
                        ),
                      )
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChip(String value, String label, setSheet) {
    return FilterChip(
      label: Text(label),
      selected: _filterMode == value,
      onSelected: (_) {
        setSheet(() => _filterMode = value);
      },
      selectedColor: Colors.teal.withValues(alpha: 0.3),
      checkmarkColor: Colors.tealAccent,
    );
  }

}