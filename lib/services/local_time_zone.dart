import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


DateTime getNow() {
  return tz.TZDateTime.now(tz.local);
}

Future<void> configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

tz.TZDateTime nextInstanceOfSunday8AM() {
  final now = getNow();
  final daysUntilSunday = 7 - now.weekday;
  final nextSunday = now.add(Duration(days: daysUntilSunday));
  final nextSunday8AM = tz.TZDateTime(
    tz.local,
    nextSunday.year,
    nextSunday.month,
    nextSunday.day,
    8,
    0,
  );
  return nextSunday8AM.isBefore(now) ? nextSunday8AM.add(const Duration(days: 7)) : nextSunday8AM;
}

// Only for debugging
tz.TZDateTime inSeconds(int seconds) {
  final now = tz.TZDateTime.now(tz.local);
  return now.add(Duration(seconds: seconds));
}

