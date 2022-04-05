import 'dart:io';
import 'dart:ui';

import 'package:catcher/catcher.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:dio/adapter.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:dio/dio.dart' as dio;
import 'package:path_provider/path_provider.dart';
import 'package:syami/constants/String%20constants.dart';
import 'package:syami/controller/classes.dart';
import 'package:syami/controller/locator.dart';
import 'package:syami/dialogs/update%20dialog.dart';
import 'package:version/version.dart';
import 'package:window_manager/window_manager.dart';
import 'package:geocoding/geocoding.dart';

class SearchEngine extends GetxController {
  late Catcher catcher;

  SearchEngine(Catcher catcher2) {
    catcher = catcher2;
  }

  String serverUrlApi = "http://api.aladhan.com/v1/";
  String appVersion = "1.0.3";
  List<UpdateVersion> releaseNotes = [];

  RxString loadingState = "".obs;
  RxString city = "".obs;
  RxString country = "".obs;

  dio.CancelToken token = dio.CancelToken();
  late dio.Dio dioInter;

  Version? latestVersion;
  List<DayPrayer> userPrayer = [];
  List<DayPrayer> meccaPrayer = [];
  Future<void> afterLoading() async {
    print("checkForUpdate()");
    //print(await determinePosition());
    //print();
    //getLocation();
    if (GetPlatform.isAndroid) {
      await checkForUpdate();
    }
    if (GetPlatform.isWindows) {
      await checkForUpdateWindows();
    }

    //update();
  }

  Future<void> getLocation() async {
    loadingState.value = "Getting Location";
    Map<String, String> location =
        await getCityFromPosition(await determinePosition());
    print(location);
    await getApiForLocation(location["city"]!, location["country"]!);
    print("###########################");
  }

//https://api.aladhan.com/v1/calendar?latitude=51.508515&longitude=-0.1254872
  Future<void> getApiForLocation(String city, String country) async {
    loadingState.value = "Getting Prayer Times";
    List<dynamic>? jsonResponse = [];
    String urlDone =
        serverUrlApi + "calendarByCity?city=$city&country=$country";
    dio.Response response = await loadLink(urlDone);
    //print(response.data);
    if (response.statusCode == 200) {
      //print(response.data);
      jsonResponse = response.data["data"];

      //print(jsonResponse);
    }
  }

  Future<dynamic> getApiForPosition(Position pos) async {
    loadingState.value = "Getting Prayer Times";
    List<dynamic>? jsonResponse = [];
    String urlDone = serverUrlApi +
        "calendar?latitude=${pos.latitude}&longitude=${pos.longitude}";
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
    try {
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
    } catch (_) {
      print("loadLink " + _.toString());
      if (_ is dio.DioError) {
        return _.response ??
            dio.Response(
                requestOptions: dio.RequestOptions(path: ''), statusCode: 1);
      } else {
        return dio.Response(
            requestOptions: dio.RequestOptions(path: ''), statusCode: 1);
      }
      //final response= dio.Response(requestOptions: null);
      //response.statusCode=987654;
      //return _;
    }
  }

  Future<void> checkForUpdate() async {
    await getServerVersion();
    Version currentVersion = jsonToVersion(appVersion);
    //int indexOfUpdate = -1;
    latestVersion = (latestVersion ?? jsonToVersion("0.0.0"));
    if (latestVersion! > currentVersion) {
      List<UpdateVersion> tmpList = [];
      for (int i = 0; i < releaseNotes.length; i++) {
        if (currentVersion < jsonToVersion(releaseNotes[i].version)) {
          tmpList.add(releaseNotes[i]);
        }
      }
      releaseNotes = tmpList;
      print("update is available");
      await updateDialog(latestVersion!);
    } else {
      print("you are up to date");
    }
  }

