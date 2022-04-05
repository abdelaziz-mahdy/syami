import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
      String dhuhrTime, String asrTime, String maghribTime, String ishaTime) {
    print(MediaQuery.of(Get.context!).alwaysUse24HourFormat);
    date = DateFormat(dateFormat.replaceAll("YYYY", "yyyy")).parse(dateString);
    fajr = DateFormat("HH:mm").parse(fajrTime);
    dhuhr = DateFormat("HH:mm").parse(dhuhrTime);
    asr = DateFormat("HH:mm").parse(asrTime);
    maghrib = DateFormat("HH:mm").parse(maghribTime);
    isha = DateFormat("HH:mm").parse(ishaTime);
  }
}
