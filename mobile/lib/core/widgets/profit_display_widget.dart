import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/currency_formatter.dart';

class ProfitDisplayWidget extends StatelessWidget {
  final double expenseAmount;
  final double profitAmount;
  final double? percentageChange;
  final TextStyle? textStyle;
  final bool showPercentBadge;

  const ProfitDisplayWidget({
    super.key,
    required this.expenseAmount,
    required this.profitAmount,
    this.percentageChange,
    this.textStyle,
    this.showPercentBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    if (expenseAmount <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.amber.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withAlpha(80), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, size: 13, color: Colors.amber.shade800),
            const SizedBox(width: 5),
            Text(
              'Add expense to know profit',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade800,
              ),
            ),
          ],
        ),
      );
    }

    final isPositive = profitAmount >= 0;
    final formattedAmount = CurrencyFormatter.format(profitAmount);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formattedAmount,
          style: textStyle ??
              TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isPositive ? AppColors.secondary : Colors.red,
              ),
        ),
        if (expenseAmount <= 0 && profitAmount > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.withAlpha(60), width: 0.8),
            ),
            child: const Text(
              'Gross (₹0 exp)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.amber,
              ),
            ),
          ),
        ],
        if (showPercentBadge && percentageChange != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (percentageChange! >= 0 ? Colors.green : Colors.red)
                  .withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${percentageChange! >= 0 ? '+' : ''}${percentageChange!.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: percentageChange! >= 0
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
