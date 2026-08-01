import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../local_db/isar_database.dart';
import '../local_db/schemas/order_schema.dart';
import '../local_db/schemas/sync_enums.dart';
import '../local_db/schemas/sync_operation_schema.dart';

/// Repository for orders.
/// Orders are always created locally first and synced later.
class OrderRepository {
  final Isar _isar;

  OrderRepository(this._isar);

  // ── Read ──────────────────────────────────────────────────────

  /// Returns orders sorted by creation date (newest first).
  Future<List<OrderSchema>> getAll({
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
    int limit = 50,
    int offset = 0,
  }) async {
    var results = await _isar.orderSchemas
        .where()
        .sortByCreatedAtDesc()
        .findAll();

    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      results = results.where((o) => o.paymentMethod == paymentMethod).toList();
    }
    if (startDate != null) {
      results = results
          .where(
            (o) =>
                o.createdAt.isAfter(startDate) ||
                o.createdAt.isAtSameMomentAs(startDate),
          )
          .toList();
    }
    if (endDate != null) {
      results = results
          .where(
            (o) =>
                o.createdAt.isBefore(endDate) ||
                o.createdAt.isAtSameMomentAs(endDate),
          )
          .toList();
    }

    // Pagination
    if (offset > 0 && offset < results.length) {
      results = results.sublist(offset);
    }
    if (results.length > limit) {
      results = results.sublist(0, limit);
    }

    return results;
  }

  /// Get total count of orders matching a filter.
  Future<int> count({DateTime? startDate, DateTime? endDate}) async {
    final all = await getAll(
      startDate: startDate,
      endDate: endDate,
      limit: 999999,
    );
    return all.length;
  }

  /// Watch all orders reactively.
  Stream<List<OrderSchema>> watchAll() {
    return _isar.orderSchemas.where().sortByCreatedAtDesc().watch(
      fireImmediately: true,
    );
  }

  /// Get today's orders for dashboard calculations.
  Future<List<OrderSchema>> getTodayOrders() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _isar.orderSchemas
        .filter()
        .createdAtBetween(startOfDay, endOfDay, includeUpper: false)
        .findAll();
  }

  /// Get this month's orders for dashboard.
  Future<List<OrderSchema>> getMonthOrders() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    return _isar.orderSchemas
        .filter()
        .createdAtBetween(startOfMonth, endOfDay, includeUpper: false)
        .findAll();
  }

  // ── Write ─────────────────────────────────────────────────────

  /// Create an order locally and enqueue it for sync.
  /// Returns the created [OrderSchema] (with local ID and orderNumber).
  Future<OrderSchema> create({
    required String orderNumber,
    String? customerServerId,
    required String customerName,
    required String customerPhone,
    required List<OrderItemEmbedded> items,
    required double subtotal,
    required double discountAmount,
    required double gstAmount,
    required double grandTotal,
    required String paymentMethod,
    String notes = '',
  }) async {
    final now = DateTime.now();

    final schema = OrderSchema()
      ..orderNumber = orderNumber
      ..customerServerId = customerServerId
      ..customerName = customerName
      ..customerPhone = customerPhone
      ..items = items
      ..subtotal = subtotal
      ..discountAmount = discountAmount
      ..gstAmount = gstAmount
      ..grandTotal = grandTotal
      ..paymentMethod = paymentMethod
      ..paymentStatus = 'paid'
      ..notes = notes
      ..createdAt = now
      ..syncStatus = SyncStatus.pending;

    await _isar.writeTxn(() async {
      await _isar.orderSchemas.put(schema);

      // Build payload for backend
      final payload = {
        'orderNumber': orderNumber,
        'customerId': customerServerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'paymentMethod': paymentMethod,
        'discountAmount': discountAmount,
        'items': items
            .map(
              (i) => {
                'menuItem': i.menuItemServerId,
                'name': i.name,
                'price': i.price,
                'quantity': i.quantity,
                'gstPercentage': i.gstPercentage,
                'notes': i.notes,
              },
            )
            .toList(),
      };

      final op = SyncOperationSchema()
        ..entityType = SyncEntityType.order
        ..operationType = SyncOperationType.create
        ..localId = schema.id
        ..payload = jsonEncode(payload)
        ..createdAt = now
        ..retryCount = 0;
      await _isar.syncOperationSchemas.put(op);
    });

    return schema;
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(isarProvider));
});
