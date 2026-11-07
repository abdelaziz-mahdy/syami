import 'package:flutter_test/flutter_test.dart';
import 'package:syami/controller/classes.dart';
import 'package:syami/controller/engine.dart';
import 'package:syami/controller/time_zones.dart';
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
  setUpAll(loadTimeZones);

  test('every zone the API names for these cities is known', () {
    // All of these were missing from the smaller database the app used,
    // so the app showed 'Location with the name ... doesn't exist'.
    for (final zone in [
      'Asia/Kuwait',
      'Asia/Bahrain',
      'Asia/Muscat',
      'Asia/Aden',
      'Asia/Kuala_Lumpur',
      'Asia/Brunei',
      'Europe/Sarajevo',
      'Europe/Stockholm',
      'Europe/Amsterdam',
      'Africa/Dakar',
      'Africa/Mogadishu',
    ]) {
      expect(() => tz.getLocation(zone), returnsNormally, reason: zone);
    }
  });

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

  group('processPrayerTimes', () {
    Map<String, dynamic> apiDay(String date) {
      final p = date.split('-');
      final iso = '${p[2]}-${p[1]}-${p[0]}';
      return {
        'date': {
          'gregorian': {
            'date': date,
            'format': 'DD-MM-YYYY',
            'weekday': {'en': 'Saturday'},
          },
        },
        'timings': {
          for (final name in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'])
            name: '${iso}T12:00:00+04:00',
        },
        'meta': {'timezone': 'Asia/Dubai'},
      };
    }

    final today = DateTime(2026, 11, 7, 15, 30);

    test('skips days before today', () {
      final days = <DayPrayer>[];
      SearchEngine().processPrayerTimes(
        [apiDay('06-11-2026'), apiDay('07-11-2026'), apiDay('08-11-2026')],
        days,
        now: today,
      );
      expect(days.map((d) => d.date.day), [7, 8]);
    });

    test('keeps every day of the same month next year', () {
      final days = <DayPrayer>[];
      SearchEngine().processPrayerTimes(
        [apiDay('01-11-2027'), apiDay('06-11-2027'), apiDay('07-11-2027')],
        days,
        now: today,
      );
      expect(days.map((d) => d.date.day), [1, 6, 7]);
    });
  });
}
