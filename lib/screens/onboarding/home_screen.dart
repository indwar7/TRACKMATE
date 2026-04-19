import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../../controllers/location_controller.dart';
import 'package:trackmate_app/screens/my_stats_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _ = Get.find<AuthService>();
    final locationController = Get.put(LocationController());
    final userName = "User";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================================================
              // HEADER
              // =========================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Greetings,",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed('/settings'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.translate, color: Colors.white, size: 24),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 22),

              // =========================================================
              // SEARCH CARD
              // =========================================================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // SEARCH BAR
                    GestureDetector(
                      onTap: () => Get.toNamed('/location-search'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.black87, size: 20),
                            const SizedBox(width: 10),

                            // FROM
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "From",
                                    style: TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                  Obx(() => Text(
                                    locationController.fromLocation.value.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  )),
                                ],
                              ),
                            ),

                            // SWAP BTN
                            GestureDetector(
                              onTap: () => locationController.swapLocations(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.swap_horiz, color: Colors.black87, size: 18),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // TO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "To",
                                    style: TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                  Obx(() => Text(
                                    locationController.toLocation.value.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // START BTN
                    GestureDetector(
                      onTap: () => Get.toNamed('/map'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA78BFA),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Text(
                          "Start",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // HOME / WORK ADDRESSES
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Get.toNamed('/edit-address', arguments: {"type": "home"}),
                            child: Row(
                              children: const [
                                Icon(Icons.location_on, color: Colors.white70, size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Home",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        "Sector Name-3 Intraspuram, Delhi, India",
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 10,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Get.toNamed('/edit-address', arguments: {"type": "work"}),
                            child: Row(
                              children: const [
                                Icon(Icons.work, color: Colors.white70, size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Work",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        "Cyber city plaza-3, Gurgaon Haryana, India",
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 10,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // =========================================================
              // ANALYTICS
              // =========================================================
              GestureDetector(
                onTap: () {
                  Get.to(() => const MyStatsScreen());
                },


                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "25%",
                                  style: TextStyle(
                                    color: Color(0xFFA78BFA),
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "more than previous month",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text(
                                "250 g/km",
                                style: TextStyle(
                                  fontSize: 28,
                                  color:Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "Monthly carbon",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                "emission",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(12, (i) {
                          final heights = [25.0, 30.0, 35.0, 40.0, 45.0, 60.0, 52.0, 54.0, 52.0, 58.0, 60.0, 62.0];
                          return Container(
                            width: 16,
                            height: heights[i],
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: i == 11 ? const Color(0xFFA78BFA) : const Color(0xFFE9D5FF),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // =========================================================
              // AI CHECKLIST
              // =========================================================
              GestureDetector(
                onTap: () => Get.toNamed('/ai-checklist'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_box, size: 22),
                      SizedBox(width: 4),
                      Icon(Icons.list, size: 22),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          "Smart Personalised Check Assist",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // =========================================================
              // AUTO + HISTORY
              // =========================================================
              Row(
                children: [
                  // AUTO TRIP TRACKING
                  Expanded(
                    flex: 50,
                    child: GestureDetector(
                      onTap: () => Get.toNamed('/live-tracking', arguments: {
                        "tripId": 0,
                        "startLocation": "Home",
                      }),
                      child: Container(
                        height: 95,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF475569),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Stack(
                          children: const [
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(Icons.location_on, color: Colors.white, size: 28),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Icon(Icons.route, color: Colors.white, size: 20),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Text(
                                  "Auto\nTrip\nTracking",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // TRIP HISTORY
                  Expanded(
                    flex: 50,
                    child: GestureDetector(
                      onTap: () => Get.toNamed('/trip-history'),
                      child: Container(
                        height: 95,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA78BFA),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Text(
                            "Trip History",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // =========================================================
              // RECORD + SCHEDULE + ANY QUESTIONS
              // =========================================================
              Row(
                children: [
                  // RECORD A TRIP
                  Expanded(
                    flex: 30,
                    child: GestureDetector(
                      onTap: () => Get.toNamed('/record-trip'),
                      child: Container(
                        height: 215,
                        decoration: BoxDecoration(
                          color: const Color(0xFFA78BFA),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Stack(
                          children: const [
                            Positioned(
                              top: 20,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Icon(Icons.calendar_today, color: Colors.black, size: 32),
                              ),
                            ),
                            Center(
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Text(
                                  "Record a trip",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    flex: 70,
                    child: Column(
                      children: [
                        // SCHEDULE TRIP
                        GestureDetector(
                          onTap: () => Get.toNamed('/planned-trip'),
                          child: Container(
                            height: 95,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: const [
                                Icon(Icons.near_me, size: 26),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Schedule a\nTrip for later",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),


                        // ANY QUESTIONS → CHAT SCREEN
                        GestureDetector(
                          onTap: () => Get.toNamed(
                            '/ai-chatbot',
                            arguments: {"initialMessage": "Hey! 👋 I need help"},
                          ),
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF475569),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: const [
                                Icon(Icons.smart_toy, color: Colors.white, size: 28),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Any questions?\nAsk your own AI personal assistant",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // =========================================================
              // COST CALCULATOR
              // =========================================================
              GestureDetector(
                onTap: () => Get.toNamed('/cost-calculator'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.calculate, size: 24),
                      SizedBox(width: 12),
                      Text(
                        "Expense Calculator",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =========================================================
              // DISCOVER
              // =========================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "DISCOVER",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed('/discover'),
                    child: const Text(
                      "See all",
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Container(
                height: 155,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  image: const DecorationImage(
                    image: AssetImage("assets/images/jaipur.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 16,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Jaipur",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Route - Delhi - BOM expy",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _tag("Services"),
                              const SizedBox(width: 12),
                              _tag("Cost"),
                              const SizedBox(width: 12),
                              _tag("Co2"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}