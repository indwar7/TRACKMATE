import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GooglePlacesService {
  // Replace with your actual Google Places API key
  static const String apiKey = 'AIzaSyCvuze7W6e4S_5bSAEuX9K0GJCPMvvVNTQ';
  static const String baseUrl = 'https://maps.googleapis.com/maps/api/place';

  Future<List<dynamic>> searchPlaces(String query) async {
    try {
      final url = Uri.parse(
          '$baseUrl/autocomplete/json?input=$query&key=$apiKey&components=country:in'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['predictions'] ?? [];
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error in searchPlaces: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
          '$baseUrl/details/json?place_id=$placeId&key=$apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error in getPlaceDetails: $e');
      return null;
    }
  }
}