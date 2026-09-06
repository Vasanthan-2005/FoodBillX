import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/local_database.dart';
import '../models/menu_item_model.dart';

class MenuItemRepository {
  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<List<MenuItemModel>> getAll({
    String? categoryServerId,
    String? search,
    bool? isVeg,
  }) async {
    return await _localDb.getMenuItems(
      categoryId: categoryServerId,
      search: search,
      isVeg: isVeg,
    );
  }

  Future<MenuItemModel> create(MenuItemModel item) async {
    _validate(item);
    return await _localDb.insertMenuItem(item);
  }

  Future<MenuItemModel> update(MenuItemModel item) async {
    _validate(item);
    final updated = await _localDb.updateMenuItem(item);
    if (updated == null) {
      throw Exception('Menu item not found');
    }
    return updated;
  }

  Future<MenuItemModel?> toggleAvailability(String id) async {
    return await _localDb.toggleMenuItemAvailability(id);
  }

  Future<void> delete(String id) async {
    await _localDb.deleteMenuItem(id);
  }

  void _validate(MenuItemModel item) {
    if (item.name.trim().isEmpty) throw ArgumentError('Item name is required');
    if (item.categoryId.isEmpty) throw ArgumentError('Category is required');
    if (!item.price.isFinite || item.price < 0) {
      throw ArgumentError('Price must be a valid non-negative number');
    }
    if (!item.discount.isFinite ||
        item.discount < 0 ||
        item.discount > item.price) {
      throw ArgumentError('Discount must be between zero and the item price');
    }
    if (!item.gstPercentage.isFinite ||
        item.gstPercentage < 0 ||
        item.gstPercentage > 100) {
      throw ArgumentError('GST must be between 0 and 100');
    }
  }
}

final menuItemRepositoryProvider = Provider<MenuItemRepository>((ref) {
  return MenuItemRepository();
});
