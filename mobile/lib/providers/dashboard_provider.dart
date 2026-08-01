import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/expense_repository.dart';
import '../repositories/order_repository.dart';

/// Dashboard analytics computed entirely from local Isar data.
class DashboardState {
  final double todayRevenue;
  final int todayOrderCount;
  final double todayExpenseTotal;
  final double netProfitToday;
  final double monthRevenue;
  final List<Map<String, dynamic>> topSellingItems;
  final bool isLoading;
  final String? errorMessage;

  DashboardState({
    this.todayRevenue = 0,
    this.todayOrderCount = 0,
    this.todayExpenseTotal = 0,
    this.netProfitToday = 0,
    this.monthRevenue = 0,
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
      topSellingItems: topSellingItems ?? this.topSellingItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final OrderRepository _orderRepo;
  final ExpenseRepository _expenseRepo;

  DashboardNotifier(this._orderRepo, this._expenseRepo)
    : super(DashboardState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Today's orders
      final todayOrders = await _orderRepo.getTodayOrders();
      final todayRevenue = todayOrders.fold(
        0.0,
        (sum, o) => sum + o.grandTotal,
      );
      final todayOrderCount = todayOrders.length;

      // Today's expenses
      final todayExpenseTotal = await _expenseRepo.getTodayTotal();

      // Month's orders
      final monthOrders = await _orderRepo.getMonthOrders();
      final monthRevenue = monthOrders.fold(
        0.0,
        (sum, o) => sum + o.grandTotal,
      );

      // Top selling items this month (aggregate from order items)
      final itemMap = <String, Map<String, dynamic>>{};
      for (final order in monthOrders) {
        for (final item in order.items) {
          final entry = itemMap.putIfAbsent(
            item.name,
            () => {'_id': item.name, 'totalQuantity': 0, 'totalSales': 0.0},
          );
          entry['totalQuantity'] =
              (entry['totalQuantity'] as int) + item.quantity;
          entry['totalSales'] = (entry['totalSales'] as double) + item.subtotal;
        }
      }
      final topSelling = itemMap.values.toList()
        ..sort(
          (a, b) =>
              (b['totalQuantity'] as int).compareTo(a['totalQuantity'] as int),
        );
      final top5 = topSelling.take(5).toList();

      state = state.copyWith(
        todayRevenue: todayRevenue,
        todayOrderCount: todayOrderCount,
        todayExpenseTotal: todayExpenseTotal,
        netProfitToday: todayRevenue - todayExpenseTotal,
        monthRevenue: monthRevenue,
        topSellingItems: top5,
        isLoading: false,
      );
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
      final orderRepo = ref.watch(orderRepositoryProvider);
      final expenseRepo = ref.watch(expenseRepositoryProvider);
      return DashboardNotifier(orderRepo, expenseRepo);
    });
