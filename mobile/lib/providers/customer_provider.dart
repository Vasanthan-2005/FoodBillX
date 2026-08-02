import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';

class CustomerState {
  final List<CustomerModel> customers;
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
    List<CustomerModel>? customers,
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

  CustomerNotifier(this._repo) : super(CustomerState.initial()) {
    loadCustomers();
  }

  Future<void> loadCustomers({bool forceSpinner = false}) async {
    final showLoading = forceSpinner || state.customers.isEmpty;
    state = state.copyWith(isLoading: showLoading, errorMessage: null);

    try {
      final customers = await _repo.getAll(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      state = state.copyWith(customers: customers, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: state.customers.isEmpty
            ? e.toString().replaceAll('Exception: ', '')
            : null,
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
      await loadCustomers(forceSpinner: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<CustomerModel?> quickCreateCustomer({
    required String name,
    required String phone,
    String? loyaltyCardNumber,
  }) async {
    try {
      final newCust = await _repo.create({
        'name': name,
        'phone': phone,
        if (loyaltyCardNumber != null && loyaltyCardNumber.isNotEmpty)
          'loyaltyCardNumber': loyaltyCardNumber,
      });
      await loadCustomers(forceSpinner: false);
      return newCust;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      await _repo.update(id, data);
      await loadCustomers(forceSpinner: false);
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
      await loadCustomers(forceSpinner: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> assignLoyaltyCard(String id, String cardNumber) async {
    try {
      await _repo.assignLoyaltyCard(id, cardNumber);
      await loadCustomers(forceSpinner: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  CustomerModel? findByPhone(String phone) {
    final p = phone.trim();
    if (p.isEmpty) return null;
    final match = state.customers.where((c) => c.phone.trim() == p);
    return match.isNotEmpty ? match.first : null;
  }

  CustomerModel? findByLoyaltyCard(String cardNumber) {
    final card = cardNumber.trim().toLowerCase();
    if (card.isEmpty) return null;
    final match = state.customers.where(
      (c) => c.loyaltyCardNumber.trim().toLowerCase() == card,
    );
    return match.isNotEmpty ? match.first : null;
  }

  Future<CustomerModel?> searchByLoyaltyCardNumber(String cardNumber) async {
    final local = findByLoyaltyCard(cardNumber);
    if (local != null) return local;

    try {
      final results = await _repo.getAll(cardNumber: cardNumber.trim());
      if (results.isNotEmpty) {
        await loadCustomers(forceSpinner: false);
        return results.first;
      }
    } catch (_) {}
    return null;
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, CustomerState>(
  (ref) {
    final repo = ref.watch(customerRepositoryProvider);
    return CustomerNotifier(repo);
  },
);
