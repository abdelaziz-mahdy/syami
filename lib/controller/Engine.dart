import 'dart:io';
import 'dart:ui';

import 'package:catcher/catcher.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:dio/adapter.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:dio/dio.dart' as dio;
import 'package:path_provider/path_provider.dart';
import 'package:syami/constants/String%20constants.dart';
import 'package:syami/controller/classes.dart';
import 'package:syami/dialogs/update%20dialog.dart';
import 'package:version/version.dart';
import 'package:window_manager/window_manager.dart';

class SearchEngine extends GetxController {
  late Catcher catcher;

  SearchEngine(Catcher catcher2) {
    catcher = catcher2;
  }

  String serverUrlApi = "http://api.aladhan.com/v1/";
  String serverUrlGoGoAnime = "https://gogoanime.film";
  String appVersion = "1.0.0";
  List<UpdateVersion> releaseNotes = [];
  List<dynamic>? jsonResponse = [];
  RxString loadingState = "".obs;

  dio.CancelToken token = dio.CancelToken();
  late dio.Dio dioInter;

  Version? latestVersion;

  Future<void> afterLoading() async {
    print("checkForUpdate()");

    if (GetPlatform.isAndroid) {
      await checkForUpdate();
    }
    if (GetPlatform.isWindows) {
      await checkForUpdateWindows();
    }

    //update();
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
    if (response.statusCode == 200) {
      jsonResponse = response.data;
      //print(jsonResponse);
      releaseNotes = [];
      for (int j = 0; j < jsonResponse!.length; j++) {
        releaseNotes.add(UpdateVersion(
            version: jsonResponse![j]["Version"],
            description: jsonResponse![j]["Release Notes"]));
        // add every element you get to be able to show it to the user
      }
      latestVersion = jsonToVersion(jsonResponse![0]["Version"]);
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
  }

  Future<void> getServerVersionWindows() async {
    String urlDone =
        "https://storage.googleapis.com/anime-293309.appspot.com/SyamiV1.json?avoidTheCaches=1";
    dio.Response response = await loadLink(urlDone);
    //print(response.data);
    if (response.statusCode == 200) {
      jsonResponse = response.data;
      //print(jsonResponse);
      releaseNotes = [];
      for (int j = 0; j < jsonResponse!.length; j++) {
        releaseNotes.add(UpdateVersion(
            version: jsonResponse![j]["Version"],
            description: jsonResponse![j]["Release Notes"]));
        // add every element you get to be able to show it to the user
      }
      latestVersion = jsonToVersion(jsonResponse![0]["Version"]);
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

    //setCatcherLogsPath();

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

    update();
    afterLoading();
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
