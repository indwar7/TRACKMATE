// =============================================================
//                   TRACKMATE - MERGED MAIN APP
// =============================================================

import 'package:provider/provider.dart';
import 'package:trackmate_app/services/api_service.dart';
import 'package:trackmate_app/services/location_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// =============== AUTH ===============
import 'package:trackmate_app/screens/auth/login_screen.dart';
import 'package:trackmate_app/screens/auth/signup_screen.dart';
import 'package:trackmate_app/screens/auth/forgot_password_screen.dart';
import 'package:trackmate_app/screens/auth/forgot_otp_screen.dart';
import 'package:trackmate_app/screens/auth/reset_password_screen.dart';
import 'package:trackmate_app/screens/auth/otp_verification.dart';
import 'package:trackmate_app/screens/auth/otp_verification_reset.dart';

// ================= SERVICES =================
import 'package:trackmate_app/services/auth_service.dart';

// ================= MIDDLEWARE =================
import 'package:trackmate_app/middleware/auth_middleware.dart';

// ================= CONTROLLERS ==============
import 'package:trackmate_app/controllers/profile_controller.dart';
import 'package:trackmate_app/controllers/language_controller.dart';
import 'package:trackmate_app/controllers/location_controller.dart';

// ================= ONBOARDING ================
import 'package:trackmate_app/screens/onboarding/welcome_screen.dart';
import 'package:trackmate_app/screens/onboarding/permissions_screen.dart';
import 'package:trackmate_app/screens/onboarding/terms_of_use_screen.dart';
import 'package:trackmate_app/screens/onboarding/main_navigation_screen.dart';

// ================= MAIN SCREENS =============
import 'package:trackmate_app/screens/discover/discover_screen.dart';
import 'package:trackmate_app/screens/map_screen.dart';
import 'package:trackmate_app/screens/my_stats_screen.dart';
import 'package:trackmate_app/screens/chat_screen/chat_screen.dart';
import 'package:trackmate_app/screens/ai_checklist_screen.dart';
import 'package:trackmate_app/screens/cost_calculator_screen.dart';

// ================= TRIP & MAP =================
import 'package:trackmate_app/screens/live_tracking_screen.dart';
import 'package:trackmate_app/screens/manual_trip_screen.dart';
import 'package:trackmate_app/screens/planned_trip_screen.dart';
import 'package:trackmate_app/screens/saved_planned_trips_screen.dart';
import 'package:trackmate_app/screens/trip_summary_screen.dart';
import 'package:trackmate_app/screens/trip_history_screen.dart';
// ================= USER =====================
import 'package:trackmate_app/screens/user/profile_screen.dart' as UserProfile;
import 'package:trackmate_app/screens/user/settings_screen.dart';
import 'package:trackmate_app/screens/user/support_screen.dart';
import 'package:trackmate_app/screens/user/trusted_contacts_screen.dart';
import 'package:trackmate_app/screens/user/vehicle_info_screen.dart';
import 'package:trackmate_app/screens/user/edit_profile_screen.dart';

// ================= VERIFICATION =============
import 'package:trackmate_app/screens/verification/user_verification_screen.dart';
import 'package:trackmate_app/screens/aadhaar_verification_screen.dart';
import 'package:trackmate_app/screens/capture_id_screen.dart';
import 'package:trackmate_app/screens/id_capture_tips_screen.dart';
import 'package:trackmate_app/screens/verification/id_status_screen.dart';

// ================= TOOLS ====================
import 'package:trackmate_app/screens/tools/safety_tools_screen.dart';
import 'package:trackmate_app/screens/tools/invite_friends_screen.dart';

// ================= LOCATIONS =================
import 'package:trackmate_app/screens/location_search_screen.dart';
import 'package:trackmate_app/screens/edit_address_screen.dart';
import 'package:trackmate_app/screens/places/add_work_screen.dart';


// =============================================================
//                           ENTRY POINT
// =============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  /// Load .env
  try {
    await dotenv.load();
  } catch (e) {
    debugPrint("⚠ .env not loaded => $e");
  }

  // Register global controllers
  Get.put(AuthService(), permanent: true);
  Get.put(ProfileController(), permanent: true);
  Get.put(LanguageController(), permanent: true);
  Get.put(LocationController(), permanent: true);

  // Load tokens and register ApiService with GetX so Get.find<ApiService>() works
  final apiService = ApiService();
  await apiService.loadTokens();
  Get.put(apiService, permanent: true);

  // =============================================================
  //                  ONBOARDING STATE LOGIC
  // =============================================================

  final box = GetStorage();

  bool hasSeenOnboarding = box.read('hasSeenOnboarding') ?? false;
  bool hasAcceptedTerms = box.read('hasAcceptedTerms') ?? false;
  bool hasGrantedPermissions = box.read('hasGrantedPermissions') ?? false;
  bool isLoggedIn = apiService.accessToken != null;

  String initialRoute = "/welcome";

  if (!hasSeenOnboarding) {
    initialRoute = "/welcome";
  } else if (!hasGrantedPermissions) {
    initialRoute = "/permissions";
  } else if (!hasAcceptedTerms) {
    initialRoute = "/terms";
  } else if (!isLoggedIn) {
    initialRoute = "/login";
  } else {
    initialRoute = "/home";
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<LocationService>(create: (_) => LocationService()),
      ],
      child: TrackMateApp(initialRoute: initialRoute),
    ),
  );
}


