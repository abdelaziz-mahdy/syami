import 'package:syami/controller/classes.dart';
import 'package:timezone/timezone.dart' as tz;

/// The day in [days] that is today in the city the days are for, or null.
///
/// "Today" is the city's date, not the phone's: at 21:00 in Atlantic time
/// it is already tomorrow in Abu Dhabi.
DayPrayer? dayFor(List<DayPrayer> days, DateTime now) {
  if (days.isEmpty) return null;
  final first = days.first.fajr;
  final local =
      first is tz.TZDateTime ? tz.TZDateTime.from(now, first.location) : now;
  for (final day in days) {
    if (day.date.year == local.year &&
        day.date.month == local.month &&
        day.date.day == local.day) {
      return day;
    }
  }
  return null;
}

/// The next prayer to come after [now].
class NextPrayer {
  const NextPrayer(this.name, this.time, {this.tomorrow = false});

  final String name;
  final DateTime time;

  /// True after Isha, when the next prayer is tomorrow's Fajr.
  final bool tomorrow;
}

/// Today's next prayer; after Isha, tomorrow's Fajr (null if tomorrow
/// isn't loaded).
NextPrayer? nextPrayer(DateTime now, DayPrayer today, DayPrayer? tomorrow) {
  for (final (name, time) in [
    ("Fajr", today.fajr),
    ("Dhuhr", today.dhuhr),
    ("Asr", today.asr),
    ("Maghrib", today.maghrib),
    ("Isha", today.isha),
  ]) {
    if (time.isAfter(now)) return NextPrayer(name, time);
  }
  if (tomorrow == null) return null;
  return NextPrayer("Fajr", tomorrow.fajr, tomorrow: true);
}

/// "1 h 12 min", "45 min" or "less than a minute" until [time]. Minutes
/// round up, so the countdown never says 0 min before the prayer.
String countdown(DateTime now, DateTime time) {
  final seconds = time.difference(now).inSeconds;
  if (seconds < 60) return "less than a minute";
  final minutes = (seconds / 60).ceil();
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return "$m min";
  if (m == 0) return "$h h";
  return "$h h $m min";
}

/// "Asr in 1 h 12 min", "Fajr tomorrow in 7 h 3 min".
String nextPrayerText(DateTime now, NextPrayer next) =>
    "${next.name}${next.tomorrow ? " tomorrow" : ""} "
    "in ${countdown(now, next.time)}";

/// Expected first and last day of Ramadan in one Hijri year, as Gregorian
/// dates (midnight, local).
class RamadanDates {
  const RamadanDates(this.hijriYear, this.start, this.end);

  final int hijriYear;
  final DateTime start;
  final DateTime end;
}

/// Where today stands relative to Ramadan.
sealed class RamadanStatus {
  const RamadanStatus();
}

class RamadanAhead extends RamadanStatus {
  const RamadanAhead(this.daysUntil, this.start);
  final int daysUntil;
  final DateTime start;
}

class RamadanNow extends RamadanStatus {
  const RamadanNow(this.day, this.daysLeft, this.end);

  /// 1 on the first day.
  final int day;

  /// Days after today; 0 on the last day.
  final int daysLeft;
  final DateTime end;
}

class RamadanOver extends RamadanStatus {
  const RamadanOver();
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whole calendar days from [a] to [b], ignoring time of day and DST.
int _daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
    .difference(DateTime.utc(a.year, a.month, a.day))
    .inDays;

RamadanStatus ramadanStatus(DateTime today, RamadanDates dates) {
  final day = _dateOnly(today);
  if (day.isBefore(dates.start)) {
    return RamadanAhead(_daysBetween(day, dates.start), dates.start);
  }
  if (!day.isAfter(dates.end)) {
    return RamadanNow(_daysBetween(dates.start, day) + 1,
        _daysBetween(day, dates.end), dates.end);
  }
  return const RamadanOver();
}

/// The Hijri year whose Ramadan is current or next, given today's Hijri
/// date: this year until the end of Ramadan (month 9), then next year.
int ramadanYearFor(HijriDate today) =>
    today.month <= 9 ? today.year : today.year + 1;
