import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trackmate_app/services/auth_service.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthService>();
    if (!auth.isLoggedIn) {
      return const RouteSettings(name: '/login');
    }
    return null;
  }
}
