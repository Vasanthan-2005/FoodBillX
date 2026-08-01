import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../local_db/isar_database.dart';
import '../local_db/schemas/expense_schema.dart';
import '../local_db/schemas/sync_enums.dart';
import '../local_db/schemas/sync_operation_schema.dart';

/// Repository for expense records.
class ExpenseRepository {
  final Isar _isar;

  ExpenseRepository(this._isar);

  // ── Read ──────────────────────────────────────────────────────

  Future<List<ExpenseSchema>> getAll({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    var results = await _isar.expenseSchemas.where().sortByDateDesc().findAll();

    if (category != null && category.isNotEmpty) {
      results = results.where((e) => e.category == category).toList();
    }
    if (startDate != null) {
      results = results
          .where(
            (e) =>
                e.date.isAfter(startDate) || e.date.isAtSameMomentAs(startDate),
          )
          .toList();
    }
    if (endDate != null) {
      results = results
          .where(
            (e) => e.date.isBefore(endDate) || e.date.isAtSameMomentAs(endDate),
          )
          .toList();
    }

    return results;
  }

  Stream<List<ExpenseSchema>> watchAll() {
    return _isar.expenseSchemas.where().sortByDateDesc().watch(
      fireImmediately: true,
    );
  }

  /// Get today's total expenses for the dashboard.
  Future<double> getTodayTotal() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final expenses = await _isar.expenseSchemas
        .filter()
        .dateBetween(startOfDay, endOfDay, includeUpper: false)
        .findAll();

    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  // ── Write ─────────────────────────────────────────────────────

  Future<ExpenseSchema> create(Map<String, dynamic> data) async {
    final now = DateTime.now();
    final schema = ExpenseSchema()
      ..category = data['category'] ?? 'Miscellaneous'
      ..title = data['title'] ?? data['category'] ?? ''
      ..amount = (data['amount'] as num?)?.toDouble() ?? 0.0
      ..date = data['date'] != null
          ? (data['date'] is DateTime
                ? data['date']
                : DateTime.tryParse(data['date'].toString()) ?? now)
          : now
      ..notes = data['notes'] ?? ''
      ..syncStatus = SyncStatus.pending
      ..updatedAt = now
      ..createdAt = now;

    await _isar.writeTxn(() async {
      await _isar.expenseSchemas.put(schema);

      // Serialise date to ISO string for backend
      final payload = Map<String, dynamic>.from(data);
      if (payload['date'] is DateTime) {
        payload['date'] = (payload['date'] as DateTime).toIso8601String();
      }

      final op = SyncOperationSchema()
        ..entityType = SyncEntityType.expense
        ..operationType = SyncOperationType.create
        ..localId = schema.id
        ..payload = jsonEncode(payload)
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
      await _isar.expenseSchemas.delete(schema.id);

      if (schema.serverId != null) {
        final op = SyncOperationSchema()
          ..entityType = SyncEntityType.expense
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

  Future<ExpenseSchema?> _findByIdOrServerId(String idStr) async {
    final intId = int.tryParse(idStr);
    if (intId != null) {
      final byId = await _isar.expenseSchemas.get(intId);
      if (byId != null) return byId;
    }
    return _isar.expenseSchemas.filter().serverIdEqualTo(idStr).findFirst();
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(isarProvider));
});
