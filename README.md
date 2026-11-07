# Syami

Fasting far from Mecca can mean very long (or very short) days. Syami shows
your local prayer times next to Mecca's, compares the two fasting durations,
and gives the iftar time you would reach if you fasted for as long as people
in Mecca do that day.

[Get it on Google Play](https://play.google.com/store/apps/details?id=com.zcreations.syami)

## Features

- **Today:** today's Fajr, Dhuhr, Asr, Maghrib and Isha for Mecca and for
  your city (each in its own time zone), a live countdown to the next prayer,
  the Gregorian and Hijri date, both fasting durations and your iftar time
  based on Mecca's fasting duration.
- **Ramadan:** how many days until the expected start, or which day of
  Ramadan it is and how many are left (the real dates depend on the moon
  sighting).
- **Full calendar:** every day from today on, one card each; scroll down to
  load the next month.
- Finds your city from the phone's location; the refresh button updates it
  and keeps your days on screen if that fails.
- Plain-language errors with a Try again button (no internet, location off,
  location not allowed).

Prayer times come from the [Aladhan API](https://aladhan.com/prayer-times-api)
(`/v1/calendar` for prayer times and Hijri dates, `/v1/hToG` for the
expected Ramadan dates).

## Code layout

| Path | What it holds |
|---|---|
| `lib/main.dart` | App start-up (time zones, edge-to-edge), the home scaffold, loading and error states |
| `lib/today_view.dart` | The Today view: Today card with the countdown, Ramadan card, Full calendar button |
| `lib/calendar_page.dart` | The full calendar: day cards with next-month loading |
| `lib/location_header.dart` | City and country with Update location |
| `lib/controller/engine.dart` | `SearchEngine` (GetX controller): location, API calls, month paging, Ramadan dates |
| `lib/controller/today.dart` | Today's day, next prayer, countdown text and Ramadan maths |
| `lib/controller/locator.dart` | Location permission and position, reverse geocoding to city and country |
| `lib/controller/classes.dart` | `DayPrayer` (one day's prayer times in the city's time zone) and `HijriDate` |
| `lib/controller/load_errors.dart` | Turns failures into messages for users |
| `lib/controller/time_zones.dart` | Loads the full IANA time zone database |
| `lib/day_card.dart` | One day: the prayer table, fasting durations and iftar time |
| `test/` | Unit and widget tests (`flutter test`) |
| `tool/play_whatsnew.py` | Turns the newest CHANGELOG entry into Play "What's new" notes |

## Run it

```bash
flutter pub get
flutter run
flutter test
flutter analyze
```

The Android build needs JDK 17. If Flutter picks a newer JDK that Gradle
can't run, build through Gradle with JDK 17 instead of changing global config:

```bash
cd android
JAVA_HOME=/path/to/jdk-17 ./gradlew assembleDebug
```

A local `bundleRelease` without `android/key.properties` stops at
`:app:signReleaseBundle`; that is expected (CI provides the upload key).

## Releasing

Every push to `master` runs `.github/workflows/deploy.yml`: it builds the
release app bundle and uploads it to Google Play **production** (no track is
set). Pushes that only touch docs, tests, `tool/` or CI are ignored.

1. Bump `version:` in `pubspec.yaml`; the build number after `+` must be
   higher than any build ever uploaded.
2. Add a `## <version>` entry at the top of `CHANGELOG.md`, written for people
   who use the app, at most 500 characters. CI sends it as the Play "What's
   new" text (en-US).
3. Merge to `master`.