  Future<void> getServerVersion() async {
    String urlDone =
        "https://storage.googleapis.com/anime-293309.appspot.com/SyamiV0.json?avoidTheCaches=1";
    dio.Response response = await loadLink(urlDone);
    //print(response.data);
    List<dynamic>? jsonResponse = [];
    if (response.statusCode == 200) {
      jsonResponse = response.data;
      //print(jsonResponse);
      releaseNotes = [];
      for (int j = 0; j < jsonResponse!.length; j++) {
        releaseNotes.add(UpdateVersion(
            version: jsonResponse[j]["Version"],
            description: jsonResponse[j]["Release Notes"]));
        // add every element you get to be able to show it to the user
      }
      latestVersion = jsonToVersion(jsonResponse[0]["Version"]);
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
  }

  Future<void> getServerVersionWindows() async {
    String urlDone =
        "https://storage.googleapis.com/anime-293309.appspot.com/SyamiV1.json?avoidTheCaches=1";
    dio.Response response = await loadLink(urlDone);
    List<dynamic>? jsonResponse = [];
    //print(response.data);
    if (response.statusCode == 200) {
      jsonResponse = response.data;
      //print(jsonResponse);
      releaseNotes = [];
      for (int j = 0; j < jsonResponse!.length; j++) {
        releaseNotes.add(UpdateVersion(
            version: jsonResponse[j]["Version"],
            description: jsonResponse[j]["Release Notes"]));
        // add every element you get to be able to show it to the user
      }
      latestVersion = jsonToVersion(jsonResponse[0]["Version"]);
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
  }

  void launchDownloadLink() {
    String url = "";
    if (GetPlatform.isAndroid) {
      url = 'https://storage.googleapis.com/anime-293309.appspot.com/Syami.apk';
      //await checkForUpdate();
    }
    if (GetPlatform.isWindows) {
      url = 'https://storage.googleapis.com/anime-293309.appspot.com/Syami.exe';
    }
    launchURL(url);
  }

  Future<void> checkForUpdateWindows() async {
    await getServerVersionWindows();
    Version currentVersion = jsonToVersion(appVersion);
    //int indexOfUpdate = -1;
    latestVersion = (latestVersion ?? jsonToVersion("0.0.0"));
    if (latestVersion! > currentVersion) {
      List<UpdateVersion> tmpList = [];
      for (int i = 0; i < releaseNotes.length; i++) {
        if (currentVersion < jsonToVersion(releaseNotes[i].version)) {
          tmpList.add(releaseNotes[i]);
        }
      }
      releaseNotes = tmpList;
      print("update is available");
      await updateDialog(latestVersion!);
    } else {
      print("you are up to date");
    }
  }

  @override
  void dispose() {
    //  flutterWebviewPlugin.dispose();
    // _onStateChanged.cancel();
    super.dispose();
  }

  @override
  Future<void> onReady() async {
    //Size windowSize = await windowManager.getSize();
    if (GetPlatform.isWindows) {
      await windowManager.ensureInitialized();
      await windowManager.setMinimumSize(const Size(600, 600));

      //windowManager.getSize().asStream().listen((event) {
      //print(event);
      //});
    }

    await initScreenUtil();

    setCatcherLogsPath();

    dioInter = dio.Dio();
    (dioInter.httpClientAdapter as DefaultHttpClientAdapter)
        .onHttpClientCreate = (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
    dioInter.options.connectTimeout = 5 * 1000;
    dioInter.interceptors.add(RetryInterceptor(
      dio: dioInter,
      logPrint: print,
      // specify log function (optional)
      onRetry: (e) {
        loadingState.value = StringConstants.loadingLinkError;
      },
      retries: 3,
      // retry count (optional)
      retryDelays: const [
        // set delays between retries (optional)
        Duration(seconds: 1), // wait 1 sec before first retry
        Duration(seconds: 2), // wait 2 sec before second retry
        Duration(seconds: 3), // wait 3 sec before third retry
      ],
    ));
    getPrayerTimes();
    update();
    afterLoading();
  }

  Future<void> getPrayerTimes() async {
    Position MeccaPos = const Position(
        speedAccuracy: 0,
        heading: 0,
        longitude: 39.826168,
        speed: 0,
        altitude: 0,
        latitude: 21.422510,
        timestamp: null,
        accuracy: 0);
    int todayDay = (DateTime.now()).day;
    int todayMonth = (DateTime.now()).month;
    var meccaPrayerTimes = await getApiForPosition(MeccaPos);

    for (int i = 0; i < meccaPrayerTimes.length; i++) {
      DayPrayer dayPrayer = DayPrayer(
        meccaPrayerTimes[i]["date"]["gregorian"]["date"],
        meccaPrayerTimes[i]["date"]["gregorian"]["format"],
        meccaPrayerTimes[i]["date"]["gregorian"]["weekday"]["en"],
        meccaPrayerTimes[i]["timings"]["Fajr"],
        meccaPrayerTimes[i]["timings"]["Dhuhr"],
        meccaPrayerTimes[i]["timings"]["Asr"],
        meccaPrayerTimes[i]["timings"]["Maghrib"],
        meccaPrayerTimes[i]["timings"]["Isha"],
      );
      //print();
      if (dayPrayer.date.month >= todayMonth &&
          dayPrayer.date.day >= todayDay) {
        meccaPrayer.add(dayPrayer);
      }
    }
    print("meccaPrayerTimes" + meccaPrayerTimes.toString());
    Position userPos = await determinePosition();
    Map<String, String> location = await getCityFromPosition(userPos);
    print(location);
    city.value = location["city"] ?? "Unknown";
    country.value = location["country"] ?? "Unknown";

    var userPrayerTimes = await getApiForPosition(userPos);

    for (int i = 0; i < userPrayerTimes.length; i++) {
      DayPrayer dayPrayer = DayPrayer(
        userPrayerTimes[i]["date"]["gregorian"]["date"],
        userPrayerTimes[i]["date"]["gregorian"]["format"],
        userPrayerTimes[i]["date"]["gregorian"]["weekday"]["en"],
        userPrayerTimes[i]["timings"]["Fajr"],
        userPrayerTimes[i]["timings"]["Dhuhr"],
        userPrayerTimes[i]["timings"]["Asr"],
        userPrayerTimes[i]["timings"]["Maghrib"],
        userPrayerTimes[i]["timings"]["Isha"],
      );
      //print();
      if (dayPrayer.date.month >= todayMonth &&
          dayPrayer.date.day >= todayDay) {
        userPrayer.add(dayPrayer);
      }
    }
    if (meccaPrayer[0].date != userPrayer[0].date) {
      print("DATES ARE NOT ALIGNED");
    }
    update();
    print("userPrayerTimes" + userPrayerTimes.toString());
  }

  setCatcherLogsPath() async {
    CatcherOptions debugOptions = CatcherOptions(SilentReportMode(), [
      FileHandler(
          File(
              join((await getApplicationDocumentsDirectory()).path, "log.txt")),
          printLogs: true),
      ConsoleHandler(
          enableApplicationParameters: true,
          enableDeviceParameters: true,
          enableCustomParameters: true,
          enableStackTrace: true,
          handleWhenRejected: false)
    ]);
    CatcherOptions releaseOptions = CatcherOptions(SilentReportMode(), [
      FileHandler(File(
          join((await getApplicationDocumentsDirectory()).path, "log.txt"))),
      ConsoleHandler(
          enableApplicationParameters: false,
          enableDeviceParameters: false,
          enableCustomParameters: false,
          enableStackTrace: true,
          handleWhenRejected: false)
    ]);
    catcher.updateConfig(
        debugConfig: debugOptions, releaseConfig: releaseOptions);
  }

  Version jsonToVersion(String? response) {
    //print(response);
    return (Version.parse(response));
  }

  Future<void> initScreenUtil() async {
    double? width;
    double? height;
    //print("width:${Get.width} ,,, height:${Get.height} ");

    if (MediaQuery.of(Get.context!).orientation == Orientation.portrait ||
        Platform.isWindows) {
      height = Get.height;
      width = Get.width;
    } else {
      height = Get.width;
      width = Get.height;
    }
    ScreenUtil.init(
        BoxConstraints(
            maxWidth: width, //new width
            maxHeight: height //new height
            ),
        context: Get.context,
        designSize: Size(411.42857142857144, 683.4285714285714),
        orientation: Orientation.portrait,
        minTextAdapt: true);
    update();
  }
}
