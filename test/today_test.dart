import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syami/controller/classes.dart';
import 'package:syami/controller/engine.dart';
import 'package:syami/controller/time_zones.dart';
import 'package:syami/controller/today.dart';
import 'package:timezone/timezone.dart' as tz;

/// A Newcastle day (UTC+0 in November), with its Hijri date.
DayPrayer newcastleDay(int day, {HijriDate? hijri}) {
  final d = day.toString().padLeft(2, '0');
  String at(String hm) => '2026-11-${d}T$hm:00+00:00';
  return DayPrayer(
      '$d-11-2026',
      'DD-MM-YYYY',
      'Saturday',
      at('05:17'),
      at('11:50'),
      at('13:53'),
      at('16:17'),
      at('18:15'),
      tz.getLocation('Europe/London'),
      hijri: hijri);
}

DateTime utc(int day, int h, int m) => DateTime.utc(2026, 11, day, h, m);

void main() {
  setUpAll(loadTimeZones);

  test("today is the city's date, not the phone's", () {
    DayPrayer abuDhabi(int day) {
      final d = day.toString().padLeft(2, '0');
      String at(String hm) => '2026-11-${d}T$hm:00+04:00';
      return DayPrayer(
          '$d-11-2026',
          'DD-MM-YYYY',
          'Day',
          at('05:14'),
          at('12:09'),
          at('15:17'),
          at('17:42'),
          at('18:58'),
          tz.getLocation('Asia/Dubai'));
    }

    final days = [abuDhabi(7), abuDhabi(8)];
    // 21:12 UTC on the 7th is 01:12 on the 8th in Abu Dhabi.
    expect(dayFor(days, DateTime.utc(2026, 11, 7, 21, 12))!.date.day, 8);
    expect(dayFor(days, DateTime.utc(2026, 11, 7, 12))!.date.day, 7);
  });

  group('nextPrayer', () {
    test('is Fajr before dawn', () {
      final next = nextPrayer(utc(7, 4, 0), newcastleDay(7), newcastleDay(8))!;
      expect((next.name, next.tomorrow), ('Fajr', false));
    });

    test('is the first prayer still to come', () {
      expect(nextPrayer(utc(7, 12, 0), newcastleDay(7), null)!.name, 'Asr');
      expect(nextPrayer(utc(7, 16, 17), newcastleDay(7), null)!.name, 'Isha');
    });

    test('after Isha is tomorrow\'s Fajr', () {
      final next = nextPrayer(utc(7, 20, 0), newcastleDay(7), newcastleDay(8))!;
      expect(next.name, 'Fajr');
      expect(next.tomorrow, isTrue);
      expect(next.time, newcastleDay(8).fajr);
    });

    test('after Isha with tomorrow not loaded is null', () {
      expect(nextPrayer(utc(7, 20, 0), newcastleDay(7), null), isNull);
    });
  });

  group('countdown text', () {
    late DayPrayer day;
    setUp(() => day = newcastleDay(7));

    test('hours and minutes, minutes rounded up', () {
      // 12:40:30 to Asr at 13:53 is 1 h 12.5 min.
      expect(
          nextPrayerText(DateTime.utc(2026, 11, 7, 12, 40, 30),
              NextPrayer('Asr', day.asr)),
          'Asr in 1 h 13 min');
      expect(countdown(utc(7, 12, 41), day.asr), '1 h 12 min');
    });

    test('minutes only, whole hours, and under a minute', () {
      expect(countdown(utc(7, 13, 8), day.asr), '45 min');
      expect(countdown(utc(7, 12, 53), day.asr), '1 h');
      expect(countdown(DateTime.utc(2026, 11, 7, 13, 52, 30), day.asr),
          'less than a minute');
    });

    test('says tomorrow after Isha', () {
      final next = NextPrayer('Fajr', newcastleDay(8).fajr, tomorrow: true);
      expect(
          nextPrayerText(utc(7, 22, 14), next), 'Fajr tomorrow in 7 h 3 min');
    });
  });

  group('Ramadan', () {
    // 1448 AH: expected 8 February to 8 March 2027.
    final r1448 =
        RamadanDates(1448, DateTime(2027, 2, 8), DateTime(2027, 3, 8));

    test('before: days until the expected start', () {
      final s = ramadanStatus(DateTime(2026, 11, 7, 15), r1448) as RamadanAhead;
      expect(s.daysUntil, 93);
      expect(s.start, DateTime(2027, 2, 8));
      expect(
          (ramadanStatus(DateTime(2027, 2, 7, 23), r1448) as RamadanAhead)
              .daysUntil,
          1);
    });

    test('during: day number and days left', () {
      final first = ramadanStatus(DateTime(2027, 2, 8, 9), r1448) as RamadanNow;
      expect((first.day, first.daysLeft), (1, 28));
      final last = ramadanStatus(DateTime(2027, 3, 8, 21), r1448) as RamadanNow;
      expect((last.day, last.daysLeft), (29, 0));
    });

    test('after: over', () {
      expect(ramadanStatus(DateTime(2027, 3, 9), r1448), isA<RamadanOver>());
    });

    test('which Ramadan to show from today\'s Hijri date', () {
      expect(ramadanYearFor(const HijriDate(27, 5, 1448)), 1448);
      expect(ramadanYearFor(const HijriDate(12, 9, 1448)), 1448);
      expect(ramadanYearFor(const HijriDate(2, 10, 1448)), 1449);
    });

    test('Hijri date reads the API object and prints plain month names', () {
      final h = HijriDate.fromApi({
        'day': '27',
        'month': {'number': 5, 'en': 'Jumādá al-ūlá'},
        'year': '1448',
      })!;
      expect('$h', '27 Jumada al-Ula 1448 AH');
      expect(HijriDate.fromApi(null), isNull);
    });
  });

  group('engine Ramadan dates', () {
    test('asks hToG once per Hijri year and picks the coming Ramadan',
        () async {
      final engine = _HToGEngine();
      engine.userPrayer
          .add(newcastleDay(7, hijri: const HijriDate(27, 5, 1448)));

      await engine.loadRamadan(now: DateTime(2026, 11, 7, 12));
      expect(engine.ramadan.value!.start, DateTime(2027, 2, 8));
      expect(engine.ramadan.value!.end, DateTime(2027, 3, 8));
      expect(engine.ramadanError.value, '');

      await engine.loadRamadan(now: DateTime(2026, 11, 7, 13));
      expect(engine.calls, 2, reason: 'start and Shawwal, cached after');
    });

    test('offline: a plain-words message, no crash', () async {
      final engine = _HToGEngine()..offline = true;
      engine.userPrayer
          .add(newcastleDay(7, hijri: const HijriDate(27, 5, 1448)));

      await engine.loadRamadan(now: DateTime(2026, 11, 7, 12));
      expect(engine.ramadan.value, isNull);
      expect(engine.ramadanError.value, contains('internet connection'));
    });
  });
}

class _HToGEngine extends SearchEngine {
  int calls = 0;
  bool offline = false;

  @override
  Future<DateTime> hijriToGregorian(int day, int month, int year) async {
    calls++;
    if (offline) throw const SocketException('Failed host lookup');
    return switch ((day, month, year)) {
      (1, 9, 1448) => DateTime(2027, 2, 8),
      (1, 10, 1448) => DateTime(2027, 3, 9),
      _ => throw StateError('unexpected $day-$month-$year'),
    };
  }
}
