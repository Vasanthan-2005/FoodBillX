import 'package:isar/isar.dart';
import 'sync_enums.dart';

part 'customer_schema.g.dart';

/// Local Isar representation of a loyalty customer.
@Collection()
class CustomerSchema {
  Id id = Isar.autoIncrement;

  /// MongoDB `_id` — null until synced.
  @Index(unique: true, replace: true)
  String? serverId;

  late String name;

  @Index(unique: true)
  late String phone;

  late String email;
  late String address;
  DateTime? birthday;
  late String notes;
  late int totalVisits;
  late double totalSpent;
  late int loyaltyPoints;

  @Index()
  late String loyaltyCardNumber;

  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;

  late DateTime updatedAt;
  late DateTime createdAt;
}
