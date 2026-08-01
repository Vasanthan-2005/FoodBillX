import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/sync/sync_status_notifier.dart';
import '../local_db/schemas/customer_schema.dart';
import '../repositories/customer_repository.dart';

class CustomerState {
  final List<CustomerSchema> customers;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  CustomerState({
    required this.customers,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  factory CustomerState.initial() => CustomerState(customers: []);

  CustomerState copyWith({
    List<CustomerSchema>? customers,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class CustomerNotifier extends StateNotifier<CustomerState> {
  final CustomerRepository _repo;
  final SyncStatusNotifier _syncStatus;

  CustomerNotifier(this._repo, this._syncStatus)
    : super(CustomerState.initial()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final customers = await _repo.getAll(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      state = state.copyWith(customers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadCustomers();
  }

  Future<bool> createCustomer(Map<String, dynamic> data) async {
    try {
      await _repo.create(data);
      await loadCustomers();
      _syncStatus.refreshPending();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      await _repo.update(id, data);
      await loadCustomers();
      _syncStatus.refreshPending();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      await _repo.delete(id);
      await loadCustomers();
      _syncStatus.refreshPending();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> assignLoyaltyCard(String id, String cardNumber) async {
    try {
      await _repo.assignLoyaltyCard(id, cardNumber);
      await loadCustomers();
      _syncStatus.refreshPending();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, CustomerState>(
  (ref) {
    final repo = ref.watch(customerRepositoryProvider);
    final syncStatus = ref.watch(syncStatusProvider.notifier);
    return CustomerNotifier(repo, syncStatus);
  },
);
