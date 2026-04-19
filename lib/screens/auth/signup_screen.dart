// 📌 lib/screens/auth/signup_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  bool loading = false;

  String? userError;
  String? emailError;
  String? passError;
  String? confirmError;

  bool obscurePass = true;
  bool obscureConfirm = true;

  // Password strength indicators
  bool hasMinLength = false;
  bool hasUpper = false;
  bool hasLower = false;
  bool hasDigit = false;
  bool hasSpecial = false;

  @override
  void initState() {
    super.initState();
    _pass.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _pass.removeListener(_updatePasswordStrength);
    _username.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    String p = _pass.text;
    setState(() {
      hasMinLength = p.length >= 8;
      hasUpper = RegExp(r'[A-Z]').hasMatch(p);
      hasLower = RegExp(r'[a-z]').hasMatch(p);
      hasDigit = RegExp(r'[0-9]').hasMatch(p);
      hasSpecial = RegExp(r'[!@#\$&*~%^()\[\]{}?<>+=]').hasMatch(p);
    });
  }

  // ================= VALIDATION =================

  void validateUser() {
    setState(() {
      if (_username.text.trim().isEmpty) {
        userError = "Username is required";
      } else if (_username.text.trim().length < 3) {
        userError = "Username must be at least 3 characters";
      } else {
        userError = null;
      }
    });
  }

  void validateEmail() {
    setState(() {
      if (_email.text.trim().isEmpty) {
        emailError = "Email is required";
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(_email.text.trim())) {
        emailError = "Enter a valid email address";
      } else {
        emailError = null;
      }
    });
  }

  void validatePassword() {
    String p = _pass.text;
    bool strong = hasMinLength && hasUpper && hasLower && hasDigit && hasSpecial;

    setState(() {
      if (p.isEmpty) {
        passError = "Password is required";
      } else if (!strong) {
        passError = "Password doesn't meet requirements";
      } else {
        passError = null;
      }
    });
    validateConfirm();
  }

  void validateConfirm() {
    setState(() {
      if (_confirm.text.isEmpty) {
        confirmError = "Please confirm your password";
      } else if (_pass.text != _confirm.text) {
        confirmError = "Passwords do not match";
      } else {
        confirmError = null;
      }
    });
  }

  bool get isValid =>
      userError == null &&
          emailError == null &&
          passError == null &&
          confirmError == null &&
          _username.text.isNotEmpty &&
          _email.text.isNotEmpty &&
          _pass.text.isNotEmpty &&
          _confirm.text.isNotEmpty;

  // ================= API CALL =================

  Future<void> signupUser() async {
    // Validate all fields
    validateUser();
    validateEmail();
    validatePassword();
    validateConfirm();

    if (!isValid) {
      Get.snackbar(
        "Validation Error",
        "Please fix the errors in the form",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() => loading = true);

    try {
      final res = await http.post(
        Uri.parse("http://13.60.63.106/api/auth/signup/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _username.text.trim(),
          "email": _email.text.trim(),
          "password": _pass.text.trim()
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      setState(() => loading = false);

      if (res.statusCode == 200 || res.statusCode == 201) {
        Get.snackbar(
          "Success",
          "OTP sent to your email",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );

        // Navigate to OTP verification screen
        await Future.delayed(const Duration(milliseconds: 500));
        Get.toNamed('/otp', arguments: _email.text.trim());
      } else {
        final errorData = jsonDecode(res.body);
        final errorMessage = errorData['message'] ?? 'Signup failed';

        Get.snackbar(
          "Signup Failed",
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      setState(() => loading = false);

      Get.snackbar(
        "Connection Error",
        "Unable to connect to server. Check your internet connection.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // ================= UI WIDGETS =================

  Widget _reqRow(bool satisfied, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: satisfied ? Colors.green : Colors.transparent,
            border: Border.all(
              color: satisfied ? Colors.green : Colors.white24,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: satisfied
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : const SizedBox(),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: satisfied ? Colors.white : Colors.white70,
            fontWeight: satisfied ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    ),
  );

  Widget textField({
    required TextEditingController c,
    required String label,
    required String hint,
    String? error,
    bool obscure = false,
    VoidCallback? toggle,
    Function(String)? onChange,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          obscureText: obscure,
          onChanged: onChange,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xff2d2d3a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: error != null
                  ? const BorderSide(color: Colors.red, width: 1.5)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF8B5CF6),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: toggle != null
                ? IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: toggle,
            )
                : null,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Sign up",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Username Field
              textField(
                c: _username,
                label: "Username",
                hint: "Enter your username",
                error: userError,
                onChange: (_) => validateUser(),
              ),

              // Email Field
              textField(
                c: _email,
                label: "Email",
                hint: "Enter your email address",
                error: emailError,
                keyboardType: TextInputType.emailAddress,
                onChange: (_) => validateEmail(),
              ),

              // Password Field
              textField(
                c: _pass,
                label: "Password",
                hint: "Enter your password",
                error: passError,
                obscure: obscurePass,
                toggle: () => setState(() => obscurePass = !obscurePass),
                onChange: (_) => validatePassword(),
              ),

              // Password Requirements
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Password Requirements:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _reqRow(hasMinLength, "At least 8 characters"),
                    _reqRow(hasUpper, "1 uppercase letter"),
                    _reqRow(hasLower, "1 lowercase letter"),
                    _reqRow(hasDigit, "1 number"),
                    _reqRow(hasSpecial, "1 special character"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Confirm Password Field
              textField(
                c: _confirm,
                label: "Confirm Password",
                hint: "Re-enter your password",
                error: confirmError,
                obscure: obscureConfirm,
                toggle: () => setState(() => obscureConfirm = !obscureConfirm),
                onChange: (_) => validateConfirm(),
              ),

              const SizedBox(height: 10),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (isValid && !loading) ? signupUser : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    disabledBackgroundColor:
                    const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: loading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    "Sign up",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Login Link
              Center(
                child: GestureDetector(
                  onTap: () => Get.toNamed('/login'),
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Already a member? ",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                        TextSpan(
                          text: "Log in",
                          style: TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}