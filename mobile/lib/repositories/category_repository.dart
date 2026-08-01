import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../local_db/isar_database.dart';
import '../local_db/schemas/category_schema.dart';
import '../local_db/schemas/sync_enums.dart';
import '../local_db/schemas/sync_operation_schema.dart';
import '../models/category_model.dart';

/// Repository for menu categories.
/// All reads come from Isar. All writes go to Isar first, then queue a sync operation.
class CategoryRepository {
  final Isar _isar;

  CategoryRepository(this._isar);

  // ── Read ──────────────────────────────────────────────────────

  /// Returns all active categories from the local database.
  Future<List<CategoryModel>> getAll() async {
    final schemas = await _isar.categorySchemas
        .where()
        .sortBySortOrder()
        .findAll();
    return schemas.map(_toModel).toList();
  }

  /// Watch all categories reactively (emits on any change).
  Stream<List<CategoryModel>> watchAll() {
    return _isar.categorySchemas
        .where()
        .sortBySortOrder()
        .watch(fireImmediately: true)
        .map((list) => list.map(_toModel).toList());
  }

  // ── Write ─────────────────────────────────────────────────────

  Future<CategoryModel> create(String name, String icon) async {
    final now = DateTime.now();
    final schema = CategorySchema()
      ..name = name
      ..icon = icon
      ..sortOrder = 0
      ..isActive = true
      ..syncStatus = SyncStatus.pending
      ..updatedAt = now
      ..createdAt = now;

    await _isar.writeTxn(() async {
      await _isar.categorySchemas.put(schema);

      // Queue sync operation
      final op = SyncOperationSchema()
        ..entityType = SyncEntityType.category
        ..operationType = SyncOperationType.create
        ..localId = schema.id
        ..payload = jsonEncode({'name': name, 'icon': icon})
        ..createdAt = now
        ..retryCount = 0;
      await _isar.syncOperationSchemas.put(op);
    });

    return _toModel(schema);
  }

  Future<CategoryModel> update(
    String localIdOrServerId,
    String name,
    String icon,
  ) async {
    final schema = await _findByIdOrServerId(localIdOrServerId);
    if (schema == null) throw Exception('Category not found');

    final now = DateTime.now();
    schema
      ..name = name
      ..icon = icon
      ..syncStatus = SyncStatus.pending
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.categorySchemas.put(schema);

      final op = SyncOperationSchema()
        ..entityType = SyncEntityType.category
        ..operationType = SyncOperationType.update
        ..localId = schema.id
        ..serverId = schema.serverId
        ..payload = jsonEncode({'name': name, 'icon': icon})
        ..createdAt = now
        ..retryCount = 0;
      await _isar.syncOperationSchemas.put(op);
    });

    return _toModel(schema);
  }

  Future<void> delete(String localIdOrServerId) async {
    final schema = await _findByIdOrServerId(localIdOrServerId);
    if (schema == null) return;

    final now = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.categorySchemas.delete(schema.id);

      if (schema.serverId != null) {
        final op = SyncOperationSchema()
          ..entityType = SyncEntityType.category
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

  Future<CategorySchema?> _findByIdOrServerId(String idStr) async {
    // Try as Isar int ID first
    final intId = int.tryParse(idStr);
    if (intId != null) {
      final byId = await _isar.categorySchemas.get(intId);
      if (byId != null) return byId;
    }
    // Try as serverId (MongoDB ObjectId)
    return _isar.categorySchemas.filter().serverIdEqualTo(idStr).findFirst();
  }

  CategoryModel _toModel(CategorySchema s) {
    return CategoryModel(
      // Use serverId if available; fall back to isar id string.
      id: s.serverId ?? s.id.toString(),
      name: s.name,
      icon: s.icon,
      sortOrder: s.sortOrder,
      isActive: s.isActive,
    );
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(isarProvider));
});
