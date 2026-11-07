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

  /// The Islamic (Hijri) date of this day, from the same API answer.
  final HijriDate? hijri;

  DayPrayer(
      String dateString,
      String dateFormat,
      this.weekDay,
      String fajrTime,
      String dhuhrTime,
      String asrTime,
      String maghribTime,
      String ishaTime,
      tz.Location timeZone,
      {this.hijri}) {
    date = DateFormat(dateFormat.replaceAll("YYYY", "yyyy")).parse(dateString);
    fajr = tz.TZDateTime.parse(timeZone, fajrTime);
    dhuhr = tz.TZDateTime.parse(timeZone, dhuhrTime);
    asr = tz.TZDateTime.parse(timeZone, asrTime);
    maghrib = tz.TZDateTime.parse(timeZone, maghribTime);
    isha = tz.TZDateTime.parse(timeZone, ishaTime);
  }
}

/// A Hijri (Islamic calendar) date: day, month 1-12 and year.
class HijriDate {
  const HijriDate(this.day, this.month, this.year);

  final int day;
  final int month;
  final int year;

  /// Reads the `date.hijri` object of an aladhan.com answer.
  static HijriDate? fromApi(dynamic hijri) {
    if (hijri == null) return null;
    final day = int.tryParse("${hijri["day"]}");
    final month = int.tryParse("${hijri["month"]?["number"]}");
    final year = int.tryParse("${hijri["year"]}");
    if (day == null || month == null || year == null) return null;
    return HijriDate(day, month, year);
  }

  static const monthNames = [
    "Muharram",
    "Safar",
    "Rabi al-Awwal",
    "Rabi al-Thani",
    "Jumada al-Ula",
    "Jumada al-Akhirah",
    "Rajab",
    "Shaban",
    "Ramadan",
    "Shawwal",
    "Dhu al-Qadah",
    "Dhu al-Hijjah",
  ];

  /// "27 Jumada al-Ula 1448 AH"
  @override
  String toString() => "$day ${monthNames[month - 1]} $year AH";
}
