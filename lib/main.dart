import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:syami/constants/string_constants.dart';

import 'package:syami/controller/engine.dart';
import 'package:timezone/data/latest.dart' as tz;

//late Catcher catcher;
void main() {
  tz.initializeTimeZones();
  WidgetsFlutterBinding.ensureInitialized();

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
        //initialRoute: "MyHomePage",

        home: const MyHomePage(
          title: 'Syami',
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => engineMyHomePageState();
}

class engineMyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the engineincrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(
          widget.title,
        ),
      ),
      body: GetX<SearchEngine>(builder: (engine) {
        if (!engine.appLoaded.value) {
          return Container(
            padding: const EdgeInsets.all(7),
            margin: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 3.0,
                    spreadRadius: 0.0,
                    offset: Offset(2.0, 2.0), // shadow direction: bottom right
                  )
                ],
                borderRadius:
                    BorderRadius.circular(StringConstants.cornersSettings)),
            child: CustomText(
              engine.loadingState.value,
              defaultFont: 18,
            ),
          );
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
              child: engine.loadingState.value ==
                          StringConstants.loadingLinkError ||
                      engine.loadingState.value
                          .toLowerCase()
                          .contains("exception")
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          engine.loadingState.value
                                  .toLowerCase()
                                  .startsWith("exception:")
                              ? engine.loadingState.value
                                  .substring("Exception :".length)
                                  .trim()
                              : engine.loadingState.value,
                          maxLines: 10,
                        ),
                        SizedBox(height: 10.h),
                        CustomButton(
                            primary: Colors.green, // background
                            onPrimary: Colors.white, // foreground
                            child: const CustomText(
                              "Retry Again",
                            ),
                            onPressed: () {
                              engine.getPrayerTimes();
                            }),
                      ],
                    )
                  : CustomText(engine.loadingState.value),
            ),
          );
        }
        return Column(
          children: [
            GetX<SearchEngine>(builder: (engine) {
              //engine.userPrayer;
              //print(engine.userPrayer.length);

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
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CustomText(
                            "Country: ${engine.country.value}",
                            bold: true,
                          ),
                          SizedBox(width: 10.w),
                          //Spacer(),
                          CustomText(
                            "City: ${engine.city.value}",
                            bold: true,
                          ),
                          IconButton(
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
                //engine.userPrayer;
                //print(engine.userPrayer.length);

                bool hourFormattedAs24 =
                    MediaQuery.of(context).alwaysUse24HourFormat;
                String hourFormat = hourFormattedAs24 ? 'HH:mm' : 'hh:mm a';
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
                                const Spacer(),
                                CustomText(
                                    "Mecca date :${dateFormatter.format(engine.meccaPrayer[index].date)}"),
                                CustomText(
                                    "${engine.city} date :${dateFormatter.format(engine.userPrayer[index].date)}")
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
                                          "${engine.city.value} iftar based on mecca duration ",
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
