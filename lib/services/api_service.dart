import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://13.60.63.106/api";
  String? accessToken;
  String? refreshToken;

  /// =====================================================
  /// TOKEN MANAGEMENT
  /// =====================================================

  Future<void> loadTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      accessToken = prefs.getString("access_token");
      refreshToken = prefs.getString("refresh_token");

      // Also check isLoggedIn flag
      final isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

      if (accessToken != null && accessToken!.isNotEmpty) {
        final preview = accessToken!.length > 20
            ? accessToken!.substring(0, 20)
            : accessToken!;
        debugPrint('🔑 [ApiService] Token loaded: $preview... (isLoggedIn: $isLoggedIn)');
      } else {
        debugPrint('⚠️ [ApiService] NO TOKEN FOUND IN STORAGE (isLoggedIn: $isLoggedIn)');
        // Log what keys are available for debugging
        final keys = prefs.getKeys();
        debugPrint('   Available keys: ${keys.where((k) => k.contains("token") || k.contains("login")).toList()}');
      }
    } catch (e) {
      debugPrint('❌ [ApiService] Error loading tokens: $e');
    }
  }

  Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("access_token", access);
    await prefs.setString("refresh_token", refresh);
    accessToken = access;
    refreshToken = refresh;
    debugPrint('💾 [ApiService] Tokens saved successfully');
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
    accessToken = null;
    refreshToken = null;
    debugPrint('🗑️ [ApiService] Tokens cleared');
  }

  /// =====================================================
  /// HEADERS
  /// =====================================================

  Map<String, String> get headers {
    final headersMap = <String, String>{
      "Content-Type": "application/json",
    };
    
    if (accessToken != null && accessToken!.isNotEmpty) {
      // Backend expects Bearer format for JWT tokens
      headersMap["Authorization"] = "Bearer $accessToken";
    } else {
      debugPrint('⚠️ [headers getter] No access token available!');
    }
    
    return headersMap;
  }
  
  /// Get headers with explicit token - use this when you need to ensure token is included
  Map<String, String> getHeadersWithToken() {
    if (accessToken == null || accessToken!.isEmpty) {
      throw Exception("No access token available. Please login first.");
    }
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken",  // Backend uses Bearer
    };
  }

  /// Handle 401 Unauthorized responses - redirect to login
  Future<void> _handleUnauthorized() async {
    debugPrint('❌ [ApiService] 401 Unauthorized - Clearing tokens and redirecting to login');
    await clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Get.offAllNamed('/login');
  }

  /// Check response status and handle 401 — redirects to login
  Future<void> _checkResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await _handleUnauthorized();
      throw Exception("Session expired. Please login again.");
    }
  }

  /// Check 401 for trip endpoints — throws but does NOT redirect (tracking should continue)
  void _checkTripResponse(http.Response response) {
    if (response.statusCode == 401) {
      debugPrint('⚠️ [Trip API] 401 — no valid token, skipping');
      throw Exception("No auth token — trip API call skipped");
    }
  }

  /// =====================================================
  /// AUTH
  /// =====================================================

  Future<Map<String, dynamic>> signup({
    required String email,
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/signup/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "username": username,
        "password": password,
      }),
    );
    if (response.body.isEmpty) throw Exception('Empty response from server');
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['detail'] ?? data['message'] ?? 'Signup failed: ${response.statusCode}');
    }
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/verify/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "code": code,
      }),
    );
    if (response.body.isEmpty) throw Exception('Empty response from server');
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['detail'] ?? data['message'] ?? 'OTP verification failed: ${response.statusCode}');
    }
    return data as Map<String, dynamic>;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 [ApiService] Starting login...');

      final response = await http.post(
        Uri.parse("$baseUrl/auth/login/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      debugPrint('📡 [ApiService] Login Status: ${response.statusCode}');
      debugPrint('📦 [ApiService] Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract token from data["access"] or data["data"]["access"]
        String? token;
        if (data is Map<String, dynamic>) {
          if (data.containsKey("data") && data["data"] is Map<String, dynamic>) {
            token = data["data"]["access"];
          } else {
            token = data["access"];
          }
        }

        if (token == null || token.isEmpty) {
          debugPrint('❌ [ApiService] No access token in response');
          throw Exception("Could not find access token in login response");
        }

        // Save token to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("access_token", token);
        await prefs.setBool("isLoggedIn", true);
        accessToken = token;

        debugPrint('✅ [ApiService] Token saved: ${token.substring(0, 20)}...');
        return true;
      }

      debugPrint('❌ [ApiService] Login failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ [ApiService] Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('🔐 [ApiService] Starting logout...');

      if (refreshToken == null || refreshToken!.isEmpty) {
        debugPrint('⚠️ [ApiService] No refresh token, clearing locally');
        await clearTokens();
        return;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/auth/logout/"),
        headers: {
          "Content-Type": "application/json",
          if (accessToken != null && accessToken!.isNotEmpty)
            "Authorization": "Bearer $accessToken",  // Backend uses Bearer
        },
        body: jsonEncode({"refresh": refreshToken}),
      );

      debugPrint('📡 [ApiService] Logout Status: ${response.statusCode}');
      await clearTokens();

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ [ApiService] Logout successful');
      }
    } catch (e) {
      debugPrint('❌ [ApiService] Logout error: $e');
      await clearTokens();
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/forgot-password/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    if (response.body.isEmpty) throw Exception('Empty response from server');
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['detail'] ?? data['message'] ?? 'Request failed: ${response.statusCode}');
    }
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/reset-password/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "code": code,
        "new_password": newPassword,
      }),
    );
    if (response.body.isEmpty) throw Exception('Empty response from server');
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['detail'] ?? data['message'] ?? 'Password reset failed: ${response.statusCode}');
    }
    return data as Map<String, dynamic>;
  }

  /// =====================================================
  /// PROFILE
  /// =====================================================

  Future<Map<String, dynamic>> getProfile() async {
    await loadTokens();
    final response = await http.get(
      Uri.parse("$baseUrl/profile/"),
      headers: headers,
    );
    await _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? bio,
    String? homeLocation,
    String? workLocation,
    File? profileImage,
  }) async {
    await loadTokens();
    final request = http.MultipartRequest(
      "PUT",
      Uri.parse("$baseUrl/profile/"),
    );

    if (accessToken != null && accessToken!.isNotEmpty) {
      request.headers["Authorization"] = "Bearer $accessToken";  // Backend uses Bearer
    }

    if (fullName != null) request.fields["full_name"] = fullName;
    if (bio != null) request.fields["bio"] = bio;
    if (homeLocation != null) request.fields["home_location"] = homeLocation;
    if (workLocation != null) request.fields["work_location"] = workLocation;

    if (profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath("profile_image", profileImage.path),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    await _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getFullProfile() async {
    await loadTokens();
    final response = await http.get(
      Uri.parse("$baseUrl/profile/full/"),
      headers: headers,
    );
    await _checkResponse(response);
    return jsonDecode(response.body);
  }

  /// =====================================================
  /// CONTACTS
  /// =====================================================

  Future<Map<String, dynamic>> addContact({
    required String name,
    required String phone,
    required String relation,
  }) async {
    await loadTokens();
    final response = await http.post(
      Uri.parse("$baseUrl/profile/contacts/"),
      headers: headers,
      body: jsonEncode({
        "name": name,
        "phone_number": phone,
        "relation": relation,
      }),
    );
    await _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getContacts() async {
    await loadTokens();
    final response = await http.get(
      Uri.parse("$baseUrl/profile/contacts/"),
      headers: headers,
    );
    await _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<void> deleteContact(int id) async {
    await loadTokens();
    final response = await http.delete(
      Uri.parse("$baseUrl/profile/contacts/$id/"),
      headers: headers,
    );
    await _checkResponse(response);
  }

  /// =====================================================
  /// AADHAAR
  /// =====================================================

  Future<Map<String, dynamic>> uploadAadhaar({
    required File front,
    required File back,
  }) async {
    await loadTokens();
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/profile/aadhaar/"),
    );

    if (accessToken != null && accessToken!.isNotEmpty) {
      request.headers["Authorization"] = "Bearer $accessToken";  // Backend uses Bearer
    }

    request.files.add(
      await http.MultipartFile.fromPath("front_image", front.path),
    );
    request.files.add(
      await http.MultipartFile.fromPath("back_image", back.path),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    await _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAadhaar() async {
    await loadTokens();
    final response = await http.get(
      Uri.parse("$baseUrl/profile/aadhaar/"),
      headers: headers,
    );
    await _checkResponse(response);
    return jsonDecode(response.body);
  }

  /// =====================================================
  /// VEHICLE
  /// =====================================================

  Future<Map<String, dynamic>> updateVehicle({
    required String number,
    required String model,
    File? rcImage,
  }) async {
    await loadTokens();
    final request = http.MultipartRequest(
      "PATCH",
      Uri.parse("$baseUrl/profile/vehicle/"),
    );

    if (accessToken != null && accessToken!.isNotEmpty) {
      request.headers["Authorization"] = "Bearer $accessToken";  // Backend uses Bearer
    }

    request.fields["vehicle_number"] = number;
    request.fields["vehicle_model"] = model;

    if (rcImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath("rc_image", rcImage.path),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    await _checkResponse(response);
    return jsonDecode(response.body);
  }

  /// =====================================================
  /// LIVE TRIP TRACKING
  /// =====================================================

  Future<Map<String, dynamic>> startTrip({
    required double startLat,
    required double startLng,
    String? locationName,
  }) async {
    await loadTokens();

    debugPrint('🚀 [START TRIP] Token loaded: ${accessToken != null ? "YES" : "NO"}');

    // Round coordinates to 6 decimal places (backend requirement)
    final roundedLat = double.parse(startLat.toStringAsFixed(6));
    final roundedLng = double.parse(startLng.toStringAsFixed(6));

    debugPrint('📍 [START TRIP] Original coords: ($startLat, $startLng) -> Rounded: ($roundedLat, $roundedLng)');

    final response = await http.post(
      Uri.parse("$baseUrl/trips/start/"),
      headers: headers,
      body: jsonEncode({
        "start_latitude": roundedLat,
        "start_longitude": roundedLng,
        if (locationName != null) "start_location_name": locationName,
      }),
    );

    debugPrint('📡 [START TRIP] Status: ${response.statusCode}');
    debugPrint('📦 [START TRIP] Response Body: ${response.body}');

    // Handle 400 error for ongoing trip
    if (response.statusCode == 400) {
      try {
        final errorData = jsonDecode(response.body);
        
        // Check if it's an ongoing trip error
        if (errorData is Map<String, dynamic> && 
            errorData.containsKey('error') &&
            errorData['error'] == "You already have an ongoing trip" &&
            errorData.containsKey('ongoing_trip_id')) {
          
          final ongoingTripId = errorData['ongoing_trip_id'];
          final tripNumber = errorData['trip_number'] ?? 'Unknown';
          
          debugPrint('⚠️ [START TRIP] Ongoing trip detected! Trip ID: $ongoingTripId, Number: $tripNumber');
          
          // Return the ongoing trip data as if it were a successful start
          return {
            'id': ongoingTripId is int ? ongoingTripId : int.tryParse(ongoingTripId.toString()),
            'ongoing_trip': true,
            'trip_number': tripNumber,
          };
        }
      } catch (e) {
        debugPrint('❌ [START TRIP] Error parsing 400 response: $e');
      }
    }

    _checkTripResponse(response);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('✅ [START TRIP] Response parsed: $data');
      
      // Extract trip ID - handle different response formats
      if (data is Map<String, dynamic>) {
        // Try nested trip.id first (normal case)
        if (data.containsKey('trip') && 
            data['trip'] is Map<String, dynamic> && 
            (data['trip'] as Map<String, dynamic>).containsKey('id')) {
          final tripData = data['trip'] as Map<String, dynamic>;
          final id = tripData['id'];
          debugPrint('✅ [START TRIP] Trip ID found in nested trip: $id (type: ${id.runtimeType})');
        }
        // Try direct id
        else if (data.containsKey('id')) {
          final id = data['id'];
          debugPrint('✅ [START TRIP] Trip ID found: $id (type: ${id.runtimeType})');
        } 
        // Try trip_id
        else if (data.containsKey('trip_id')) {
          debugPrint('✅ [START TRIP] Trip ID found as trip_id: ${data['trip_id']}');
        } 
        else {
          debugPrint('⚠️ [START TRIP] No trip ID in response. Available keys: ${data.keys.toList()}');
          if (data.containsKey('trip')) {
            debugPrint('   Trip object keys: ${(data['trip'] as Map).keys.toList()}');
          }
        }
      }
      
      return data;
    } else {
      throw Exception(
          'Failed to start trip: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>> addTrackingPoint({
    required int tripId,
    required double lat,
    required double lng,
    required double accuracy,
    double? speed,
    String? timestamp,
  }) async {
    await loadTokens();

    // Round coordinates to 6 decimal places (backend requirement)
    final roundedLat = double.parse(lat.toStringAsFixed(6));
    final roundedLng = double.parse(lng.toStringAsFixed(6));

    final body = {
      "latitude": roundedLat,
      "longitude": roundedLng,
      "accuracy": accuracy,
      if (speed != null) "speed": speed,
      if (timestamp != null) "timestamp": timestamp,
    };

    final requestHeaders = <String, String>{
      "Content-Type": "application/json",
      if (accessToken != null && accessToken!.isNotEmpty)
        "Authorization": "Bearer $accessToken",
    };
    
    debugPrint('📤 [addTrackingPoint] Token: ${accessToken != null ? "${accessToken!.substring(0, 20)}..." : "none"}');

    final response = await http.post(
      Uri.parse("$baseUrl/trips/$tripId/add-tracking-point/"),
      headers: requestHeaders,
      body: jsonEncode(body),
    );

    _checkTripResponse(response);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add tracking point: ${response.statusCode}');
    }
  }

  /// =====================================================
  /// END TRIP - CRITICAL FIX
  /// =====================================================
  /// =====================================================
  Future<Map<String, dynamic>> endTrip({
    required int tripId,
    required double endLat,
    required double endLng,
    String? endLocationName,
    String? modeOfTravel,
    String? tripPurpose,
    int? companions,
    List<Map<String, String>>? companionDetails, // ✅ NEW: Companion details
    double? fuelExpense,
    double? parkingCost,
    double? tollCost,
    double? ticketCost,
  }) async {
    try {
      debugPrint('🚗 [END TRIP] ======================================');
      debugPrint('🚗 [END TRIP] Starting endTrip for ID: $tripId');

      await loadTokens();

      // Round coordinates to 6 decimal places (backend requirement)
      final roundedEndLat = double.parse(endLat.toStringAsFixed(6));
      final roundedEndLng = double.parse(endLng.toStringAsFixed(6));

      // STEP 2: Build request body exactly as API expects
      final body = {
        "end_latitude": roundedEndLat,
        "end_longitude": roundedEndLng,
        if (endLocationName != null && endLocationName.isNotEmpty)
          "end_location_name": endLocationName,
        if (modeOfTravel != null && modeOfTravel.isNotEmpty)
          "mode_of_travel": modeOfTravel,
        if (tripPurpose != null && tripPurpose.isNotEmpty)
          "trip_purpose": tripPurpose,
        if (companions != null)
          "number_of_companions": companions,
        // ✅ NEW: Add companion details if provided
        if (companionDetails != null && companionDetails.isNotEmpty)
          "companion_details": companionDetails,
        if (fuelExpense != null)
          "fuel_expense": fuelExpense,
        if (parkingCost != null)
          "parking_cost": parkingCost,
        if (tollCost != null)
          "toll_cost": tollCost,
        if (ticketCost != null)
          "ticket_cost": ticketCost,
      };

      debugPrint('📤 [END TRIP] URL: $baseUrl/trips/$tripId/end/');
      debugPrint('📤 [END TRIP] Headers: $headers');
      debugPrint('📤 [END TRIP] Body: ${jsonEncode(body)}');

      // ✅ NEW: Log companion details if present
      if (companionDetails != null && companionDetails.isNotEmpty) {
        debugPrint('👥 [END TRIP] Companion Details Count: ${companionDetails.length}');
        for (int i = 0; i < companionDetails.length; i++) {
          debugPrint('👥 [END TRIP] Companion ${i + 1}: ${companionDetails[i]}');
        }
      }

      // STEP 3: Make the API call
      final response = await http.post(
        Uri.parse("$baseUrl/trips/$tripId/end/"),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('📡 [END TRIP] Status Code: ${response.statusCode}');
      debugPrint('📦 [END TRIP] Response Body: ${response.body}');

      // STEP 4: Handle response
      _checkTripResponse(response);

      if (response.statusCode == 200) {
        debugPrint('✅ [END TRIP] SUCCESS! Trip ended successfully');
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        debugPrint('❌ [END TRIP] 404 Not Found - Trip may already be ended');
        throw Exception("Trip not found. It may have already been completed.");
      } else if (response.statusCode == 400) {
        debugPrint('❌ [END TRIP] 400 Bad Request');
        final errorData = jsonDecode(response.body);
        throw Exception("Invalid data: ${errorData.toString()}");
      } else {
        debugPrint('❌ [END TRIP] Error ${response.statusCode}');
        throw Exception("Failed to end trip: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ [END TRIP] EXCEPTION CAUGHT: $e");
      debugPrint("Stack trace: $stackTrace");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getOngoingTrip() async {
    await loadTokens();
    final response = await http.get(
      Uri.parse("$baseUrl/trips/ongoing/"),
      headers: headers,
    );

    // Handle 401 separately to redirect to login
    if (response.statusCode == 401) {
      await _handleUnauthorized();
      return null;
    }

    if (response.statusCode == 404 || response.statusCode == 403) {
      return null;
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded == null) return null;

      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('id') && _looksActive(decoded)) {
          return decoded;
        }
        if (decoded.containsKey('trip') &&
            decoded['trip'] is Map<String, dynamic>) {
          final trip = decoded['trip'] as Map<String, dynamic>;
          if (_looksActive(trip)) return trip;
        }
      }
      return null;
    }

    throw Exception('Failed to get ongoing trip: ${response.statusCode}');
  }

  bool _looksActive(Map<String, dynamic> trip) {
    if (trip.containsKey('status') && trip['status'] is String) {
      final s = (trip['status'] as String).toLowerCase();
      if (s == 'ongoing' || s == 'in_progress' || s == 'active') return true;
    }
    if (trip.containsKey('is_active')) {
      final ia = trip['is_active'];
      if (ia is bool && ia) return true;
      if (ia is String && ia.toLowerCase() == 'true') return true;
    }
    return false;
  }

  /// =====================================================
  /// TRIP HISTORY & DETAILS
  /// =====================================================

  Future<Map<String, dynamic>> getTripHistory({
    String? dateFrom,
    String? dateTo,
    String? mode,
    String? purpose,
    String? ordering,
  }) async {
    try {
      await loadTokens();

      final query = <String, String>{};
      if (dateFrom != null) query["date_from"] = dateFrom;
      if (dateTo != null) query["date_to"] = dateTo;
      if (mode != null) query["mode"] = mode;
      if (purpose != null) query["purpose"] = purpose;
      if (ordering != null) query["ordering"] = ordering;

      final uri = Uri.parse("$baseUrl/trips/history/").replace(
        queryParameters: query.isEmpty ? null : query,
      );

      final response = await http.get(uri, headers: headers);

      await _checkResponse(response); // This will handle 401 and redirect to login

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return {"count": data.length, "trips": data};
        }
        if (data is Map<String, dynamic>) {
          return data;
        }
        return {"count": 0, "trips": []};
      } else if (response.statusCode == 404) {
        return {"count": 0, "trips": []};
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ API Error in getTripHistory: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTripDetails(int id) async {
    await loadTokens();
    final response = await http.get(
      Uri.parse("$baseUrl/trips/$id/"),
      headers: headers,
    );

    await _checkResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get trip details: ${response.statusCode}');
    }
  }
  // Add this method to your existing ApiService class

  /// Update trip details (fuel, parking, toll costs)
  Future<Map<String, dynamic>> updateTripDetails({
    required int tripId,
    double? fuelExpense,
    double? parkingCost,
    double? tollCost,
  }) async {
    await loadTokens();

    if (accessToken == null || accessToken!.isEmpty) {
      throw Exception('No access token available');
    }

    final url = Uri.parse('$baseUrl/trips/$tripId/update-details/');

    // Build request body - only include non-null values
    final Map<String, dynamic> body = {};
    if (fuelExpense != null) body['fuel_expense'] = fuelExpense;
    if (parkingCost != null) body['parking_cost'] = parkingCost;
    if (tollCost != null) body['toll_cost'] = tollCost;

    debugPrint('🔄 Updating trip $tripId with: $body');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      debugPrint('📡 Update response status: ${response.statusCode}');
      debugPrint('📡 Update response body: ${response.body}');

      await _checkResponse(response); // Use existing error handler

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Trip updated successfully');
        return data;
      } else {
        throw Exception('Failed to update trip: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error updating trip: $e');
      rethrow;
    }
  }

  /// =====================================================
  /// MANUAL TRIPS
  /// =====================================================

  Future<Map<String, dynamic>> createManualTrip({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String? startLocation,
    String? endLocation,
    String? tripDate,
    String? modeOfTravel,
    String? tripPurpose,
    int? companions,
    double? fuelExpense,
    double? parkingCost,
    double? tollCost,
    double? ticketCost,
  }) async {
    await loadTokens();
    
    // Round coordinates to 6 decimal places (backend requirement)
    final roundedStartLat = double.parse(startLat.toStringAsFixed(6));
    final roundedStartLng = double.parse(startLng.toStringAsFixed(6));
    final roundedEndLat = double.parse(endLat.toStringAsFixed(6));
    final roundedEndLng = double.parse(endLng.toStringAsFixed(6));
    
    final body = {
      "start_latitude": roundedStartLat,
      "start_longitude": roundedStartLng,
      "end_latitude": roundedEndLat,
      "end_longitude": roundedEndLng,
      if (startLocation != null) "start_location": startLocation,
      if (endLocation != null) "end_location": endLocation,
      if (tripDate != null) "trip_date": tripDate,
      if (modeOfTravel != null) "mode_of_travel": modeOfTravel,
      if (tripPurpose != null) "trip_purpose": tripPurpose,
      if (companions != null) "number_of_companions": companions,
      if (fuelExpense != null) "fuel_expense": fuelExpense,
      if (parkingCost != null) "parking_cost": parkingCost,
      if (tollCost != null) "toll_cost": tollCost,
      if (ticketCost != null) "ticket_cost": ticketCost,
    };

    final response = await http.post(
      Uri.parse("$baseUrl/trips/create-manual/"),
      headers: headers,
      body: jsonEncode(body),
    );

    await _checkResponse(response);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to create manual trip: ${response.statusCode}');
    }
  }
// Add this method to your ApiService class

  Future<Map<String, dynamic>> previewRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String? startName,
    String? endName,
    String mode = "car",
  }) async {
    await loadTokens();

    if (accessToken == null || accessToken!.isEmpty) {
      throw Exception('No access token available');
    }

    // Round coordinates to 6 decimal places (backend requirement)
    final roundedStartLat = double.parse(startLat.toStringAsFixed(6));
    final roundedStartLng = double.parse(startLng.toStringAsFixed(6));
    final roundedEndLat = double.parse(endLat.toStringAsFixed(6));
    final roundedEndLng = double.parse(endLng.toStringAsFixed(6));

    final body = {
      "start_latitude": roundedStartLat,
      "start_longitude": roundedStartLng,
      "end_latitude": roundedEndLat,
      "end_longitude": roundedEndLng,
      "mode_of_travel": mode,
      if (startName != null) "start_location_name": startName,
      if (endName != null) "end_location_name": endName,
    };

    final response = await http.post(
      Uri.parse("$baseUrl/trips/preview-route/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to preview route: ${response.statusCode} - ${response.body}');
    }
  }
  /// =====================================================
  /// PLANNED TRIPS
  /// =====================================================

  Future<List<dynamic>> getPlannedTrips({
    String? status,
    String? ordering,
  }) async {
    await loadTokens();
    final query = <String, String>{};
    if (status != null) query["status"] = status;
    if (ordering != null) query["ordering"] = ordering;

    final uri = Uri.parse("$baseUrl/planned-trips/").replace(
      queryParameters: query.isEmpty ? null : query,
    );

    final response = await http.get(uri, headers: headers);

    await _checkResponse(response);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      return [];
    } else {
      throw Exception('Failed to get planned trips: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createPlannedTrip(
      Map<String, dynamic> data) async {
    await loadTokens();
    final response = await http.post(
      Uri.parse("$baseUrl/planned-trips/"),
      headers: headers,
      body: jsonEncode(data),
    );

    await _checkResponse(response);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to create planned trip: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getPlannedTripDetails(int id) async {
    await loadTokens();
    final response = await http.get(
      Uri.parse("$baseUrl/planned-trips/$id/"),
      headers: headers,
    );

    await _checkResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get planned trip: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updatePlannedTrip(
      int id, Map<String, dynamic> data) async {
    await loadTokens();
    final response = await http.patch(
      Uri.parse("$baseUrl/planned-trips/$id/"),
      headers: headers,
      body: jsonEncode(data),
    );

    await _checkResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to update planned trip: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> patchPlannedTrip(
      int id, Map<String, dynamic> data) async {
    await loadTokens();
    final response = await http.patch(
      Uri.parse("$baseUrl/planned-trips/$id/"),
      headers: headers,
      body: jsonEncode(data),
    );

    await _checkResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to patch planned trip: ${response.statusCode}');
    }
  }

  Future<void> deletePlannedTrip(int id) async {
    await loadTokens();
    final response = await http.delete(
      Uri.parse("$baseUrl/planned-trips/$id/"),
      headers: headers,
    );

    await _checkResponse(response);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
          'Failed to delete planned trip: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getUpcomingTrips() async {
    await loadTokens();
    final response = await http.get(
      Uri.parse("$baseUrl/planned-trips/upcoming/"),
      headers: headers,
    );

    await _checkResponse(response);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      return [];
    } else {
      throw Exception(
          'Failed to get upcoming trips: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> startPlannedTrip(
      int id, {
        double? lat,
        double? lng,
        String? name,
      }) async {
    await loadTokens();
    final body = {
      if (lat != null) "start_latitude": lat,
      if (lng != null) "start_longitude": lng,
      if (name != null) "start_location_name": name,
    };

    final response = await http.post(
      Uri.parse("$baseUrl/planned-trips/$id/start_trip/"),
      headers: headers,
      body: jsonEncode(body),
    );

    await _checkResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to start planned trip: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> cancelPlannedTrip(int id,
      {String? reason}) async {
    await loadTokens();
    final response = await http.post(
      Uri.parse("$baseUrl/planned-trips/$id/cancel/"),
      headers: headers,
      body: jsonEncode({
        if (reason != null) "reason": reason,
      }),
    );

    await _checkResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to cancel planned trip: ${response.statusCode}');
    }
  }

  /// =====================================================
  /// ANALYTICS / STATS
  /// =====================================================

  Future<Map<String, dynamic>> getDailyScore({String? date}) async {
    await loadTokens();
    final uri = Uri.parse("$baseUrl/trips/stats/daily-score/")
        .replace(queryParameters: date != null ? {"date": date} : null);

    final response = await http.get(uri, headers: headers);

    await _checkResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get daily score: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getCalendarStats({
    int? month,
    int? year,
  }) async {
    await loadTokens();
    final query = <String, String>{};
    if (month != null) query["month"] = "$month";
    if (year != null) query["year"] = "$year";

    final uri = Uri.parse("$baseUrl/trips/stats/calendar-stats/")
        .replace(queryParameters: query.isEmpty ? null : query);

    final response = await http.get(uri, headers: headers);

    await _checkResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to get calendar stats: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getMonthlyChartData({
    int? month,
    int? year,
  }) async {
    await loadTokens();
    final query = <String, String>{};
    if (month != null) query["month"] = "$month";
    if (year != null) query["year"] = "$year";

    final uri = Uri.parse("$baseUrl/trips/stats/monthly-chart/")
        .replace(queryParameters: query.isEmpty ? null : query);

    final response = await http.get(uri, headers: headers);

    await _checkResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to get monthly chart: ${response.statusCode}');
    }
  }
}