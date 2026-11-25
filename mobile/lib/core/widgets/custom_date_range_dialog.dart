import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';

/// Opens a dedicated modal with separate **From Date** and **To Date** pickers.
Future<DateTimeRange?> showCustomDateRangeModal(
  BuildContext context, {
  DateTime? initialStart,
  DateTime? initialEnd,
  String title = 'Select Date Range',
}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  DateTime fromDate = initialStart != null
      ? DateTime(initialStart.year, initialStart.month, initialStart.day)
      : today.subtract(const Duration(days: 6));
  if (fromDate.isAfter(today)) fromDate = today;

  DateTime toDate = initialEnd != null
      ? DateTime(initialEnd.year, initialEnd.month, initialEnd.day)
      : today;
  if (toDate.isAfter(today)) toDate = today;
  if (toDate.isBefore(fromDate)) toDate = fromDate;

  return showDialog<DateTimeRange>(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final dayCount = toDate.difference(fromDate).inDays + 1;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
            contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            title: Row(
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Pick a starting date and ending date:',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  InlineFromToDatePickers(
                    fromDate: fromDate,
                    toDate: toDate,
                    onFromChanged: (picked) {
                      setDialogState(() {
                        fromDate = DateTime(picked.year, picked.month, picked.day);
                        if (toDate.isBefore(fromDate)) {
                          toDate = fromDate;
                        }
                      });
                    },
                    onToChanged: (picked) {
                      setDialogState(() {
                        toDate = DateTime(picked.year, picked.month, picked.day);
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_available_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '$dayCount ${dayCount == 1 ? 'day' : 'days'} selected',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(
                    dialogCtx,
                    DateTimeRange(
                      start: DateTime(
                        fromDate.year,
                        fromDate.month,
                        fromDate.day,
                        0,
                        0,
                        0,
                      ),
                      end: DateTime(
                        toDate.year,
                        toDate.month,
                        toDate.day,
                        23,
                        59,
                        59,
                        999,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Apply Range',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Dual **From Date** and **To Date** picker widget reusable inside modals and dialogs.
class InlineFromToDatePickers extends StatelessWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final ValueChanged<DateTime> onFromChanged;
  final ValueChanged<DateTime> onToChanged;

  const InlineFromToDatePickers({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.onFromChanged,
    required this.onToChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeFrom = fromDate.isAfter(today) ? today : fromDate;
    final safeTo = toDate.isBefore(safeFrom)
        ? safeFrom
        : (toDate.isAfter(today) ? today : toDate);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DatePickerFieldTile(
          label: 'From Date',
          date: safeFrom,
          icon: Icons.login_rounded,
          isDark: isDark,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: safeFrom,
              firstDate: DateTime(2020),
              lastDate: today,
              helpText: 'Select From Date',
            );
            if (picked != null) {
              onFromChanged(DateTime(picked.year, picked.month, picked.day));
            }
          },
        ),
        const SizedBox(height: 10),
        _DatePickerFieldTile(
          label: 'To Date',
          date: safeTo,
          icon: Icons.logout_rounded,
          isDark: isDark,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: safeTo,
              firstDate: safeFrom,
              lastDate: today,
              helpText: 'Select To Date',
            );
            if (picked != null) {
              onToChanged(DateTime(picked.year, picked.month, picked.day));
            }
          },
        ),
      ],
    );
  }
}

class _DatePickerFieldTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _DatePickerFieldTile({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ??
              (isDark ? AppColors.darkCard : AppColors.lightBackground),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.dividerColor.withAlpha(110),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy').format(date),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
