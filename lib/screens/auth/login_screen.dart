import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:trackmate_app/services/auth_service.dart';
import 'package:trackmate_app/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool passwordVisible = false;
  bool isLoading = false;

  String? emailError;
  String? passwordError;

  bool hasMinLength = false;
  bool hasUpper = false;
  bool hasLower = false;
  bool hasDigit = false;
  bool hasSpecial = false;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    passwordController.removeListener(_onPasswordChanged);
    passwordController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    final pwd = passwordController.text;
    setState(() {
      hasMinLength = pwd.length >= 8;
      hasUpper = RegExp(r'[A-Z]').hasMatch(pwd);
      hasLower = RegExp(r'[a-z]').hasMatch(pwd);
      hasDigit = RegExp(r'[0-9]').hasMatch(pwd);
      hasSpecial = RegExp(r'[!@#\$&*~%^()\[\]{}?<>|/+_=.,-]').hasMatch(pwd);
    });
  }

  bool isValidEmail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  bool isPasswordStrong() =>
      hasMinLength && hasUpper && hasLower && hasDigit && hasSpecial;

  Future<void> loginUser() async {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => emailError = "Email is required");
      return;
    }

    if (!isValidEmail(email)) {
      setState(() => emailError = "Invalid email format");
      return;
    }

    if (password.isEmpty) {
      setState(() => passwordError = "Password is required");
      return;
    }

    if (!isPasswordStrong()) {
      setState(() => passwordError = "Password doesn't meet requirements");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://13.60.63.106/api/auth/login/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('Request timeout');
      });

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['access'] as String?;
        final refresh = data['refresh'] as String?;

        if (token == null || token.isEmpty) {
          throw Exception('No token in response');
        }

        // Sync into ApiService and persist via AuthService
        final apiService = Get.find<ApiService>();
        apiService.accessToken = token;
        apiService.refreshToken = refresh;
        await Get.find<AuthService>().login(email, token);

        Get.snackbar(
          "Success",
          "Welcome back!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed('/home');
      } else if (response.statusCode == 401) {
        Get.snackbar(
          "Login Failed",
          "Invalid email or password",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        final body = jsonDecode(response.body);
        final message = body['detail'] ?? body['message'] ?? 'Something went wrong. Please try again.';
        Get.snackbar(
          "Error",
          message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      final msg = e.toString().contains('timeout')
          ? 'Request timed out. Check your connection.'
          : 'Unable to connect to server.';
      Get.snackbar(
        "Connection Error",
        msg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    const fieldFill = Color(0xFF3A3A3A);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.black45,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Log in",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // EMAIL FIELD
                const Text(
                  "Email",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    if (emailError != null) {
                      setState(() => emailError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Enter your Email",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: emailError != null
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
                  ),
                ),
                if (emailError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    emailError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // PASSWORD FIELD
                const Text(
                  "Password",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: !passwordVisible,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    if (passwordError != null) {
                      setState(() => passwordError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Enter your Password",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: fieldFill,
                    suffixIcon: IconButton(
                      icon: Icon(
                        passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () =>
                          setState(() => passwordVisible = !passwordVisible),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: passwordError != null
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
                  ),
                ),
                if (passwordError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    passwordError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // PASSWORD REQUIREMENTS
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white12,
                      width: 1,
                    ),
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

                // FORGOT PASSWORD
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Get.toNamed('/forgot-password'),
                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : loginUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      disabledBackgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // SIGN UP LINK
                Center(
                  child: GestureDetector(
                    onTap: () => Get.toNamed('/signup'),
                    child: const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                          TextSpan(
                            text: "Register Instead",
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
      ),
    );
  }
}
