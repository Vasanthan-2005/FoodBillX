import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/local_cache_service.dart';
import '../repositories/order_repository.dart';

class DashboardState {
  final double todayRevenue;
  final int todayOrderCount;
  final double todayExpenseTotal;
  final double netProfitToday;
  final double monthRevenue;
  final double weekRevenue;
  final int weekOrderCount;
  final int monthOrderCount;
  final List<double> recentDailyRevenue;
  final List<Map<String, dynamic>> topSellingItems;
  final bool isLoading;
  final String? errorMessage;

  DashboardState({
    this.todayRevenue = 0,
    this.todayOrderCount = 0,
    this.todayExpenseTotal = 0,
    this.netProfitToday = 0,
    this.monthRevenue = 0,
    this.weekRevenue = 0,
    this.weekOrderCount = 0,
    this.monthOrderCount = 0,
    this.recentDailyRevenue = const [],
    this.topSellingItems = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    double? todayRevenue,
    int? todayOrderCount,
    double? todayExpenseTotal,
    double? netProfitToday,
    double? monthRevenue,
    double? weekRevenue,
    int? weekOrderCount,
    int? monthOrderCount,
    List<double>? recentDailyRevenue,
    List<Map<String, dynamic>>? topSellingItems,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      todayRevenue: todayRevenue ?? this.todayRevenue,
      todayOrderCount: todayOrderCount ?? this.todayOrderCount,
      todayExpenseTotal: todayExpenseTotal ?? this.todayExpenseTotal,
      netProfitToday: netProfitToday ?? this.netProfitToday,
      monthRevenue: monthRevenue ?? this.monthRevenue,
      weekRevenue: weekRevenue ?? this.weekRevenue,
      weekOrderCount: weekOrderCount ?? this.weekOrderCount,
      monthOrderCount: monthOrderCount ?? this.monthOrderCount,
      recentDailyRevenue: recentDailyRevenue ?? this.recentDailyRevenue,
      topSellingItems: topSellingItems ?? this.topSellingItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final ApiClient _apiClient;
  final OrderRepository _orderRepo;
  static const String _cacheKey = 'dashboard_summary';

  DashboardNotifier(this._apiClient, this._orderRepo)
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
    final monthRevenue = (summary['monthRevenue'] as num?)?.toDouble() ?? 0.0;
    final rawTop = summary['topSellingItems'] as List? ?? [];
    final topSellingItems = rawTop.map((e) => Map<String, dynamic>.from(e)).toList();

    // Fetch orders and expenses for graphs
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(const Duration(days: 6));

    List periodOrders = [];
    try {
      periodOrders = await _orderRepo.getBetween(
        startOfWeek,
        startOfDay.add(const Duration(days: 1)),
      );
    } catch (_) {}

    final weekOrders = periodOrders
        .where((order) => !order.createdAt.isBefore(startOfWeek))
        .toList(growable: false);
    final weekRevenue = weekOrders.fold(
      0.0,
      (sum, order) => sum + order.grandTotal,
    );

    final dailyRevenue = List<double>.filled(7, 0);
    for (final order in weekOrders) {
      final day = DateTime(
        order.createdAt.year,
        order.createdAt.month,
        order.createdAt.day,
      );
      final index = day.difference(startOfWeek).inDays;
      if (index >= 0 && index < dailyRevenue.length) {
        dailyRevenue[index] += order.grandTotal;
      }
    }

    state = state.copyWith(
      todayRevenue: todayRevenue,
      todayOrderCount: todayOrderCount,
      todayExpenseTotal: todayExpenseTotal,
      netProfitToday: netProfitToday,
      monthRevenue: monthRevenue > 0 ? monthRevenue : todayRevenue,
      weekRevenue: weekRevenue > 0 ? weekRevenue : todayRevenue,
      weekOrderCount: weekOrders.isNotEmpty ? weekOrders.length : todayOrderCount,
      monthOrderCount: periodOrders.isNotEmpty ? periodOrders.length : todayOrderCount,
      recentDailyRevenue: dailyRevenue,
      topSellingItems: topSellingItems,
      isLoading: false,
      errorMessage: null,
    );
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      final orderRepo = ref.watch(orderRepositoryProvider);
      return DashboardNotifier(apiClient, orderRepo);
    });
