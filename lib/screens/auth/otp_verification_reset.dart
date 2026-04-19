import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// --------------------
/// RESET OTP SCREEN
/// --------------------
class OtpVerificationResetScreen extends StatefulWidget {   // 🔥 name changed here
  const OtpVerificationResetScreen({super.key});

  @override
  State<OtpVerificationResetScreen> createState() => _OtpVerificationResetScreenState();
}

class _OtpVerificationResetScreenState extends State<OtpVerificationResetScreen> {
  final List<TextEditingController> otp = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> nodes = List.generate(6, (_) => FocusNode());

  String email = "";
  int timer = 30;
  String? error;

  @override
  void initState() {
    super.initState();
    email = Get.arguments ?? "";                          // safe argument read
    startTimer();
  }

  void startTimer() {
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (timer == 0) t.cancel();
      if (mounted) setState(() => timer = timer > 0 ? timer - 1 : 0);
    });
  }

  String getOTP() => otp.map((e) => e.text).join();

  void verifyOTP() {
    final code = getOTP();

    if (code.length < 6) {
      setState(() => error = "OTP can't be empty");
      return;
    }

    Get.toNamed("/reset-password", arguments: {
      "email": email,
      "otp": code,
    });
  }

  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            const Text(
              "Enter verification code",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),
            Text(
              "Verification OTP sent to:\n$email",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),

            const SizedBox(height: 30),

            // OTP TEXT BOXES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => _otpBox(i)),
            ),

            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, style: const TextStyle(color: Colors.redAccent)),
              ),

            const SizedBox(height: 10),
            Text("$timer seconds left", style: const TextStyle(color: Colors.white70)),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Verify OTP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 18),

            TextButton(
              onPressed: () => timer == 0 ? startTimer() : null,
              child: const Text("Resend Code", style: TextStyle(color: Color(0xFF8B5CF6))),
            ),
          ],
        ),
      ),
    );
  }

  /// SINGLE OTP INPUT BOX UI
  Widget _otpBox(int i) => SizedBox(
    width: 45,
    height: 55,
    child: TextField(
      controller: otp[i],
      focusNode: nodes[i],
      maxLength: 1,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),

      decoration: InputDecoration(
        counterText: "",
        filled: true,
        fillColor: const Color(0xFF3A3A3A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),

      onChanged: (v) {
        if (v.isNotEmpty && i < 5) FocusScope.of(context).nextFocus();
        if (v.isEmpty && i > 0) FocusScope.of(context).previousFocus();
        setState(() => error = null);
      },
    ),
  );
}
