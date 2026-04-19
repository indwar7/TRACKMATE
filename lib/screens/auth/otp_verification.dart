import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class OtpVerificationScreen extends StatefulWidget {   // 🔥 Fixed Name
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focus = List.generate(6, (_) => FocusNode());

  String email = "";
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    email = Get.arguments ?? "";
  }

  String getCode() => _controllers.map((c) => c.text).join();

  Future<void> verifyOTP() async {
    if (getCode().length != 6) {
      setState(() => error = "Invalid OTP");
      return;
    }

    setState(() => loading = true);
    final res = await http.post(
      Uri.parse("http://13.60.63.106/api/auth/verify/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "code": getCode()}),
    );

    setState(() => loading = false);

    if (res.statusCode == 200) {
      Get.offAllNamed("/login");
    } else {
      setState(() => error = "Wrong OTP");
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: const Text("Enter Verification Code",
            style: TextStyle(color: Colors.white,fontSize:22,fontWeight:FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [

          Text("OTP sent to $email",style:const TextStyle(color:Colors.white70,fontSize:14)),
          const SizedBox(height:20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) =>
                otpBox(_controllers[i], _focus[i], i)),
          ),

          if(error != null) Padding(
            padding: const EdgeInsets.only(top:8),
            child: Text(error!,style:const TextStyle(color:Colors.red)),
          ),

          const Spacer(),
          ElevatedButton(
            onPressed: loading ? null : verifyOTP,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                minimumSize: const Size(double.infinity,56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Verify OTP",style:TextStyle(fontSize:16,fontWeight:FontWeight.w600)),
          )
        ]),
      ),
    );
  }

  Widget otpBox(TextEditingController c, FocusNode f, int index){
    return SizedBox(
      width:48, height:58,
      child: TextField(
        controller:c, focusNode:f, textAlign:TextAlign.center, maxLength:1,
        keyboardType:TextInputType.number,
        style: const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold),
        decoration: InputDecoration(counterText:"",filled:true,fillColor:const Color(0xFF16213E),
            border:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide.none)),
        onChanged:(v){
          if(v.isNotEmpty && index<5) _focus[index+1].requestFocus();
          if(v.isEmpty && index>0) _focus[index-1].requestFocus();
          setState(() => error=null);
        },
      ),
    );
  }
}
