import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trackmate_app/services/api_service.dart';

class StatsService {
  static const String baseUrl = "http://13.60.63.106/";

  /// We will reuse api_service token system
  final ApiService api = ApiService();

  /// --------------------------------------------
  /// Get Token (always Bearer)
  /// --------------------------------------------
  Future<String?> _getToken() async {
    await api.loadTokens(); // REQUIRED: Load from SharedPreferences

    final token = api.accessToken;
    if (token == null || token.isEmpty) {
      debugPrint("❌ [StatsService] No access token found");
      return null;
    }

    debugPrint("🔐 [StatsService] Using Bearer token: ${token.substring(0, 12)}...");
    return token;
  }

  /// --------------------------------------------
  /// GET DAILY SCORE
  /// --------------------------------------------
  Future<Map<String, dynamic>?> getDailyScore({String? date}) async {
    final token = await _getToken();
    if (token == null) return null;

    final uri = Uri.parse(
      date == null
          ? "${baseUrl}api/trips/stats/daily-score/"
          : "${baseUrl}api/trips/stats/daily-score/?date=$date",
    );

    final res = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint("📡 [Daily Score] Status: ${res.statusCode}");
    debugPrint("📦 Response: ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  /// --------------------------------------------
  /// GET CALENDAR STATS
  /// --------------------------------------------
  Future<Map<String, dynamic>?> getCalendarStats({
    int? month,
    int? year,
  }) async {
    final token = await _getToken();
    if (token == null) return null;

    final uri = Uri.parse(
      "${baseUrl}api/trips/stats/calendar-stats/"
          "?month=${month ?? DateTime.now().month}"
          "&year=${year ?? DateTime.now().year}",
    );

    final res = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint("📡 [Calendar Stats] Status: ${res.statusCode}");
    debugPrint("📦 Response: ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  /// --------------------------------------------
  /// GET MONTHLY CHART
  /// --------------------------------------------
  Future<Map<String, dynamic>?> getMonthlyChart({
    int? month,
    int? year,
  }) async {
    final token = await _getToken();
    if (token == null) return null;

    final uri = Uri.parse(
      "${baseUrl}api/trips/stats/monthly-chart/"
          "?month=${month ?? DateTime.now().month}"
          "&year=${year ?? DateTime.now().year}",
    );

    final res = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint("📡 [Monthly Chart] Status: ${res.statusCode}");
    debugPrint("📦 Response: ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }
}
