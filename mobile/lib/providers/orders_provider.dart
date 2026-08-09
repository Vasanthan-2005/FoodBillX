import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';
import 'dashboard_provider.dart';

enum OrderDateFilter { today, yesterday, thisWeek, thisMonth, custom }

class OrdersState {
  final List<OrderModel> orders;
  final OrderDateFilter dateFilter;
  final DateTimeRange? customDateRange;
  final String selectedPaymentFilter;
  final int totalCount;
  final bool isLoading;
  final String? errorMessage;
  final bool isLoadingMore;
  final bool hasMore;

  OrdersState({
    required this.orders,
    this.dateFilter = OrderDateFilter.today,
    this.customDateRange,
    this.selectedPaymentFilter = 'ALL',
    this.totalCount = 0,
    this.isLoading = false,
    this.errorMessage,
    this.isLoadingMore = false,
    this.hasMore = false,
  });

  factory OrdersState.initial() => OrdersState(orders: []);

  OrdersState copyWith({
    List<OrderModel>? orders,
    OrderDateFilter? dateFilter,
    DateTimeRange? customDateRange,
    String? selectedPaymentFilter,
    int? totalCount,
    bool? isLoading,
    String? errorMessage,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      dateFilter: dateFilter ?? this.dateFilter,
      customDateRange: customDateRange ?? this.customDateRange,
      selectedPaymentFilter: selectedPaymentFilter ?? this.selectedPaymentFilter,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderRepository _repo;
  final Ref _ref;
  int _loadGeneration = 0;

  OrdersNotifier(this._repo, this._ref) : super(OrdersState.initial()) {
    loadOrders();
  }

  (DateTime?, DateTime?) _calculateDateRange(OrderDateFilter filter, DateTimeRange? customRange) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (filter) {
      case OrderDateFilter.today:
        return (startOfDay, endOfDay);
      case OrderDateFilter.yesterday:
        final startYest = startOfDay.subtract(const Duration(days: 1));
        final endYest = endOfDay.subtract(const Duration(days: 1));
        return (startYest, endYest);
      case OrderDateFilter.thisWeek:
        final startWeek = startOfDay.subtract(Duration(days: startOfDay.weekday - 1));
        return (startWeek, endOfDay);
      case OrderDateFilter.thisMonth:
        final startMonth = DateTime(now.year, now.month, 1);
        return (startMonth, endOfDay);
      case OrderDateFilter.custom:
        if (customRange != null) {
          return (customRange.start, customRange.end);
        }
        return (startOfDay, endOfDay);
    }
  }

  void updateFromBootstrap(List<OrderModel> orders) {
    state = state.copyWith(
      orders: orders,
      totalCount: orders.length,
      isLoading: false,
      errorMessage: null,
    );
  }

  Future<void> loadOrders({
    OrderDateFilter? dateFilter,
    DateTimeRange? customRange,
    String? paymentFilter,
    bool forceSpinner = false,
  }) async {
    final newFilter = dateFilter ?? state.dateFilter;
    final newCustomRange = customRange ?? state.customDateRange;
    final newPaymentFilter = paymentFilter ?? state.selectedPaymentFilter;

    final (start, end) = _calculateDateRange(newFilter, newCustomRange);
    final generation = ++_loadGeneration;

    final showLoading = forceSpinner || state.orders.isEmpty;
    state = state.copyWith(
      dateFilter: newFilter,
      customDateRange: newCustomRange,
      selectedPaymentFilter: newPaymentFilter,
      isLoading: showLoading,
      errorMessage: null,
    );

    try {
      final orders = await _repo.getAll(
        startDate: start,
        endDate: end,
        paymentMethod: newPaymentFilter == 'ALL' ? null : newPaymentFilter.toLowerCase(),
      );
      if (generation != _loadGeneration) return;
      state = state.copyWith(
        orders: orders,
        totalCount: orders.length,
        isLoading: false,
        hasMore: false,
      );
    } catch (e) {
      if (generation != _loadGeneration) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: state.orders.isEmpty
            ? e.toString().replaceAll('Exception: ', '')
            : null,
      );
    }
  }

  Future<bool> refundOrder(String orderId) async {
    try {
      await _repo.refund(orderId);
      await loadOrders(forceSpinner: false);
      _ref.read(dashboardProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return OrdersNotifier(repo, ref);
});
