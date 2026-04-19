import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/location_controller.dart';
import '../services/google_places_service.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final locationController = Get.find<LocationController>();
  final placesService = GooglePlacesService();

  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  List<dynamic> fromSuggestions = [];
  List<dynamic> toSuggestions = [];

  bool isFromFocused = false;
  bool isToFocused = false;

  @override
  void initState() {
    super.initState();
    fromController.text = locationController.fromLocation.value.name;
    toController.text = locationController.toLocation.value.name;
  }

  Future<void> searchPlaces(String query, bool isFrom) async {
    if (query.isEmpty) {
      setState(() {
        if (isFrom) {
          fromSuggestions = [];
        } else {
          toSuggestions = [];
        }
      });
      return;
    }

    try {
      final results = await placesService.searchPlaces(query);
      setState(() {
        if (isFrom) {
          fromSuggestions = results;
        } else {
          toSuggestions = results;
        }
      });
    } catch (e) {
      debugPrint('Error searching places: $e');
    }
  }

  void selectPlace(dynamic place, bool isFrom) {
    final description = place['description'] ?? '';
    final parts = description.split(',');
    final city = parts.isNotEmpty ? parts[0].trim() : description;
    final code = city.substring(0, city.length > 4 ? 4 : city.length).toUpperCase();

    if (isFrom) {
      locationController.updateFromLocation(city, code,);
      fromController.text = city;
      setState(() {
        fromSuggestions = [];
        isFromFocused = false;
      });
    } else {
      locationController.updateToLocation(city, code,);
      toController.text = city;
      setState(() {
        toSuggestions = [];
        isToFocused = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Select Location',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Search Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // From Field
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'From',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              TextField(
                                controller: fromController,
                                onChanged: (value) => searchPlaces(value, true),
                                onTap: () {
                                  setState(() {
                                    isFromFocused = true;
                                    isToFocused = false;
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Enter location',
                                  hintStyle: TextStyle(fontSize: 18),
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (fromController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              fromController.clear();
                              setState(() {
                                fromSuggestions = [];
                              });
                            },
                          ),
                      ],
                    ),

                    Divider(color: Colors.grey[300], thickness: 1),
                    const SizedBox(height: 12),

                    // To Field
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'To',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              TextField(
                                controller: toController,
                                onChanged: (value) => searchPlaces(value, false),
                                onTap: () {
                                  setState(() {
                                    isFromFocused = false;
                                    isToFocused = true;
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Enter destination',
                                  hintStyle: TextStyle(fontSize: 18),
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (toController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              toController.clear();
                              setState(() {
                                toSuggestions = [];
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Suggestions List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListView.builder(
                    itemCount: isFromFocused
                        ? fromSuggestions.length
                        : toSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = isFromFocused
                          ? fromSuggestions[index]
                          : toSuggestions[index];
                      final description = suggestion['description'] ?? '';

                      return ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.grey),
                        title: Text(
                          description,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () => selectPlace(suggestion, isFromFocused),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Done Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }
}