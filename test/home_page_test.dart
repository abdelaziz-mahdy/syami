import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:syami/controller/engine.dart';
import 'package:syami/main.dart';

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

void main() {
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
}
