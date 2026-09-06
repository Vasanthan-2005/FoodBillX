import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/local_database.dart';
import '../models/order_model.dart';

class OrderRepository {
  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<List<OrderModel>> getAll({
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
    String? status,
    int limit = 100,
    int offset = 0,
  }) async {
    return await _localDb.getOrders(
      startDate: startDate,
      endDate: endDate,
      paymentMethod: paymentMethod,
      status: status,
      limit: limit,
      offset: offset,
    );
  }

  Future<OrderModel> create({
    String? orderNumber,
    String? customerServerId,
    required String customerName,
    required String customerPhone,
    String loyaltyCardNumber = '',
    required List<OrderItemModel> items,
    required double subtotal,
    required double discountAmount,
    required double gstAmount,
    required double serviceChargeAmount,
    required double grandTotal,
    required String paymentMethod,
    String notes = '',
  }) async {
    return await _localDb.insertOrder(
      orderNumber: orderNumber,
      customerId: customerServerId,
      customerName: customerName,
      customerPhone: customerPhone,
      loyaltyCardNumber: loyaltyCardNumber,
      items: items,
      subtotal: subtotal,
      discountAmount: discountAmount,
      gstAmount: gstAmount,
      serviceChargeAmount: serviceChargeAmount,
      grandTotal: grandTotal,
      paymentMethod: paymentMethod,
      notes: notes,
    );
  }

  Future<OrderModel> refund(String orderId) async {
    final refunded = await _localDb.refundOrder(orderId);
    if (refunded == null) {
      throw Exception('Order not found');
    }
    return refunded;
  }

  Future<void> delete(String orderId) async {
    final db = await _localDb.database;
    await db.update(
      'orders',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'sync_status': 'pendingDelete',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<List<OrderModel>> getBetween(DateTime start, DateTime end) async {
    return getAll(startDate: start, endDate: end, limit: 1000);
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});
