import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syami/controller/classes.dart';

/// "12 h 33 min" for a fasting duration.
String formatFastingDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, "0");
  return "${duration.inHours} h $minutes min";
}

/// One day: the five prayers for Mecca and the user's city side by side,
/// then both fasting durations and the iftar time that matches Mecca's.
///
/// Every time sits on one line with tabular figures, one row per prayer, so
/// rows keep the same height whatever the time ("12:04 PM" used to wrap in
/// a five-column grid while "5:09 AM" didn't).
class DayCard extends StatelessWidget {
  const DayCard({
    super.key,
    required this.mecca,
    required this.local,
    required this.city,
  });

  final DayPrayer mecca;
  final DayPrayer local;
  final String city;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;
    final time = DateFormat(use24h ? 'HH:mm' : 'h:mm a');
    final date = DateFormat("dd-MM-yyyy");
    const tabular = [FontFeature.tabularFigures()];

    Widget card(List<Widget> children) => Card(
          elevation: 0,
          color: colors.surfaceContainer,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        );

    final heading = Row(
      children: [
        Expanded(
          child: Text(mecca.weekDay,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        Text(date.format(mecca.date),
            style: text.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant, fontFeatures: tabular)),
      ],
    );

    if (date.format(mecca.date) != date.format(local.date)) {
      return card([
        heading,
        const SizedBox(height: 8),
        Text("Dates are not the same",
            style: text.bodyMedium?.copyWith(color: colors.error)),
        const SizedBox(height: 6),
        Text("Mecca date: ${date.format(mecca.date)}", style: text.bodyMedium),
        Text("$city date: ${date.format(local.date)}", style: text.bodyMedium),
      ]);
    }

    final fastingMecca = mecca.maghrib.difference(mecca.fajr);
    final fastingLocal = local.maghrib.difference(local.fajr);
    final iftar = local.fajr.add(fastingMecca);

    final headerStyle = text.labelMedium
        ?.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600);
    final timeStyle = text.bodyLarge?.copyWith(fontFeatures: tabular);

    Widget cell(String value, {TextStyle? style, bool end = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Align(
            alignment: end ? Alignment.centerRight : Alignment.centerLeft,
            // Times never wrap: scale down rather than break a line.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: end ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(value, style: style, maxLines: 1, softWrap: false),
            ),
          ),
        );

    final prayers = [
      ("Fajr", mecca.fajr, local.fajr),
      ("Dhuhr", mecca.dhuhr, local.dhuhr),
      ("Asr", mecca.asr, local.asr),
      ("Maghrib", mecca.maghrib, local.maghrib),
      ("Isha", mecca.isha, local.isha),
    ];

    final table = Table(
      columnWidths: const {
        0: FlexColumnWidth(1.1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          children: [
            cell("Prayer", style: headerStyle),
            cell("Mecca", style: headerStyle, end: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Text(city,
                  style: headerStyle,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        for (final (i, (name, inMecca, inCity)) in prayers.indexed)
          TableRow(
            decoration: BoxDecoration(
              color: i.isOdd ? colors.surfaceContainerHighest : null,
              borderRadius: BorderRadius.circular(6),
            ),
            children: [
              cell(name, style: text.bodyLarge),
              cell(time.format(inMecca), style: timeStyle, end: true),
              cell(time.format(inCity), style: timeStyle, end: true),
            ],
          ),
      ],
    );

    Widget fact(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(label, style: text.bodyMedium)),
              const SizedBox(width: 12),
              Text(value,
                  maxLines: 1,
                  softWrap: false,
                  style: text.titleSmall
                      ?.copyWith(color: colors.primary, fontFeatures: tabular)),
            ],
          ),
        );

    return card([
      heading,
      const SizedBox(height: 10),
      table,
      const SizedBox(height: 12),
      fact("Fasting in Mecca", formatFastingDuration(fastingMecca)),
      fact("Fasting in $city", formatFastingDuration(fastingLocal)),
      fact("Iftar using Mecca's fasting time", time.format(iftar)),
    ]);
  }
}
