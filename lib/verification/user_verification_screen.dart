import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/capture_id_screen.dart';
import '../screens/id_capture_tips_screen.dart';

class UserVerificationScreen extends StatelessWidget {
  const UserVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text("Verification", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Complete your identity verification to ensure secure travel experience.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            buildButton(
              text: "Upload Aadhaar (Front & Back)",
              onTap: () => Get.to(() => const IdCaptureTipsScreen()),
            ),

            const SizedBox(height: 15),

            buildButton(
              text: "Capture ID Now",
              onTap: () => Get.to(() => CaptureIdScreen(isFront: true)),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ),
    );
  }
}
