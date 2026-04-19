import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'discover_item.dart';

class DiscoverDetailScreen extends StatelessWidget {
  final DiscoverItem item;
  const DiscoverDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          item.title,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // EMOJI + CATEGORY
            Row(
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Text(
                  item.category.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // SUBTITLE
            Text(
              item.subtitle,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            // STATUS + ETA
            Row(
              children: [
                _pill("Status: ${item.status}", Colors.greenAccent.withValues(alpha: 0.16), Colors.greenAccent),
                const SizedBox(width: 10),
                _pill("Timeline: ${item.eta}", Colors.orangeAccent.withValues(alpha: 0.16), Colors.orangeAccent),
              ],
            ),

            const SizedBox(height: 18),

            // DESCRIPTION
            Text(
              item.description,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 22),

            Text(
              "Key Highlights",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            ...item.highlights.map(
                  (h) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "• $h",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 26),

            // FUTURE BUTTONS AREA (Book / Plan Trip etc.)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Soon you’ll be able to plan trips, compare modes, and get live traffic & fares for this route.",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
