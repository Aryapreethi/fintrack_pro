import 'package:fintrack_app/core/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats USD with grouping in en', () {
      const f = CurrencyFormatter(localeTag: 'en', currencyCode: 'USD');
      final out = f.format(1234.5);
      expect(out.contains('1,234'), isTrue);
      expect(out.contains(r'$'), isTrue);
    });

    test('formats INR with Hindi locale', () {
      const f = CurrencyFormatter(localeTag: 'hi', currencyCode: 'INR');
      final out = f.format(1234.5);
      expect(out.contains('₹'), isTrue);
    });

    test('parse handles grouping characters', () {
      const f = CurrencyFormatter(localeTag: 'en', currencyCode: 'USD');
      expect(f.parse('1,234.56'), 1234.56);
      expect(f.parse('   '), isNull);
      expect(f.parse('not a number'), isNull);
    });

    test('compact format produces short string', () {
      const f = CurrencyFormatter(localeTag: 'en', currencyCode: 'USD');
      final out = f.formatCompact(125000);
      expect(out.length, lessThan(10));
    });
  });
}
