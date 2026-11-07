import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:syami/constants/string_constants.dart';

import 'package:syami/controller/engine.dart';
import 'package:syami/controller/time_zones.dart';

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
                    CustomButton(
                        primary: Colors.green, // background
                        onPrimary: Colors.white, // foreground
                        child: const CustomText(
                          "Try again",
                        ),
                        onPressed: () {
                          engine.getPrayerTimes();
                        }),
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
                      IconButton(
                          tooltip: "Update location",
                          onPressed: () {
                            engine.getPrayerTimes(getNewLocation: true);
                          },
                          icon: const Icon(
                            Icons.refresh,
                          ))
                    ])),
              );
            }),
            Expanded(
              child: GetBuilder<SearchEngine>(builder: (engine) {
                bool hourFormattedAs24 =
                    MediaQuery.of(context).alwaysUse24HourFormat;
                String hourFormat = hourFormattedAs24 ? 'HH:mm' : 'h:mm a';
                DateFormat formatter = DateFormat(hourFormat);
                DateFormat dateFormatter = DateFormat("dd-MM-yyyy");
                return SmartRefresher(
                  enablePullDown: false,
                  enablePullUp: true,
                  controller: engine.listRefresher,
                  footer: const ClassicFooter(
                    loadingIcon: CircularProgressIndicator(
                      strokeWidth: 2.0,
                    ),
                  ),
                  onLoading: () {
                    engine.loadMoreMonth();
                  },
                  child: ListView.separated(
                      scrollDirection: Axis.vertical,
                      itemCount: engine.userPrayer.length,
                      separatorBuilder: (context, index) {
                        return const Divider(
                          height: 5,
                        );
                      },
                      itemBuilder: (BuildContext context, int index) {
                        if (dateFormatter
                                .format(engine.meccaPrayer[index].date) !=
                            dateFormatter
                                .format(engine.userPrayer[index].date)) {
                          return Container(
                            padding: const EdgeInsets.all(7),
                            margin: const EdgeInsets.only(left: 7, right: 7),
                            decoration: BoxDecoration(
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 3.0,
                                    spreadRadius: 0.0,
                                    offset: Offset(2.0,
                                        2.0), // shadow direction: bottom right
                                  )
                                ],
                                borderRadius: BorderRadius.circular(
                                    StringConstants.cornersSettings)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const CustomText(
                                  "Dates are not the same",
                                  color: Colors.red,
                                ),
                                // A Spacer here threw: list items have no height
                                // limit for it to fill.
                                const SizedBox(height: 6),
                                CustomText(
                                    "Mecca date: ${dateFormatter.format(engine.meccaPrayer[index].date)}"),
                                CustomText(
                                    "${engine.city} date: ${dateFormatter.format(engine.userPrayer[index].date)}")
                              ],
                            ),
                          );
                        }
                        Duration fastingMecca = engine
                            .meccaPrayer[index].maghrib
                            .difference(engine.meccaPrayer[index].fajr);
                        Duration fastingUser = engine.userPrayer[index].maghrib
                            .difference(engine.userPrayer[index].fajr);

                        DateTime iftarUser =
                            engine.userPrayer[index].fajr.add(fastingMecca);

                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            margin: const EdgeInsets.only(left: 7, right: 7),
                            decoration: BoxDecoration(
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 3.0,
                                    spreadRadius: 0.0,
                                    offset: Offset(2.0,
                                        2.0), // shadow direction: bottom right
                                  )
                                ],
                                borderRadius: BorderRadius.circular(
                                    StringConstants.cornersSettings)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  children: [
                                    CustomText(
                                      engine.meccaPrayer[index].weekDay,
                                      bold: true,
                                      //defaultFont: 18,
                                    ),
                                    const Spacer(),
                                    CustomText(
                                      dateFormatter.format(
                                        engine.meccaPrayer[index].date,
                                      ),
                                      bold: true,
                                      //defaultFont: 18,
                                    ),
                                  ],
                                ),
                                const Divider(),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 7.0),
                                  child: CustomText(
                                    "Mecca Times",
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 5, right: 5, bottom: 25.0),
                                  child: Table(
                                      border:
                                          TableBorder.all(color: Colors.white),
                                      // Allows to add a border decoration around your table
                                      children: [
                                        TableRow(
                                            children: [
                                          const Center(
                                              child: CustomText(
                                            "Fajr",
                                          )),
                                          const Center(
                                              child: CustomText(
                                            'Dhuhr',
                                          )),
                                          const Center(
                                              child: CustomText(
                                            'Asr',
                                          )),
                                          const Center(
                                              child: CustomText(
                                            'Maghrib',
                                          )),
                                          const Center(
                                              child: CustomText(
                                            'Isha',
                                          )),
                                        ]
                                                .map((e) => Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: e))
                                                .toList()),
                                        TableRow(
                                            children: [
                                          Center(
                                            child: CustomText(
                                              formatter.format(engine
                                                  .meccaPrayer[index].fajr),
                                            ),
                                          ),
                                          Center(
                                            child: CustomText(
                                              formatter.format(engine
                                                  .meccaPrayer[index].dhuhr),
                                            ),
                                          ),
                                          Center(
                                            child: CustomText(
                                              formatter.format(engine
                                                  .meccaPrayer[index].asr),
                                            ),
                                          ),
                                          Center(
                                            child: CustomText(
                                              formatter.format(engine
                                                  .meccaPrayer[index].maghrib),
                                            ),
                                          ),
                                          Center(
                                            child: CustomText(
                                              formatter.format(engine
                                                  .meccaPrayer[index].isha),
                                            ),
                                          ),
                                        ]
                                                .map((e) => Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: e))
                                                .toList()),
                                      ]),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 7.0),
                                  child: CustomText(
                                    "${engine.city.value} Prayer Times",
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 5, right: 5, bottom: 25.0),
                                  child: Table(
                                      border:
                                          TableBorder.all(color: Colors.white),
                                      // Allows to add a border decoration around your table
                                      children: [
                                        TableRow(
                                            children: [
                                          const Center(
                                              child: CustomText(
                                            "Fajr",
                                          )),
                                          const Center(
                                              child: CustomText(
                                            'Dhuhr',
                                          )),
                                          const Center(
                                              child: CustomText(
                                            'Asr',
                                          )),
                                          const Center(
                                              child: CustomText(
                                            'Maghrib',
                                          )),
                                          const Center(
                                              child: CustomText(
                                            'Isha',
                                          )),
                                        ]
                                                .map((e) => Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: e))
                                                .toList()),
                                        TableRow(
                                            children: [
                                          Center(
                                            child: CustomText(
                                              formatter.format(engine
                                                  .userPrayer[index].fajr),
                                            ),
                                          ),
                                          Center(
                                            child: CustomText(
                                              formatter.format(engine
                                                  .userPrayer[index].dhuhr),
                                            ),
                                          ),
                                          Center(
                                            child: CustomText(
                                              formatter.format(
                                                  engine.userPrayer[index].asr),
                                            ),
                                          ),
                                          Center(
                                            child: CustomText(
                                              formatter.format(engine
                                                  .userPrayer[index].maghrib),
                                            ),
                                          ),
                                          Center(
                                            child: CustomText(
                                              formatter.format(engine
                                                  .userPrayer[index].isha),
                                            ),
                                          ),
                                        ]
                                                .map((e) => Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: e))
                                                .toList()),
                                      ]),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 7.0),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: CustomText(
                                          "Mecca Fasting Duration ",
                                          center: false,
                                        ),
                                      ),
                                      Expanded(
                                          child: CustomText(
                                        engineprintDuration(fastingMecca),
                                        color: Colors.blue,
                                      ))
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 7.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: CustomText(
                                          "${engine.city.value} Fasting Duration ",
                                          center: false,
                                        ),
                                      ),
                                      Expanded(
                                          child: CustomText(
                                        engineprintDuration(fastingUser),
                                        color: Colors.blue,
                                      ))
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 7.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: CustomText(
                                          "${engine.city.value} Iftar by Mecca's Fasting Duration",
                                          center: false,
                                          maxLines: 3,
                                        ),
                                      ),
                                      Expanded(
                                          child: CustomText(
                                        formatter.format(iftarUser),
                                        maxLines: 3,
                                        color: Colors.blue,
                                      ))
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                );
              }),
            ),
          ],
        );
      }),
    );
  }

  String engineprintDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${twoDigits(duration.inHours)} Hours and $twoDigitMinutes Minutes";
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
