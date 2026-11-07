import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:dio/dio.dart' as dio;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:syami/controller/classes.dart';
import 'package:syami/controller/load_errors.dart';
import 'package:syami/controller/locator.dart';
import 'package:timezone/timezone.dart' as tz;

class SearchEngine extends GetxController {
  String serverUrlApi = "https://api.aladhan.com/v1/";

  Rx<String> loadingState = Rx<String>("");

  /// True when the last load failed; [loadingState] then holds the message.
  RxBool loadFailed = false.obs;
  RxBool appLoaded = false.obs;
  RxString city = "".obs;
  RxString country = "".obs;
  RefreshController listRefresher = RefreshController(initialRefresh: false);

  late dio.Dio dioInter;

  RxList<DayPrayer> userPrayer = RxList<DayPrayer>();
  RxList<DayPrayer> meccaPrayer = RxList<DayPrayer>();

  Position meccaPosition = Position(
      speedAccuracy: 0,
      heading: 0,
      longitude: 39.826168,
      speed: 0,
      altitude: 0,
      latitude: 21.422510,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
      timestamp: DateTime.now(),
      accuracy: 0);
  Position? userPosition;

  @override
  Future<void> onReady() async {
    dioInter = dio.Dio();
    dioInter.options.connectTimeout = const Duration(seconds: 5);
    dioInter.interceptors.add(RetryInterceptor(
      dio: dioInter,
      // Retry logs are for debugging only, not for release logcat.
      logPrint: kDebugMode ? print : null,
      retries: 3,
      retryDelays: const [
        // set delays between retries (optional)
        Duration(seconds: 1), // wait 1 sec before first retry
        Duration(seconds: 2), // wait 2 sec before second retry
        Duration(seconds: 3), // wait 3 sec before third retry
      ],
    ));
    appLoaded.value = true;
    await getPrayerTimes();
  }

  Future<dynamic> getApiForPosition(Position pos, int month, int year) async {
    String urlDone =
        "${serverUrlApi}calendar/$year/$month?latitude=${pos.latitude}&longitude=${pos.longitude}&iso8601=true";
    if (kDebugMode) {
      print(urlDone);
    }
    dio.Response response = await loadLink(urlDone);
    if (response.statusCode == 200) {
      return response.data["data"];
    }
  }

  Future<dio.Response> loadLink(
    String? url, {
    Map<String, String>? param,
    Map<String, String>? headers,
  }) async {
    return await dioInter.get(url!,
        queryParameters: param,
        options: dio.Options(
          headers: headers,
          followRedirects: true,
          receiveDataWhenStatusError: true,
        ));
  }

  Future<void> getUserLocation() async {
    final (position, place) = await locate();
    userPosition = position;
    city.value = place.city;
    country.value = place.country;
  }

  /// Reads the device position and names its city and country, without
  /// changing what the screen shows.
  Future<(Position, ({String city, String country}))> locate(
      {bool fresh = false}) async {
    loadingState.value = "Getting your location";
    final position = await determinePosition(getNew: fresh);
    final location = await getCityFromPosition(position);
    if (kDebugMode) {
      print(location);
    }
    return (
      position,
      (
        city: location["city"] ?? "Unknown",
        country: location["country"] ?? "Unknown",
      )
    );
  }

  /// True while [updateLocation] runs; the list stays on screen meanwhile.
  RxBool updatingLocation = false.obs;

