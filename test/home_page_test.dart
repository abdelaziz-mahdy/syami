import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:syami/controller/engine.dart';
import 'package:syami/controller/classes.dart';
import 'package:syami/controller/time_zones.dart';
import 'package:syami/main.dart';
import 'package:timezone/timezone.dart' as tz;

/// An engine that never touches the network or GPS; tests set its state.
class FakeEngine extends SearchEngine {
  int loads = 0;

  @override
  Future<void> onReady() async {
    appLoaded.value = true;
  }

  @override
  Future<void> getPrayerTimes() async {
    loads++;
  }

  /// What the next location read throws, or else returns.
  Object? locateError;
  (Position, ({String city, String country}))? located;

  @override
  Future<(Position, ({String city, String country}))> locate(
      {bool fresh = false}) async {
    if (locateError != null) throw locateError!;
    return located!;
  }

  /// One week of days from today, as the calendar API returns them.
  @override
  Future<dynamic> getApiForPosition(Position pos, int month, int year) async {
    final today = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return [
      for (var i = 0; i < 7; i++)
        () {
          final d = DateTime(today.year, today.month, today.day + i);
          final iso = '${d.year}-${two(d.month)}-${two(d.day)}';
          return {
            'date': {
              'gregorian': {
                'date': '${two(d.day)}-${two(d.month)}-${d.year}',
                'format': 'DD-MM-YYYY',
                'weekday': {'en': 'Day$i'},
              },
            },
            'timings': {
              for (final n in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'])
                n: '${iso}T12:00:00+01:00',
            },
            'meta': {'timezone': 'Europe/Sarajevo'},
          };
        }(),
    ];
  }
}

Position at(double lat, double lon) => Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime(2026),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

Future<FakeEngine> pumpAbuDhabiList(WidgetTester tester) async {
  final engine = await pumpHome(tester);
  engine.userPosition = at(24.45, 54.38);
  engine.country.value = 'United Arab Emirates';
  engine.city.value = 'Abu Dhabi';
  engine.userPrayer.add(abuDhabiDay());
  engine.meccaPrayer.add(abuDhabiDay());
  engine.update();
  await tester.pump();
  return engine;
}

Future<FakeEngine> pumpHome(WidgetTester tester) async {
  final engine = FakeEngine();
  Get.put<SearchEngine>(engine, permanent: true);
  await tester.pumpWidget(const MyApp());
  await tester.pump();
  return engine;
}

DayPrayer abuDhabiDay([String day = '07']) => DayPrayer(
      '$day-11-2026',
      'DD-MM-YYYY',
      'Saturday',
      '2026-11-${day}T05:14:00+04:00',
      '2026-11-${day}T12:09:00+04:00',
      '2026-11-${day}T15:17:00+04:00',
      '2026-11-${day}T17:42:00+04:00',
      '2026-11-${day}T18:58:00+04:00',
      tz.getLocation('Asia/Dubai'),
    );

void main() {
  setUpAll(loadTimeZones);
  tearDown(Get.reset);

  testWidgets('a failed load always offers Retry', (tester) async {
    final engine = await pumpHome(tester);
    // This message has no "exception" in it, which used to hide the button.
    engine.loadingState.value =
        "The location service on the device is disabled.";
    engine.loadFailed.value = true;
    await tester.pump();

    expect(find.textContaining('location service'), findsOneWidget);
    // A themed button, not a hard-coded green one.
    expect(
      find.ancestor(
        of: find.text('Try again'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Try again'));
    expect(engine.loads, 1);
  });

  testWidgets('loading shows a spinner with the current step', (tester) async {
    final engine = await pumpHome(tester);
    engine.loadingState.value = "Getting your location";
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Getting your location'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('a long country and city fit a phone-width header',
      (tester) async {
    // Pixel 9 size; the header used to overflow here and cover the button.
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final engine = await pumpHome(tester);
    engine.country.value = 'United Arab Emirates';
    engine.city.value = 'Abu Dhabi';
    engine.userPrayer.add(abuDhabiDay());
    engine.meccaPrayer.add(abuDhabiDay());
    engine.update();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Country: United Arab Emirates'), findsOneWidget);
    expect(find.text('City: Abu Dhabi'), findsOneWidget);
    expect(tester.getRect(find.byIcon(Icons.refresh)).right,
        lessThanOrEqualTo(1080 / 2.625));
  });

  testWidgets('the refresh button says what it does', (tester) async {
    final engine = await pumpHome(tester);
    engine.country.value = 'United States';
    engine.city.value = 'Mountain View';
    engine.userPrayer.add(abuDhabiDay());
    engine.meccaPrayer.add(abuDhabiDay());
    engine.update();
    await tester.pump();

    expect(find.byTooltip('Update location'), findsOneWidget);
  });

  testWidgets('the iftar row names Mecca properly', (tester) async {
    final engine = await pumpHome(tester);
    engine.city.value = 'Mountain View';
    engine.userPrayer.add(abuDhabiDay());
    engine.meccaPrayer.add(abuDhabiDay());
    engine.update();
    await tester.pump();

    expect(find.text("Mountain View Iftar by Mecca's Fasting Duration"),
        findsOneWidget);
  });

  testWidgets('a day whose dates differ shows a notice instead of throwing',
      (tester) async {
    final engine = await pumpHome(tester);
    engine.city.value = 'Abu Dhabi';
    engine.userPrayer.add(abuDhabiDay('07'));
    engine.meccaPrayer.add(abuDhabiDay('08'));
    engine.update();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Dates are not the same'), findsOneWidget);
    expect(find.text('Abu Dhabi date: 07-11-2026'), findsOneWidget);
  });

  testWidgets('12-hour times have no leading zero', (tester) async {
    final engine = await pumpHome(tester);
    engine.userPrayer.add(abuDhabiDay());
    engine.meccaPrayer.add(abuDhabiDay());
    engine.update();
    await tester.pump();

    expect(find.text('5:14 AM'), findsWidgets);
    expect(find.text('05:14 AM'), findsNothing);
  });

  testWidgets('a failed Update location keeps the list and offers Try again',
      (tester) async {
    final engine = await pumpAbuDhabiList(tester);
    engine.locateError = const LocationServiceDisabledException();

    await tester.tap(find.byTooltip('Update location'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    // The list, place and position are untouched.
    expect(find.text('Abu Dhabi Prayer Times'), findsOneWidget);
    expect(engine.userPrayer, hasLength(1));
    expect(engine.city.value, 'Abu Dhabi');
    expect(engine.userPosition!.latitude, 24.45);
    // The reason and a way to retry, in a SnackBar.
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find
            .text('Location is turned off. Turn it on, then tap Try again.'),
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(SnackBarAction, 'Try again'), findsOneWidget);
    expect(engine.loadFailed.value, isFalse);
  });

  testWidgets('a successful Update location swaps in the new place',
      (tester) async {
    final engine = await pumpAbuDhabiList(tester);
    engine.located = (
      at(43.86, 18.41),
      (city: 'Sarajevo', country: 'Bosnia and Herzegovina'),
    );

    await tester.tap(find.byTooltip('Update location'));
    await tester.pump();
    await tester.pump();

    expect(engine.city.value, 'Sarajevo');
    expect(engine.userPrayer, hasLength(7));
    expect(engine.userPrayer.first.date.day, DateTime.now().day);
    expect(find.text('Sarajevo Prayer Times'), findsWidgets);
    expect(find.byType(SnackBar), findsNothing);
  });
}
