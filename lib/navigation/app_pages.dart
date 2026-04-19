import 'package:get/get.dart';

// ---------------- SCREENS ----------------
import 'package:trackmate_app/screens/chat_screen/chat_screen.dart';

import 'package:trackmate_app/screens/onboarding/home_screen.dart';
import 'package:trackmate_app/screens/user/profile_screen.dart';

import 'package:trackmate_app/screens/auth/login_screen.dart';
import 'package:trackmate_app/screens/auth/signup_screen.dart';
import 'package:trackmate_app/screens/auth/forgot_password_screen.dart';
import 'package:trackmate_app/screens/auth/reset_password_screen.dart';
import 'package:trackmate_app/screens/auth/forgot_otp_screen.dart';

import 'package:trackmate_app/screens/map_screen.dart';
import 'package:trackmate_app/screens/onboarding/splash_screen.dart';

import 'package:trackmate_app/screens/onboarding/welcome_screen.dart';
import 'package:trackmate_app/screens/onboarding/terms_of_use_screen.dart';
import 'package:trackmate_app/screens/onboarding/language_selection_screen.dart';
import 'package:trackmate_app/screens/onboarding/permissions_screen.dart';

import 'package:trackmate_app/screens/user/settings_screen.dart';
import 'package:trackmate_app/screens/user/support_screen.dart';
import 'package:trackmate_app/screens/user/trusted_contacts_screen.dart';

import 'package:trackmate_app/screens/verification/user_verification_screen.dart';
import 'package:trackmate_app/screens/capture_id_screen.dart';
import 'package:trackmate_app/screens/id_capture_tips_screen.dart';
import 'package:trackmate_app/screens/verification/id_status_screen.dart';

import 'package:trackmate_app/screens/my_stats_screen.dart';
import 'package:trackmate_app/screens/ai_checklist_screen.dart';
import '../screens/cost_calculator_screen.dart';

class AppPages {
  /// 🚀 Initial screen when app opens
  static const initial = '/splash';

  /// 🚀 All routes used in app
  static final routes = [

    // ---------------- Onboarding ----------------
    GetPage(name: '/splash', page: () => const SplashScreen()),
    GetPage(name: '/welcome', page: () => const WelcomeScreen()),
    GetPage(name: '/language-selection', page: () => const LanguageSelectionScreen()),
    GetPage(name: '/permissions', page: () => const LocationPermissionScreen()),
    GetPage(name: '/terms', page: () => const TermsOfUseScreen()),

    // ---------------- AUTH ----------------
    GetPage(name: '/login', page: () => const LoginScreen()),
    GetPage(name: '/signup', page: () => const SignUpScreen()),
    GetPage(name: '/forgot-password', page: () => const ForgotPasswordScreen()),
    GetPage(name: '/forgot-otp', page: () => const ForgotOtpVerifyScreen()),
    GetPage(name: '/reset-password', page: () => const ResetPasswordScreen()),

    // ---------------- HOME ----------------
    GetPage(name: '/home', page: () => const HomeScreen()),

    // ---------------- MAIN FEATURES ----------------
    GetPage(name: '/my-stats', page: () => const MyStatsScreen()),
    GetPage(name: '/cost-calculator', page: () => const CostCalculatorScreen()),
    //GetPage(name: '/planner', page: () => const PlannerScreen()),
    GetPage(name: '/maps', page: () => const MapScreen()),
    GetPage(name: '/ai-checklist', page: () => const AiChecklistScreen()),
    GetPage(name: '/ai-chatbot', page: () => ChatScreen()),

    // ---------------- USER ----------------
    GetPage(name: '/profile', page: () => const ProfileScreen()),
    GetPage(name: '/settings', page: () => const SettingsScreen()),
    GetPage(name: '/support', page: () => const SupportScreen()),
    GetPage(name: '/trusted-contacts', page: () =>TrustedContactsScreen()),

    // ---------------- VERIFICATION ----------------
    GetPage(name: '/verification', page: () => const UserVerificationScreen()),
    GetPage(
      name: '/capture-id',
      page: () => CaptureIdScreen(isFront: Get.arguments ?? true),
    ),
    GetPage(name: '/id-tips', page: () => const IdCaptureTipsScreen()),
    GetPage(name: '/id-status', page: () => const IdStatusScreen()),
  ];
}
