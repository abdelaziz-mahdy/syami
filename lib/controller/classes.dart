import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class UpdateVersion {
  final String? version, description;

  UpdateVersion({
    required this.version,
    required this.description,
  });
}

enum LoadingStatus {
  loading,
  error,
  loaded,
}

class DayPrayer {
  late DateTime date;
  late String weekDay;
  late DateTime fajr;
  late DateTime dhuhr;
  late DateTime asr;
  late DateTime maghrib;
  late DateTime isha;
  DayPrayer(String dateString, String dateFormat, this.weekDay, String fajrTime,
      String dhuhrTime, String asrTime, String maghribTime, String ishaTime,tz.Location timeZone) {
    print(MediaQuery.of(Get.context!).alwaysUse24HourFormat);
    date = DateFormat(dateFormat.replaceAll("YYYY", "yyyy")).parse(dateString);
    fajr = tz.TZDateTime.parse(timeZone,fajrTime);
    dhuhr = tz.TZDateTime.parse(timeZone,dhuhrTime);
    asr = tz.TZDateTime.parse(timeZone,asrTime);
    maghrib = tz.TZDateTime.parse(timeZone,maghribTime);
    isha = tz.TZDateTime.parse(timeZone,ishaTime);

  }
}
