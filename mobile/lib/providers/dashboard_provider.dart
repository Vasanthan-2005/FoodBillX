import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/local_cache_service.dart';

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

  final double monthRevenue;
  final int monthOrderCount;
  final double monthExpenseTotal;
  final double monthlyProfit;

  final double overallRevenue;
  final int overallOrderCount;
  final double overallExpenseTotal;
  final double overallProfit;

  final double averageBillValue;
  final String peakSellingHour;

  final List<double> recentDailyRevenue;
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
    this.monthRevenue = 0,
    this.monthOrderCount = 0,
    this.monthExpenseTotal = 0,
    this.monthlyProfit = 0,
    this.overallRevenue = 0,
    this.overallOrderCount = 0,
    this.overallExpenseTotal = 0,
    this.overallProfit = 0,
    this.averageBillValue = 0,
    this.peakSellingHour = '1:00 PM',
    this.recentDailyRevenue = const [],
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
    double? monthRevenue,
    int? monthOrderCount,
    double? monthExpenseTotal,
    double? monthlyProfit,
    double? overallRevenue,
    int? overallOrderCount,
    double? overallExpenseTotal,
    double? overallProfit,
    double? averageBillValue,
    String? peakSellingHour,
    List<double>? recentDailyRevenue,
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
      monthRevenue: monthRevenue ?? this.monthRevenue,
      monthOrderCount: monthOrderCount ?? this.monthOrderCount,
      monthExpenseTotal: monthExpenseTotal ?? this.monthExpenseTotal,
      monthlyProfit: monthlyProfit ?? this.monthlyProfit,
      overallRevenue: overallRevenue ?? this.overallRevenue,
      overallOrderCount: overallOrderCount ?? this.overallOrderCount,
      overallExpenseTotal: overallExpenseTotal ?? this.overallExpenseTotal,
      overallProfit: overallProfit ?? this.overallProfit,
      averageBillValue: averageBillValue ?? this.averageBillValue,
      peakSellingHour: peakSellingHour ?? this.peakSellingHour,
      recentDailyRevenue: recentDailyRevenue ?? this.recentDailyRevenue,
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
  final ApiClient _apiClient;
  static const String _cacheKey = 'dashboard_summary';

  DashboardNotifier(this._apiClient)
    : super(DashboardState()) {
    refresh(forceSpinner: true);
  }

  Future<void> refresh({bool forceSpinner = false}) async {
    final showLoading = forceSpinner || (state.recentDailyRevenue.isEmpty && state.todayRevenue == 0);
    state = state.copyWith(isLoading: showLoading, errorMessage: null);

    dynamic data;
    try {
      final response = await _apiClient.dio.get('/reports/dashboard');
      data = response.data;
      await LocalCacheService.saveCache(_cacheKey, data);
    } catch (_) {
      data = await LocalCacheService.getCache(_cacheKey);
    }

    Map<String, dynamic> summary = {};
    if (data is Map && data.containsKey('data')) {
      final d = data['data'];
      if (d is Map && d.containsKey('summary')) {
        summary = Map<String, dynamic>.from(d['summary']);
      }
    }

    final todayRevenue = (summary['todayRevenue'] as num?)?.toDouble() ?? 0.0;
    final todayOrderCount = (summary['todayOrderCount'] as num?)?.toInt() ?? 0;
    final todayExpenseTotal = (summary['todayExpenseTotal'] as num?)?.toDouble() ?? 0.0;
    final netProfitToday = (summary['netProfitToday'] as num?)?.toDouble() ?? (todayRevenue - todayExpenseTotal);

    final yesterdayRevenue = (summary['yesterdayRevenue'] as num?)?.toDouble() ?? 0.0;
    final weekRevenue = (summary['weekRevenue'] as num?)?.toDouble() ?? 0.0;
    final weekOrderCount = (summary['weekOrderCount'] as num?)?.toInt() ?? 0;
    final weekExpenseTotal = (summary['weekExpenseTotal'] as num?)?.toDouble() ?? 0.0;
    final weeklyProfit = (summary['weeklyProfit'] as num?)?.toDouble() ?? (weekRevenue - weekExpenseTotal);

    final monthRevenue = (summary['monthRevenue'] as num?)?.toDouble() ?? 0.0;
    final monthOrderCount = (summary['monthOrderCount'] as num?)?.toInt() ?? 0;
    final monthExpenseTotal = (summary['monthExpenseTotal'] as num?)?.toDouble() ?? 0.0;
    final monthlyProfit = (summary['monthlyProfit'] as num?)?.toDouble() ?? (monthRevenue - monthExpenseTotal);

    final overallRevenue = (summary['overallRevenue'] as num?)?.toDouble() ?? 0.0;
    final overallOrderCount = (summary['overallOrderCount'] as num?)?.toInt() ?? 0;
    final overallExpenseTotal = (summary['overallExpenseTotal'] as num?)?.toDouble() ?? 0.0;
    final overallProfit = (summary['overallProfit'] as num?)?.toDouble() ?? (overallRevenue - overallExpenseTotal);

    final averageBillValue = (summary['averageBillValue'] as num?)?.toDouble() ?? 0.0;
    final peakSellingHour = (summary['peakSellingHour'] as String?) ?? '1:00 PM';

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

    final rawDailyRev = summary['recentDailyRevenue'] as List? ?? [];
    final recentDailyRevenue = rawDailyRev.map((e) => (e as num).toDouble()).toList();

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
      monthRevenue: monthRevenue,
      monthOrderCount: monthOrderCount,
      monthExpenseTotal: monthExpenseTotal,
      monthlyProfit: monthlyProfit,
      overallRevenue: overallRevenue,
      overallOrderCount: overallOrderCount,
      overallExpenseTotal: overallExpenseTotal,
      overallProfit: overallProfit,
      averageBillValue: averageBillValue,
      peakSellingHour: peakSellingHour,
      recentDailyRevenue: recentDailyRevenue.isNotEmpty ? recentDailyRevenue : List.filled(7, 0.0),
      topSellingItems: topSellingItems,
      leastSellingItems: leastSellingItems,
      customerAnalytics: customerAnalytics,
      paymentAnalytics: paymentAnalytics,
      expenseBreakdown: expenseBreakdown,
      isLoading: false,
      errorMessage: null,
    );
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return DashboardNotifier(apiClient);
    });