  /// Loads the next month (the current one on first load), and keeps going
  /// until at least five days are listed.
  Future<void> getPrayerTimes() async {
    loadFailed.value = false;
    try {
      // Fetch user location if needed
      if (userPosition == null) {
        await getUserLocation();
      }
      loadingState.value = "Getting prayer times for ${placeName()}";
      await loadMonths(userPosition!, userPrayer, meccaPrayer);
      if (kDebugMode) {
        print("DONE LOADING PRAYER TIMES");
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      loadingState.value = describeLoadError(e);
      loadFailed.value = true;
    }
  }

  /// Re-reads the device location and reloads from today for it.
  ///
  /// The current list stays on screen until the new one is ready. If
  /// anything fails, the old list, place and position are kept and the
  /// error is returned as a message for the user (null on success). It used
  /// to clear the list first, so a failure left only an error screen.
  Future<String?> updateLocation() async {
    if (updatingLocation.value) return null;
    updatingLocation.value = true;
    try {
      final (position, place) = await locate(fresh: true);
      final user = <DayPrayer>[];
      final mecca = <DayPrayer>[];
      await loadMonths(position, user, mecca);
      // Swap everything in one go, so the header, labels and days always
      // belong to the same place.
      userPosition = position;
      city.value = place.city;
      country.value = place.country;
      userPrayer.assignAll(user);
      meccaPrayer.assignAll(mecca);
      update();
      return null;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return describeLoadError(e);
    } finally {
      updatingLocation.value = false;
    }
  }

  String placeName() => city.value == "Unknown" || city.value.isEmpty
      ? country.value
      : city.value;

  /// Appends the month after the last day in [user] (or the current month)
  /// for [position] and Mecca, repeating until [user] has five days.
  Future<void> loadMonths(
      Position position, List<DayPrayer> user, List<DayPrayer> mecca) async {
    // At most three months: the current month always has today in it, so
    // this only guards against an API answer with no usable days.
    var months = 0;
    do {
      final (month, year) = getNextMonthAndYearFromPrayers(user);
      final userPrayerTimes = await getApiForPosition(position, month, year);
      final meccaPrayerTimes =
          await getApiForPosition(meccaPosition, month, year);
      processPrayerTimes(userPrayerTimes, user);
      processPrayerTimes(meccaPrayerTimes, mecca);
    } while (user.length < 5 && ++months < 3);
  }

  /// Adds the days in [prayerTimes] (one aladhan.com calendar month) to
  /// [prayersList], skipping days before today.
  void processPrayerTimes(
      List<dynamic> prayerTimes, List<DayPrayer> prayersList,
      {DateTime? now}) {
    tz.Location timeZone = tz.getLocation(prayerTimes[0]["meta"]["timezone"]);
    final today = now ?? DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    for (var times in prayerTimes) {
      DayPrayer dayPrayer = DayPrayer(
          times["date"]["gregorian"]["date"],
          times["date"]["gregorian"]["format"],
          times["date"]["gregorian"]["weekday"]["en"],
          times["timings"]["Fajr"],
          times["timings"]["Dhuhr"],
          times["timings"]["Asr"],
          times["timings"]["Maghrib"],
          times["timings"]["Isha"],
          timeZone);

      // Compare whole dates: checking only the month and day dropped the
      // first days of this month a year later (e.g. 1-6 November 2027 when
      // today is 7 November 2026).
      if (!dayPrayer.date.isBefore(startOfToday)) {
        prayersList.add(dayPrayer);
      }
    }
  }

  (int month, int year) getNextMonthAndYearFromPrayers(
      List<DayPrayer> prayers) {
    if (prayers.isEmpty) {
      // Handle the case where there are no prayers in the list
      final now = DateTime.now();
      // If no prayers, return the current month and year as is
      return (now.month, now.year);
    }

    // Get the date of the last prayer in the list
    DateTime lastDate = prayers.last.date;

    int nextMonth;
    int nextYear;

    if (lastDate.month == 12) {
      // If the last date is in December, increment the year and reset the month to January
      nextMonth = 1;
      nextYear = lastDate.year + 1;
    } else {
      // Otherwise, just increment the month
      nextMonth = lastDate.month + 1;
      nextYear = lastDate.year;
    }

    return (nextMonth, nextYear);
  }

  Future<void> loadMoreMonth() async {
    // While Update location runs, the list is about to be replaced; adding a
    // month for the old place would mix two places in one list.
    if (!updatingLocation.value) await getPrayerTimes();
    listRefresher.loadComplete();
  }
}
