import 'dart:io';

import 'package:catcher/catcher.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syami/constants/String%20constants.dart';
import 'package:syami/controller/Engine.dart';

class SizeChangesListener with WidgetsBindingObserver {
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    Get.find<SearchEngine>().initScreenUtil();
    //print('changed size');
  }
}

late Catcher catcher;
void main() {
  /// STEP 1. Create catcher configuration.
  /// Debug configuration with dialog report mode and console handler. It will show dialog and once user accepts it, error will be shown   /// in console.
  CatcherOptions debugOptions =
      CatcherOptions(PageReportMode(showStackTrace: true), []);

  /// Release configuration. Same as above, but once user accepts dialog, user will be prompted to send email with crash to support.
  CatcherOptions releaseOptions =
      CatcherOptions(PageReportMode(showStackTrace: true), []);

  /// STEP 2. Pass your root widget (MyApp) along with Catcher configuration:
  catcher = Catcher(
      rootWidget: MyApp(),
      ensureInitialized: true,
      debugConfig: debugOptions,
      releaseConfig: releaseOptions);

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    WidgetsBinding.instance!.addObserver(SizeChangesListener());
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Get.put(SearchEngine(catcher), permanent: true);

    return GetMaterialApp(
      title: "Syami",
      navigatorKey: Catcher.navigatorKey,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      //initialRoute: "MyHomePage",

      home: const MyHomePage(
        title: 'Syami',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

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
      backgroundColor: Colors.grey[500],
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(
          widget.title,
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          GetX<SearchEngine>(builder: (_) {
            //_.userPrayer;
            //print(_.userPrayer.length);
            return Container(
                padding: const EdgeInsets.all(7),
                margin: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: Colors.black,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 3.0,
                        spreadRadius: 0.0,
                        offset:
                            Offset(2.0, 2.0), // shadow direction: bottom right
                      )
                    ],
                    borderRadius:
                        BorderRadius.circular(StringConstants.cornersSettings)),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      RichText(
                          text: TextSpan(
                              text: "Country" + ": ",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              children: <TextSpan>[
                            TextSpan(text: _.country.value),
                          ])),
                      //Spacer(),
                      RichText(
                          text: TextSpan(
                              text: "City" + ": ",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              children: <TextSpan>[
                            TextSpan(text: _.city.value),
                          ])),
                    ]));
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
              return ListView.separated(
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
                            color: Colors.black,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                blurRadius: 3.0,
                                spreadRadius: 0.0,
                                offset: Offset(
                                    2.0, 2.0), // shadow direction: bottom right
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
                                "mecca date :${dateFormatter.format(_.meccaPrayer[index].date)}"),
                            CustomText(
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

                    return Container(
                      padding: const EdgeInsets.all(7),
                      margin: const EdgeInsets.only(left: 7, right: 7),
                      decoration: BoxDecoration(
                          color: Colors.black,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              blurRadius: 3.0,
                              spreadRadius: 0.0,
                              offset: Offset(
                                  2.0, 2.0), // shadow direction: bottom right
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
                              CustomText(_.meccaPrayer[index].weekDay),
                              const Spacer(),
                              CustomText(dateFormatter
                                  .format(_.meccaPrayer[index].date)),
                            ],
                          ),
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 7.0),
                            child: CustomText("Mecca Times"),
                          ),
                          Table(
                              border: TableBorder.all(
                                  color: Colors
                                      .white), // Allows to add a border decoration around your table
                              children: [
                                const TableRow(children: [
                                  Center(
                                      child: Text(
                                    "Fajr",
                                    style: TextStyle(color: Colors.white),
                                  )),
                                  Center(
                                      child: Text(
                                    'Dhuhr',
                                    style: TextStyle(color: Colors.white),
                                  )),
                                  Center(
                                      child: Text(
                                    'Asr',
                                    style: TextStyle(color: Colors.white),
                                  )),
                                  Center(
                                      child: Text(
                                    'Maghrib',
                                    style: TextStyle(color: Colors.white),
                                  )),
                                  Center(
                                      child: Text(
                                    'Isha',
                                    style: TextStyle(color: Colors.white),
                                  )),
                                ]),
                                TableRow(children: [
                                  Center(
                                    child: Text(
                                      formatter
                                          .format(_.meccaPrayer[index].fajr),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      formatter
                                          .format(_.meccaPrayer[index].dhuhr),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      formatter
                                          .format(_.meccaPrayer[index].asr),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      formatter
                                          .format(_.meccaPrayer[index].maghrib),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      formatter
                                          .format(_.meccaPrayer[index].isha),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ]),
                              ]),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 7.0),
                            child: CustomText(_.city.value + " Prayer Times"),
                          ),
                          Table(
                              border: TableBorder.all(
                                  color: Colors
                                      .white), // Allows to add a border decoration around your table
                              children: [
                                const TableRow(children: [
                                  Center(
                                      child: Text(
                                    "Fajr",
                                    style: TextStyle(color: Colors.white),
                                  )),
                                  Center(
                                      child: Text(
                                    'Dhuhr',
                                    style: TextStyle(color: Colors.white),
                                  )),
                                  Center(
                                      child: Text(
                                    'Asr',
                                    style: TextStyle(color: Colors.white),
                                  )),
                                  Center(
                                      child: Text(
                                    'Maghrib',
                                    style: TextStyle(color: Colors.white),
                                  )),
                                  Center(
                                      child: Text(
                                    'Isha',
                                    style: TextStyle(color: Colors.white),
                                  )),
                                ]),
                                TableRow(children: [
                                  Center(
                                    child: Text(
                                      formatter
                                          .format(_.userPrayer[index].fajr),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      formatter
                                          .format(_.userPrayer[index].dhuhr),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      formatter.format(_.userPrayer[index].asr),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      formatter
                                          .format(_.userPrayer[index].maghrib),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      formatter
                                          .format(_.userPrayer[index].isha),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ]),
                              ]),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 7.0),
                            child: CustomText("Mecca Fasting Duration " +
                                _printDuration(fastingMecca)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 7.0),
                            child: CustomText(_.city.value +
                                " Fasting Duration " +
                                _printDuration(fastingUser)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 7.0),
                            child: CustomText(
                              _.city.value +
                                  " iftar based on mecca duration " +
                                  formatter.format(iftarUser),
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                    );
                  });
            }),
          ),
        ],
      ),
    );
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes";
  }
}
