import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class DayPrayer {
  late DateTime date;
  late String weekDay;
  late DateTime fajr;
  late DateTime dhuhr;
  late DateTime asr;
  late DateTime maghrib;
  late DateTime isha;
  DayPrayer(
      String dateString,
      String dateFormat,
      this.weekDay,
      String fajrTime,
      String dhuhrTime,
      String asrTime,
      String maghribTime,
      String ishaTime,
      tz.Location timeZone) {
    date = DateFormat(dateFormat.replaceAll("YYYY", "yyyy")).parse(dateString);
    fajr = tz.TZDateTime.parse(timeZone, fajrTime);
    dhuhr = tz.TZDateTime.parse(timeZone, dhuhrTime);
    asr = tz.TZDateTime.parse(timeZone, asrTime);
    maghrib = tz.TZDateTime.parse(timeZone, maghribTime);
    isha = tz.TZDateTime.parse(timeZone, ishaTime);
  }
}
