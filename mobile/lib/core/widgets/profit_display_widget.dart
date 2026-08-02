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
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Log expense to see profit',
            style: TextStyle(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.bold,
              fontSize: textStyle?.fontSize ?? 13,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.info_outline_rounded,
            size: (textStyle?.fontSize ?? 13) + 2,
            color: Colors.orange.shade800,
          ),
        ],
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
