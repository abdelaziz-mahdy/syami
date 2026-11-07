import 'package:flutter_test/flutter_test.dart';
import 'package:syami/controller/classes.dart';
import 'package:syami/controller/engine.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// A day as the aladhan.com calendar API returns it (iso8601=true).
DayPrayer losAngelesDay(String date) {
  final parts = date.split('-');
  final iso = '${parts[2]}-${parts[1]}-${parts[0]}';
  return DayPrayer(
    date,
    'DD-MM-YYYY',
    'Thursday',
    '${iso}T06:05:00-08:00',
    '${iso}T12:10:00-08:00',
    '${iso}T14:41:00-08:00',
    '${iso}T17:00:00-08:00',
    '${iso}T18:17:00-08:00',
    tz.getLocation('America/Los_Angeles'),
  );
}

void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('DayPrayer', () {
    test('parses the API date and keeps times in the local time zone', () {
      final day = losAngelesDay('31-12-2026');

      expect(day.date, DateTime(2026, 12, 31));
      expect(day.fajr.hour, 6);
      expect(day.fajr.minute, 5);
      expect(day.maghrib.hour, 17);
      expect(
        day.maghrib.difference(day.fajr),
        const Duration(hours: 10, minutes: 55),
      );
    });
  });

  group('next month to load', () {
    final engine = SearchEngine();

    test('is the month after the last loaded day', () {
      expect(
        engine.getNextMonthAndYearFromPrayers([losAngelesDay('30-11-2026')]),
        (12, 2026),
      );
    });

    test('rolls December over to January of the next year', () {
      expect(
        engine.getNextMonthAndYearFromPrayers([losAngelesDay('31-12-2026')]),
        (1, 2027),
      );
    });
  });
}
