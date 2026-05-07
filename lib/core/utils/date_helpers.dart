import 'package:intl/intl.dart';

class DateHelpers {
  const DateHelpers._();

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month);
  static DateTime endOfMonth(DateTime d) {
    final next = d.month == 12
        ? DateTime(d.year + 1)
        : DateTime(d.year, d.month + 1);
    return next.subtract(const Duration(milliseconds: 1));
  }

  static int daysInMonth(DateTime d) =>
      DateTime(d.year, d.month + 1, 0).day;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String formatDate(DateTime d, String localeTag) =>
      DateFormat.yMMMd(localeTag).format(d);

  static String formatMonth(DateTime d, String localeTag) =>
      DateFormat.yMMMM(localeTag).format(d);

  static String formatDateTime(DateTime d, String localeTag) =>
      DateFormat.yMMMd(localeTag).add_jm().format(d);

  static String formatRelative(DateTime d, String localeTag, DateTime now) {
    final diff = now.difference(d);
    if (diff.inDays == 0 && isSameDay(d, now)) return 'Today';
    if (isSameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    if (diff.inDays.abs() < 7) {
      return DateFormat.EEEE(localeTag).format(d);
    }
    return formatDate(d, localeTag);
  }
}
