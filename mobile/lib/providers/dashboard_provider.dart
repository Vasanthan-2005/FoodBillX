import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/local_database.dart';

class DashboardState {
  final double todayRevenue;
  final int todayOrderCount;
  final double todayExpenseTotal;
  final double netProfitToday;

  final double yesterdayRevenue;
  final double weekRevenue;
  final int weekOrderCount;
  final double weekExpenseTotal;
  final double weeklyProfit;
  final double previousWeekRevenue;

  final double monthRevenue;
  final int monthOrderCount;
  final double monthExpenseTotal;
  final double monthlyProfit;
  final double previousMonthRevenue;

  final double overallRevenue;
  final int overallOrderCount;
  final double overallExpenseTotal;
  final double overallProfit;

  final double averageBillValue;
  final String peakSellingHour;

  final String todayTopDishName;
  final int todayTopDishCount;
  final Map<String, double> todayPaymentBreakdown;

  final List<double> hourlyRevenueToday;
  final List<double> recentDailyRevenue;
  final List<double> currentWeekDailyRevenue;
  final List<double> monthlyWeeklyRevenue;
  final List<Map<String, dynamic>> topSellingItems;
  final List<Map<String, dynamic>> leastSellingItems;
  final Map<String, dynamic> customerAnalytics;
  final Map<String, dynamic> paymentAnalytics;
  final List<Map<String, dynamic>> expenseBreakdown;

  final bool isLoading;
  final String? errorMessage;

