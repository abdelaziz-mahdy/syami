import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

/// Turns a failure while loading prayer times into a sentence for the user.
///
/// The screen used to print `error.toString()`, so people saw text such as
/// "DioException [connection error]: ... Failed host lookup:
/// 'api.aladhan.com' ... errno = 7".
String describeLoadError(Object error) {
  const offline = "Couldn't reach the prayer times service. "
      "Check your internet connection, then tap Try again.";
  if (error is LocationServiceDisabledException) {
    return "Couldn't read your location. Check that location is on, then tap Try again.";
  }
  if (error is PermissionDeniedException) {
    return locationPermissionDenied;
  }
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return offline;
      default:
        return "The prayer times service didn't answer properly. "
            "Please try again in a few minutes.";
    }
  }
  if (error is SocketException || error is TimeoutException) {
    return offline;
  }
  // Exceptions thrown by lib/controller/locator.dart are already written for
  // users; only drop Dart's "Exception: " prefix.
  final text = error.toString();
  if (error is Exception && text.startsWith("Exception: ")) {
    return text.substring("Exception: ".length);
  }
  return "Something went wrong while loading prayer times. "
      "Please tap Try again.";
}

const locationPermissionDenied =
    "Syami needs your location to show your prayer times. "
    "Tap Try again and allow location access.";
