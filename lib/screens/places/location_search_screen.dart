import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/location_controller.dart';

class LocationSearchScreen extends StatelessWidget {
  LocationSearchScreen({super.key});

  final LocationController locationController = Get.find<LocationController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Search Location',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// SEARCH INPUT
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search place...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                locationController.searchPlaces(value);
              },
            ),

            const SizedBox(height: 16),

            /// RESULT LIST
            Expanded(
              child: Obx(() {
                final results = locationController.searchResults;

                if (results.isEmpty) {
                  return const Center(
                    child: Text(
                      "Start typing to search...",
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];  // {place_id, name}

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      title: Text(
                        item["name"],
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white60,
                        size: 16,
                      ),

                      onTap: () async {
                        /// 1️⃣ UPDATE FROM LOCATION (GETS lat/lng/name)
                        await locationController.setFromByPlaceId(
                          item["place_id"],
                        );

                        /// 2️⃣ CLOSE SEARCH
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
