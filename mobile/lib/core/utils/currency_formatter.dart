import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final Map<String, NumberFormat> _currencyFormatters = {};
  static final NumberFormat _indianIntFormatter = NumberFormat('#,##,##0', 'en_IN');

  static NumberFormat _getFormatter(String currencySymbol, int decimalDigits) {
    final key = '$currencySymbol|$decimalDigits';
    return _currencyFormatters.putIfAbsent(
      key,
      () => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '$currencySymbol ',
        decimalDigits: decimalDigits,
      ),
    );
  }

  /// Formats monetary values using the Indian numbering system (e.g. ₹ 10,00,000.00).
  static String format(
    double amount, {
    String currencySymbol = '₹',
    int decimalDigits = 2,
  }) {
    if (amount < 0) {
      final positive = _getFormatter(currencySymbol, decimalDigits).format(amount.abs());
      return '-$positive';
    }
    return _getFormatter(currencySymbol, decimalDigits).format(amount);
  }

  /// Formats integer counts using the Indian numbering system (e.g. 1,00,000).
  static String formatInteger(num value) {
    return _indianIntFormatter.format(value.round());
  }

  /// Formats monetary values using Indian compact units (Cr, L, K).
  static String formatCompact(double amount, {String currencySymbol = '₹'}) {
    final sign = amount < 0 ? '-' : '';
    final abs = amount.abs();
    if (abs >= 10000000) {
      final val = abs / 10000000;
      return '$sign$currencySymbol ${val >= 100 ? val.toStringAsFixed(0) : val.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '')} Cr';
    }
    if (abs >= 100000) {
      final val = abs / 100000;
      return '$sign$currencySymbol ${val >= 100 ? val.toStringAsFixed(0) : val.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '')} L';
    }
    if (abs >= 1000) {
      final val = abs / 1000;
      return '$sign$currencySymbol ${val >= 100 ? val.toStringAsFixed(0) : val.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')} K';
    }
    return '$sign$currencySymbol ${abs == abs.roundToDouble() ? abs.toStringAsFixed(0) : abs.toStringAsFixed(2)}';
  }
}
