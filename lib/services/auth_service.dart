import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends GetxService {
  final _isLoggedIn = true.obs;
  final _token = ''.obs;
  final _email = ''.obs;
  final _username = ''.obs;

  // ValueNotifier for ValueListenableBuilder
  static final ValueNotifier<bool> loginState = ValueNotifier<bool>(false);

  // GETTERS
  bool get isLoggedIn => _isLoggedIn.value;
  String get token => _token.value;
  String get email => _email.value;
  String get username => _username.value;

  @override
  void onInit() {
    super.onInit();
    _loadAuthState();

    // Listen to changes in _isLoggedIn and sync with loginState
    ever(_isLoggedIn, (value) {
      loginState.value = value;
    });
  }

  /// Load auth state from SharedPreferences on app start
  Future<void> _loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isLoggedIn.value = prefs.getBool('isLoggedIn') ?? false;
      _token.value = prefs.getString('access_token') ?? '';
      _email.value = prefs.getString('email') ?? '';
      _username.value = prefs.getString('username') ?? 'User';

      // Update the static loginState
      loginState.value = _isLoggedIn.value;

      if (_isLoggedIn.value) {
        debugPrint('✅ Auth state loaded - User is logged in');
        debugPrint('   Email: $_email');
        debugPrint(
          '   Token: ${_token.value.isNotEmpty ? "${_token.value.substring(0, 20)}..." : "NONE"}',
        );
      } else {
        debugPrint('ℹ️ Auth state loaded - User is NOT logged in');
      }
    } catch (e) {
      debugPrint('❌ Error loading auth state: $e');
    }
  }

  /// CALL THIS AFTER LOGIN API SUCCESS
  /// Pass the actual token returned from your API
  Future<void> login(String email, String token, {String? username}) async {
    try {
      debugPrint('🔐 Saving login state...');
      debugPrint('   Email: $email');
      debugPrint('   Token: ${token.substring(0, 20)}...');

      _isLoggedIn.value = true;
      _token.value = token;
      _email.value = email;
      _username.value = username ?? email.split('@')[0];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('access_token', token);
      await prefs.setString('email', email);
      await prefs.setString('username', _username.value);

      debugPrint('✅ Login state saved successfully');

      // loginState.value will be updated automatically via the ever() listener
    } catch (e) {
      debugPrint('❌ Error saving login state: $e');
      rethrow;
    }
  }

  /// CALL THIS ON LOGOUT
  Future<void> logout() async {
    try {
      debugPrint('🔐 Logging out...');

      _isLoggedIn.value = false;
      _token.value = '';
      _email.value = '';
      _username.value = '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all SharedPreferences

      debugPrint('✅ Logout successful - all data cleared');

      Get.offAllNamed('/login');
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    await _loadAuthState();
    return _isLoggedIn.value && _token.value.isNotEmpty;
  }
}

/// Initialize AuthService
Future<AuthService> initAuthService() async {
  Get.put(AuthService());
  return Get.find<AuthService>();
}
