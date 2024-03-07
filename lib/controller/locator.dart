import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

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
    throw Exception('Location services are disabled. Please enable it.');
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
      throw Exception('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.');
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

Future<Map<String, String>> getCityFromPosition(Position pos) async {
  Map<String, int> countCity = {};
  Map<String, int> countCountry = {};
  Map<String, String> returned = {};
  List<Placemark> placemarks = await placemarkFromCoordinates(
    pos.latitude,
    pos.longitude,
  );

  for (int i = 0; i < placemarks.length; i++) {
    if (countCity.containsKey(placemarks[i].locality)) {
      countCity[placemarks[i].locality!] =
          (countCity[placemarks[i].locality]! + 1);
    } else {
      countCity[placemarks[i].locality!] = 1;
    }
    if (countCountry.containsKey(placemarks[i].country)) {
      countCountry[placemarks[i].country!] =
          (countCountry[placemarks[i].country]! + 1);
    } else {
      countCountry[placemarks[i].country!] = 1;
    }
  }

  int thevalue = -1;
  String thekey = "";

  countCity.forEach((k, v) {
    if (v > thevalue) {
      thevalue = v;
      thekey = k;
    }
  });
  returned["city"] = thekey;

  thevalue = -1;
  thekey = "";
  countCountry.forEach((k, v) {
    if (v > thevalue) {
      thevalue = v;
      thekey = k;
    }
  });
  returned["country"] = thekey;
  return returned;
}
