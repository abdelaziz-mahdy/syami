import 'package:timezone/data/latest_all.dart' as tz_data;

/// Loads the full IANA time zone database.
///
/// The aladhan.com API names each city's zone, and many of those names are
/// links (Asia/Kuwait, Asia/Muscat, Asia/Kuala_Lumpur, Europe/Sarajevo,
/// Europe/Stockholm...). The smaller `latest.dart` database leaves 257 of
/// them out, so prayer times failed to load for everyone in those zones.
void loadTimeZones() => tz_data.initializeTimeZones();
