import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'schemas/business_settings_schema.dart';
import 'schemas/category_schema.dart';
import 'schemas/customer_schema.dart';
import 'schemas/expense_category_schema.dart';
import 'schemas/expense_schema.dart';
import 'schemas/menu_item_schema.dart';
import 'schemas/order_schema.dart';
import 'schemas/sync_operation_schema.dart';

/// Singleton wrapper around the Isar database instance.
///
/// Call [IsarDatabase.initialize] once in `main.dart` before `runApp`.
/// Afterward, access the instance via the Riverpod [isarProvider].
class IsarDatabase {
  static Isar? _instance;

  /// Opens (or returns the existing) Isar database.
  static Future<Isar> initialize() async {
    if (_instance != null && _instance!.isOpen) return _instance!;

    final dir = await getApplicationDocumentsDirectory();

    _instance = await Isar.open(
      [
        CategorySchemaSchema,
        MenuItemSchemaSchema,
        OrderSchemaSchema,
        CustomerSchemaSchema,
        ExpenseSchemaSchema,
        ExpenseCategorySchemaSchema,
        BusinessSettingsSchemaSchema,
        SyncOperationSchemaSchema,
      ],
      directory: dir.path,
      name: 'foodbillx',
    );

    return _instance!;
  }

  /// Returns the currently open Isar instance.
  /// Throws if [initialize] has not been called.
  static Isar get instance {
    assert(_instance != null, 'IsarDatabase.initialize() must be called first');
    return _instance!;
  }
}

/// Riverpod provider for the Isar instance.
/// Override this in `ProviderScope` after calling [IsarDatabase.initialize].
final isarProvider = Provider<Isar>((ref) {
  return IsarDatabase.instance;
});
