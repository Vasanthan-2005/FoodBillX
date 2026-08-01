import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../local_db/isar_database.dart';
import '../local_db/schemas/expense_category_schema.dart';
import '../local_db/schemas/sync_enums.dart';
import '../local_db/schemas/sync_operation_schema.dart';

/// Repository for expense categories.
class ExpenseCategoryRepository {
  final Isar _isar;

  ExpenseCategoryRepository(this._isar);

  // ── Read ──────────────────────────────────────────────────────

  Future<List<ExpenseCategorySchema>> getAll() async {
    return _isar.expenseCategorySchemas.where().findAll();
  }

  Stream<List<ExpenseCategorySchema>> watchAll() {
    return _isar.expenseCategorySchemas.where().watch(fireImmediately: true);
  }

  // ── Write ─────────────────────────────────────────────────────

  Future<ExpenseCategorySchema> create(String name, String icon) async {
    final now = DateTime.now();
    final schema = ExpenseCategorySchema()
      ..name = name
      ..icon = icon
      ..isActive = true
      ..syncStatus = SyncStatus.pending
      ..updatedAt = now
      ..createdAt = now;

    await _isar.writeTxn(() async {
      await _isar.expenseCategorySchemas.put(schema);

      final op = SyncOperationSchema()
        ..entityType = SyncEntityType.expenseCategory
        ..operationType = SyncOperationType.create
        ..localId = schema.id
        ..payload = jsonEncode({'name': name, 'icon': icon})
        ..createdAt = now
        ..retryCount = 0;
      await _isar.syncOperationSchemas.put(op);
    });

    return schema;
  }

  Future<ExpenseCategorySchema> update(
    String idOrServerId,
    String name,
    String icon,
  ) async {
    final schema = await _findByIdOrServerId(idOrServerId);
    if (schema == null) throw Exception('Expense category not found');

    final now = DateTime.now();
    schema
      ..name = name
      ..icon = icon
      ..syncStatus = SyncStatus.pending
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.expenseCategorySchemas.put(schema);

      final op = SyncOperationSchema()
        ..entityType = SyncEntityType.expenseCategory
        ..operationType = SyncOperationType.update
        ..localId = schema.id
        ..serverId = schema.serverId
        ..payload = jsonEncode({'name': name, 'icon': icon})
        ..createdAt = now
        ..retryCount = 0;
      await _isar.syncOperationSchemas.put(op);
    });

    return schema;
  }

  Future<void> delete(String idOrServerId) async {
    final schema = await _findByIdOrServerId(idOrServerId);
    if (schema == null) return;

    final now = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.expenseCategorySchemas.delete(schema.id);

      if (schema.serverId != null) {
        final op = SyncOperationSchema()
          ..entityType = SyncEntityType.expenseCategory
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

  Future<ExpenseCategorySchema?> _findByIdOrServerId(String idStr) async {
    final intId = int.tryParse(idStr);
    if (intId != null) {
      final byId = await _isar.expenseCategorySchemas.get(intId);
      if (byId != null) return byId;
    }
    return _isar.expenseCategorySchemas
        .filter()
        .serverIdEqualTo(idStr)
        .findFirst();
  }
}

final expenseCategoryRepositoryProvider = Provider<ExpenseCategoryRepository>((
  ref,
) {
  return ExpenseCategoryRepository(ref.watch(isarProvider));
});
