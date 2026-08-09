import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/business_settings_model.dart';
import '../models/category_model.dart';
import '../models/customer_model.dart';
import '../models/expense_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import 'customer_provider.dart';
import 'dashboard_provider.dart';
import 'expense_provider.dart';
import 'menu_provider.dart';
import 'orders_provider.dart';
import 'settings_provider.dart';

class BootstrapState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  BootstrapState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  BootstrapState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return BootstrapState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}

class BootstrapNotifier extends StateNotifier<BootstrapState> {
  final ApiClient _apiClient;
  final Ref _ref;

  BootstrapNotifier(this._apiClient, this._ref) : super(BootstrapState());

  Future<bool> loadBootstrap() async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      final response = await _apiClient.dio.get('bootstrap');
      final body = response.data;

      if (body is Map && body['success'] == true && body['data'] is Map) {
        final data = Map<String, dynamic>.from(body['data']);

        // 1. Settings
        if (data['settings'] is Map) {
          final settingsMap = Map<String, dynamic>.from(data['settings']);
          final settingsModel = BusinessSettingsModel.fromJson(settingsMap);
          _ref.read(settingsProvider.notifier).updateFromBootstrap(settingsModel);
        }

        // 2. Categories & Menu Items
        final rawCategories = (data['categories'] as List? ?? []);
        final categories = rawCategories
            .map((c) => CategoryModel.fromJson(Map<String, dynamic>.from(c)))
            .toList();

        final rawMenuItems = (data['menuItems'] as List? ?? []);
        final menuItems = rawMenuItems
            .map((m) => MenuItemModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();

        _ref
            .read(menuProvider.notifier)
            .updateFromBootstrap(categories, menuItems);

        // 3. Customers
        final rawCustomers = (data['customers'] as List? ?? []);
        final customers = rawCustomers
            .map((c) => CustomerModel.fromJson(Map<String, dynamic>.from(c)))
            .toList();
        _ref.read(customerProvider.notifier).updateFromBootstrap(customers);

        // 4. Recent Orders
        final rawOrders = (data['recentOrders'] as List? ?? []);
        final orders = rawOrders
            .map((o) => OrderModel.fromJson(Map<String, dynamic>.from(o)))
            .toList();
        _ref.read(ordersProvider.notifier).updateFromBootstrap(orders);

        // 5. Expenses
        final rawExpenses = (data['expenses'] as List? ?? []);
        final expenses = rawExpenses
            .map((e) => ExpenseModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _ref.read(expenseProvider.notifier).updateFromBootstrap(expenses);

        // 6. Dashboard Analytics Summary
        if (data['dashboard'] is Map) {
          final dashMap = Map<String, dynamic>.from(data['dashboard']);
          _ref.read(dashboardProvider.notifier).populateFromData(dashMap);
        }

        state = state.copyWith(isLoading: false, isSuccess: true);
        return true;
      } else {
        throw Exception('Invalid server bootstrap response format');
      }
    } on DioException catch (dioErr) {
      // Fallback for legacy server endpoints (if /bootstrap is 404 Not Found)
      if (dioErr.response?.statusCode == 404) {
        try {
          await Future.wait([
            _ref.read(menuProvider.notifier).loadCategoriesAndItems(),
            _ref.read(customerProvider.notifier).loadCustomers(),
            _ref.read(settingsProvider.notifier).loadSettings(),
            _ref.read(dashboardProvider.notifier).refresh(forceSpinner: true),
            _ref.read(expenseProvider.notifier).loadAll(),
            _ref.read(ordersProvider.notifier).loadOrders(),
          ]);

          state = state.copyWith(isLoading: false, isSuccess: true);
          return true;
        } catch (e) {
          final cleanMsg = e.toString().replaceAll('Exception: ', '');
          state = state.copyWith(
            isLoading: false,
            isSuccess: false,
            errorMessage: cleanMsg,
          );
          return false;
        }
      }

      final cleanMsg = dioErr.message ?? 'Server connection error (${dioErr.response?.statusCode ?? 500})';
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: cleanMsg,
      );
      return false;
    } catch (e) {
      final cleanMsg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: cleanMsg,
      );
      return false;
    }
  }
}

final bootstrapProvider =
    StateNotifierProvider<BootstrapNotifier, BootstrapState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BootstrapNotifier(apiClient, ref);
});
