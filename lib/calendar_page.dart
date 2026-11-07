import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:syami/controller/engine.dart';
import 'package:syami/day_card.dart';
import 'package:syami/location_header.dart';

/// Every loaded day from today on, one card each; pulling up at the end
/// loads the next month.
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Full calendar")),
      body: const Column(
        children: [
          LocationHeader(),
          Expanded(child: MonthList()),
        ],
      ),
    );
  }
}

class MonthList extends StatelessWidget {
  const MonthList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GetBuilder<SearchEngine>(builder: (engine) {
      final days = min(engine.userPrayer.length, engine.meccaPrayer.length);
      // The app draws behind the navigation bar (edge-to-edge), so keep the
      // last card and the next-month footer above it.
      return SafeArea(
        top: false,
        child: SmartRefresher(
          enablePullDown: false,
          enablePullUp: true,
          controller: engine.listRefresher,
          // The package's default footer copy ("Pull up load", "Load
          // Failed!") is replaced with plain sentences in theme text.
          footer: ClassicFooter(
            idleText: "Pull up for the next month",
            canLoadingText: "Release to load the next month",
            loadingText: "Loading the next month",
            failedText: "Couldn't load the next month. Pull up to try again.",
            textStyle: theme.textTheme.bodyMedium!
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
            loadingIcon: const SizedBox.square(
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
        ),
      );
    });
  }
}
