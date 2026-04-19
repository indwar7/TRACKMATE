import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/location_controller.dart';
import '../../../services/google_places_service.dart';

class EditAddressScreen extends StatefulWidget {
  const EditAddressScreen({super.key});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final locationController = Get.find<LocationController>();
  final placesService = GooglePlacesService();
  final TextEditingController addressController = TextEditingController();

  List<dynamic> suggestions = [];
  String addressType = 'home'; // 'home' or 'work'

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    addressType = args?['type'] ?? 'home';

    if (addressType == 'home') {
      addressController.text ="${locationController.homeAddress.value.address}, ${locationController.homeAddress.value.city}";
    } else {
      addressController.text = "${locationController.workAddress.value.address}, ${locationController.workAddress.value.city}";
    }
  }

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        suggestions = [];
      });
      return;
    }

    try {
      final results = await placesService.searchPlaces(query);
      setState(() {
        suggestions = results;
      });
    } catch (e) {
      debugPrint('Error searching places: $e');
    }
  }

  void selectPlace(dynamic place) {
    final description = place['description'] ?? '';
    final parts = description.split(',');

    // Extract address and city
    String address = parts.isNotEmpty ? parts[0].trim() : '';
    String city = parts.length > 1
        ? parts.sublist(1).join(',').trim()
        : '';

    if (addressType == 'home') {
      locationController.updateHomeAddress(address, city);
    } else {
      locationController.updateWorkAddress(address, city);
    }

    addressController.text = description;
    setState(() {
      suggestions = [];
    });
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
        title: Text(
          'Edit ${addressType == 'home' ? 'Home' : 'Work'} Address',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Address Input Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          addressType == 'home' ? Icons.home : Icons.work,
                          color: const Color(0xFF7C3AED),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          addressType == 'home' ? 'Home Address' : 'Work Address',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      onChanged: searchPlaces,
                      decoration: InputDecoration(
                        hintText: 'Enter your address',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: addressController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            addressController.clear();
                            setState(() {
                              suggestions = [];
                            });
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Suggestions List
              if (suggestions.isNotEmpty)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListView.builder(
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
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
                          onTap: () => selectPlace(suggestion),
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Save Button
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
                    'Save Address',
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
    addressController.dispose();
    super.dispose();
  }
}