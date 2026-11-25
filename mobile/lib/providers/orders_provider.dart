import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';
import 'customer_provider.dart';
import 'dashboard_provider.dart';
import 'sync_provider.dart';

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

  static const int _pageSize = 100;

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
      final fetched = await _repo.getAll(
        startDate: start,
        endDate: end,
        paymentMethod: newPaymentFilter == 'ALL' ? null : newPaymentFilter.toLowerCase(),
        limit: _pageSize + 1,
        offset: 0,
      );
      if (generation != _loadGeneration) return;
      final hasMore = fetched.length > _pageSize;
      final orders = hasMore ? fetched.sublist(0, _pageSize) : fetched;
      state = state.copyWith(
        orders: orders,
        totalCount: orders.length,
        isLoading: false,
        hasMore: hasMore,
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

  Future<void> loadMoreOrders() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final generation = _loadGeneration;
    final (start, end) = _calculateDateRange(state.dateFilter, state.customDateRange);
    state = state.copyWith(isLoadingMore: true);

    try {
      final fetched = await _repo.getAll(
        startDate: start,
        endDate: end,
        paymentMethod: state.selectedPaymentFilter == 'ALL'
            ? null
            : state.selectedPaymentFilter.toLowerCase(),
        limit: _pageSize + 1,
        offset: state.orders.length,
      );
      if (generation != _loadGeneration) return;
      final hasMore = fetched.length > _pageSize;
      final page = hasMore ? fetched.sublist(0, _pageSize) : fetched;
      final combined = [...state.orders, ...page];
      state = state.copyWith(
        orders: combined,
        totalCount: combined.length,
        isLoadingMore: false,
        hasMore: hasMore,
      );
    } catch (_) {
      if (generation == _loadGeneration) {
        state = state.copyWith(isLoadingMore: false);
      }
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

  Future<bool> deleteOrder(String orderId) async {
    try {
      final deleted = await _repo.delete(orderId);
      if (!deleted) return false;
      await loadOrders(forceSpinner: false);
      await _ref.read(dashboardProvider.notifier).refresh();
      await _ref.read(customerProvider.notifier).loadCustomers();
      await _ref.read(syncProvider.notifier).refreshStatus();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateOrder({
    required String orderId,
    required String customerName,
    required String customerPhone,
    required String paymentMethod,
    required List<OrderItemModel> items,
    required double subtotal,
    required double discountAmount,
    required double serviceChargeAmount,
    required double grandTotal,
    String notes = '',
  }) async {
    try {
      final updated = await _repo.update(
        orderId: orderId,
        customerName: customerName,
        customerPhone: customerPhone,
        paymentMethod: paymentMethod,
        items: items,
        subtotal: subtotal,
        discountAmount: discountAmount,
        serviceChargeAmount: serviceChargeAmount,
        grandTotal: grandTotal,
        notes: notes,
      );
      if (updated == null) return false;
      await loadOrders(forceSpinner: false);
      await _ref.read(dashboardProvider.notifier).refresh();
      await _ref.read(customerProvider.notifier).loadCustomers();
      await _ref.read(syncProvider.notifier).refreshStatus();
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
