import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/local_database.dart';
import '../models/expense_category_model.dart';
import '../models/expense_model.dart';
import '../repositories/expense_category_repository.dart';
import '../repositories/expense_repository.dart';
import 'dashboard_provider.dart';
import 'sync_provider.dart';

class ExpenseState {
  final List<ExpenseModel> expenses;
  final List<ExpenseCategoryModel> categories;
  final String? selectedCategory;
  final double monthlyBudget;
  final double monthExpenseTotal;
  final String currentMonthKey;
  final bool isLoading;
  final String? errorMessage;

  ExpenseState({
    required this.expenses,
    required this.categories,
    this.selectedCategory,
    this.monthlyBudget = 0.0,
    this.monthExpenseTotal = 0.0,
    this.currentMonthKey = '',
    this.isLoading = false,
    this.errorMessage,
  });

  factory ExpenseState.initial() => ExpenseState(
        expenses: [],
        categories: [],
        currentMonthKey: LocalDatabase.formatMonthKey(DateTime.now()),
      );

  ExpenseState copyWith({
    List<ExpenseModel>? expenses,
    List<ExpenseCategoryModel>? categories,
    String? selectedCategory,
    bool clearCategory = false,
    double? monthlyBudget,
    double? monthExpenseTotal,
    String? currentMonthKey,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      categories: categories ?? this.categories,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      monthExpenseTotal: monthExpenseTotal ?? this.monthExpenseTotal,
      currentMonthKey: currentMonthKey ?? this.currentMonthKey,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  double get budgetRemaining =>
      (monthlyBudget > 0 && monthlyBudget >= monthExpenseTotal)
          ? (monthlyBudget - monthExpenseTotal)
          : 0.0;

  double get budgetUsageRatio =>
      monthlyBudget > 0 ? (monthExpenseTotal / monthlyBudget).clamp(0.0, 1.0) : 0.0;

  bool get isOverBudget => monthlyBudget > 0 && monthExpenseTotal > monthlyBudget;
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
      final now = DateTime.now();
      final monthKey = LocalDatabase.formatMonthKey(now);

      final expenses = await _expenseRepo.getAll(
        category: state.selectedCategory,
      );
      final categories = await _catRepo.getAll();
      final monthTotal = await _expenseRepo.getMonthlyTotal(now);
      final budget = await _expenseRepo.getMonthlyBudget(monthKey);

      state = state.copyWith(
        expenses: expenses,
        categories: categories,
        monthlyBudget: budget,
        monthExpenseTotal: monthTotal,
        currentMonthKey: monthKey,
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

  Future<bool> setMonthlyBudget(double amount) async {
    try {
      final now = DateTime.now();
      final monthKey = LocalDatabase.formatMonthKey(now);
      await _expenseRepo.setMonthlyBudget(monthKey, amount);
      state = state.copyWith(monthlyBudget: amount);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createExpense(Map<String, dynamic> data) async {
    try {
      await _expenseRepo.create(data);
      await loadAll(forceSpinner: false);
      _ref.read(dashboardProvider.notifier).refresh();
      _ref.read(syncProvider.notifier).autoSyncIfOnline();
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
      _ref.read(syncProvider.notifier).autoSyncIfOnline();
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
      _ref.read(syncProvider.notifier).autoSyncIfOnline();
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