// =============================================================
//                        ROOT APP
// =============================================================

class TrackMateApp extends StatelessWidget {
  final String initialRoute;
  const TrackMateApp({required this.initialRoute, super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "TrackMate",
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      fallbackLocale: const Locale('en', 'US'),

      theme: ThemeData.dark(useMaterial3: true).copyWith(
        primaryColor: const Color(0xFF8B5CF6),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16213e),
          elevation: 0,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),

      // =============================================================
      //                          ROUTES
      // =============================================================
      getPages: [

        /// ---------------- ONBOARDING (public) -------
        GetPage(name: "/welcome", page: () => const WelcomeScreen()),
        GetPage(name: "/permissions", page: () => const LocationPermissionScreen()),
        GetPage(name: "/terms", page: () => const TermsOfUseScreen()),

        /// ---------------- AUTH (public) -------------
        GetPage(name: "/login", page: () => const LoginScreen()),
        GetPage(name: "/signup", page: () => const SignUpScreen()),
        GetPage(name: "/otp", page: () => const OtpVerificationScreen()),
        GetPage(name: "/otp-reset", page: () => const OtpVerificationResetScreen()),
        GetPage(name: "/forgot-password", page: () => const ForgotPasswordScreen()),
        GetPage(name: "/forgot-otp", page: () => const ForgotOtpVerifyScreen()),
        GetPage(name: "/reset-password", page: () => const ResetPasswordScreen()),

        /// ---------------- PROTECTED ROUTES ----------
        GetPage(
          name: "/home",
          page: () => const MainNavigationScreen(),
          middlewares: [AuthMiddleware()],
        ),

        /// ---------------- MAIN ----------------------
        GetPage(
          name: "/discover",
          page: () => const DiscoverScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/my-stats",
          page: () => const MyStatsScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/ai-chatbot",
          page: () => ChatScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/ai-checklist",
          page: () => const AiChecklistScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/cost-calculator",
          page: () => const CostCalculatorScreen(),
          middlewares: [AuthMiddleware()],
        ),

        /// ---------------- TRIP & MAP ----------------
        GetPage(
          name: "/map",
          page: () => const MapScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/trip-history",
          page: () => const TripHistoryScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/saved-planned-trips",
          page: () => const ManualTripEntryScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/record-trip",
          page: () => const ManualTripScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/plan-trip",
          page: () => const PlannedTripScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/live-tracking",
          page: () {
            final args = Get.arguments as Map<String, dynamic>? ?? {};
            return LiveTrackingScreen(
              tripId: args['tripId'] ?? 0,
              startLocation: args['startLocation'] ?? '',
            );
          },
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/trip-summary",
          page: () {
            final args = Get.arguments as Map<String, dynamic>? ?? {};
            return TripSummaryScreen(data: args);
          },
          middlewares: [AuthMiddleware()],
        ),

        /// ---------------- USER ----------------------
        GetPage(
          name: "/profile",
          page: () => const UserProfile.ProfileScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/edit-profile",
          page: () => const EditProfileScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/settings",
          page: () => const SettingsScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/support",
          page: () => const SupportScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/trusted-contacts",
          page: () => TrustedContactsScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/vehicle-info",
          page: () => const VehicleInfoScreen(),
          middlewares: [AuthMiddleware()],
        ),

        /// ---------------- VERIFICATION --------------
        GetPage(
          name: "/user-verification",
          page: () => const UserVerificationScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/aadhaar",
          page: () => const AadhaarVerificationScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/capture-id",
          page: () => const CaptureIdScreen(isFront: true),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/id-tips",
          page: () => const IdCaptureTipsScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/id-status",
          page: () => const IdStatusScreen(),
          middlewares: [AuthMiddleware()],
        ),

        /// ---------------- TOOLS ---------------------
        GetPage(
          name: "/safety-tools",
          page: () => const SafetyToolsScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/invite",
          page: () => const InviteFriendsScreen(),
          middlewares: [AuthMiddleware()],
        ),

        /// ---------------- LOCATIONS -----------------
        GetPage(
          name: "/location-search",
          page: () => const LocationSearchScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/edit-address",
          page: () => const EditAddressScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: "/add-work",
          page: () => const AddWorkScreen(),
          middlewares: [AuthMiddleware()],
        ),
      ],
    );
  }
}