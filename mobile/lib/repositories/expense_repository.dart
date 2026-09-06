import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/local_database.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<List<ExpenseModel>> getAll({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    return await _localDb.getExpenses(
      category: category,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<ExpenseModel> create(Map<String, dynamic> data) async {
    return await _localDb.insertExpense(data);
  }

  Future<ExpenseModel> update(String id, Map<String, dynamic> data) async {
    final updated = await _localDb.updateExpense(id, data);
    if (updated == null) {
      throw Exception('Expense not found');
    }
    return updated;
  }

  Future<void> delete(String id) async {
    await _localDb.deleteExpense(id);
  }

  Future<double> getTodayTotal() async {
    return await _localDb.getTodayExpenseTotal();
  }

  Future<double> getMonthlyTotal(DateTime monthDate) async {
    return await _localDb.getMonthlyExpenseTotal(monthDate);
  }

  Future<double> getMonthlyBudget(String monthKey) async {
    return await _localDb.getMonthlyBudget(monthKey);
  }

  Future<void> setMonthlyBudget(String monthKey, double amount) async {
    await _localDb.setMonthlyBudget(monthKey, amount);
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});
