import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/sync/sync_status_notifier.dart';
import '../local_db/schemas/expense_category_schema.dart';
import '../local_db/schemas/expense_schema.dart';
import '../repositories/expense_category_repository.dart';
import '../repositories/expense_repository.dart';

class ExpenseState {
  final List<ExpenseSchema> expenses;
  final List<ExpenseCategorySchema> categories;
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
    List<ExpenseSchema>? expenses,
    List<ExpenseCategorySchema>? categories,
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
  final SyncStatusNotifier _syncStatus;

  ExpenseNotifier(this._expenseRepo, this._catRepo, this._syncStatus)
    : super(ExpenseState.initial()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
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
        errorMessage: e.toString().replaceAll('Exception: ', ''),
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
      await loadAll();
      _syncStatus.refreshPending();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      await _expenseRepo.delete(id);
      await loadAll();
      _syncStatus.refreshPending();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createExpenseCategory(String name, String icon) async {
    try {
      await _catRepo.create(name, icon);
      await loadAll();
      _syncStatus.refreshPending();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteExpenseCategory(String id) async {
    try {
      await _catRepo.delete(id);
      await loadAll();
      _syncStatus.refreshPending();
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
  final syncStatus = ref.watch(syncStatusProvider.notifier);
  return ExpenseNotifier(expenseRepo, catRepo, syncStatus);
});
