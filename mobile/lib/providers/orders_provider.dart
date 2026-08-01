import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';

class OrdersState {
  final List<OrderModel> orders;
  final int totalCount;
  final bool isLoading;
  final String? errorMessage;
  final bool isLoadingMore;
  final bool hasMore;

  OrdersState({
    required this.orders,
    this.totalCount = 0,
    this.isLoading = false,
    this.errorMessage,
    this.isLoadingMore = false,
    this.hasMore = false,
  });

  factory OrdersState.initial() => OrdersState(orders: []);

  OrdersState copyWith({
    List<OrderModel>? orders,
    int? totalCount,
    bool? isLoading,
    String? errorMessage,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
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
  int _loadGeneration = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _paymentMethod;

  OrdersNotifier(this._repo) : super(OrdersState.initial()) {
    loadOrders();
  }

  Future<void> loadOrders({
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
    bool forceSpinner = false,
  }) async {
    _startDate = startDate;
    _endDate = endDate;
    _paymentMethod = paymentMethod;
    final generation = ++_loadGeneration;

    final showLoading = forceSpinner || state.orders.isEmpty;
    state = state.copyWith(isLoading: showLoading, errorMessage: null);

    try {
      final orders = await _repo.getAll(
        startDate: startDate,
        endDate: endDate,
        paymentMethod: paymentMethod,
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

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final next = await _repo.getAll(
        startDate: _startDate,
        endDate: _endDate,
        paymentMethod: _paymentMethod,
        offset: state.orders.length,
      );
      final combined = [...state.orders, ...next];
      state = state.copyWith(
        orders: combined,
        isLoadingMore: false,
        hasMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: error.toString(),
      );
    }
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((
  ref,
) {
  final repo = ref.watch(orderRepositoryProvider);
  return OrdersNotifier(repo);
});
