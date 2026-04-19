import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DirectionsService {
  final String? apiKey = dotenv.env['directions_api_key'];

  Future<Map<String, dynamic>?> getDirections(
      String origin, String destination) async {
    if (apiKey == null) {
      debugPrint('ERROR: directions_api_key not found in .env file');
      return null;
    }

    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'OK') {
          return jsonResponse['routes'][0];
        }
      }
    } catch (e) {
      debugPrint('Error fetching directions: $e');
    }
    return null;
  }
}