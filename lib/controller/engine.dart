import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:dio/dio.dart' as dio;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:syami/controller/classes.dart';
import 'package:syami/controller/locator.dart';
import 'package:timezone/timezone.dart' as tz;

class SearchEngine extends GetxController {
  String serverUrlApi = "https://api.aladhan.com/v1/";

  Rx<String> loadingState = Rx<String>("");
  RxBool appLoaded = false.obs;
  RxString city = "".obs;
  RxString country = "".obs;
  RefreshController listRefresher = RefreshController(initialRefresh: false);

  dio.CancelToken token = dio.CancelToken();
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
  void dispose() {
    //  flutterWebviewPlugin.dispose();
    // _onStateChanged.cancel();
    super.dispose();
  }

  @override
  Future<void> onReady() async {
    //setCatcherLogsPath();

    dioInter = dio.Dio();
    dioInter.options.connectTimeout = const Duration(seconds: 5);
    dioInter.interceptors.add(RetryInterceptor(
      dio: dioInter,
      logPrint: print,
      retries: 3,
      // retry count (optional)
      retryDelays: const [
        // set delays between retries (optional)
        Duration(seconds: 1), // wait 1 sec before first retry
        Duration(seconds: 2), // wait 2 sec before second retry
        Duration(seconds: 3), // wait 3 sec before third retry
      ],
    ));
    appLoaded.value = true;
    await getPrayerTimes();

    //update();
    //afterLoading();
  }

  Future<dynamic> getApiForPosition(Position pos, int month, int year) async {
    List<dynamic>? jsonResponse = [];
    String urlDone =
        "${serverUrlApi}calendar?latitude=${pos.latitude}&longitude=${pos.longitude}&month=$month&year=$year&iso8601=true";
    print(urlDone);
    dio.Response response = await loadLink(urlDone);
    //print(response.data);
    if (response.statusCode == 200) {
      //print(response.data);
      jsonResponse = response.data["data"];
      return jsonResponse;
      //print(jsonResponse);
    }
  }

  Future<dio.Response> loadLink(
    String? url, {
    Map<String, String>? param,
    Map<String, String>? headers,
  }) async {
    /*
    dio.BaseOptions(

        headers: headers,
        connectTimeout: 5000,
        followRedirects: true,
        receiveDataWhenStatusError: true,*/
    return await dioInter.get(url!,
        queryParameters: param,
        options: dio.Options(
          headers: headers,
          followRedirects: true,
          receiveDataWhenStatusError: true,
        ));
  }

  Future<void> getUserLocation({bool getNewLocation = false}) async {
    loadingState.value = "Getting your location";
    userPosition = await determinePosition(getNew: getNewLocation);
    Map<String, String> location = await getCityFromPosition(userPosition!);
    print(location);
    city.value = location["city"] ?? "Unknown";
    country.value = location["country"] ?? "Unknown";
  }

  Future<void> getPrayerTimes({bool getNewLocation = false}) async {
    try {
      // Clear data if fetching for a new location
      if (getNewLocation) {
        userPrayer.clear();
        meccaPrayer.clear();
      }
      int month, year;
      (month, year) = getNextMonthAndYearFromPrayers(userPrayer);
      // Fetch user location if needed
      if (userPosition == null || getNewLocation) {
        print("FETCHING NEW LOCATION");
        await getUserLocation(getNewLocation: getNewLocation);
      }

      loadingState.value =
          "Getting prayer times for ${city.value == "Unknown" || city.value.isEmpty ? country.value : city.value}";

      // Fetch prayer times
      var userPrayerTimes = await getApiForPosition(userPosition!, month, year);
      var meccaPrayerTimes =
          await getApiForPosition(meccaPosition, month, year);

      processPrayerTimes(userPrayerTimes, userPrayer);
      processPrayerTimes(meccaPrayerTimes, meccaPrayer);

      // Check for date alignment
      if (meccaPrayer.isNotEmpty &&
          userPrayer.isNotEmpty &&
          meccaPrayer[0].date != userPrayer[0].date) {
        print("DATES ARE NOT ALIGNED");
      }

      // Check if further pagination is needed
      if (userPrayer.length < 5) {
        await getPrayerTimes();
      }
      print("DONE LOADING PRAYER TIMES");
    } catch (e) {
      print(e);
      loadingState.value = e.toString();
    }
  }

  void processPrayerTimes(
      List<dynamic> prayerTimes, List<DayPrayer> prayersList) {
    tz.Location timeZone = tz.getLocation(prayerTimes[0]["meta"]["timezone"]);

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

      // Add prayer times for current and future dates
      if (dayPrayer.date.month == DateTime.now().month) {
        if (dayPrayer.date.day >= DateTime.now().day) {
          prayersList.add(dayPrayer);
        }
      } else {
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
    await getPrayerTimes();
    listRefresher.loadComplete();
  }
}
