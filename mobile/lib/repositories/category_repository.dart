import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/local_database.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<List<CategoryModel>> getAll() async {
    return await _localDb.getMenuCategories();
  }

  Future<CategoryModel> create(String name, String icon) async {
    return await _localDb.insertMenuCategory(name, icon);
  }

  Future<CategoryModel> update(String id, String name, String icon) async {
    final updated = await _localDb.updateMenuCategory(id, name, icon);
    if (updated == null) {
      throw Exception('Category not found');
    }
    return updated;
  }

  Future<void> delete(String id) async {
    await _localDb.deleteMenuCategory(id);
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});
