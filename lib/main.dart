import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:syami/constants/string_constants.dart';
import 'package:syami/controller/engine.dart';

//late Catcher catcher;
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SearchEngine(), permanent: true);

    return ScreenUtilInit(
      designSize: const Size(360, 690),
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
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
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
      body: GetX<SearchEngine>(builder: (_) {
        if (!_.appLoaded.value) {
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
              _.loadingState.value,
              defaultFont: 18,
            ),
          );
        }
        if (_.userPrayer.isEmpty) {
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
              child: _.loadingState.value == StringConstants.loadingLinkError ||
                      _.loadingState.value.toLowerCase().contains("exception")
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomAutoSizeText(
                          _.loadingState.value
                                  .toLowerCase()
                                  .startsWith("exception:")
                              ? _.loadingState.value
                                  .substring("Exception :".length)
                                  .trim()
                              : _.loadingState.value,
                          maxLines: 10,
                        ),
                        SizedBox(height: 10.h),
                        CustomButton(
                            primary: Colors.green, // background
                            onPrimary: Colors.white, // foreground
                            child: const CustomAutoSizeText(
                              "Retry Again",
                            ),
                            onPressed: () {
                              _.getPrayerTimes();
                            }),
                      ],
                    )
                  : CustomAutoSizeText(_.loadingState.value),
            ),
          );
        }
        return Column(
          children: [
            GetX<SearchEngine>(builder: (_) {
              //_.userPrayer;
              //print(_.userPrayer.length);

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
                          CustomAutoSizeText(
                            "Country: ${_.country.value}",
                            bold: true,
                          ),
                          //Spacer(),
                          CustomAutoSizeText(
                            "City: ${_.city.value}",
                            bold: true,
                          ),
                          IconButton(
                              onPressed: () {
                                _.getPrayerTimes(getNewLocation: true);
                              },
                              icon: const Icon(
                                Icons.refresh,
                              ))
                        ])),
              );
            }),
            Expanded(
              child: GetBuilder<SearchEngine>(builder: (_) {
                //_.userPrayer;
                //print(_.userPrayer.length);

                bool hourFormattedAs24 =
                    MediaQuery.of(context).alwaysUse24HourFormat;
                String hourFormat = hourFormattedAs24 ? 'HH:mm' : 'hh:mm a';
                DateFormat formatter = DateFormat(hourFormat);
                DateFormat dateFormatter = DateFormat("dd-MM-yyyy");
                return SmartRefresher(
                  enablePullDown: false,
                  enablePullUp: true,
                  controller: _.listRefresher,
                  footer: const ClassicFooter(
                    loadingIcon: CircularProgressIndicator(
                      strokeWidth: 2.0,
                    ),
                  ),
                  onLoading: () {
                    _.loadMoreMonth();
                  },
                  child: ListView.separated(
                      scrollDirection: Axis.vertical,
                      itemCount: _.userPrayer.length,
                      separatorBuilder: (context, index) {
                        return const Divider(
                          height: 5,
                        );
                      },
                      itemBuilder: (BuildContext context, int index) {
                        if (dateFormatter.format(_.meccaPrayer[index].date) !=
                            dateFormatter.format(_.userPrayer[index].date)) {
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
                                const CustomAutoSizeText(
                                  "Dates are not the same",
                                  color: Colors.red,
                                ),
                                const Spacer(),
                                CustomAutoSizeText(
                                    "Mecca date :${dateFormatter.format(_.meccaPrayer[index].date)}"),
                                CustomAutoSizeText(
                                    "${_.city} date :${dateFormatter.format(_.userPrayer[index].date)}")
                              ],
                            ),
                          );
                        }
                        Duration fastingMecca = _.meccaPrayer[index].maghrib
                            .difference(_.meccaPrayer[index].fajr);
                        Duration fastingUser = _.userPrayer[index].maghrib
                            .difference(_.userPrayer[index].fajr);

                        DateTime iftarUser =
                            _.userPrayer[index].fajr.add(fastingMecca);

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
                                    CustomAutoSizeText(
                                      _.meccaPrayer[index].weekDay,
                                      bold: true,
                                      //defaultFont: 18,
                                      maxFont: 18,
                                    ),
                                    const Spacer(),
                                    CustomAutoSizeText(
                                      dateFormatter.format(
                                        _.meccaPrayer[index].date,
                                      ),
                                      bold: true,
                                      //defaultFont: 18,
                                      maxFont: 18,
                                    ),
                                  ],
                                ),
                                const Divider(),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 7.0),
                                  child: CustomAutoSizeText(
                                    "Mecca Times",
                                    maxFont: 18,
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
                                              child: CustomAutoSizeText(
                                            "Fajr",
                                          )),
                                          const Center(
                                              child: CustomAutoSizeText(
                                            'Dhuhr',
                                          )),
                                          const Center(
                                              child: CustomAutoSizeText(
                                            'Asr',
                                          )),
                                          const Center(
                                              child: CustomAutoSizeText(
                                            'Maghrib',
                                          )),
                                          const Center(
                                              child: CustomAutoSizeText(
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
                                            child: CustomAutoSizeText(
                                              formatter.format(
                                                  _.meccaPrayer[index].fajr),
                                            ),
                                          ),
                                          Center(
                                            child: CustomAutoSizeText(
                                              formatter.format(
                                                  _.meccaPrayer[index].dhuhr),
                                            ),
                                          ),
                                          Center(
                                            child: CustomAutoSizeText(
                                              formatter.format(
                                                  _.meccaPrayer[index].asr),
                                            ),
                                          ),
                                          Center(
                                            child: CustomAutoSizeText(
                                              formatter.format(
                                                  _.meccaPrayer[index].maghrib),
                                            ),
                                          ),
                                          Center(
                                            child: CustomAutoSizeText(
                                              formatter.format(
                                                  _.meccaPrayer[index].isha),
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
                                  child: CustomAutoSizeText(
                                    "${_.city.value} Prayer Times",
                                    maxFont: 18,
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
                                              child: CustomAutoSizeText(
                                            "Fajr",
                                          )),
                                          const Center(
                                              child: CustomAutoSizeText(
                                            'Dhuhr',
                                          )),
                                          const Center(
                                              child: CustomAutoSizeText(
                                            'Asr',
                                          )),
                                          const Center(
                                              child: CustomAutoSizeText(
                                            'Maghrib',
                                          )),
                                          const Center(
                                              child: CustomAutoSizeText(
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
                                            child: CustomAutoSizeText(
                                              formatter.format(
                                                  _.userPrayer[index].fajr),
                                            ),
                                          ),
                                          Center(
                                            child: CustomAutoSizeText(
                                              formatter.format(
                                                  _.userPrayer[index].dhuhr),
                                            ),
                                          ),
                                          Center(
                                            child: CustomAutoSizeText(
                                              formatter.format(
                                                  _.userPrayer[index].asr),
                                            ),
                                          ),
                                          Center(
                                            child: CustomAutoSizeText(
                                              formatter.format(
                                                  _.userPrayer[index].maghrib),
                                            ),
                                          ),
                                          Center(
                                            child: CustomAutoSizeText(
                                              formatter.format(
                                                  _.userPrayer[index].isha),
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
                                        child: CustomAutoSizeText(
                                          "Mecca Fasting Duration ",
                                          center: false,
                                        ),
                                      ),
                                      Expanded(
                                          child: CustomAutoSizeText(
                                        _printDuration(fastingMecca),
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
                                        child: CustomAutoSizeText(
                                          "${_.city.value} Fasting Duration ",
                                          center: false,
                                        ),
                                      ),
                                      Expanded(
                                          child: CustomAutoSizeText(
                                        _printDuration(fastingUser),
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
                                        child: CustomAutoSizeText(
                                          "${_.city.value} iftar based on mecca duration ",
                                          center: false,
                                          maxLines: 3,
                                        ),
                                      ),
                                      Expanded(
                                          child: CustomAutoSizeText(
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

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${twoDigits(duration.inHours)} Hours and $twoDigitMinutes Minutes";
  }
}
