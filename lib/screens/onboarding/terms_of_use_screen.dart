import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsOfUseScreen extends StatefulWidget {
  const TermsOfUseScreen({super.key});

  @override
  State<TermsOfUseScreen> createState() => _TermsOfUseScreenState();
}

class _TermsOfUseScreenState extends State<TermsOfUseScreen> {
  bool hasAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Terms of Use",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Terms content (scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome to TrackMate",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Please read and accept our terms of use to continue.",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    // Add your terms content here
                    _buildTermsSection(
                      "1. Acceptance of Terms",
                      "By accessing and using TrackMate, you accept and agree to be bound by these terms.",
                    ),
                    _buildTermsSection(
                      "2. Location Services",
                      "TrackMate requires access to your location to provide accurate tracking and navigation services.",
                    ),
                    _buildTermsSection(
                      "3. Privacy Policy",
                      "Your privacy is important to us. We collect and use your data as described in our Privacy Policy.",
                    ),
                    _buildTermsSection(
                      "4. User Responsibilities",
                      "You are responsible for maintaining the confidentiality of your account credentials.",
                    ),
                    // Add more sections as needed
                  ],
                ),
              ),
            ),

            // Accept checkbox and button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: hasAccepted,
                        onChanged: (value) {
                          setState(() => hasAccepted = value ?? false);
                        },
                        activeColor: const Color(0xFF8B5CF6),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => hasAccepted = !hasAccepted);
                          },
                          child: const Text(
                            "I agree to the Terms of Use and Privacy Policy",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: hasAccepted
                          ? () {
                        // Navigate to permissions screen
                        Get.offNamed('/permissions');
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
