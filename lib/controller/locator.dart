import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:syami/controller/load_errors.dart';

/// Determine the current position of the device.
///
/// When the location services are not enabled or permissions
/// are denied the `Future` will return an error.
Future<Position> determinePosition({bool getNew = false}) async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    throw Exception('Location is turned off. Turn it on, then tap Try again.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      throw Exception(locationPermissionDenied);
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    throw Exception("Location access is blocked for Syami. Allow it in your "
        "phone's Settings, then tap Try again.");
  }
  Position? lastKnown = await Geolocator.getLastKnownPosition();
  if (lastKnown != null && !getNew) {
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return lastKnown;
  } else {
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}

/// The name that appears most often in [names], ignoring empty ones, or
/// null when there is none. Ties go to the name seen first.
String? mostCommonName(Iterable<String?> names) {
  final counts = <String, int>{};
  for (final raw in names) {
    final name = raw?.trim() ?? "";
    if (name.isEmpty) continue;
    counts[name] = (counts[name] ?? 0) + 1;
  }
  String? best;
  var bestCount = 0;
  counts.forEach((name, count) {
    if (count > bestCount) {
      best = name;
      bestCount = count;
    }
  });
  return best;
}

Future<Map<String, String>> getCityFromPosition(Position pos) async {
  List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
    pos.latitude,
    pos.longitude,
  );
  // The geocoder can return an empty locality for every result (central
  // Newcastle upon Tyne does). Counting those empty names made the city
  // blank, so fall back to the wider area instead.
  final city = mostCommonName(placemarks.map((p) => p.locality)) ??
      mostCommonName(placemarks.map((p) => p.subAdministrativeArea)) ??
      mostCommonName(placemarks.map((p) => p.administrativeArea));
  final country = mostCommonName(placemarks.map((p) => p.country));
  return {
    if (city != null) "city": city,
    if (country != null) "country": country,
  };
}
