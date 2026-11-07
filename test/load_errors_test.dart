import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:syami/controller/load_errors.dart';

void main() {
  group('describeLoadError', () {
    test('explains a missing connection instead of printing DioException', () {
      final error = DioException.connectionError(
        requestOptions: RequestOptions(path: 'https://api.aladhan.com/v1/'),
        reason: "Failed host lookup: 'api.aladhan.com'",
      );
      final message = describeLoadError(error);
      expect(message, contains('internet connection'));
      expect(message, isNot(contains('DioException')));
      expect(message, isNot(contains('aladhan')));
    });

    test('explains a bad server answer', () {
      final error = DioException.badResponse(
        statusCode: 500,
        requestOptions: RequestOptions(path: '/'),
        response: Response(requestOptions: RequestOptions(path: '/')),
      );
      expect(describeLoadError(error), contains('try again in a few minutes'));
    });

    test('tells the user to turn location on', () {
      expect(
        describeLoadError(const LocationServiceDisabledException()),
        "Couldn't read your location. Check that location is on, then tap Try again.",
      );
    });

    test('drops the "Exception: " prefix from the app\'s own messages', () {
      expect(describeLoadError(Exception(locationPermissionDenied)),
          locationPermissionDenied);
    });

    test('never shows raw text for unknown errors', () {
      expect(
        describeLoadError(StateError('Bad state: no element')),
        isNot(contains('Bad state')),
      );
    });
  });
}
