import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String currencySymbol = '₹'}) {
    final formatter = NumberFormat.currency(
      symbol: '$currencySymbol ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatCompact(double amount, {String currencySymbol = '₹'}) {
    final formatter = NumberFormat.compactCurrency(
      symbol: '$currencySymbol ',
      decimalDigits: 1,
    );
    return formatter.format(amount);
  }
}
