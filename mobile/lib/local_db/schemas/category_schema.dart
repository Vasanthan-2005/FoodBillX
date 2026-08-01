import 'package:isar/isar.dart';
import 'sync_enums.dart';

part 'category_schema.g.dart';

/// Local Isar representation of a menu category.
/// [serverId] is the MongoDB ObjectId assigned after the record syncs.
@Collection()
class CategorySchema {
  Id id = Isar.autoIncrement;

  /// MongoDB `_id` — null until this record has been synced.
  @Index(unique: true, replace: true)
  String? serverId;

  @Index()
  late String name;

  late String icon;
  late int sortOrder;
  late bool isActive;

  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;

  late DateTime updatedAt;
  late DateTime createdAt;
}
