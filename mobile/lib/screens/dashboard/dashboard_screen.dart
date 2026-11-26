import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/storage/local_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/report_export_helper.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/custom_date_range_dialog.dart';
import '../../core/widgets/metric_card_widget.dart';
import '../../core/widgets/profit_display_widget.dart';
import '../../core/widgets/revenue_line_chart_widget.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';

enum _ReportExportType { reports, customers, orders, backup }

enum _ReportExportScope {
  selectedPeriod,
  allTime,
  today,
  thisMonth,
  last1Month,
  last3Months,
  last6Months,
  custom,
}

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onGoToBilling;
  final VoidCallback onOpenSettings;
  final VoidCallback? onOpenOrders;
  final VoidCallback? onOpenExpenses;

  const DashboardScreen({
    super.key,
    required this.onGoToBilling,
    required this.onOpenSettings,
    this.onOpenOrders,
    this.onOpenExpenses,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _selectedTimeframe = 'Monthly';
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _customRange;
  Map<String, dynamic>? _periodData;
  AvailableDataDates _availableDates = AvailableDataDates.empty;
  bool _isLoadingPeriod = false;
  bool _showAllDishes = false;
  bool _isExporting = false;

  static const List<({String id, String label})> _timeframeOptions = [
    (id: 'Daily', label: 'Daily'),
    (id: 'Weekly', label: 'Weekly'),
    (id: 'Monthly', label: 'Monthly'),
    (id: 'Yearly', label: 'Yearly'),
    (id: 'Custom', label: 'Custom'),
    (id: 'All Time', label: 'All'),
  ];

  @override
  void initState() {
    super.initState();
    _loadPeriodReport();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).refresh();
    });
  }

  DateTimeRange get _effectiveCustomRange {
    if (_customRange != null) return _customRange!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    return DateTimeRange(start: weekStart, end: today);
  }

  Future<void> _loadPeriodReport() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPeriod = true;
      _showAllDishes = false;
    });
    try {
      final range = _selectedTimeframe == 'Custom' ? _effectiveCustomRange : null;
      final results = await Future.wait([
        LocalDatabase.instance.computePeriodReports(
          timeframe: _selectedTimeframe,
          referenceDate: _selectedDate,
          customStartDate: range?.start,
          customEndDate: range?.end,
        ),
        LocalDatabase.instance.getAvailableDataDates(
          includeOrders: true,
          includeExpenses: true,
          excludeRefundedOrders: true,
        ),
      ]);
      final data = results[0] as Map<String, dynamic>;
      final avail = results[1] as AvailableDataDates;
      if (mounted) {
        setState(() {
          _periodData = data;
          _availableDates = avail;
          _isLoadingPeriod = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading period report: $e');
      if (mounted) {
        setState(() => _isLoadingPeriod = false);
      }
    }
  }

  bool get _canGoPrevious {
    if (_selectedTimeframe == 'All Time') return false;
    if (_availableDates.isEmpty) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earliest = _availableDates.earliestDate;
    if (earliest == null) return false;

    switch (_selectedTimeframe) {
      case 'Daily':
        final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        return selected.isAfter(earliest);
      case 'Weekly':
        final mondaySelected = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final mondayEarliest = earliest.subtract(Duration(days: earliest.weekday - 1));
        return DateTime(mondaySelected.year, mondaySelected.month, mondaySelected.day)
            .isAfter(DateTime(mondayEarliest.year, mondayEarliest.month, mondayEarliest.day));
      case 'Monthly':
        final currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
        return _availableDates.sortedMonths.any((m) => m.isBefore(currentMonth));
      case 'Yearly':
        return _availableDates.years.any((y) => y < _selectedDate.year);
      case 'Custom':
        final start = _effectiveCustomRange.start;
        final clampedToday = earliest.isAfter(today) ? today : earliest;
        return DateTime(start.year, start.month, start.day).isAfter(clampedToday);
      default:
        return false;
    }
  }

  bool get _canGoNext {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final latest = _availableDates.latestDate;
    final upperDay = latest != null && !latest.isAfter(today) ? latest : today;

    switch (_selectedTimeframe) {
      case 'Daily':
        final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        return selected.isBefore(_availableDates.isEmpty ? today : upperDay);
      case 'Weekly':
        final mondaySelected = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final refEnd = _availableDates.isEmpty ? now : upperDay;
        final mondayUpper = refEnd.subtract(Duration(days: refEnd.weekday - 1));
        return DateTime(mondaySelected.year, mondaySelected.month, mondaySelected.day)
            .isBefore(DateTime(mondayUpper.year, mondayUpper.month, mondayUpper.day));
      case 'Monthly':
        final currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final currentRealMonth = DateTime(now.year, now.month, 1);
        if (_availableDates.isEmpty) {
          return currentMonth.isBefore(currentRealMonth);
        }
        return _availableDates.sortedMonths.any(
          (m) => m.isAfter(currentMonth) && !m.isAfter(currentRealMonth),
        );
      case 'Yearly':
        if (_availableDates.isEmpty) {
          return _selectedDate.year < now.year;
        }
        return _availableDates.years.any((y) => y > _selectedDate.year && y <= now.year);
      case 'Custom':
        final end = _effectiveCustomRange.end;
        return DateTime(end.year, end.month, end.day)
            .isBefore(_availableDates.isEmpty ? today : upperDay);
      case 'All Time':
      default:
        return false;
    }
  }

  bool _weekIntersectsAvailableMonth(DateTime refDate) {
    if (_availableDates.isEmpty) return true;
    final mon = DateTime(refDate.year, refDate.month, refDate.day)
        .subtract(Duration(days: refDate.weekday - 1));
    final sun = mon.add(const Duration(days: 6));
    return _availableDates.hasMonthForDate(mon) || _availableDates.hasMonthForDate(sun);
  }

  void _onPreviousPeriod() {
    if (!_canGoPrevious || _selectedTimeframe == 'All Time') return;
    final sortedMonths = _availableDates.sortedMonths;

    setState(() {
      switch (_selectedTimeframe) {
        case 'Daily':
          final candidate = _selectedDate.subtract(const Duration(days: 1));
          if (_availableDates.isNotEmpty && !_availableDates.hasMonthForDate(candidate)) {
            final candMonth = DateTime(candidate.year, candidate.month, 1);
            final prevMonths = sortedMonths.where((m) => m.isBefore(candMonth)).toList();
            if (prevMonths.isNotEmpty) {
              final targetM = prevMonths.last;
              _selectedDate = DateTime(targetM.year, targetM.month + 1, 0);
            }
          } else {
            _selectedDate = candidate;
          }
          break;
        case 'Weekly':
          final candidate = _selectedDate.subtract(const Duration(days: 7));
          if (_availableDates.isNotEmpty && !_weekIntersectsAvailableMonth(candidate)) {
            final mondaySelected = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
            final monMonth = DateTime(mondaySelected.year, mondaySelected.month, 1);
            final prevMonths = sortedMonths.where((m) => m.isBefore(monMonth)).toList();
            if (prevMonths.isNotEmpty) {
              final targetM = prevMonths.last;
              _selectedDate = DateTime(targetM.year, targetM.month + 1, 0);
            }
          } else {
            _selectedDate = candidate;
          }
          break;
        case 'Monthly':
          final currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
          final prevMonths = sortedMonths.where((m) => m.isBefore(currentMonth)).toList();
          if (prevMonths.isNotEmpty) {
            _selectedDate = prevMonths.last;
          }
          break;
        case 'Yearly':
          final prevYears = _availableDates.years.where((y) => y < _selectedDate.year).toList()..sort();
          if (prevYears.isNotEmpty) {
            _selectedDate = DateTime(prevYears.last, 1, 1);
          }
          break;
        case 'Custom':
          final current = _effectiveCustomRange;
          final spanDays = current.end.difference(current.start).inDays + 1;
          _customRange = DateTimeRange(
            start: current.start.subtract(Duration(days: spanDays)),
            end: current.end.subtract(Duration(days: spanDays)),
          );
          break;
      }
    });
    _loadPeriodReport();
  }

  void _onNextPeriod() {
    if (!_canGoNext || _selectedTimeframe == 'All Time') return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sortedMonths = _availableDates.sortedMonths;

    setState(() {
      switch (_selectedTimeframe) {
        case 'Daily':
          final candidate = _selectedDate.add(const Duration(days: 1));
          final clamped = candidate.isAfter(today) ? today : candidate;
          if (_availableDates.isNotEmpty && !_availableDates.hasMonthForDate(clamped)) {
            final candMonth = DateTime(clamped.year, clamped.month, 1);
            final nextMonths = sortedMonths.where((m) => m.isAfter(candMonth)).toList();
            if (nextMonths.isNotEmpty) {
              _selectedDate = nextMonths.first;
            }
          } else {
            _selectedDate = clamped;
          }
          break;
        case 'Weekly':
          final candidate = _selectedDate.add(const Duration(days: 7));
          if (_availableDates.isNotEmpty && !_weekIntersectsAvailableMonth(candidate)) {
            final sundaySelected = _selectedDate
                .subtract(Duration(days: _selectedDate.weekday - 1))
                .add(const Duration(days: 6));
            final sunMonth = DateTime(sundaySelected.year, sundaySelected.month, 1);
            final nextMonths = sortedMonths.where((m) => m.isAfter(sunMonth)).toList();
            if (nextMonths.isNotEmpty) {
              _selectedDate = nextMonths.first;
            }
          } else {
            _selectedDate = candidate;
          }
          break;
        case 'Monthly':
          final currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
          final currentRealMonth = DateTime(now.year, now.month, 1);
          final nextMonths = sortedMonths
              .where((m) => m.isAfter(currentMonth) && !m.isAfter(currentRealMonth))
              .toList();
          if (nextMonths.isNotEmpty) {
            _selectedDate = nextMonths.first;
          } else if (currentMonth.isBefore(currentRealMonth)) {
            _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          }
          break;
        case 'Yearly':
          final nextYears = _availableDates.years
              .where((y) => y > _selectedDate.year && y <= now.year)
              .toList()
            ..sort();
          if (nextYears.isNotEmpty) {
            _selectedDate = DateTime(nextYears.first, 1, 1);
          } else if (_selectedDate.year < now.year) {
            _selectedDate = DateTime(_selectedDate.year + 1, 1, 1);
          }
          break;
        case 'Custom':
          final current = _effectiveCustomRange;
          final spanDays = current.end.difference(current.start).inDays + 1;
          var newStart = current.start.add(Duration(days: spanDays));
          var newEnd = current.end.add(Duration(days: spanDays));
          if (newEnd.isAfter(today)) {
            newEnd = today;
            newStart = today.subtract(Duration(days: spanDays - 1));
          }
          _customRange = DateTimeRange(start: newStart, end: newEnd);
          break;
      }
    });
    _loadPeriodReport();
  }

  Future<void> _onTapSlicerCenter() async {
    switch (_selectedTimeframe) {
      case 'Monthly':
        await _pickMonthYear();
        break;
      case 'Yearly':
        await _pickYear();
        break;
      case 'Custom':
        await _pickCustomRange();
        break;
      case 'Daily':
      case 'Weekly':
        await _pickDate();
        break;
      case 'All Time':
      default:
        break;
    }
  }

  Future<AvailableDataDates> _refreshAvailableDates() async {
    final avail = await LocalDatabase.instance.getAvailableDataDates(
      includeOrders: true,
      includeExpenses: true,
      excludeRefundedOrders: true,
    );
    if (mounted) {
      setState(() => _availableDates = avail);
    }
    return avail;
  }

  Future<void> _pickDate() async {
    final available = await _refreshAvailableDates();
    if (!mounted) return;
    final c = available.buildPickerConstraints(
      candidateInitialDate: _selectedDate,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: c.initialDate,
      firstDate: c.firstDate,
      lastDate: c.lastDate,
      selectableDayPredicate: c.selectableDayPredicate,
      helpText: _selectedTimeframe == 'Weekly'
          ? 'Pick Any Date in Target Week'
          : 'Select Report Date',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadPeriodReport();
    }
  }

  Future<void> _pickCustomRange() async {
    final available = await _refreshAvailableDates();
    if (!mounted) return;
    final current = _effectiveCustomRange;
    final picked = await showCustomDateRangeModal(
      context,
      initialStart: current.start,
      initialEnd: current.end,
      title: 'Select Report Date Range',
      includeOrders: true,
      includeExpenses: true,
      excludeRefundedOrders: true,
      availableDates: available,
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedTimeframe = 'Custom';
      });
      _loadPeriodReport();
    }
  }

  Future<void> _pickMonthYear() async {
    final available = await _refreshAvailableDates();
    if (!mounted) return;
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final yearsWithData = available.years.where((y) => y <= now.year).toList()..sort();
    int dialogYear = available.isEmpty
        ? now.year
        : (yearsWithData.contains(_selectedDate.year)
            ? _selectedDate.year
            : (yearsWithData.isNotEmpty ? yearsWithData.last : now.year));

    final selected = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final prevYears = yearsWithData.where((y) => y < dialogYear).toList();
            final nextYears = yearsWithData.where((y) => y > dialogYear).toList();
            final canPrevYear = prevYears.isNotEmpty;
            final canNextYear = dialogYear < now.year && nextYears.isNotEmpty;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: canPrevYear
                        ? () => setDialogState(() => dialogYear = prevYears.last)
                        : null,
                  ),
                  Text(
                    '$dialogYear',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: canNextYear
                        ? () => setDialogState(() => dialogYear = nextYears.first)
                        : null,
                  ),
                ],
              ),
              content: SizedBox(
                width: 280,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.0,
                  ),
                  itemCount: 12,
                  itemBuilder: (_, idx) {
                    final month = idx + 1;
                    final isFuture = dialogYear > now.year ||
                        (dialogYear == now.year && month > now.month);
                    final hasData = available.isEmpty
                        ? (dialogYear == now.year && month == now.month)
                        : available.hasMonth(dialogYear, month);
                    final isDisabled = isFuture || !hasData;
                    final isCurrentSelected = !isDisabled &&
                        _selectedDate.year == dialogYear &&
                        _selectedDate.month == month;
                    final label = DateFormat('MMM').format(DateTime(dialogYear, month, 1));

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: isDisabled
                          ? null
                          : () => Navigator.pop(ctx, DateTime(dialogYear, month, 1)),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrentSelected
                              ? AppColors.primary
                              : (isDisabled
                                  ? Colors.transparent
                                  : AppColors.primary.withAlpha(20)),
                          borderRadius: BorderRadius.circular(10),
                          border: isCurrentSelected
                              ? null
                              : Border.all(
                                  color: isDisabled
                                      ? (isDark ? Colors.white12 : Colors.grey.withAlpha(38))
                                      : AppColors.primary.withAlpha(65),
                                ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: isCurrentSelected ? FontWeight.bold : FontWeight.w600,
                            color: isCurrentSelected
                                ? Colors.white
                                : (isDisabled
                                    ? (isDark ? Colors.white24 : Colors.grey.shade400)
                                    : null),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() => _selectedDate = selected);
      _loadPeriodReport();
    }
  }

  Future<void> _pickYear() async {
    final available = await _refreshAvailableDates();
    if (!mounted) return;
    final currentYear = DateTime.now().year;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final earliestYear = available.earliestDate?.year ?? currentYear;
    final minYear = earliestYear < currentYear ? earliestYear : currentYear;
    final years = List<int>.generate(
      (currentYear - minYear + 1).clamp(1, 30),
      (i) => currentYear - i,
    );
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Year', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 260,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: years.map((yr) {
              final hasData = available.isEmpty
                  ? (yr == currentYear)
                  : available.years.contains(yr);
              final isSelected = hasData && _selectedDate.year == yr;
              return ChoiceChip(
                label: Text('$yr'),
                selected: isSelected,
                selectedColor: AppColors.primary,
                disabledColor: Colors.transparent,
                side: !hasData
                    ? BorderSide(color: isDark ? Colors.white12 : Colors.grey.withAlpha(40))
                    : null,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: !hasData
                      ? (isDark ? Colors.white24 : Colors.grey.shade400)
                      : (isSelected ? Colors.white : null),
                ),
                onSelected: hasData ? (_) => Navigator.pop(ctx, yr) : null,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (selected != null) {
      setState(() => _selectedDate = DateTime(selected, 1, 1));
      _loadPeriodReport();
    }
  }

  bool get _isCurrentPeriod {
    final now = DateTime.now();
    switch (_selectedTimeframe) {
      case 'Daily':
        return _selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day;
      case 'Weekly':
        final mondaySelected = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final mondayNow = now.subtract(Duration(days: now.weekday - 1));
        return mondaySelected.year == mondayNow.year &&
            mondaySelected.month == mondayNow.month &&
            mondaySelected.day == mondayNow.day;
      case 'Monthly':
        return _selectedDate.year == now.year && _selectedDate.month == now.month;
      case 'Yearly':
        return _selectedDate.year == now.year;
      case 'Custom':
        final end = _effectiveCustomRange.end;
        return end.year == now.year && end.month == now.month && end.day == now.day;
      case 'All Time':
      default:
        return true;
    }
  }

  String get _slicerLabel {
    final now = DateTime.now();
    switch (_selectedTimeframe) {
      case 'Daily':
        if (_selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day) {
          return 'Today, ${DateFormat('d MMM yyyy').format(_selectedDate)}';
        }
        final yesterday = now.subtract(const Duration(days: 1));
        if (_selectedDate.year == yesterday.year &&
            _selectedDate.month == yesterday.month &&
            _selectedDate.day == yesterday.day) {
          return 'Yesterday, ${DateFormat('d MMM yyyy').format(_selectedDate)}';
        }
        return DateFormat('EEE, d MMM yyyy').format(_selectedDate);

      case 'Weekly':
        final monday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        if (monday.year == sunday.year && monday.month == sunday.month) {
          return '${DateFormat('d').format(monday)} - ${DateFormat('d MMM yyyy').format(sunday)}';
        } else if (monday.year == sunday.year) {
          return '${DateFormat('d MMM').format(monday)} - ${DateFormat('d MMM yyyy').format(sunday)}';
        } else {
          return '${DateFormat('d MMM yyyy').format(monday)} - ${DateFormat('d MMM yyyy').format(sunday)}';
        }

      case 'Monthly':
        return DateFormat('MMMM yyyy').format(_selectedDate);

      case 'Yearly':
        return 'Year ${_selectedDate.year}';

      case 'Custom':
        final range = _effectiveCustomRange;
        if (range.start.year == range.end.year &&
            range.start.month == range.end.month &&
            range.start.day == range.end.day) {
          return DateFormat('EEE, d MMM yyyy').format(range.start);
        }
        if (range.start.year == range.end.year && range.start.month == range.end.month) {
          return '${DateFormat('d').format(range.start)} - ${DateFormat('d MMM yyyy').format(range.end)}';
        }
        if (range.start.year == range.end.year) {
          return '${DateFormat('d MMM').format(range.start)} - ${DateFormat('d MMM yyyy').format(range.end)}';
        }
        return '${DateFormat('d MMM yy').format(range.start)} - ${DateFormat('d MMM yy').format(range.end)}';

      case 'All Time':
        return 'All Recorded History';

      default:
        return DateFormat('MMMM yyyy').format(_selectedDate);
    }
  }

  String get _comparisonSubtitle {
    return switch (_selectedTimeframe) {
      'Daily' => 'vs prior day',
      'Weekly' => 'vs prior week',
      'Monthly' => 'vs prior month',
      'Yearly' => 'vs prior year',
      'Custom' => 'vs prior period',
      _ => '',
    };
  }

  DashboardState _buildSlicedState(DashboardState fallback) =>
      _buildStateFromPeriodMap(_periodData, fallback);

  DashboardState _buildStateFromPeriodMap(
    Map<String, dynamic>? data,
    DashboardState fallback,
  ) {
    if (data == null) return fallback;
    final rev = (data['revenue'] as num?)?.toDouble() ?? 0.0;
    final exp = (data['expenses'] as num?)?.toDouble() ?? 0.0;
    final ord = (data['orderCount'] as num?)?.toInt() ?? 0;
    final prof = (data['profit'] as num?)?.toDouble() ?? (rev - exp);
    final dishes = (data['dishBreakdown'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        fallback.todayDishBreakdown;
    final rawPayments = data['paymentAnalytics'] as Map?;
    final payments = <String, double>{
      'cash': (rawPayments?['cash'] as num?)?.toDouble() ?? 0.0,
      'upi': (rawPayments?['upi'] as num?)?.toDouble() ?? 0.0,
      'card': (rawPayments?['card'] as num?)?.toDouble() ?? 0.0,
      'wallet': (rawPayments?['wallet'] as num?)?.toDouble() ?? 0.0,
    };
    final avgBill =
        (data['averageBillValue'] as num?)?.toDouble() ?? fallback.averageBillValue;
    final peak =
        (data['peakSellingHour'] as String?) ?? fallback.peakSellingHour;
    final chartPoints = (data['chartDataPoints'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [];
    final expenseBreakdown = (data['expenseBreakdown'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        fallback.expenseBreakdown;
    final customerAnalytics = data['customerAnalytics'] is Map
        ? Map<String, dynamic>.from(data['customerAnalytics'] as Map)
        : fallback.customerAnalytics;

    return fallback.copyWith(
      todayRevenue: rev,
      todayOrderCount: ord,
      todayExpenseTotal: exp,
      netProfitToday: prof,
      weekRevenue: rev,
      weekOrderCount: ord,
      weekExpenseTotal: exp,
      weeklyProfit: prof,
      monthRevenue: rev,
      monthOrderCount: ord,
      monthExpenseTotal: exp,
      monthlyProfit: prof,
      overallRevenue: rev,
      overallOrderCount: ord,
      overallExpenseTotal: exp,
      overallProfit: prof,
      todayDishBreakdown: dishes,
      weekDishBreakdown: dishes,
      monthDishBreakdown: dishes,
      overallDishBreakdown: dishes,
      topSellingItems: dishes,
      todayPaymentBreakdown: payments,
      paymentAnalytics: payments,
      expenseBreakdown: expenseBreakdown,
      customerAnalytics: customerAnalytics,
      averageBillValue: avgBill,
      peakSellingHour: peak,
      hourlyRevenueToday: chartPoints,
      currentWeekDailyRevenue: chartPoints,
      monthlyWeeklyRevenue: chartPoints,
    );
  }

  Widget _buildDateSlicer(BuildContext context, bool isDark) {
    final canPrev = _canGoPrevious;
    final canNext = _canGoNext;
    final isAllTime = _selectedTimeframe == 'All Time';
    final theme = Theme.of(context);
    final isAmoled = theme.scaffoldBackgroundColor == AppColors.amoledBackground;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ??
            (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAmoled
              ? AppColors.amoledBorder
              : (isDark ? Colors.white12 : Colors.grey.shade200),
          width: 1,
        ),
        boxShadow: isAmoled
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 50 : 12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  tooltip: (isAllTime || !canPrev) ? null : 'Previous $_selectedTimeframe',
                  color: (isAllTime || !canPrev)
                      ? (isDark ? Colors.white24 : Colors.grey.shade300)
                      : (isDark ? Colors.white : Colors.grey.shade800),
                  onPressed: (isAllTime || !canPrev) ? null : _onPreviousPeriod,
                ),
                Expanded(
                  child: Tooltip(
                    message: isAllTime
                        ? 'All Recorded History'
                        : 'Tap to pick $_selectedTimeframe period',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: isAllTime ? null : _onTapSlicerCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedTimeframe == 'Custom'
                                  ? Icons.date_range_rounded
                                  : Icons.calendar_month_rounded,
                              size: 18,
                              color: isAllTime ? Colors.grey : AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _slicerLabel,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.grey.shade900,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (!isAllTime) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 20,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  tooltip: canNext ? 'Next $_selectedTimeframe' : 'Current period',
                  color: canNext
                      ? (isDark ? Colors.white : Colors.grey.shade800)
                      : (isDark ? Colors.white24 : Colors.grey.shade300),
                  onPressed: canNext ? _onNextPeriod : null,
                ),
              ],
            ),
          ),
          if (_isLoadingPeriod)
            const ClipRRect(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              child: LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJumpToTodayBadge(bool isDark) {
    if (_isCurrentPeriod || _selectedTimeframe == 'All Time') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            setState(() {
              _selectedDate = now;
              if (_selectedTimeframe == 'Custom') {
                final spanDays = _effectiveCustomRange.end
                        .difference(_effectiveCustomRange.start)
                        .inDays +
                    1;
                _customRange = DateTimeRange(
                  start: today.subtract(Duration(days: spanDays - 1)),
                  end: today,
                );
              }
            });
            _loadPeriodReport();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Viewing Past Period • Jump to Current',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.amber.shade300 : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeFilterBar(BuildContext context, bool isDark) {
    final isAmoled =
        Theme.of(context).scaffoldBackgroundColor == AppColors.amoledBackground;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isAmoled
            ? AppColors.amoledCard
            : (isDark ? Colors.grey.shade900 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
        border: isAmoled
            ? Border.all(color: AppColors.amoledBorder, width: 1)
            : null,
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: _timeframeOptions.map((opt) {
          final isSelected = _selectedTimeframe == opt.id;
          return Expanded(
            child: GestureDetector(
              onTap: () async {
                if (opt.id == 'Custom') {
                  if (_selectedTimeframe != 'Custom' && _customRange == null) {
                    setState(() => _selectedTimeframe = 'Custom');
                    await _pickCustomRange();
                    await _loadPeriodReport();
                  } else if (_selectedTimeframe == 'Custom') {
                    await _pickCustomRange();
                  } else {
                    setState(() => _selectedTimeframe = 'Custom');
                    await _loadPeriodReport();
                  }
                  return;
                }
                if (_selectedTimeframe != opt.id) {
                  setState(() => _selectedTimeframe = opt.id);
                  _loadPeriodReport();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DashboardState>(dashboardProvider, (prev, next) {
      if (!mounted) return;
      if (prev != null &&
          !next.isLoading &&
          (prev.isLoading ||
              prev.overallOrderCount != next.overallOrderCount ||
              prev.overallRevenue != next.overallRevenue ||
              prev.overallExpenseTotal != next.overallExpenseTotal)) {
        _loadPeriodReport();
      }
    });

    final metrics = ref.watch(dashboardProvider);
    final settings = ref.watch(settingsProvider).settings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sliced period values with fallback to provider metrics
    final double currentRevenue = _periodData != null
        ? ((_periodData!['revenue'] as num?)?.toDouble() ?? 0.0)
        : switch (_selectedTimeframe) {
            'All Time' => metrics.overallRevenue,
            'Monthly' => metrics.monthRevenue,
            'Weekly' => metrics.weekRevenue,
            _ => metrics.todayRevenue,
          };

    final double currentExpenses = _periodData != null
        ? ((_periodData!['expenses'] as num?)?.toDouble() ?? 0.0)
        : switch (_selectedTimeframe) {
            'All Time' => metrics.overallExpenseTotal,
            'Monthly' => metrics.monthExpenseTotal,
            'Weekly' => metrics.weekExpenseTotal,
            _ => metrics.todayExpenseTotal,
          };

    final double currentProfit = _periodData != null
        ? ((_periodData!['profit'] as num?)?.toDouble() ?? (currentRevenue - currentExpenses))
        : switch (_selectedTimeframe) {
            'All Time' => metrics.overallProfit,
            'Monthly' => metrics.monthlyProfit,
            'Weekly' => metrics.weeklyProfit,
            _ => metrics.netProfitToday,
          };

    final int currentOrders = _periodData != null
        ? ((_periodData!['orderCount'] as num?)?.toInt() ?? 0)
        : switch (_selectedTimeframe) {
            'All Time' => metrics.overallOrderCount,
            'Monthly' => metrics.monthOrderCount,
            'Weekly' => metrics.weekOrderCount,
            _ => metrics.todayOrderCount,
          };

    final double priorRevenue = _periodData != null
        ? ((_periodData!['priorRevenue'] as num?)?.toDouble() ?? 0.0)
        : switch (_selectedTimeframe) {
            'Monthly' => metrics.previousMonthRevenue,
            'Weekly' => metrics.previousWeekRevenue,
            'Daily' => metrics.yesterdayRevenue,
            _ => 0.0,
          };

    final double pctChange = priorRevenue > 0
        ? ((currentRevenue - priorRevenue) / priorRevenue * 100)
        : 0.0;

    final List<String> chartXLabels = _periodData != null && _periodData!['chartLabels'] != null
        ? (_periodData!['chartLabels'] as List<dynamic>).map((e) => e.toString()).toList()
        : switch (_selectedTimeframe) {
            'All Time' => const ['Past', '3 Mo', '2 Mo', 'Last Mo', 'Now'],
            'Monthly' => const ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4', 'Wk 5'],
            'Weekly' => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            'Yearly' => const ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'],
            _ => const ['12-4A', '4-8A', '8-12P', '12-4P', '4-8P', '8-12A'],
          };

    final List<double> chartDataPoints = _periodData != null && _periodData!['chartDataPoints'] != null
        ? (_periodData!['chartDataPoints'] as List<dynamic>).map((e) => (e as num).toDouble()).toList()
        : switch (_selectedTimeframe) {
            'All Time' => metrics.monthlyWeeklyRevenue.isNotEmpty
                ? metrics.monthlyWeeklyRevenue
                : List.filled(5, 0.0),
            'Monthly' => metrics.monthlyWeeklyRevenue.isNotEmpty
                ? metrics.monthlyWeeklyRevenue
                : List.filled(5, 0.0),
            'Weekly' => metrics.currentWeekDailyRevenue.isNotEmpty
                ? metrics.currentWeekDailyRevenue
                : List.filled(7, 0.0),
            _ => metrics.hourlyRevenueToday.isNotEmpty
                ? metrics.hourlyRevenueToday
                : List.filled(6, 0.0),
          };

    final List<Map<String, dynamic>> dishList = _periodData != null && _periodData!['dishBreakdown'] != null
        ? (_periodData!['dishBreakdown'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
        : switch (_selectedTimeframe) {
            'Weekly' => metrics.weekDishBreakdown.isNotEmpty
                ? metrics.weekDishBreakdown
                : metrics.topSellingItems,
            'Monthly' => metrics.monthDishBreakdown.isNotEmpty
                ? metrics.monthDishBreakdown
                : metrics.topSellingItems,
            'All Time' => metrics.overallDishBreakdown.isNotEmpty
                ? metrics.overallDishBreakdown
                : metrics.topSellingItems,
            _ => metrics.todayDishBreakdown.isNotEmpty
                ? metrics.todayDishBreakdown
                : metrics.topSellingItems,
          };

    final Map<String, dynamic> paymentMap = _periodData != null && _periodData!['paymentAnalytics'] != null
        ? Map<String, dynamic>.from(_periodData!['paymentAnalytics'] as Map)
        : metrics.paymentAnalytics;

    final List<Map<String, dynamic>> expenseBreakdown =
        _periodData != null && _periodData!['expenseBreakdown'] != null
            ? (_periodData!['expenseBreakdown'] as List<dynamic>)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
            : metrics.expenseBreakdown;

    final String peakHour = _periodData != null && _periodData!['peakSellingHour'] != null
        ? (_periodData!['peakSellingHour'] as String)
        : metrics.peakSellingHour;

    final double avgOrderVal = _periodData != null && _periodData!['averageBillValue'] != null
        ? ((_periodData!['averageBillValue'] as num?)?.toDouble() ?? 0.0)
        : (currentOrders > 0 ? (currentRevenue / currentOrders) : metrics.averageBillValue);

    final Map<String, dynamic> custAnalytics =
        _periodData != null && _periodData!['customerAnalytics'] != null
            ? Map<String, dynamic>.from(_periodData!['customerAnalytics'] as Map)
            : metrics.customerAnalytics;

    final double profitMargin = currentRevenue > 0
        ? ((currentProfit / currentRevenue) * 100).clamp(-100.0, 100.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Reports',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              '${settings?.businessName ?? 'FoodBillX'} • $_slicerLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            tooltip: 'Export Reports & Data',
            onPressed: _isExporting
                ? null
                : () => _showExportModal(
                      context,
                      metrics,
                      settings?.businessName ?? 'FoodBillX',
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(dashboardProvider.notifier).refresh(forceSpinner: true),
            _loadPeriodReport(),
          ]);
        },
        child: (metrics.isLoading && _periodData == null)
            ? const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    MetricCardSkeleton(),
                    SizedBox(height: 12),
                    MetricCardSkeleton(),
                    SizedBox(height: 20),
                    SkeletonLoader(width: double.infinity, height: 220),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Date Slicer ABOVE (e.g., < November 2026 >)
                    _buildDateSlicer(context, isDark),
                    _buildJumpToTodayBadge(isDark),
                    const SizedBox(height: 10),

                    // 2. Timeframe Filter Bar BELOW (Daily, Weekly, Monthly, Yearly, Custom, All)
                    _buildTimeframeFilterBar(context, isDark),
                    const SizedBox(height: 16),

                    // Section 1: Executive P&L Overview Cards
                    Row(
                      children: [
                        Expanded(
                          child: MetricCardWidget(
                            title: '$_selectedTimeframe Revenue',
                            value: CurrencyFormatter.format(currentRevenue),
                            icon: Icons.payments_rounded,
                            color: AppColors.secondary,
                            subtitle: '${CurrencyFormatter.formatInteger(currentOrders)} orders completed',
                            onTap: widget.onOpenOrders,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCardWidget(
                            title: '$_selectedTimeframe Expenses',
                            value: CurrencyFormatter.format(currentExpenses),
                            icon: Icons.shopping_bag_outlined,
                            color: Colors.red.shade400,
                            subtitle: currentExpenses > 0 ? 'Tap to manage' : 'Tap to add expense',
                            onTap: widget.onOpenExpenses,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: MetricCardWidget(
                            title: '$_selectedTimeframe Profit',
                            value: currentExpenses > 0
                                ? CurrencyFormatter.format(currentProfit)
                                : 'Add expense',
                            icon: currentExpenses > 0
                                ? Icons.trending_up_rounded
                                : Icons.info_outline_rounded,
                            color: currentExpenses > 0
                                ? (currentProfit >= 0 ? AppColors.secondary : Colors.red)
                                : Colors.amber.shade700,
                            subtitle: currentExpenses > 0
                                ? 'Margin: ${profitMargin.toStringAsFixed(1)}%'
                                : 'to know profit',
                            onTap: currentExpenses <= 0 ? widget.onOpenExpenses : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCardWidget(
                            title: 'Avg Order Value',
                            value: CurrencyFormatter.format(avgOrderVal),
                            icon: Icons.receipt_long_rounded,
                            color: Colors.blue.shade600,
                            subtitle: 'Per order ticket',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Sales & Revenue Trends Chart
                    _buildSectionHeader('1. Sales & Revenue Trends'),
                    const SizedBox(height: 8),

                    RevenueLineChartWidget(
                      title: '$_selectedTimeframe Revenue ($_slicerLabel)',
                      totalRevenue: currentRevenue,
                      totalProfit: currentProfit,
                      expenseAmount: currentExpenses,
                      percentageChange: pctChange,
                      percentageSubtitle: _comparisonSubtitle,
                      xLabels: chartXLabels,
                      dataPoints: chartDataPoints,
                    ),
                    const SizedBox(height: 12),

                    Card(
                      elevation: AppTheme.isAmoledTheme(context) ? 0 : 1,
                      shape: AppTheme.cardShape(context, radius: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSummaryRow('Gross Revenue', CurrencyFormatter.format(currentRevenue)),
                            const Divider(height: 16),
                            _buildSummaryRow('Total Orders', '$currentOrders orders'),
                            const Divider(height: 16),
                            _buildSummaryRow('Operating Expenses', CurrencyFormatter.format(currentExpenses)),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Net Profit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                ProfitDisplayWidget(
                                  expenseAmount: currentExpenses,
                                  profitAmount: currentProfit,
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            if (currentRevenue > 0 && currentExpenses > 0) ...[
                              const Divider(height: 16),
                              _buildSummaryRow('Net Profit Margin', '${profitMargin.toStringAsFixed(1)}%'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Order Analytics & Operational Insights
                    _buildSectionHeader('2. Order & Peak Hours Analytics'),
                    const SizedBox(height: 8),

                    Card(
                      elevation: AppTheme.isAmoledTheme(context) ? 0 : 1,
                      shape: AppTheme.cardShape(context, radius: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'Completed Orders',
                              '$currentOrders orders',
                              Icons.shopping_cart_rounded,
                              Colors.blue.shade600,
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              'Peak Selling Hour',
                              peakHour,
                              Icons.access_time_filled_rounded,
                              Colors.amber.shade800,
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              'Average Bill Value',
                              CurrencyFormatter.format(avgOrderVal),
                              Icons.analytics_rounded,
                              AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 4: Menu Dish Performance
                    _buildSectionHeader('3. Menu Dish Performance'),
                    const SizedBox(height: 8),

                    Card(
                      elevation: AppTheme.isAmoledTheme(context) ? 0 : 1,
                      shape: AppTheme.cardShape(context, radius: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Builder(
                          builder: (context) {
                            final totalDishesSold = dishList.fold<int>(
                              0,
                              (sum, i) => sum + ((i['totalQuantity'] ?? i['quantity'] ?? 0) as num).toInt(),
                            );

                            final dishCardTitle = _selectedTimeframe == 'All Time'
                                ? 'Top Selling Dishes (${CurrencyFormatter.formatInteger(totalDishesSold)} items)'
                                : 'Dishes Sold • $_slicerLabel (${CurrencyFormatter.formatInteger(totalDishesSold)} items)';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        dishCardTitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ),
                                    if (dishList.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withAlpha(25),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${CurrencyFormatter.formatInteger(dishList.length)} varieties',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (dishList.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.restaurant_menu_rounded,
                                            size: 36,
                                            color: isDark ? Colors.white24 : Colors.black26,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No dishes sold for $_slicerLabel.',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Billed dishes and quantities will appear here in real time',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Builder(
                                    builder: (context) {
                                      const maxPreview = 25;
                                      final visibleDishes = _showAllDishes || dishList.length <= maxPreview
                                          ? dishList
                                          : dishList.take(maxPreview).toList();
                                      return Column(
                                        children: [
                                          ListView.separated(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: visibleDishes.length,
                                            separatorBuilder: (_, __) => const Divider(height: 8),
                                            itemBuilder: (_, idx) {
                                              final item = visibleDishes[idx];
                                              final name = (item['name'] ?? item['_id'])?.toString() ?? 'Dish';
                                              final qty = ((item['totalQuantity'] ?? item['quantity'] ?? 0) as num).toInt();
                                              final sales = (item['totalSales'] as num?)?.toDouble() ?? 0.0;

                                              return ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                leading: CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: idx == 0
                                                      ? Colors.amber.withAlpha(40)
                                                      : (idx == 1
                                                          ? Colors.grey.withAlpha(40)
                                                          : (idx == 2
                                                              ? Colors.orange.withAlpha(20)
                                                              : AppColors.primary.withAlpha(15))),
                                                  child: Text(
                                                    '#${idx + 1}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: idx == 0
                                                          ? Colors.amber.shade800
                                                          : (idx == 1
                                                              ? Colors.grey.shade400
                                                              : (idx == 2
                                                                  ? Colors.orange.shade800
                                                                  : AppColors.primary)),
                                                    ),
                                                  ),
                                                ),
                                                title: Text(
                                                  name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                subtitle: Text(
                                                  '${CurrencyFormatter.formatInteger(qty)} portion${qty > 1 ? 's' : ''} ordered',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                trailing: ConstrainedBox(
                                                  constraints: const BoxConstraints(maxWidth: 165),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment: Alignment.centerRight,
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.primary.withAlpha(25),
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(color: AppColors.primary.withAlpha(50)),
                                                          ),
                                                          child: Text(
                                                            'x${CurrencyFormatter.formatInteger(qty)}',
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 13,
                                                              color: AppColors.primary,
                                                            ),
                                                          ),
                                                        ),
                                                        if (sales > 0) ...[
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            CurrencyFormatter.format(sales),
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: AppColors.secondary,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          if (dishList.length > maxPreview) ...[
                                            const SizedBox(height: 8),
                                            TextButton.icon(
                                              onPressed: () => setState(() => _showAllDishes = !_showAllDishes),
                                              icon: Icon(_showAllDishes ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                                              label: Text(
                                                _showAllDishes
                                                    ? 'Show Top $maxPreview Only'
                                                    : 'Show All ${CurrencyFormatter.formatInteger(dishList.length)} Varieties',
                                              ),
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 5: Payment Breakdown
                    _buildSectionHeader('4. Payment Methods Breakdown'),
                    const SizedBox(height: 8),

                    _buildPaymentBreakdownCard(paymentMap, isDark),

                    const SizedBox(height: 24),

                    // Section 6: Operating Expenses Breakdown
                    _buildSectionHeader('5. Expense Breakdown'),
                    const SizedBox(height: 8),

                    _buildExpenseBreakdownCard(expenseBreakdown, currentExpenses, isDark),

                    const SizedBox(height: 24),

                    // Section 7: Customer & Loyalty Analytics
                    _buildSectionHeader('6. Customer & Loyalty Analytics'),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: MetricCardWidget(
                            title: 'Active Guests',
                            value: CurrencyFormatter.formatInteger((custAnalytics['periodActiveGuests'] ?? custAnalytics['totalCustomers'] ?? 0) as num),
                            icon: Icons.person_pin_circle_rounded,
                            color: Colors.teal,
                            subtitle: 'In selected period',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCardWidget(
                            title: 'Total Registered',
                            value: CurrencyFormatter.formatInteger((custAnalytics['totalCustomers'] ?? 0) as num),
                            icon: Icons.people_rounded,
                            color: Colors.purple,
                            subtitle: 'Guest database',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: MetricCardWidget(
                            title: 'Loyalty Members',
                            value: CurrencyFormatter.formatInteger((custAnalytics['loyaltyMembers'] ?? 0) as num),
                            icon: Icons.card_membership_rounded,
                            color: Colors.amber.shade800,
                            subtitle: 'Cardholders',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCardWidget(
                            title: 'Returning Guests',
                            value: CurrencyFormatter.formatInteger((custAnalytics['returningCustomers'] ?? 0) as num),
                            icon: Icons.repeat_rounded,
                            color: Colors.blue,
                            subtitle: '>1 Visit recorded',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 8: Export Data Modal Trigger
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isExporting
                            ? null
                            : () => _showExportModal(
                                  context,
                                  metrics,
                                  settings?.businessName ?? 'FoodBillX',
                                ),
                        icon: _isExporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.file_download_outlined, size: 20),
                        label: Text(
                          _isExporting
                              ? 'Preparing Export...'
                              : 'Export Reports & Data',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showExportModal(
    BuildContext context,
    DashboardState metrics,
    String businessName,
  ) {
    _ReportExportType selectedType = _ReportExportType.reports;
    _ReportExportScope selectedScope = _ReportExportScope.selectedPeriod;
    ExportFormat selectedFormat = ExportFormat.pdf;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime customFromDate = today.subtract(const Duration(days: 6));
    DateTime customToDate = today;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isBackup = selectedType == _ReportExportType.backup;
            final isCustomerOnly = selectedType == _ReportExportType.customers;
            final effectiveFormat = isBackup ? ExportFormat.excel : selectedFormat;
            final typeLabel = switch (selectedType) {
              _ReportExportType.reports => 'Business Report',
              _ReportExportType.customers => 'Customer Data',
              _ReportExportType.orders => 'Order Data',
              _ReportExportType.backup => 'Full Backup',
            };

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.file_download_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Export Data',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
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
                      'Choose export category, date filter, and file format:',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    _buildModalDropdownSection(
                      context: context,
                      label: 'Export Type',
                      icon: Icons.category_outlined,
                      child: DropdownButton<_ReportExportType>(
                        value: selectedType,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: const [
                          DropdownMenuItem(
                            value: _ReportExportType.reports,
                            child: Text(
                              'Business Report',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          DropdownMenuItem(
                            value: _ReportExportType.customers,
                            child: Text(
                              'Customer Data',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          DropdownMenuItem(
                            value: _ReportExportType.orders,
                            child: Text(
                              'Order Data',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          DropdownMenuItem(
                            value: _ReportExportType.backup,
                            child: Text(
                              'Full Backup (Excel only)',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedType = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildModalDropdownSection(
                      context: context,
                      label: isCustomerOnly ? 'Customer Scope' : 'Date Range (Timeframe)',
                      icon: Icons.date_range_outlined,
                      child: isCustomerOnly
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'All Registered Customers',
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            )
                          : DropdownButton<_ReportExportScope>(
                              value: selectedScope,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              items: [
                                DropdownMenuItem(
                                  value: _ReportExportScope.selectedPeriod,
                                  child: Text(
                                    'Selected: $_selectedTimeframe ($_slicerLabel)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const DropdownMenuItem(
                                  value: _ReportExportScope.allTime,
                                  child: Text('All Time (Full History)', style: TextStyle(fontSize: 13)),
                                ),
                                const DropdownMenuItem(
                                  value: _ReportExportScope.today,
                                  child: Text('Today Only', style: TextStyle(fontSize: 13)),
                                ),
                                const DropdownMenuItem(
                                  value: _ReportExportScope.thisMonth,
                                  child: Text('This Month', style: TextStyle(fontSize: 13)),
                                ),
                                const DropdownMenuItem(
                                  value: _ReportExportScope.last1Month,
                                  child: Text('Last 1 Month (Past 30 Days)', style: TextStyle(fontSize: 13)),
                                ),
                                const DropdownMenuItem(
                                  value: _ReportExportScope.last3Months,
                                  child: Text('Last 3 Months (Past 90 Days)', style: TextStyle(fontSize: 13)),
                                ),
                                const DropdownMenuItem(
                                  value: _ReportExportScope.last6Months,
                                  child: Text('Last 6 Months (Past 180 Days)', style: TextStyle(fontSize: 13)),
                                ),
                                const DropdownMenuItem(
                                  value: _ReportExportScope.custom,
                                  child: Text(
                                    'Custom Date Range (From - To)',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedScope = val);
                                }
                              },
                            ),
                    ),
                    if (!isCustomerOnly && selectedScope == _ReportExportScope.custom) ...[
                      const SizedBox(height: 12),
                      InlineFromToDatePickers(
                        fromDate: customFromDate,
                        toDate: customToDate,
                        includeOrders: true,
                        includeExpenses: selectedType != _ReportExportType.orders,
                        excludeRefundedOrders: selectedType != _ReportExportType.orders,
                        onFromChanged: (d) {
                          setDialogState(() {
                            customFromDate = d;
                            if (customToDate.isBefore(customFromDate)) {
                              customToDate = customFromDate;
                            }
                          });
                        },
                        onToChanged: (d) {
                          setDialogState(() => customToDate = d);
                        },
                      ),
                    ],
                    const SizedBox(height: 12),

                    _buildModalDropdownSection(
                      context: context,
                      label: 'File Format',
                      icon: Icons.tune_rounded,
                      child: isBackup
                          ? Row(
                              children: [
                                Icon(Icons.table_chart_rounded, color: Colors.green.shade700, size: 18),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Excel (.xlsx) - Full Archive',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Excel only',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : DropdownButton<ExportFormat>(
                              value: selectedFormat,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              items: const [
                                DropdownMenuItem(
                                  value: ExportFormat.pdf,
                                  child: Row(
                                    children: [
                                      Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Executive PDF (.pdf)',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: ExportFormat.excel,
                                  child: Row(
                                    children: [
                                      Icon(Icons.table_chart_rounded, color: Colors.green, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Excel Spreadsheet (.xlsx)',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedFormat = val);
                                }
                              },
                            ),
                    ),
                    const SizedBox(height: 18),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: effectiveFormat == ExportFormat.excel
                            ? Colors.green.shade700
                            : Colors.redAccent.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(
                        effectiveFormat == ExportFormat.excel
                            ? Icons.table_chart_rounded
                            : Icons.picture_as_pdf_rounded,
                        size: 18,
                      ),
                      label: Text(
                        'Export $typeLabel (${effectiveFormat == ExportFormat.excel ? "Excel" : "PDF"})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _executeModalExport(
                          metrics: metrics,
                          businessName: businessName,
                          type: selectedType,
                          scope: selectedScope,
                          format: effectiveFormat,
                          customFromDate: customFromDate,
                          customToDate: customToDate,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalDropdownSection({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(120),
            ),
          ),
          child: DropdownButtonHideUnderline(child: child),
        ),
      ],
    );
  }

  (DateTime?, DateTime?, String) _resolveExportScope(
    _ReportExportScope scope, {
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    switch (scope) {
      case _ReportExportScope.selectedPeriod:
        final sd = _periodData?['startDate'] as DateTime?;
        final ed = _periodData?['endDate'] as DateTime?;
        if (_selectedTimeframe == 'All Time') {
          return (null, null, 'All Time');
        }
        return (sd, ed, '$_selectedTimeframe ($_slicerLabel)');
      case _ReportExportScope.allTime:
        return (null, null, 'All Time');
      case _ReportExportScope.today:
        return (DateTime(now.year, now.month, now.day), todayEnd, 'Today');
      case _ReportExportScope.thisMonth:
        return (DateTime(now.year, now.month, 1), todayEnd, 'This Month');
      case _ReportExportScope.last1Month:
        return (now.subtract(const Duration(days: 30)), todayEnd, 'Last 1 Month');
      case _ReportExportScope.last3Months:
        return (now.subtract(const Duration(days: 90)), todayEnd, 'Last 3 Months');
      case _ReportExportScope.last6Months:
        return (now.subtract(const Duration(days: 180)), todayEnd, 'Last 6 Months');
      case _ReportExportScope.custom:
        final f = customFrom ?? now.subtract(const Duration(days: 6));
        final t = customTo ?? now;
        final orderedStart = f.isAfter(t) ? t : f;
        final orderedEnd = f.isAfter(t) ? f : t;
        final s = DateTime(orderedStart.year, orderedStart.month, orderedStart.day, 0, 0, 0);
        final e = DateTime(orderedEnd.year, orderedEnd.month, orderedEnd.day, 23, 59, 59, 999);
        final label = '${DateFormat('dd MMM yyyy').format(s)} - ${DateFormat('dd MMM yyyy').format(e)}';
        return (s, e, label);
    }
  }

  Future<void> _executeModalExport({
    required DashboardState metrics,
    required String businessName,
    required _ReportExportType type,
    required _ReportExportScope scope,
    required ExportFormat format,
    DateTime? customFromDate,
    DateTime? customToDate,
  }) async {
    setState(() => _isExporting = true);
    try {
      final settings = ref.read(settingsProvider).settings;
      final (startDate, endDate, rangeLabel) = _resolveExportScope(
        scope,
        customFrom: customFromDate,
        customTo: customToDate,
      );

      switch (type) {
        case _ReportExportType.reports:
          DashboardState sliced;
          List<String>? labels;
          if (scope == _ReportExportScope.selectedPeriod) {
            sliced = _buildSlicedState(metrics);
            labels = (_periodData?['chartLabels'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList();
          } else if (scope == _ReportExportScope.allTime) {
            final data = await LocalDatabase.instance.computePeriodReports(
              timeframe: 'All Time',
              referenceDate: DateTime.now(),
            );
            sliced = _buildStateFromPeriodMap(data, metrics);
            labels = (data['chartLabels'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList();
          } else {
            final data = await LocalDatabase.instance.computePeriodReports(
              timeframe: 'Custom',
              referenceDate: DateTime.now(),
              customStartDate: startDate,
              customEndDate: endDate,
            );
            sliced = _buildStateFromPeriodMap(data, metrics);
            labels = (data['chartLabels'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList();
          }
          await ReportExportHelper.exportReport(
            metrics: sliced,
            businessName: businessName,
            format: format,
            settings: settings,
            dateRangeLabel: rangeLabel,
            isPeriodSlice: true,
            chartLabels: labels,
          );
          break;

        case _ReportExportType.orders:
          final orders = await LocalDatabase.instance.getOrders(
            startDate: startDate,
            endDate: endDate,
            limit: 50000,
          );
          if (orders.isEmpty) {
            if (mounted) {
              SnackbarUtils.showInfo(
                context,
                'No orders found for $rangeLabel.',
              );
            }
            return;
          }
          await ReportExportHelper.exportOrders(
            orders: orders,
            businessName: businessName,
            format: format,
            settings: settings,
            dateRangeLabel: rangeLabel,
          );
          break;

        case _ReportExportType.customers:
          final customers = await LocalDatabase.instance.getCustomers();
          if (customers.isEmpty) {
            if (mounted) {
              SnackbarUtils.showInfo(context, 'No customers registered yet.');
            }
            return;
          }
          await ReportExportHelper.exportCustomers(
            customers: customers,
            businessName: businessName,
            format: format,
            settings: settings,
            dateRangeLabel: 'All Registered Customers',
          );
          break;

        case _ReportExportType.backup:
          await ReportExportHelper.exportCompleteAppBackup(
            db: LocalDatabase.instance,
            businessName: businessName,
            settings: settings,
            startDate: startDate,
            endDate: endDate,
            dateRangeLabel: rangeLabel,
          );
          break;
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to export $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseBreakdownCard(
    List<Map<String, dynamic>> expenseBreakdown,
    double totalExpenses,
    bool isDark,
  ) {
    return Card(
      elevation: AppTheme.isAmoledTheme(context) ? 0 : 1,
      shape: AppTheme.cardShape(context, radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: expenseBreakdown.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No expenses recorded for $_slicerLabel.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
              )
            : Column(
                children: expenseBreakdown.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final row = entry.value;
                  final category = row['category']?.toString() ?? 'Miscellaneous';
                  final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
                  final count = (row['count'] as num?)?.toInt() ?? 0;
                  final pct = totalExpenses > 0 ? (amount / totalExpenses * 100) : 0.0;
                  final isLast = idx == expenseBreakdown.length - 1;

                  return Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.red.withAlpha(25),
                            child: Icon(Icons.receipt_outlined, color: Colors.red.shade400, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                Text(
                                  '$count entr${count == 1 ? 'y' : 'ies'} • ${pct.toStringAsFixed(1)}% of spend',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 135),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                CurrencyFormatter.format(amount),
                                maxLines: 1,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isLast) const Divider(height: 16),
                    ],
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildPaymentBreakdownCard(Map<String, dynamic> paymentAnalytics, bool isDark) {
    final cash = (paymentAnalytics['cash'] as num?)?.toDouble() ?? 0.0;
    final upi = (paymentAnalytics['upi'] as num?)?.toDouble() ?? 0.0;
    final card = (paymentAnalytics['card'] as num?)?.toDouble() ?? 0.0;
    final wallet = (paymentAnalytics['wallet'] as num?)?.toDouble() ?? 0.0;
    final total = cash + upi + card + wallet;

    final cashPct = total > 0 ? (cash / total) : 0.0;
    final upiPct = total > 0 ? (upi / total) : 0.0;
    final cardPct = total > 0 ? (card / total) : 0.0;
    final walletPct = total > 0 ? (wallet / total) : 0.0;

    return Card(
      elevation: AppTheme.isAmoledTheme(context) ? 0 : 1,
      shape: AppTheme.cardShape(context, radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Distribution Progress Bar
            if (total > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      if (cashPct > 0)
                        Expanded(flex: (cashPct * 1000).round().clamp(1, 1000), child: Container(color: Colors.green)),
                      if (upiPct > 0)
                        Expanded(flex: (upiPct * 1000).round().clamp(1, 1000), child: Container(color: Colors.blue)),
                      if (cardPct > 0)
                        Expanded(flex: (cardPct * 1000).round().clamp(1, 1000), child: Container(color: Colors.purple)),
                      if (walletPct > 0)
                        Expanded(flex: (walletPct * 1000).round().clamp(1, 1000), child: Container(color: Colors.orange)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildPaymentMethodRow('Cash Payments', cash, cashPct, Icons.money_rounded, Colors.green),
            const Divider(height: 16),
            _buildPaymentMethodRow('UPI / QR Payments', upi, upiPct, Icons.qr_code_2_rounded, Colors.blue),
            const Divider(height: 16),
            _buildPaymentMethodRow('Card Payments', card, cardPct, Icons.credit_card_rounded, Colors.purple),
            if (wallet > 0) ...[
              const Divider(height: 16),
              _buildPaymentMethodRow('Wallet / Other', wallet, walletPct, Icons.account_balance_wallet_rounded, Colors.orange),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodRow(
    String label,
    double amount,
    double pct,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withAlpha(25),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (pct > 0)
                Text(
                  '${(pct * 100).toStringAsFixed(1)}% of total sales',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 135),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              CurrencyFormatter.format(amount),
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
