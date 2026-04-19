import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // -----------------------------
    // ANIMATIONS
    // -----------------------------
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    _controller.forward();

    // -----------------------------
    // NAVIGATION - Check auth state
    // -----------------------------
    Future.delayed(const Duration(seconds: 2), () {
      Get.offAllNamed('/home'); // CHANGE if needed
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6C5CE7);

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -------------------------------------------------
                // APP ICON CONTAINER
                // -------------------------------------------------
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: purple.withValues(alpha: 0.4), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: purple.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      "assets/app_icon.png",
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.travel_explore,
                        color: purple.withValues(alpha: 0.8),
                        size: 56,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // -------------------------------------------------
                // TITLE
                // -------------------------------------------------
                const Text(
                  "Welcome Traveller!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),

                const SizedBox(height: 6),

                // -------------------------------------------------
                // SUBTITLE
                // -------------------------------------------------
                Text(
                  "Smart Travel Companion",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 45),

                // -------------------------------------------------
                // PURPLE PROGRESS INDICATOR
                // -------------------------------------------------
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.2,
                    valueColor: AlwaysStoppedAnimation<Color>(purple),
                    backgroundColor: Colors.white24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
