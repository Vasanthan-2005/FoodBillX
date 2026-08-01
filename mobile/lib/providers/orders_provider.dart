import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_db/schemas/order_schema.dart';
import '../repositories/order_repository.dart';

class OrdersState {
  final List<OrderSchema> orders;
  final int totalCount;
  final bool isLoading;
  final String? errorMessage;

  OrdersState({
    required this.orders,
    this.totalCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  factory OrdersState.initial() => OrdersState(orders: []);

  OrdersState copyWith({
    List<OrderSchema>? orders,
    int? totalCount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderRepository _repo;

  OrdersNotifier(this._repo) : super(OrdersState.initial()) {
    loadOrders();
  }

  Future<void> loadOrders({
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final orders = await _repo.getAll(
        startDate: startDate,
        endDate: endDate,
        paymentMethod: paymentMethod,
      );
      state = state.copyWith(
        orders: orders,
        totalCount: orders.length,
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

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((
  ref,
) {
  final repo = ref.watch(orderRepositoryProvider);
  return OrdersNotifier(repo);
});
