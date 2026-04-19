import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class LocationSearchWidget extends StatefulWidget {
  final String label;
  final String? initialValue;
  final Function(LatLng location, String address) onLocationSelected;
  final Color accentColor;

  const LocationSearchWidget({
    super.key,
    required this.label,
    this.initialValue,
    required this.onLocationSelected,
    this.accentColor = const Color(0xFF00adb5),
  });

  @override
  State<LocationSearchWidget> createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends State<LocationSearchWidget> {
  final _searchController = TextEditingController();
  List<Location> _suggestions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _searchController.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final locations = await locationFromAddress(query);
      setState(() {
        _suggestions = locations.take(5).toList();
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _selectLocation(Location location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      String address = 'Unknown location';
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        address = '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }

      setState(() {
        _searchController.text = address;
        _suggestions = [];
      });

      widget.onLocationSelected(
        LatLng(location.latitude, location.longitude),
        address,
      );
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          onChanged: _searchLocation,
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            hintText: 'Search location...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: Icon(Icons.search, color: widget.accentColor),
            suffixIcon: _isSearching
                ? const SizedBox(
              width: 20,
              height: 20,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.white54),
              onPressed: () {
                _searchController.clear();
                setState(() => _suggestions = []);
              },
            )
                : null,
            filled: true,
            fillColor: const Color(0xFF16213e),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.accentColor),
            ),
          ),
        ),

        // Suggestions List
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.accentColor.withValues(alpha: 0.3)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => Divider(
                color: Colors.white.withValues(alpha: 0.1),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final location = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.location_on, color: widget.accentColor, size: 20),
                  title: Text(
                    'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  onTap: () => _selectLocation(location),
                );
              },
            ),
          ),
      ],
    );
  }
}