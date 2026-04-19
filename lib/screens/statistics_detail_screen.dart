// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackmate_app/services/stats_service.dart';

class StatisticsDetailScreen extends StatefulWidget {
  final String section; // distance / co2_emissions / fuel_cost

  const StatisticsDetailScreen({super.key, required this.section});

  @override
  State<StatisticsDetailScreen> createState() => _StatisticsDetailScreenState();
}

class _StatisticsDetailScreenState extends State<StatisticsDetailScreen> {
  int selectedTab = 0;
  final tabs = ["Day", "Week", "Month", "Year"];

  bool loading = true;
  List<Map<String, dynamic>> chartData = [];
  double totalValue = 0;
  double avgValue = 0;

  final StatsService statsService = StatsService();

  // Color palette for bars
  final List<Color> barColors = const [
    Color(0xFF00D9FF), // Cyan
    Color(0xFF00FF87), // Green
    Color(0xFFFF6B9D), // Pink
    Color(0xFFFFC107), // Amber
    Color(0xFFAB47BC), // Purple
    Color(0xFF26C6DA), // Light Blue
    Color(0xFF66BB6A), // Light Green
  ];

  @override
  void initState() {
    super.initState();
    loadChartData();
  }

  Color getBarColor(int index) {
    return barColors[index % barColors.length];
  }

