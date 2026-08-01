import 'package:isar/isar.dart';
import 'sync_enums.dart';

part 'business_settings_schema.g.dart';

/// Local Isar representation of the business settings document.
/// There is only ever one record (singleton). We use a fixed [isarId] of 1.
@Collection()
class BusinessSettingsSchema {
  Id id = 1; // Singleton: always ID 1.

  /// MongoDB `_id` — null until synced.
  String? serverId;

  late String businessName;
  late String logo;
  late String phone;
  late String address;
  late String gstin;
  late String currency;
  late String invoicePrefix;
  late double taxPercentage;
  late double serviceChargePercentage;
  late String invoiceFooter;

  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;

  late DateTime updatedAt;
}
