import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  Future<void> getPrayerTimes({bool getNewLocation = false}) async {
    loads++;
  }
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
}
