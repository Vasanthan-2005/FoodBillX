import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../local_db/isar_database.dart';
import '../local_db/schemas/menu_item_schema.dart';
import '../local_db/schemas/sync_enums.dart';
import '../local_db/schemas/sync_operation_schema.dart';
import '../models/menu_item_model.dart';

/// Repository for menu items.
class MenuItemRepository {
  final Isar _isar;

  MenuItemRepository(this._isar);

  // ── Read ──────────────────────────────────────────────────────

  /// Returns menu items filtered by optional criteria.
  Future<List<MenuItemModel>> getAll({
    String? categoryServerId,
    String? search,
    bool? isVeg,
  }) async {
    var query = _isar.menuItemSchemas.where().sortBySortOrder();

    // Isar QueryBuilder requires chaining filters before the final findAll.
    final all = await query.findAll();

    // Apply filters in-memory for simplicity (Isar compound filters are verbose).
    var results = all;
    if (categoryServerId != null && categoryServerId.isNotEmpty) {
      results = results
          .where((i) => i.categoryServerId == categoryServerId)
          .toList();
    }
    if (search != null && search.isNotEmpty) {
      final lower = search.toLowerCase();
      results = results
          .where((i) => i.name.toLowerCase().contains(lower))
          .toList();
    }
    if (isVeg != null) {
      results = results.where((i) => i.isVeg == isVeg).toList();
    }

    return results.map(_toModel).toList();
  }

  /// Watch all menu items reactively.
  Stream<List<MenuItemModel>> watchAll() {
    return _isar.menuItemSchemas
        .where()
        .sortBySortOrder()
        .watch(fireImmediately: true)
        .map((list) => list.map(_toModel).toList());
  }

  // ── Write ─────────────────────────────────────────────────────

  Future<MenuItemModel> create(MenuItemModel item) async {
    final now = DateTime.now();
    final schema = MenuItemSchema()
      ..categoryServerId = item.categoryId
      ..categoryName = item.categoryName
      ..name = item.name
      ..description = item.description
      ..price = item.price
      ..discount = item.discount
      ..gstPercentage = item.gstPercentage
      ..image = item.image
      ..isVeg = item.isVeg
      ..isAvailable = item.isAvailable
      ..sortOrder = 0
      ..syncStatus = SyncStatus.pending
      ..updatedAt = now
      ..createdAt = now;

    await _isar.writeTxn(() async {
      await _isar.menuItemSchemas.put(schema);

      final op = SyncOperationSchema()
        ..entityType = SyncEntityType.menuItem
        ..operationType = SyncOperationType.create
        ..localId = schema.id
        ..payload = jsonEncode(item.toJson())
        ..createdAt = now
        ..retryCount = 0;
      await _isar.syncOperationSchemas.put(op);
    });

    return _toModel(schema);
  }

  Future<MenuItemModel> update(MenuItemModel item) async {
    final schema = await _findByIdOrServerId(item.id);
    if (schema == null) throw Exception('Menu item not found');

    final now = DateTime.now();
    schema
      ..categoryServerId = item.categoryId
      ..categoryName = item.categoryName
      ..name = item.name
      ..description = item.description
      ..price = item.price
      ..discount = item.discount
      ..gstPercentage = item.gstPercentage
      ..image = item.image
      ..isVeg = item.isVeg
      ..isAvailable = item.isAvailable
      ..syncStatus = SyncStatus.pending
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.menuItemSchemas.put(schema);

      final op = SyncOperationSchema()
        ..entityType = SyncEntityType.menuItem
        ..operationType = SyncOperationType.update
        ..localId = schema.id
        ..serverId = schema.serverId
        ..payload = jsonEncode(item.toJson())
        ..createdAt = now
        ..retryCount = 0;
      await _isar.syncOperationSchemas.put(op);
    });

    return _toModel(schema);
  }

  Future<MenuItemModel?> toggleAvailability(String itemIdOrServerId) async {
    final schema = await _findByIdOrServerId(itemIdOrServerId);
    if (schema == null) return null;

    final now = DateTime.now();
    schema
      ..isAvailable = !schema.isAvailable
      ..syncStatus = SyncStatus.pending
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.menuItemSchemas.put(schema);

      final op = SyncOperationSchema()
        ..entityType = SyncEntityType.menuItem
        ..operationType = SyncOperationType.update
        ..localId = schema.id
        ..serverId = schema.serverId
        ..payload = jsonEncode({'isAvailable': schema.isAvailable})
        ..createdAt = now
        ..retryCount = 0;
      await _isar.syncOperationSchemas.put(op);
    });

    return _toModel(schema);
  }

  Future<void> delete(String itemIdOrServerId) async {
    final schema = await _findByIdOrServerId(itemIdOrServerId);
    if (schema == null) return;

    final now = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.menuItemSchemas.delete(schema.id);

      if (schema.serverId != null) {
        final op = SyncOperationSchema()
          ..entityType = SyncEntityType.menuItem
          ..operationType = SyncOperationType.delete
          ..localId = schema.id
          ..serverId = schema.serverId
          ..payload = '{}'
          ..createdAt = now
          ..retryCount = 0;
        await _isar.syncOperationSchemas.put(op);
      }
    });
  }

  // ── Helpers ───────────────────────────────────────────────────

  Future<MenuItemSchema?> _findByIdOrServerId(String idStr) async {
    final intId = int.tryParse(idStr);
    if (intId != null) {
      final byId = await _isar.menuItemSchemas.get(intId);
      if (byId != null) return byId;
    }
    return _isar.menuItemSchemas.filter().serverIdEqualTo(idStr).findFirst();
  }

  MenuItemModel _toModel(MenuItemSchema s) {
    return MenuItemModel(
      id: s.serverId ?? s.id.toString(),
      categoryId: s.categoryServerId,
      categoryName: s.categoryName,
      name: s.name,
      description: s.description,
      price: s.price,
      discount: s.discount,
      gstPercentage: s.gstPercentage,
      image: s.image,
      isVeg: s.isVeg,
      isAvailable: s.isAvailable,
    );
  }
}

final menuItemRepositoryProvider = Provider<MenuItemRepository>((ref) {
  return MenuItemRepository(ref.watch(isarProvider));
});
