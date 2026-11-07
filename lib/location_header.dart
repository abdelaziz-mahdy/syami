import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syami/controller/engine.dart';

/// The place the times are for, with Update location on the right.
///
/// Update location keeps whatever is on screen while the position is
/// re-read; a failure shows a SnackBar with the reason and Try again.
class LocationHeader extends StatefulWidget {
  const LocationHeader({super.key});

  @override
  State<LocationHeader> createState() => _LocationHeaderState();
}

class _LocationHeaderState extends State<LocationHeader> {
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

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return GetX<SearchEngine>(builder: (engine) {
      // Same flat surface as the day cards: the place is the title, the
      // country under it, Update location on the right.
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
    });
  }
}
