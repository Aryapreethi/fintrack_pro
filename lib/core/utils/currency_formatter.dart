import 'package:intl/intl.dart';

class CurrencyFormatter {
  const CurrencyFormatter({
    required this.localeTag,
    required this.currencyCode,
  });

  final String localeTag;
  final String currencyCode;

  String format(num amount) {
    final fmt = NumberFormat.currency(
      locale: localeTag,
      name: currencyCode,
      symbol: _symbolFor(currencyCode),
    );
    return fmt.format(amount);
  }

  String formatCompact(num amount) {
    final fmt = NumberFormat.compactCurrency(
      locale: localeTag,
      name: currencyCode,
      symbol: _symbolFor(currencyCode),
    );
    return fmt.format(amount);
  }

  String formatPlain(num amount) {
    return NumberFormat.decimalPattern(localeTag).format(amount);
  }

  /// Convert a user-typed string (possibly with grouping/decimal separators)
  /// into a parsable double. Returns null if invalid.
  double? parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    try {
      return NumberFormat.decimalPattern(localeTag).parse(trimmed).toDouble();
    } catch (_) {
      // Fallback: strip non-digit/decimal-point chars and try plain double.
      final cleaned = trimmed.replaceAll(RegExp(r'[^0-9.\-]'), '');
      return double.tryParse(cleaned);
    }
  }

  static String _symbolFor(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      case 'AUD':
        return r'A$';
      case 'CAD':
        return r'C$';
      default:
        return code;
    }
  }
}
