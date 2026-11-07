import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:syami/controller/load_errors.dart';
import 'package:syami/controller/locator.dart';

void main() {
  group('mostCommonName', () {
    test('picks the name most results agree on', () {
      expect(
        mostCommonName(['Abu Dhabi', 'Al Reem', 'Abu Dhabi']),
        'Abu Dhabi',
      );
    });

    test('ignores empty and missing names instead of returning a blank', () {
      // What the geocoder returns for central Newcastle upon Tyne.
      expect(mostCommonName(['', '', null, '  ', 'Newcastle']), 'Newcastle');
      expect(mostCommonName(['', '', '', '', '']), isNull);
      expect(mostCommonName(<String?>[]), isNull);
    });

    test('keeps the first name on a tie', () {
      expect(mostCommonName(['Sarajevo', 'Ilidza']), 'Sarajevo');
    });
  });

  group('getCityFromPosition', () {
    final newcastle = Position(
      latitude: 54.9783,
      longitude: -1.6178,
      timestamp: DateTime(2026),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

    test('falls back to the wider area when no result has a city', () async {
      final place = await getCityFromPosition(
        newcastle,
        lookup: (_, __) async => List.filled(
          5,
          Placemark(
            locality: '',
            subAdministrativeArea: 'Tyne and Wear',
            country: 'United Kingdom',
          ),
        ),
      );
      expect(place, {'city': 'Tyne and Wear', 'country': 'United Kingdom'});
    });

    test('gives up on a geocoder that never answers', () async {
      final never = Completer<List<Placemark>>().future;
      Object? error;
      try {
        await getCityFromPosition(
          newcastle,
          timeout: const Duration(milliseconds: 50),
          lookup: (_, __) => never,
        );
      } catch (e) {
        error = e;
      }
      expect(error, isA<TimeoutException>());
      expect(describeLoadError(error!), contains('internet connection'));
    });
  });
}
