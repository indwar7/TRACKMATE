// lib/screens/auth/reset_password_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final newPass = TextEditingController();
  final confirmPass = TextEditingController();
  bool show1 = false, show2 = false;
  bool loading = false;

  Future<void> resetPassword() async {
    final email = Get.arguments["email"];
    final otp = Get.arguments["otp"];

    if (newPass.text.trim().isEmpty || newPass.text != confirmPass.text) {
      Get.snackbar("Error", "Passwords do not match", backgroundColor: Colors.red,colorText: Colors.white);
      return;
    }

    setState(() => loading = true);

    final response = await http.post(
      Uri.parse("http://13.60.63.106/api/auth/reset-password/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "code": otp,
        "new_password": newPass.text.trim(),
      }),
    );

    setState(() => loading = false);

    if (response.statusCode == 200) {
      Get.snackbar("Done", "Password Reset Successful",
          backgroundColor: Colors.green,colorText: Colors.white);
      Get.offAllNamed('/login');
    } else {
      Get.snackbar("Failed", "Incorrect OTP or email",
          backgroundColor: Colors.red,colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Reset Password",
            style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold)),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          const SizedBox(height: 25),
          _field("New Password", newPass, show1, ()=>setState(()=> show1=!show1)),
          const SizedBox(height: 20),
          _field("Confirm Password", confirmPass, show2, ()=>setState(()=> show2=!show2)),

          const SizedBox(height: 45),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: loading ? null : resetPassword,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Done", style: TextStyle(fontSize: 17,fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, bool v, VoidCallback toggle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white,fontSize: 16)),
      const SizedBox(height: 8),
      TextField(
        controller: c,
        obscureText: !v,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true, fillColor: const Color(0xFF3A3A3A),
          suffixIcon: GestureDetector(
            onTap: toggle,
            child: Icon(v ? Icons.visibility : Icons.visibility_off,color:Colors.white),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      )
    ]);
  }
}
