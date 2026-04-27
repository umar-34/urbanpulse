import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String address;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationService {
  /// Request permission then fetch current GPS position.
  /// Returns [LocationResult] or throws a descriptive [String] error.
  static Future<LocationResult> getCurrentLocation() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled. Please enable GPS.';
    }

    // Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied. Enable it in Settings.';
    }

    // Get position
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    // Reverse geocode (cleaned)
    String address = '${position.latitude.toStringAsFixed(4)}, '
        '${position.longitude.toStringAsFixed(4)}';
    try {
      final parts = await reverseGeocodeParts(position.latitude, position.longitude);
      final area = parts['subLocality'] ?? '';
      final loc = parts['locality'] ?? '';
      if (area.isNotEmpty && loc.isNotEmpty) {
        address = '$area, $loc';
      } else if (loc.isNotEmpty) {
        address = loc;
      } else if (area.isNotEmpty) {
        address = area;
      }
    } catch (_) {
      // keep coordinates on failure
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
    );
  }

  /// Reverse geocode a lat/lon to a human-readable address.
  static Future<String> reverseGeocode(
      double latitude, double longitude) async {
    try {
      final parts = await reverseGeocodeParts(latitude, longitude);
      final area = parts['subLocality'] ?? '';
      final loc = parts['locality'] ?? '';
      if (area.isEmpty && loc.isEmpty) return '';
      if (area.isEmpty) return loc;
      if (loc.isEmpty) return area;
      return '$area, $loc';
    } catch (_) {
      return '';
    }
  }

  /// Returns map: { 'street': ..., 'subLocality': ..., 'locality': ... }
  /// Fields are cleaned: plus-code segments removed, trimmed, and de-duplicated.
  static Future<Map<String, String>> reverseGeocodeParts(
      double latitude, double longitude) async {
    final result = <String, String>{};
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return result;
      final p = placemarks.first;

      String takeSafe(String? s) {
        if (s == null) return '';
        var v = s.trim();
        if (v.isEmpty) return '';
        // remove any comma-separated tokens that contain '+' (plus-codes)
        final tokens = v.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
        final filtered = tokens.where((t) => !t.contains('+')).toList();
        return filtered.join(', ').trim();
      }

      final rawSub = takeSafe(p.subLocality);
      final rawThorough = takeSafe(p.thoroughfare);
      final rawStreet = takeSafe(p.street);
      final rawLocal = takeSafe(p.locality);

      // Decide street: prefer thoroughfare, then street, then empty
      final street = rawThorough.isNotEmpty ? rawThorough : rawStreet;
      // Decide subLocality: prefer subLocality
      var sub = rawSub;
      // If sub equals locality, ignore sub
      if (sub.isNotEmpty && rawLocal.isNotEmpty && sub.toLowerCase() == rawLocal.toLowerCase()) {
        sub = '';
      }

      result['street'] = street;
      result['subLocality'] = sub;
      result['locality'] = rawLocal;
      return result;
    } catch (_) {
      return result;
    }
  }
}
