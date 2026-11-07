import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:get/get.dart';
import 'package:syami/controller/engine.dart';
import 'package:syami/controller/classes.dart';
import 'package:syami/controller/time_zones.dart';
import 'package:syami/main.dart';
import 'package:syami/controller/today.dart';
import 'package:syami/day_card.dart';
import 'package:syami/today_view.dart';
import 'package:timezone/timezone.dart' as tz;

/// An engine that never touches the network or GPS; tests set its state.
class FakeEngine extends SearchEngine {
  int loads = 0;

  @override
  Future<void> onReady() async {
    appLoaded.value = true;
  }

  bool failNextLoad = false;

  @override
  Future<void> getPrayerTimes() async {
    loads++;
    loadFailed.value = failNextLoad;
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

/// Records how a load-more ended instead of animating a footer.
class SpyRefreshController extends RefreshController {
  String? reported;

  @override
  void loadFailed() => reported = 'failed';

  @override
  void loadComplete() => reported = 'complete';
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

/// Opens the full calendar from the app bar and lets the route settle (the
/// Ramadan card's progress bar keeps pumpAndSettle from returning).
Future<void> openCalendar(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Full calendar'));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  setUpAll(loadTimeZones);
  // 10:00 in Abu Dhabi on the fixture day: Dhuhr (12:09) is next.
  setUp(() => appClock = () => DateTime.utc(2026, 11, 7, 6));
  tearDown(() {
    appClock = DateTime.now;
    Get.reset();
  });

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
    // Nothing to open yet.
    expect(find.byTooltip('Full calendar'), findsNothing);
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
    expect(find.text('United Arab Emirates'), findsOneWidget);
    expect(find.text('Abu Dhabi'), findsWidgets);
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

  testWidgets('the iftar fact names Mecca properly', (tester) async {
    final engine = await pumpHome(tester);
    engine.city.value = 'Mountain View';
    engine.userPrayer.add(abuDhabiDay());
    engine.meccaPrayer.add(abuDhabiDay());
    engine.update();
    await tester.pump();

    expect(find.text("Iftar using Mecca's fasting time"), findsOneWidget);
    expect(find.text("Fasting in Mountain View"), findsOneWidget);
  });

  testWidgets('a day whose dates differ shows a notice instead of throwing',
      (tester) async {
    final engine = await pumpHome(tester);
    engine.city.value = 'Abu Dhabi';
    engine.userPrayer.add(abuDhabiDay('07'));
    engine.meccaPrayer.add(abuDhabiDay('08'));
    engine.update();
    await tester.pump();
    await openCalendar(tester);

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
    expect(find.text('Fasting in Abu Dhabi'), findsOneWidget);
    expect(engine.userPrayer, hasLength(1));
    expect(engine.city.value, 'Abu Dhabi');
    expect(engine.userPosition!.latitude, 24.45);
    // The reason and a way to retry, in a SnackBar.
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(
            "Couldn't read your location. Check that location is on, then tap Try again."),
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
    expect(find.text('Fasting in Sarajevo'), findsWidgets);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('list colours come from the theme', (tester) async {
    await pumpAbuDhabiList(tester);
    final colors =
        Theme.of(tester.element(find.text('Fasting in Mecca'))).colorScheme;

    final duration = tester.widget<Text>(find.text('12 h 28 min').first);
    expect(duration.style!.color, colors.primary);
    final card = tester.widget<Card>(find.byType(Card).last);
    expect(card.color, colors.surfaceContainer);
  });

  group('day card at 360 dp', () {
    setUpAll(() async {
      // Real Roboto, so text widths match a phone instead of the test font.
      final dir =
          '${Platform.environment['FLUTTER_ROOT'] ?? '/Users/AbdelazizMahdy/Developer/flutter'}'
          '/bin/cache/artifacts/material_fonts';
      final loader = FontLoader('Roboto');
      for (final f in [
        'Roboto-Regular.ttf',
        'Roboto-Medium.ttf',
        'Roboto-Bold.ttf'
      ]) {
        loader
            .addFont(File('$dir/$f').readAsBytes().then(ByteData.sublistView));
      }
      await loader.load();
    });

    for (final (country, city) in [
      ('Bosnia and Herzegovina', 'Sarajevo'),
      ('United Arab Emirates', 'Abu Dhabi'),
      ('United Kingdom', 'Newcastle upon Tyne'),
    ]) {
      testWidgets('$city: five prayers, both columns, every time on one line',
          (tester) async {
        tester.view.physicalSize = const Size(360 * 3, 800 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        final engine = await pumpHome(tester);
        engine.country.value = country;
        engine.city.value = city;
        engine.userPrayer.add(abuDhabiDay());
        engine.meccaPrayer.add(abuDhabiDay());
        engine.update();
        await tester.pump();
        expect(tester.takeException(), isNull);

        for (final name in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
          expect(find.text(name), findsOneWidget);
        }
        expect(find.text('Mecca'), findsOneWidget);
        // The city heads its column (and titles the location header).
        expect(
            find.descendant(of: find.byType(Table), matching: find.text(city)),
            findsOneWidget);

        for (final t in [
          '5:14 AM',
          '12:09 PM',
          '3:17 PM',
          '5:42 PM',
          '6:58 PM'
        ]) {
          // One in the Mecca column, one in the city column.
          final inTable =
              find.descendant(of: find.byType(Table), matching: find.text(t));
          expect(inTable, findsNWidgets(2));
          for (final e in inTable.evaluate()) {
            final paragraph = e.renderObject! as RenderParagraph;
            final lineHeight =
                paragraph.getFullHeightForCaret(const TextPosition(offset: 0));
            expect(paragraph.size.height, lessThan(lineHeight * 1.5),
                reason: '$t wraps');
            // Fits its column at full size: FittedBox didn't have to shrink it.
            final box = tester.getSize(find
                .ancestor(
                    of: find.byElementPredicate((x) => x == e),
                    matching: find.byType(FittedBox))
                .first);
            expect(paragraph.size.width, lessThanOrEqualTo(box.width + 0.5),
                reason: t);
          }
        }
      });
    }
  });

  test('a failed next month shows the failed footer, not a silent stop',
      () async {
    final footer = SpyRefreshController();
    final engine = FakeEngine()
      ..listRefresher = footer
      ..failNextLoad = true;
    await engine.loadMoreMonth();
    expect(footer.reported, 'failed');

    engine.failNextLoad = false;
    await engine.loadMoreMonth();
    expect(footer.reported, 'complete');
  });

  group('Today view', () {
    // A tall phone, so the whole Today view is laid out.
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(412 * 3, 2400 * 3);
      view.devicePixelRatio = 3;
    });
    tearDown(() => TestWidgetsFlutterBinding
        .instance.platformDispatcher.views.first
        .reset());

    testWidgets('shows today with the next prayer counting down',
        (tester) async {
      await pumpAbuDhabiList(tester);

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Saturday 7 November 2026'), findsOneWidget);
      // 10:00 local (06:00 UTC) to Dhuhr at 12:09 (+04:00).
      expect(find.text('Dhuhr in 2 h 9 min'), findsOneWidget);
      expect(find.text('Iftar using Mecca\'s fasting time'), findsOneWidget);
    });

    testWidgets('Full calendar opens the day-by-day list', (tester) async {
      final engine = await pumpAbuDhabiList(tester);
      engine.userPrayer.add(abuDhabiDay('08'));
      engine.meccaPrayer.add(abuDhabiDay('08'));
      engine.update();
      await tester.pump();

      await tester.tap(find.text('Full calendar'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.widgetWithText(AppBar, 'Full calendar'), findsOneWidget);
      expect(find.byType(DayCard), findsNWidgets(2));
      expect(find.text('Today'), findsNothing);
    });

    testWidgets('Ramadan card counts down to the expected start',
        (tester) async {
      final engine = await pumpAbuDhabiList(tester);
      engine.ramadan.value =
          RamadanDates(1448, DateTime(2027, 2, 8), DateTime(2027, 3, 8));
      await tester.pump();

      expect(find.text('Ramadan starts in 93 days'), findsOneWidget);
      expect(find.text('Expected on Monday 8 February 2027.'), findsOneWidget);
      expect(find.textContaining('moon sighting'), findsOneWidget);
    });

    testWidgets('Ramadan card explains a failed load and offers Try again',
        (tester) async {
      final engine = await pumpAbuDhabiList(tester);
      engine.ramadanError.value = "Couldn't reach the prayer times service. "
          "Check your internet connection, then tap Try again.";
      await tester.pump();

      expect(find.textContaining("Couldn't reach"), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Try again'), findsOneWidget);
    });
  });
}
