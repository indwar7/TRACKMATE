import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController email = TextEditingController();

  String? emailError;
  bool loading = false;

  bool isValidEmail(String mail) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(mail);
  }

  Future<void> sendOtp() async {
    final text = email.text.trim();

    // validate
    if (!isValidEmail(text)) {
      setState(() => emailError = "Invalid Email!");
      return;
    }

    setState(() {
      emailError = null;
      loading = true;
    });

    final response = await http.post(
      Uri.parse("http://13.60.63.106/api/auth/forgot-password/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": text}),
    );

    setState(() => loading = false);

    if (response.statusCode == 200) {
      Get.snackbar(
        "OTP Sent",
        "Check your email for the reset code",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // 👉 Go to OTP screen, pass email
      Get.toNamed('/forgot-otp', arguments: text);
    } else {
      Get.snackbar(
        "Error",
        "Email not registered",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const fieldColor = Color(0xFF3A3A3A);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Forgot Password",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                "No worries, it happens!\nReset your password and get back to your journey!",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 32),

              const Text(
                "Email address",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) {
                  if (emailError != null) {
                    setState(() => emailError = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: "Enter your Email",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: fieldColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: emailError == null ? Colors.transparent : Colors.red,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: emailError == null
                          ? const Color(0xFF8B5CF6)
                          : Colors.red,
                      width: 1.4,
                    ),
                  ),
                ),
              ),

              if (emailError != null) ...[
                const SizedBox(height: 6),
                Text(
                  emailError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: loading ? null : sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
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
}
