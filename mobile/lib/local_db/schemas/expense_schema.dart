import 'package:isar/isar.dart';
import 'sync_enums.dart';

part 'expense_schema.g.dart';

/// Local Isar representation of an expense record.
@Collection()
class ExpenseSchema {
  Id id = Isar.autoIncrement;

  /// MongoDB `_id` — null until synced.
  @Index(unique: true, replace: true)
  String? serverId;

  /// Free-text category name (mirrors ExpenseCategory.name).
  @Index()
  late String category;

  late String title;
  late double amount;

  @Index()
  late DateTime date;

  late String notes;

  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;

  late DateTime updatedAt;
  late DateTime createdAt;
}
