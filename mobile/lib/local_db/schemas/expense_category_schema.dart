import 'package:isar/isar.dart';
import 'sync_enums.dart';

part 'expense_category_schema.g.dart';

/// Local Isar representation of an expense category.
@Collection()
class ExpenseCategorySchema {
  Id id = Isar.autoIncrement;

  /// MongoDB `_id` — null until synced.
  @Index(unique: true, replace: true)
  String? serverId;

  @Index(unique: true)
  late String name;

  late String icon;
  late bool isActive;

  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;

  late DateTime updatedAt;
  late DateTime createdAt;
}
