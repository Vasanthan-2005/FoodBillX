import 'package:isar/isar.dart';
import 'sync_enums.dart';

part 'menu_item_schema.g.dart';

/// Local Isar representation of a menu item.
/// [categoryServerId] links to [CategorySchema.serverId] for backend association.
/// [categoryName] is denormalized here for fast display without a second query.
@Collection()
class MenuItemSchema {
  Id id = Isar.autoIncrement;

  /// MongoDB `_id` — null until synced.
  @Index(unique: true, replace: true)
  String? serverId;

  /// Foreign key → CategorySchema.serverId (for backend queries).
  @Index()
  late String categoryServerId;

  /// Denormalized from CategorySchema for display convenience.
  String? categoryName;

  @Index()
  late String name;

  late String description;
  late double price;
  late double discount;
  late double gstPercentage;
  late String image;
  late bool isVeg;
  late bool isAvailable;
  late int sortOrder;

  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;

  late DateTime updatedAt;
  late DateTime createdAt;
}
