import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'discover_data.dart';
import 'discover_item.dart';
import 'discover_detail_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  // Trending theme chips
  List<Map<String, String>> get themes => const [
    {"name": "Hill Stations", "emoji": "⛰️"},
    {"name": "Beaches", "emoji": "🏖️"},
    {"name": "Pilgrimage", "emoji": "🛕"},
    {"name": "Road Trips", "emoji": "🚗"},
    {"name": "Wildlife", "emoji": "🐅"},
    {"name": "City Breaks", "emoji": "🌆"},
  ];

  @override
  Widget build(BuildContext context) {
    // Grouped data
    final highways =
    discoverItems.where((e) => e.category == "Highway").toList();
    final flights =
    discoverItems.where((e) => e.category == "Flights").toList();
    final buses = discoverItems.where((e) => e.category == "Bus").toList();

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Discover",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                    const Icon(Icons.search, color: Colors.white, size: 22),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // THEMES
              Text(
                "Trending themes",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: themes
                      .map(
                        (t) => Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${t['emoji']}  ${t['name']}",
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                  )
                      .toList(),
                ),
              ),

              const SizedBox(height: 26),

              // HIGHWAYS SECTION
              _sectionHeader("🛣️ New & Upgraded Highways"),
              const SizedBox(height: 10),
              ...highways.map((item) => _itemCard(context, item)).toList(),

              const SizedBox(height: 26),

              // FLIGHTS SECTION
              _sectionHeader("✈️ New Flight Routes & Airlines"),
              const SizedBox(height: 10),
              ...flights.map((item) => _itemCard(context, item)).toList(),

              const SizedBox(height: 26),

              // BUS SECTION
              _sectionHeader("🚌 Intercity & Electric Bus Networks"),
              const SizedBox(height: 10),
              ...buses.map((item) => _itemCard(context, item)).toList(),

              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _itemCard(BuildContext context, DiscoverItem item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiscoverDetailScreen(item: item),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _statusTag(item.status),
                      const SizedBox(width: 6),
                      _etaTag(item.eta),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusTag(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          color: Colors.greenAccent,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _etaTag(String eta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        eta,
        style: GoogleFonts.poppins(
          color: Colors.orangeAccent,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
