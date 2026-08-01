import 'package:isar/isar.dart';
import 'sync_enums.dart';

part 'order_schema.g.dart';

/// Embedded sub-document for a single line item within an order.
@embedded
class OrderItemEmbedded {
  /// MongoDB `_id` of the MenuItem (may be empty if item was created offline).
  String menuItemServerId = '';
  String name = '';
  double price = 0.0;
  int quantity = 1;
  double gstPercentage = 5.0;
  double subtotal = 0.0;
  String notes = '';
}

/// Local Isar representation of a completed order / bill.
@Collection()
class OrderSchema {
  Id id = Isar.autoIncrement;

  /// MongoDB `_id` — null until synced.
  @Index(unique: true, replace: true)
  String? serverId;

  /// Human-readable order number generated locally (e.g. INV-20260727-0001).
  @Index(unique: true)
  late String orderNumber;

  String? customerServerId;
  late String customerName;
  late String customerPhone;

  late List<OrderItemEmbedded> items;

  late double subtotal;
  late double discountAmount;
  late double gstAmount;
  late double grandTotal;

  /// 'cash' | 'upi' | 'card' | 'wallet'
  late String paymentMethod;

  /// 'paid' | 'pending'
  late String paymentStatus;

  late String notes;

  @Index()
  late DateTime createdAt;

  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;
}
