import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocationService {
  static const String _apiKey = "AIzaSyAtGcgY_MayhcKQRUJRTRoV5d3vvxOYOwQ";

  /// =====================================================
  /// CURRENT LOCATION
  /// =====================================================
  static Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// =====================================================
  /// GET ADDRESS FROM COORDINATES
  /// =====================================================
  static Future<String> getAddressFromCoordinates(double lat, double lng) async {
    // Native geocoding on Android/iOS — no API key required
    if (!kIsWeb) {
      try {
        final placemarks = await geo.placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.name,
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ].where((s) => s != null && s.isNotEmpty).map((s) => s!).toList();
          if (parts.isNotEmpty) return parts.join(', ');
        }
      } catch (e) {
        debugPrint('Native geocoding failed, trying API: $e');
      }
    }

    // Fallback: Google Geocoding API (web, or if native fails)
    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json"
            "?latlng=$lat,$lng&key=$_apiKey",
      );
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      final data = jsonDecode(res.body);
      if (data["status"] == "OK" && (data["results"] as List).isNotEmpty) {
        return data["results"][0]["formatted_address"];
      }
      debugPrint('Geocoding API status: ${data["status"]}');
    } catch (e) {
      debugPrint('Geocoding API error: $e');
    }

    return '$lat, $lng'; // Last resort: show raw coordinates
  }

  /// =====================================================
  /// AUTOCOMPLETE SEARCH → returns List<Map<String,dynamic>>
  /// =====================================================
  static Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/autocomplete/json"
          "?input=$query&key=$_apiKey&components=country:in",
    );

    final res = await http.get(url);
    final data = jsonDecode(res.body);

    if (!data.containsKey("predictions")) return [];

    return List<Map<String, dynamic>>.from(
      data["predictions"].map((p) {
        return {
          "place_id": p["place_id"],
          "name": p["description"],
        };
      }),
    );
  }


  /// ==============================================
  /// CHECK PERMISSIONS
  /// ==============================================
  static Future<bool> checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// ==============================================
  /// POSITION STREAM (REAL-TIME LIVE TRACKING)
  /// ==============================================
  static Stream<Position> getPositionStream() {
    final LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "TrackMate – Trip in progress",
          notificationText: "Tracking your route in the background",
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }


  /// =====================================================
  /// PLACE DETAILS → returns {lat,lng,name}
  /// =====================================================
  static Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/details/json"
          "?place_id=$placeId&fields=name,geometry&key=$_apiKey",
    );

    final res = await http.get(url);
    final data = jsonDecode(res.body);

    if (!data.containsKey("result")) return {};

    final result = data["result"];
    final loc = result["geometry"]["location"];

    return {
      "name": result["name"],
      "lat": loc["lat"],
      "lng": loc["lng"],
    };
  }
}