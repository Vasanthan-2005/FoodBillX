import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/local_database.dart';
import '../models/expense_category_model.dart';

class ExpenseCategoryRepository {
  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<List<ExpenseCategoryModel>> getAll() async {
    return await _localDb.getExpenseCategories();
  }

  Future<ExpenseCategoryModel> create(String name, String icon) async {
    return await _localDb.insertExpenseCategory(name, icon);
  }

  Future<void> delete(String id) async {
    await _localDb.deleteExpenseCategory(id);
  }
}

final expenseCategoryRepositoryProvider = Provider<ExpenseCategoryRepository>((ref) {
  return ExpenseCategoryRepository();
});
