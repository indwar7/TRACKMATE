// lib/widgets/onboarding_widget.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:trackmate_app/screens/auth/login_screen.dart';
import 'package:trackmate_app/utils/app_colors.dart';

// The OnboardingData class is defined here, so no need to import it.
class OnboardingData {
  String image;
  String title;
  String subtitle;

  OnboardingData({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}

class OnboardingWidget extends StatefulWidget {
  const OnboardingWidget({
    Key? key,
    required this.pageController,
  }) : super(key: key);

  final PageController pageController;

  @override
  State<OnboardingWidget> createState() => _OnboardingWidgetState();
}

class _OnboardingWidgetState extends State<OnboardingWidget> {
  final box = GetStorage();
  int currentIndex = 0;

  List<OnboardingData> onboardingData = [
    OnboardingData(
      image: 'assets/images/onboard1.png',
      title: 'Welcome to Trackmate',
      subtitle: 'Your personal safety and travel companion.',
    ),
    OnboardingData(
      image: 'assets/images/onboard2.png',
      title: 'Real-time Tracking',
      subtitle: 'Share your location with trusted contacts.',
    ),
    OnboardingData(
      image: 'assets/images/onboard3.png',
      title: 'Emergency SOS',
      subtitle: 'Get help instantly with a single tap.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: widget.pageController,
          itemCount: onboardingData.length,
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(onboardingData[index].image, height: 300),
                const SizedBox(height: 40),
                Text(
                  onboardingData[index].title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    onboardingData[index].subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Center(
            child: SmoothPageIndicator(
              controller: widget.pageController,
              count: onboardingData.length,
              effect: WormEffect(
                dotColor: Colors.white30,
                activeDotColor: AppColors.secondaryColor,
                dotHeight: 10,
                dotWidth: 10,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: AppColors.secondaryColor,
            child: Icon(
              currentIndex == onboardingData.length - 1
                  ? Icons.check
                  : Icons.arrow_forward_ios,
              color: Colors.white,
            ),
            onPressed: () {
              if (currentIndex == onboardingData.length - 1) {
                box.write('onBoard', true);
                Get.offAll(() => LoginScreen()); // Corrected Navigation Call
              } else {
                widget.pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}