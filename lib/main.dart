import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:syami/controller/engine.dart';
import 'package:syami/controller/time_zones.dart';
import 'package:syami/day_card.dart';

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
        title: Text(
          widget.title,
        ),
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
        return Column(
          children: [
            GetX<SearchEngine>(builder: (engine) {
              final text = Theme.of(context).textTheme;
              final colors = Theme.of(context).colorScheme;
              // Same flat surface as the day cards: the place is the title,
              // the country under it, Update location on the right.
              return Card(
                elevation: 0,
                color: colors.surfaceContainer,
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                  child: Row(children: [
                    Icon(Icons.place_outlined, color: colors.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(engine.city.value,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Text(engine.country.value,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    engine.updatingLocation.value
                        ? const SizedBox.square(
                            dimension: 48,
                            child: Center(
                              child: SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  semanticsLabel: "Updating location",
                                ),
                              ),
                            ),
                          )
                        : IconButton(
                            tooltip: "Update location",
                            onPressed: () => updateLocation(engine),
                            icon: const Icon(Icons.refresh),
                          ),
                  ]),
                ),
              );
            }),
            Expanded(
              child: GetBuilder<SearchEngine>(builder: (engine) {
                final days =
                    min(engine.userPrayer.length, engine.meccaPrayer.length);
                return SmartRefresher(
                  enablePullDown: false,
                  enablePullUp: true,
                  controller: engine.listRefresher,
                  footer: const ClassicFooter(
                    loadingIcon: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  ),
                  onLoading: engine.loadMoreMonth,
                  child: ListView.builder(
                    itemCount: days,
                    itemBuilder: (context, index) => DayCard(
                      mecca: engine.meccaPrayer[index],
                      local: engine.userPrayer[index],
                      city: engine.placeName(),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      }),
    );
  }

  /// Keeps the current list on screen while the location is re-read; a
  /// failure shows a SnackBar with the reason and a Try again action.
  Future<void> updateLocation(SearchEngine engine) async {
    final error = await engine.updateLocation();
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(error),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: "Try again",
          onPressed: () => updateLocation(engine),
        ),
      ));
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
