import 'package:fintrack_app/core/utils/date_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateHelpers', () {
    test('startOfMonth and endOfMonth are inclusive', () {
      final d = DateTime(2026, 5, 7, 12);
      expect(DateHelpers.startOfMonth(d), DateTime(2026, 5));
      final end = DateHelpers.endOfMonth(d);
      expect(end.year, 2026);
      expect(end.month, 5);
      expect(end.day, 31);
    });

    test('daysInMonth is correct for leap year February', () {
      expect(DateHelpers.daysInMonth(DateTime(2024, 2)), 29);
      expect(DateHelpers.daysInMonth(DateTime(2025, 2)), 28);
    });

    test('isSameDay distinguishes by date only', () {
      final a = DateTime(2026, 5, 7, 1);
      final b = DateTime(2026, 5, 7, 23);
      final c = DateTime(2026, 5, 8);
      expect(DateHelpers.isSameDay(a, b), isTrue);
      expect(DateHelpers.isSameDay(a, c), isFalse);
    });
  });
}
