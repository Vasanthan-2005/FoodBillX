import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_category_model.dart';
import '../models/expense_model.dart';
import '../repositories/expense_category_repository.dart';
import '../repositories/expense_repository.dart';
import 'dashboard_provider.dart';

class ExpenseState {
  final List<ExpenseModel> expenses;
  final List<ExpenseCategoryModel> categories;
  final String? selectedCategory;
  final bool isLoading;
  final String? errorMessage;

  ExpenseState({
    required this.expenses,
    required this.categories,
    this.selectedCategory,
    this.isLoading = false,
    this.errorMessage,
  });

  factory ExpenseState.initial() => ExpenseState(expenses: [], categories: []);

  ExpenseState copyWith({
    List<ExpenseModel>? expenses,
    List<ExpenseCategoryModel>? categories,
    String? selectedCategory,
    bool clearCategory = false,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      categories: categories ?? this.categories,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final ExpenseRepository _expenseRepo;
  final ExpenseCategoryRepository _catRepo;
  final Ref _ref;

  ExpenseNotifier(this._expenseRepo, this._catRepo, this._ref)
    : super(ExpenseState.initial()) {
    loadAll();
  }

  void updateFromBootstrap(List<ExpenseModel> expenses) {
    state = state.copyWith(expenses: expenses, isLoading: false, errorMessage: null);
  }

  Future<void> loadAll({bool forceSpinner = false}) async {
    final showLoading = forceSpinner || state.expenses.isEmpty;
    state = state.copyWith(isLoading: showLoading, errorMessage: null);

    try {
      final expenses = await _expenseRepo.getAll(
        category: state.selectedCategory,
      );
      final categories = await _catRepo.getAll();
      state = state.copyWith(
        expenses: expenses,
        categories: categories,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: state.expenses.isEmpty
            ? e.toString().replaceAll('Exception: ', '')
            : null,
      );
    }
  }

  void selectCategory(String? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
    loadAll();
  }

  Future<bool> createExpense(Map<String, dynamic> data) async {
    try {
      await _expenseRepo.create(data);
      await loadAll(forceSpinner: false);
      _ref.read(dashboardProvider.notifier).refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateExpense(String id, Map<String, dynamic> data) async {
    try {
      await _expenseRepo.update(id, data);
      await loadAll(forceSpinner: false);
      _ref.read(dashboardProvider.notifier).refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      await _expenseRepo.delete(id);
      await loadAll(forceSpinner: false);
      _ref.read(dashboardProvider.notifier).refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createExpenseCategory(String name, String icon) async {
    try {
      await _catRepo.create(name, icon);
      await loadAll(forceSpinner: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteExpenseCategory(String id) async {
    try {
      await _catRepo.delete(id);
      await loadAll(forceSpinner: false);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((
  ref,
) {
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  final catRepo = ref.watch(expenseCategoryRepositoryProvider);
  return ExpenseNotifier(expenseRepo, catRepo, ref);
});
