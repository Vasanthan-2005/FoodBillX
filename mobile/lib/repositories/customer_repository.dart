import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../local_db/isar_database.dart';
import '../local_db/schemas/customer_schema.dart';
import '../local_db/schemas/sync_enums.dart';
import '../local_db/schemas/sync_operation_schema.dart';

/// Repository for loyalty customers.
class CustomerRepository {
  final Isar _isar;

  CustomerRepository(this._isar);

  // ── Read ──────────────────────────────────────────────────────

  Future<List<CustomerSchema>> getAll({
    String? search,
    String? cardNumber,
  }) async {
    var results = await _isar.customerSchemas
        .where()
        .sortByTotalSpentDesc()
        .findAll();

    if (cardNumber != null && cardNumber.isNotEmpty) {
      results = results
          .where((c) => c.loyaltyCardNumber == cardNumber.trim())
          .toList();
    } else if (search != null && search.isNotEmpty) {
      final lower = search.toLowerCase();
      results = results.where((c) {
        return c.name.toLowerCase().contains(lower) ||
            c.phone.contains(lower) ||
            c.loyaltyCardNumber.toLowerCase().contains(lower);
      }).toList();
    }

    return results;
  }

  Stream<List<CustomerSchema>> watchAll() {
    return _isar.customerSchemas.where().sortByTotalSpentDesc().watch(
      fireImmediately: true,
    );
  }

  // ── Write ─────────────────────────────────────────────────────

  Future<CustomerSchema> create(Map<String, dynamic> data) async {
    // Check for existing phone
    final existingPhone = data['phone']?.toString().trim() ?? '';
    if (existingPhone.isNotEmpty) {
      final existing = await _isar.customerSchemas
          .filter()
          .phoneEqualTo(existingPhone)
          .findFirst();
      if (existing != null) {
        throw Exception('Customer with this phone number already exists');
      }
    }

    final now = DateTime.now();
    final schema = CustomerSchema()
      ..name = data['name'] ?? ''
      ..phone = existingPhone
      ..email = data['email'] ?? ''
      ..address = data['address'] ?? ''
      ..birthday = data['birthday'] != null
          ? DateTime.tryParse(data['birthday'])
          : null
      ..notes = data['notes'] ?? ''
      ..totalVisits = 0
      ..totalSpent = 0.0
      ..loyaltyPoints = 0
      ..loyaltyCardNumber = data['loyaltyCardNumber'] ?? ''
      ..syncStatus = SyncStatus.pending
      ..updatedAt = now
      ..createdAt = now;

    await _isar.writeTxn(() async {
      await _isar.customerSchemas.put(schema);

      final op = SyncOperationSchema()
        ..entityType = SyncEntityType.customer
        ..operationType = SyncOperationType.create
        ..localId = schema.id
        ..payload = jsonEncode(data)
        ..createdAt = now
        ..retryCount = 0;
      await _isar.syncOperationSchemas.put(op);
    });

    return schema;
  }

  Future<CustomerSchema> update(
    String idOrServerId,
    Map<String, dynamic> data,
  ) async {
    final schema = await _findByIdOrServerId(idOrServerId);
    if (schema == null) throw Exception('Customer not found');

    // Phone collision check
    if (data.containsKey('phone')) {
      final newPhone = data['phone']?.toString().trim() ?? '';
      if (newPhone.isNotEmpty && newPhone != schema.phone) {
        final conflict = await _isar.customerSchemas
            .filter()
            .phoneEqualTo(newPhone)
            .findFirst();
        if (conflict != null && conflict.id != schema.id) {
          throw Exception(
            'Another customer with this phone number already exists',
          );
        }
      }
    }

    final now = DateTime.now();
    if (data.containsKey('name')) schema.name = data['name'];
    if (data.containsKey('phone')) {
      schema.phone = data['phone']?.toString().trim() ?? schema.phone;
    }
    if (data.containsKey('email')) schema.email = data['email'] ?? '';
    if (data.containsKey('address')) schema.address = data['address'] ?? '';
    if (data.containsKey('notes')) schema.notes = data['notes'] ?? '';
    if (data.containsKey('loyaltyCardNumber')) {
      schema.loyaltyCardNumber = data['loyaltyCardNumber'] ?? '';
    }
    schema
      ..syncStatus = SyncStatus.pending
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.customerSchemas.put(schema);

      final op = SyncOperationSchema()
        ..entityType = SyncEntityType.customer
        ..operationType = SyncOperationType.update
        ..localId = schema.id
        ..serverId = schema.serverId
        ..payload = jsonEncode(data)
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
      await _isar.customerSchemas.delete(schema.id);

      if (schema.serverId != null) {
        final op = SyncOperationSchema()
          ..entityType = SyncEntityType.customer
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

  Future<CustomerSchema?> assignLoyaltyCard(
    String idOrServerId,
    String cardNumber,
  ) async {
    final schema = await _findByIdOrServerId(idOrServerId);
    if (schema == null) throw Exception('Customer not found');

    // Check card uniqueness
    final trimmed = cardNumber.trim();
    if (trimmed.isNotEmpty) {
      final existing = await _isar.customerSchemas
          .filter()
          .loyaltyCardNumberEqualTo(trimmed)
          .and()
          .not()
          .idEqualTo(schema.id)
          .findFirst();
      if (existing != null) {
        throw Exception(
          'Loyalty Card #$trimmed is already assigned to another customer',
        );
      }
    }

    return update(idOrServerId, {'loyaltyCardNumber': trimmed});
  }

  /// Increment visit stats after an order (called locally by billing).
  Future<void> recordVisit(String idOrServerId, double orderTotal) async {
    final schema = await _findByIdOrServerId(idOrServerId);
    if (schema == null) return;

    schema
      ..totalVisits += 1
      ..totalSpent += orderTotal
      ..loyaltyPoints += (orderTotal ~/ 100) * 10
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() => _isar.customerSchemas.put(schema));
  }

  // ── Helpers ───────────────────────────────────────────────────

  Future<CustomerSchema?> _findByIdOrServerId(String idStr) async {
    final intId = int.tryParse(idStr);
    if (intId != null) {
      final byId = await _isar.customerSchemas.get(intId);
      if (byId != null) return byId;
    }
    return _isar.customerSchemas.filter().serverIdEqualTo(idStr).findFirst();
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(isarProvider));
});