  Future<void> loadChartData() async {
    setState(() => loading = true);

    try {
      final data = await statsService.getMonthlyChart();

      if (data != null && data[widget.section] != null) {
        final rawList = data[widget.section] as List;

        List<Map<String, dynamic>> processedData = rawList
            .map((item) => {
          'date': item['date'].toString(),
          'value': ((item['value'] ?? 0) as num).toDouble(),
        })
            .toList();

        // Filter based on selected tab
        processedData = filterByTimeRange(processedData);

        // Calculate totals
        final total = processedData.fold<double>(
          0,
              (sum, item) => sum + ((item['value'] ?? 0) as num).toDouble(),
        );

        setState(() {
          chartData = processedData;
          totalValue = total;
          avgValue = processedData.isEmpty ? 0 : total / processedData.length;
          loading = false;
        });
      } else {
        setState(() {
          chartData = [];
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        chartData = [];
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> filterByTimeRange(List<Map<String, dynamic>> data) {
    final now = DateTime.now();

    switch (selectedTab) {
      case 0: // Day - Show today's data only
        return data.where((item) {
          final date = DateTime.parse(item['date']);
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }).toList();

      case 1: // Week - Show last 7 days
        final weekAgo = now.subtract(const Duration(days: 7));
        return data.where((item) {
          final date = DateTime.parse(item['date']);
          return date.isAfter(weekAgo);
        }).toList();

      case 2: // Month - Show current month
        return data.where((item) {
          final date = DateTime.parse(item['date']);
          return date.year == now.year && date.month == now.month;
        }).toList();

      case 3: // Year - Show last 12 months (aggregate by month)
        final Map<String, double> monthlyData = {};
        for (var item in data) {
          final date = DateTime.parse(item['date']);
          final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + ((item['value'] ?? 0) as num).toDouble();
        }
        return monthlyData.entries
            .map((e) => {'date': '${e.key}-01', 'value': e.value})
            .toList();

      default:
        return data;
    }
  }

  String formatXAxisLabel(String dateStr) {
    final date = DateTime.parse(dateStr);
    switch (selectedTab) {
      case 0: // Day - Show hours
        return DateFormat('HH:mm').format(date);
      case 1: // Week - Show day names
        return DateFormat('E').format(date); // Mon, Tue, etc
      case 2: // Month - Show day numbers
        return DateFormat('d').format(date);
      case 3: // Year - Show month names
        return DateFormat('MMM').format(date); // Jan, Feb, etc
      default:
        return DateFormat('d').format(date);
    }
  }

  String getUnit() {
    switch (widget.section) {
      case 'distance':
        return 'km';
      case 'co2_emissions':
        return 'g';
      case 'fuel_cost':
        return '₹';
      default:
        return '';
    }
  }

  String getTitle() {
    switch (widget.section) {
      case 'distance':
        return 'DISTANCE';
      case 'co2_emissions':
        return 'CO₂ EMISSIONS';
      case 'fuel_cost':
        return 'FUEL COST';
      default:
        return widget.section.toUpperCase();
    }
  }

  Widget buildYAxisLabel(double value) {
    return Text(
      value.toStringAsFixed(0),
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = chartData.isEmpty
        ? 100.0
        : chartData.fold<double>(0, (max, item) {
      final val = ((item['value'] ?? 0) as num).toDouble();
      return val > max ? val : max;
    });

    return Scaffold(
      backgroundColor: const Color(0xff0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          getTitle(),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TAB SWITCHER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(tabs.length, (i) {
                  final isActive = selectedTab == i;
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedTab = i);
                      loadChartData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: isActive
                            ? const LinearGradient(
                          colors: [Color(0xFF00D9FF), Color(0xFF00A8CC)],
                        )
                            : null,
                        color: isActive ? null : Colors.white10,
                      ),
                      child: Text(
                        tabs[i],
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white54,
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              /// GOAL CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xff1a1a1a),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${totalValue.toStringAsFixed(1)} ${getUnit()}",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Average: ${avgValue.toStringAsFixed(1)} ${getUnit()}",
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 8,
                        value: maxValue > 0 ? (avgValue / maxValue).clamp(0, 1) : 0,
                        color: const Color(0xFF00D9FF),
                        backgroundColor: Colors.white10,
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// BAR CHART WITH AXES
              chartData.isEmpty
                  ? Container(
                height: 300,
                alignment: Alignment.center,
                child: const Text(
                  "No data available for this period",
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              )
                  : Container(
                height: 450,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xff1a1a1a),
                ),
                child: Column(
                  children: [
                    // Chart title
                    Text(
                      "${tabs[selectedTab]} View",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chart area
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Y-axis
                          SizedBox(
                            width: 50,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                buildYAxisLabel(maxValue),
                                buildYAxisLabel(maxValue * 0.75),
                                buildYAxisLabel(maxValue * 0.5),
                                buildYAxisLabel(maxValue * 0.25),
                                buildYAxisLabel(0),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Chart bars
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Column(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: List.generate(chartData.length, (index) {
                                          final item = chartData[index];
                                          final double value = ((item['value'] ?? 0) as num).toDouble();
                                          final double heightPercent = maxValue > 0 ? value / maxValue : 0;
                                          final barHeight = (constraints.maxHeight * 0.85 * heightPercent).clamp(2.0, constraints.maxHeight * 0.85);

                                          return Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 3),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  // Value label on top
                                                  if (value > 0)
                                                    Text(
                                                      value.toStringAsFixed(0),
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      overflow: TextOverflow.visible,
                                                    ),
                                                  const SizedBox(height: 2),
                                                  // Bar
                                                  Container(
                                                    width: double.infinity,
                                                    height: barHeight,
                                                    decoration: BoxDecoration(
                                                      borderRadius: const BorderRadius.vertical(
                                                        top: Radius.circular(8),
                                                      ),
                                                      gradient: LinearGradient(
                                                        begin: Alignment.bottomCenter,
                                                        end: Alignment.topCenter,
                                                        colors: [
                                                          getBarColor(index).withValues(alpha: 0.7),
                                                          getBarColor(index),
                                                        ],
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: getBarColor(index).withValues(alpha: 0.3),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // X-axis
                                    SizedBox(
                                      height: 30,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: chartData.map<Widget>((item) {
                                          return Expanded(
                                            child: Text(
                                              formatXAxisLabel(item['date']),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 9,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Data info
              Center(
                child: Text(
                  "${chartData.length} data points",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}