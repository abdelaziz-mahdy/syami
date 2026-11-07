import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syami/calendar_page.dart';
import 'package:syami/controller/engine.dart';
import 'package:syami/controller/today.dart';
import 'package:syami/day_card.dart';
import 'package:syami/location_header.dart';

/// The time the Today view counts from. Tests replace it with a fixed one.
DateTime Function() appClock = DateTime.now;

void openFullCalendar(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => const CalendarPage()));

/// The home screen: where you are, today's prayers with a countdown to the
/// next one, Ramadan, and the way into the full calendar.
class TodayView extends StatelessWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const LocationHeader(),
          const TodayCard(),
          const RamadanCard(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: FilledButton.tonalIcon(
              onPressed: () => openFullCalendar(context),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text("Full calendar"),
            ),
          ),
        ],
      ),
    );
  }
}

/// Today: the dates, the next prayer with a live countdown, the five
/// prayers for Mecca and the city, and today's fasting facts.
class TodayCard extends StatefulWidget {
  const TodayCard({super.key});

  @override
  State<TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<TodayCard> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Redraw on each new minute so the countdown stays current.
    final now = appClock();
    _tick = Timer(Duration(seconds: 60 - now.second), () {
      if (!mounted) return;
      setState(() {});
      _tick = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    return GetX<SearchEngine>(builder: (engine) {
      final now = appClock();
      final days = engine.userPrayer;
      if (days.isEmpty || engine.meccaPrayer.isEmpty) {
        return const SizedBox.shrink();
      }
      final today = dayFor(days, now) ?? days.first;
      final index = days.indexOf(today);
      final mecca = engine.meccaPrayer[index];
      final tomorrow = index + 1 < days.length ? days[index + 1] : null;
      final next = nextPrayer(now, today, tomorrow);
      final city = engine.placeName();
      final time = clockFormat(context);

      return SurfaceCard(children: [
        Text("Today",
            style: text.labelLarge
                ?.copyWith(color: colors.primary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(DateFormat("EEEE d MMMM y").format(today.date),
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        if (today.hijri != null)
          Text("${today.hijri}",
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
        if (next != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: colors.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(nextPrayerText(now, next),
                      style: text.titleMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w600)),
                ),
                Text(time.format(next.time),
                    style: text.titleMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontFeatures: tabularFigures)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        PrayerTable(
          mecca: mecca,
          local: today,
          city: city,
          highlight: next != null && !next.tomorrow ? next.name : null,
        ),
        const SizedBox(height: 12),
        FastingFacts(mecca: mecca, local: today, city: city),
      ]);
    });
  }
}

/// How far away Ramadan is, or how far into it today is. The dates are the
/// calculated ones; the real start depends on the moon sighting.
class RamadanCard extends StatelessWidget {
  const RamadanCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final date = DateFormat("EEEE d MMMM y");
    return GetX<SearchEngine>(builder: (engine) {
      final dates = engine.ramadan.value;
      final error = engine.ramadanError.value;
      final children = <Widget>[];
      if (error.isNotEmpty) {
        children.addAll([
          Text("Ramadan", style: text.titleMedium),
          const SizedBox(height: 4),
          Text(error, style: text.bodyMedium),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: engine.loadRamadan,
              icon: const Icon(Icons.refresh),
              label: const Text("Try again"),
            ),
          ),
        ]);
      } else if (dates == null) {
        children.addAll([
          Text("Ramadan", style: text.titleMedium),
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ]);
      } else {
        final (title, detail) = switch (ramadanStatus(appClock(), dates)) {
          RamadanAhead(daysUntil: 1, :final start) => (
              "Ramadan starts tomorrow",
              "Expected on ${date.format(start)}."
            ),
          RamadanAhead(:final daysUntil, :final start) => (
              "Ramadan starts in $daysUntil days",
              "Expected on ${date.format(start)}."
            ),
          RamadanNow(:final day, daysLeft: 0, :final end) => (
              "Day $day of Ramadan · last day",
              "Expected to end on ${date.format(end)}."
            ),
          RamadanNow(:final day, daysLeft: 1, :final end) => (
              "Day $day of Ramadan · 1 day left",
              "Expected to end on ${date.format(end)}."
            ),
          RamadanNow(:final day, :final daysLeft, :final end) => (
              "Day $day of Ramadan · $daysLeft days left",
              "Expected to end on ${date.format(end)}."
            ),
          RamadanOver() => ("", ""),
        };
        if (title.isEmpty) return const SizedBox.shrink();
        children.addAll([
          Text(title,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(detail, style: text.bodyMedium),
          const SizedBox(height: 6),
          Text("The real start and end depend on the moon sighting.",
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
        ]);
      }
      return SurfaceCard(children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 12),
              child: Icon(Icons.nightlight_outlined, color: colors.primary),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ]);
    });
  }
}
