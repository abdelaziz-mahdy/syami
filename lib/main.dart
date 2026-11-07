import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:syami/constants/string_constants.dart';

import 'package:syami/controller/engine.dart';
import 'package:syami/controller/time_zones.dart';
import 'package:syami/day_card.dart';

void main() {
  loadTimeZones();
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the status and navigation bars on every Android version.
  // Android 15+ already forces this for apps targeting API 35+, so older
  // versions now match it instead of showing an opaque black navigation bar
  // (Play: "Edge-to-edge may not display for all users").
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SearchEngine(), permanent: true);

    return ScreenUtilInit(
      designSize: const Size(411.42857142857144, 683.4285714285714),
      child: GetMaterialApp(
        title: "Syami",
        theme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: const MyHomePage(
          title: 'Syami',
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
        ),
      ),
      body: GetX<SearchEngine>(builder: (engine) {
        if (!engine.appLoaded.value) {
          return LoadingView(message: engine.loadingState.value);
        }
        if (engine.userPrayer.isEmpty && !engine.loadFailed.value) {
          return LoadingView(message: engine.loadingState.value);
        }
        if (engine.userPrayer.isEmpty) {
          return Center(
            child: Container(
                padding: const EdgeInsets.all(7),
                margin: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 3.0,
                        spreadRadius: 0.0,
                        offset:
                            Offset(2.0, 2.0), // shadow direction: bottom right
                      )
                    ],
                    borderRadius:
                        BorderRadius.circular(StringConstants.cornersSettings)),
                // Every failure gets a Retry button. Matching the message text
                // for "exception" missed errors such as "The location service
                // on the device is disabled.", leaving no way out.
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      engine.loadingState.value,
                      maxLines: 10,
                    ),
                    SizedBox(height: 10.h),
                    FilledButton.icon(
                      onPressed: engine.getPrayerTimes,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Try again"),
                    ),
                  ],
                )),
          );
        }
        return Column(
          children: [
            GetX<SearchEngine>(builder: (engine) {
              return Padding(
                padding: const EdgeInsets.all(5.0),
                child: Container(
                    padding: const EdgeInsets.all(7),
                    margin: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 3.0,
                            spreadRadius: 0.0,
                            offset: Offset(
                                2.0, 2.0), // shadow direction: bottom right
                          )
                        ],
                        borderRadius: BorderRadius.circular(
                            StringConstants.cornersSettings)),
                    child: Row(children: [
                      // Wrap puts City on its own line when both don't fit,
                      // instead of overflowing and covering the refresh
                      // button ("United Arab Emirates" + "Abu Dhabi").
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10.w,
                          runSpacing: 4,
                          children: [
                            CustomText(
                              "Country: ${engine.country.value}",
                              bold: true,
                            ),
                            CustomText(
                              "City: ${engine.city.value}",
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                      engine.updatingLocation.value
                          ? const SizedBox.square(
                              dimension: 48,
                              child: Center(
                                child: SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    semanticsLabel: "Updating location",
                                  ),
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: "Update location",
                              onPressed: () => updateLocation(engine),
                              icon: const Icon(
                                Icons.refresh,
                              ))
                    ])),
              );
            }),
            Expanded(
              child: GetBuilder<SearchEngine>(builder: (engine) {
                final days =
                    min(engine.userPrayer.length, engine.meccaPrayer.length);
                return SmartRefresher(
                  enablePullDown: false,
                  enablePullUp: true,
                  controller: engine.listRefresher,
                  footer: const ClassicFooter(
                    loadingIcon: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  ),
                  onLoading: engine.loadMoreMonth,
                  child: ListView.builder(
                    itemCount: days,
                    itemBuilder: (context, index) => DayCard(
                      mecca: engine.meccaPrayer[index],
                      local: engine.userPrayer[index],
                      city: engine.placeName(),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      }),
    );
  }

  /// Keeps the current list on screen while the location is re-read; a
  /// failure shows a SnackBar with the reason and a Try again action.
  Future<void> updateLocation(SearchEngine engine) async {
    final error = await engine.updateLocation();
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(error),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: "Try again",
          onPressed: () => updateLocation(engine),
        ),
      ));
  }
}

/// A spinner with the current step ("Getting your location") under it, so
/// a slow load reads as work in progress rather than a stuck screen.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 20),
              CustomText(message, maxLines: 3),
            ],
          ],
        ),
      ),
    );
  }
}