  DashboardState({
    this.todayRevenue = 0,
    this.todayOrderCount = 0,
    this.todayExpenseTotal = 0,
    this.netProfitToday = 0,
    this.yesterdayRevenue = 0,
    this.weekRevenue = 0,
    this.weekOrderCount = 0,
    this.weekExpenseTotal = 0,
    this.weeklyProfit = 0,
    this.previousWeekRevenue = 0,
    this.monthRevenue = 0,
    this.monthOrderCount = 0,
    this.monthExpenseTotal = 0,
    this.monthlyProfit = 0,
    this.previousMonthRevenue = 0,
    this.overallRevenue = 0,
    this.overallOrderCount = 0,
    this.overallExpenseTotal = 0,
    this.overallProfit = 0,
    this.averageBillValue = 0,
    this.peakSellingHour = 'No orders yet',
    this.todayTopDishName = '',
    this.todayTopDishCount = 0,
    this.todayPaymentBreakdown = const {},
    this.hourlyRevenueToday = const [],
    this.recentDailyRevenue = const [],
    this.currentWeekDailyRevenue = const [],
    this.monthlyWeeklyRevenue = const [],
    this.topSellingItems = const [],
    this.leastSellingItems = const [],
    this.customerAnalytics = const {},
    this.paymentAnalytics = const {},
    this.expenseBreakdown = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    double? todayRevenue,
    int? todayOrderCount,
    double? todayExpenseTotal,
    double? netProfitToday,
    double? yesterdayRevenue,
    double? weekRevenue,
    int? weekOrderCount,
    double? weekExpenseTotal,
    double? weeklyProfit,
    double? previousWeekRevenue,
    double? monthRevenue,
    int? monthOrderCount,
    double? monthExpenseTotal,
    double? monthlyProfit,
    double? previousMonthRevenue,
    double? overallRevenue,
    int? overallOrderCount,
    double? overallExpenseTotal,
    double? overallProfit,
    double? averageBillValue,
    String? peakSellingHour,
    String? todayTopDishName,
    int? todayTopDishCount,
    Map<String, double>? todayPaymentBreakdown,
    List<double>? hourlyRevenueToday,
    List<double>? recentDailyRevenue,
    List<double>? currentWeekDailyRevenue,
    List<double>? monthlyWeeklyRevenue,
    List<Map<String, dynamic>>? topSellingItems,
    List<Map<String, dynamic>>? leastSellingItems,
    Map<String, dynamic>? customerAnalytics,
    Map<String, dynamic>? paymentAnalytics,
    List<Map<String, dynamic>>? expenseBreakdown,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      todayRevenue: todayRevenue ?? this.todayRevenue,
      todayOrderCount: todayOrderCount ?? this.todayOrderCount,
      todayExpenseTotal: todayExpenseTotal ?? this.todayExpenseTotal,
      netProfitToday: netProfitToday ?? this.netProfitToday,
      yesterdayRevenue: yesterdayRevenue ?? this.yesterdayRevenue,
      weekRevenue: weekRevenue ?? this.weekRevenue,
      weekOrderCount: weekOrderCount ?? this.weekOrderCount,
      weekExpenseTotal: weekExpenseTotal ?? this.weekExpenseTotal,
      weeklyProfit: weeklyProfit ?? this.weeklyProfit,
      previousWeekRevenue: previousWeekRevenue ?? this.previousWeekRevenue,
      monthRevenue: monthRevenue ?? this.monthRevenue,
      monthOrderCount: monthOrderCount ?? this.monthOrderCount,
      monthExpenseTotal: monthExpenseTotal ?? this.monthExpenseTotal,
      monthlyProfit: monthlyProfit ?? this.monthlyProfit,
      previousMonthRevenue: previousMonthRevenue ?? this.previousMonthRevenue,
      overallRevenue: overallRevenue ?? this.overallRevenue,
      overallOrderCount: overallOrderCount ?? this.overallOrderCount,
      overallExpenseTotal: overallExpenseTotal ?? this.overallExpenseTotal,
      overallProfit: overallProfit ?? this.overallProfit,
      averageBillValue: averageBillValue ?? this.averageBillValue,
      peakSellingHour: peakSellingHour ?? this.peakSellingHour,
      todayTopDishName: todayTopDishName ?? this.todayTopDishName,
      todayTopDishCount: todayTopDishCount ?? this.todayTopDishCount,
      todayPaymentBreakdown: todayPaymentBreakdown ?? this.todayPaymentBreakdown,
      hourlyRevenueToday: hourlyRevenueToday ?? this.hourlyRevenueToday,
      recentDailyRevenue: recentDailyRevenue ?? this.recentDailyRevenue,
      currentWeekDailyRevenue: currentWeekDailyRevenue ?? this.currentWeekDailyRevenue,
      monthlyWeeklyRevenue: monthlyWeeklyRevenue ?? this.monthlyWeeklyRevenue,
      topSellingItems: topSellingItems ?? this.topSellingItems,
      leastSellingItems: leastSellingItems ?? this.leastSellingItems,
      customerAnalytics: customerAnalytics ?? this.customerAnalytics,
      paymentAnalytics: paymentAnalytics ?? this.paymentAnalytics,
      expenseBreakdown: expenseBreakdown ?? this.expenseBreakdown,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final LocalDatabase _localDb = LocalDatabase.instance;

  DashboardNotifier() : super(DashboardState()) {
    refresh();
  }

  void populateFromData(Map<String, dynamic> summary) {
    final kpis = summary['kpis'] is Map ? Map<String, dynamic>.from(summary['kpis']) : <String, dynamic>{};

    final todayRevenue = (summary['todayRevenue'] as num?)?.toDouble() ?? (kpis['revenue'] as num?)?.toDouble() ?? 0.0;
    final todayOrderCount = (summary['todayOrderCount'] as num?)?.toInt() ?? (kpis['ordersCount'] as num?)?.toInt() ?? 0;
    final todayExpenseTotal = (summary['todayExpenseTotal'] as num?)?.toDouble() ?? (kpis['totalExpenses'] as num?)?.toDouble() ?? 0.0;
    final netProfitToday = (summary['netProfitToday'] as num?)?.toDouble() ?? (kpis['netProfit'] as num?)?.toDouble() ?? (todayRevenue - todayExpenseTotal);

    final yesterdayRevenue = (summary['yesterdayRevenue'] as num?)?.toDouble() ?? 0.0;
    final weekRevenue = (summary['weekRevenue'] as num?)?.toDouble() ?? 0.0;
    final weekOrderCount = (summary['weekOrderCount'] as num?)?.toInt() ?? 0;
    final weekExpenseTotal = (summary['weekExpenseTotal'] as num?)?.toDouble() ?? 0.0;
    final weeklyProfit = (summary['weeklyProfit'] as num?)?.toDouble() ?? (weekRevenue - weekExpenseTotal);
    final previousWeekRevenue = (summary['previousWeekRevenue'] as num?)?.toDouble() ?? 0.0;

    final monthRevenue = (summary['monthRevenue'] as num?)?.toDouble() ?? 0.0;
    final monthOrderCount = (summary['monthOrderCount'] as num?)?.toInt() ?? 0;
    final monthExpenseTotal = (summary['monthExpenseTotal'] as num?)?.toDouble() ?? 0.0;
    final monthlyProfit = (summary['monthlyProfit'] as num?)?.toDouble() ?? (monthRevenue - monthExpenseTotal);
    final previousMonthRevenue = (summary['previousMonthRevenue'] as num?)?.toDouble() ?? 0.0;

    final overallRevenue = (summary['overallRevenue'] as num?)?.toDouble() ?? 0.0;
    final overallOrderCount = (summary['overallOrderCount'] as num?)?.toInt() ?? 0;
    final overallExpenseTotal = (summary['overallExpenseTotal'] as num?)?.toDouble() ?? 0.0;
    final overallProfit = (summary['overallProfit'] as num?)?.toDouble() ?? (overallRevenue - overallExpenseTotal);

    final averageBillValue = (summary['averageBillValue'] as num?)?.toDouble() ?? 0.0;
    final peakSellingHour = (summary['peakSellingHour'] as String?) ?? 'No orders yet';
    final todayTopDishName = (summary['todayTopDishName'] as String?) ?? '';
    final todayTopDishCount = (summary['todayTopDishCount'] as num?)?.toInt() ?? 0;

    final rawTodayPay = summary['todayPaymentBreakdown'] as Map? ?? {};
    final todayPaymentBreakdown = <String, double>{};
    for (final e in rawTodayPay.entries) {
      todayPaymentBreakdown[e.key.toString()] = (e.value as num?)?.toDouble() ?? 0.0;
    }

    final rawTop = summary['topSellingItems'] as List? ?? [];
    final topSellingItems = rawTop.map((e) => Map<String, dynamic>.from(e)).toList();

    final rawLeast = summary['leastSellingItems'] as List? ?? [];
    final leastSellingItems = rawLeast.map((e) => Map<String, dynamic>.from(e)).toList();

    final customerAnalytics = summary['customerAnalytics'] is Map
        ? Map<String, dynamic>.from(summary['customerAnalytics'])
        : <String, dynamic>{};

    final paymentAnalytics = summary['paymentAnalytics'] is Map
        ? Map<String, dynamic>.from(summary['paymentAnalytics'])
        : <String, dynamic>{};

    final rawExpB = summary['expenseBreakdown'] as List? ?? [];
    final expenseBreakdown = rawExpB.map((e) => Map<String, dynamic>.from(e)).toList();

    final rawHourlyRev = summary['hourlyRevenueToday'] as List? ?? [];
    final hourlyRevenueToday = rawHourlyRev.map((e) => (e as num).toDouble()).toList();

    final rawDailyRev = summary['recentDailyRevenue'] as List? ?? [];
    final recentDailyRevenue = rawDailyRev.map((e) => (e as num).toDouble()).toList();

    final rawCurrentWeekDailyRev = summary['currentWeekDailyRevenue'] as List? ?? [];
    final currentWeekDailyRevenue = rawCurrentWeekDailyRev.map((e) => (e as num).toDouble()).toList();

    final rawMonthlyRev = summary['monthlyWeeklyRevenue'] as List? ?? [];
    final monthlyWeeklyRevenue = rawMonthlyRev.map((e) => (e as num).toDouble()).toList();

    state = state.copyWith(
      todayRevenue: todayRevenue,
      todayOrderCount: todayOrderCount,
      todayExpenseTotal: todayExpenseTotal,
      netProfitToday: netProfitToday,
      yesterdayRevenue: yesterdayRevenue,
      weekRevenue: weekRevenue,
      weekOrderCount: weekOrderCount,
      weekExpenseTotal: weekExpenseTotal,
      weeklyProfit: weeklyProfit,
      previousWeekRevenue: previousWeekRevenue,
      monthRevenue: monthRevenue,
      monthOrderCount: monthOrderCount,
      monthExpenseTotal: monthExpenseTotal,
      monthlyProfit: monthlyProfit,
      previousMonthRevenue: previousMonthRevenue,
      overallRevenue: overallRevenue,
      overallOrderCount: overallOrderCount,
      overallExpenseTotal: overallExpenseTotal,
      overallProfit: overallProfit,
      averageBillValue: averageBillValue,
      peakSellingHour: peakSellingHour,
      todayTopDishName: todayTopDishName,
      todayTopDishCount: todayTopDishCount,
      todayPaymentBreakdown: todayPaymentBreakdown,
      hourlyRevenueToday: hourlyRevenueToday.isNotEmpty ? hourlyRevenueToday : List.filled(6, 0.0),
      recentDailyRevenue: recentDailyRevenue.isNotEmpty ? recentDailyRevenue : List.filled(7, 0.0),
      currentWeekDailyRevenue: currentWeekDailyRevenue.isNotEmpty ? currentWeekDailyRevenue : List.filled(7, 0.0),
      monthlyWeeklyRevenue: monthlyWeeklyRevenue.isNotEmpty ? monthlyWeeklyRevenue : List.filled(5, 0.0),
      topSellingItems: topSellingItems,
      leastSellingItems: leastSellingItems,
      customerAnalytics: customerAnalytics,
      paymentAnalytics: paymentAnalytics,
      expenseBreakdown: expenseBreakdown,
      isLoading: false,
      errorMessage: null,
    );
  }

  Future<void> refresh({bool forceSpinner = false}) async {
    final showLoading = forceSpinner && state.todayRevenue == 0;
    if (showLoading) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      // 100% Offline Aggregation from SQLite Local Database
      final metrics = await _localDb.computeDashboardMetrics();
      populateFromData(metrics);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});
