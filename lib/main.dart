import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:syami/controller/engine.dart';
import 'package:syami/controller/time_zones.dart';
import 'package:syami/today_view.dart';

void main() {
  loadTimeZones();
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the status and navigation bars on every Android version.
  // Android 15+ already forces this for apps targeting API 35+, so older
  // versions now match it instead of showing an opaque black navigation bar
  // (Play: "Edge-to-edge may not display for all users").
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SearchEngine(), permanent: true);

    return GetMaterialApp(
      title: "Syami",
      theme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: const MyHomePage(
        title: 'Syami',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: "Full calendar",
            onPressed: () => openFullCalendar(context),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
      body: GetX<SearchEngine>(builder: (engine) {
        if (!engine.appLoaded.value) {
          return LoadingView(message: engine.loadingState.value);
        }
        if (engine.userPrayer.isEmpty && !engine.loadFailed.value) {
          return LoadingView(message: engine.loadingState.value);
        }
        if (engine.userPrayer.isEmpty) {
          // Every failure gets a Try again button. Matching the message text
          // for "exception" missed errors such as "The location service on
          // the device is disabled.", leaving no way out.
          return ErrorView(
            message: engine.loadingState.value,
            onRetry: engine.getPrayerTimes,
          );
        }
        return const TodayView();
      }),
    );
  }
}

/// A spinner with the current step ("Getting your location") under it, so
/// a slow load reads as work in progress rather than a stuck screen.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A first load that failed with nothing to show: the reason in plain
/// words and the screen's one action, Try again.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 40, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text("Try again"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
