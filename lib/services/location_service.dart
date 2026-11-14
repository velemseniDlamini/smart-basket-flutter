import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

enum LocationStatus { unknown, granted, denied, serviceDisabled }

class LocationResult {
  final LocationStatus status;
  final String? label;

  const LocationResult(this.status, [this.label]);
}

class LocationService {
  /// Returns the current location if permission was already granted, without
  /// prompting the user.
  static Future<LocationResult> currentIfGranted() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return const LocationResult(LocationStatus.unknown);
      }
      return await _resolve();
    } catch (_) {
      return const LocationResult(LocationStatus.unknown);
    }
  }

  /// Prompts for location permission (if needed) and resolves the location.
  static Future<LocationResult> request() async {
    try {
      if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(LocationStatus.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.denied);
      }
      return await _resolve();
    } catch (_) {
      return const LocationResult(LocationStatus.denied);
    }
  }

  static Future<LocationResult> _resolve() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LocationResult(LocationStatus.granted, await _label(position));
  }

  static Future<String> _label(Position position) async {
    // Reverse geocoding uses the device's own geocoder, which isn't available
    // on web, so fall back to coordinates there.
    if (!kIsWeb) {
      try {
        final places = await Geocoding().placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (places.isNotEmpty) {
          final place = places.first;
          final parts = [
            place.subLocality,
            place.locality,
          ].whereType<String>().where((part) => part.isNotEmpty).toSet();
          if (parts.isNotEmpty) return parts.join(', ');
        }
      } catch (_) {}
    }
    return '${position.latitude.toStringAsFixed(3)}, '
        '${position.longitude.toStringAsFixed(3)}';
  }
}
