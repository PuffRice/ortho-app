import 'package:flutter/material.dart';

/// Every timestamp persisted by the app is a UTC ISO-8601 string.
/// Always convert to local time before showing it to the user, and let the
/// command handlers store `DateTime`s in UTC (they call `toUtc()` themselves).
class AppDateTime {
  const AppDateTime._();

  static DateTime toLocal(DateTime value) => value.toLocal();

  static DateTime toUtc(DateTime value) => value.toUtc();

  static String formatMediumDate(BuildContext context, DateTime value) {
    return MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
  }

  static String formatShortDate(BuildContext context, DateTime value) {
    return MaterialLocalizations.of(context).formatShortDate(value.toLocal());
  }

  static String formatTime(BuildContext context, DateTime value) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(value.toLocal()),
    );
  }

  /// `21 Oct 2026, 14:30`
  static String formatDateTime(BuildContext context, DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    final local = value.toLocal();
    final date = localizations.formatMediumDate(local);
    final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local));
    return '$date, $time';
  }

  /// `21 Oct 2026, 14:30` (no BuildContext needed, used by exports/services)
  static String formatLocalDateTime(DateTime value) {
    final local = value.toLocal();
    return '${formatLocalDate(local)}, ${formatLocalTime(local)}';
  }

  /// `21 Oct 2026`
  static String formatLocalDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day} ${_monthNames[local.month - 1]} ${local.year}';
  }

  /// `14:30`
  static String formatLocalTime(DateTime value) {
    final local = value.toLocal();
    return '${_two(local.hour)}:${_two(local.minute)}';
  }

  /// `2026-10-21 14:30`
  static String formatLocalDateTimeStamp(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${_two(local.month)}-${_two(local.day)} '
        '${_two(local.hour)}:${_two(local.minute)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}
