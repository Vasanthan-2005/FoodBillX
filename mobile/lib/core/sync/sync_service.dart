import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../api/api_client.dart';
import '../../local_db/isar_database.dart';
import '../../local_db/schemas/business_settings_schema.dart';
import '../../local_db/schemas/category_schema.dart';
import '../../local_db/schemas/customer_schema.dart';
import '../../local_db/schemas/expense_category_schema.dart';
import '../../local_db/schemas/expense_schema.dart';
import '../../local_db/schemas/menu_item_schema.dart';
import '../../local_db/schemas/order_schema.dart';
import '../../local_db/schemas/sync_enums.dart';
import '../../local_db/schemas/sync_operation_schema.dart';
import 'connectivity_service.dart';
import 'sync_status_notifier.dart';

/// Background sync engine that:
/// 1. **Seeds** the local database on first launch (pull all from backend).
/// 2. **Pushes** pending outbox operations to the backend.
/// 3. **Pulls** updated records from the backend since last sync.
///
/// Triggered automatically when connectivity changes from offline → online,
/// and can be triggered manually via [syncNow].
class SyncService {
  final Isar _isar;
  final ApiClient _apiClient;
  final SyncStatusNotifier _statusNotifier;
  bool _isSyncing = false;

  SyncService(this._isar, this._apiClient, this._statusNotifier);

  /// Returns `true` if the local database is empty (first launch).
  Future<bool> get _isFirstLaunch async {
    final catCount = await _isar.categorySchemas.count();
    final itemCount = await _isar.menuItemSchemas.count();
    final settingsExists = await _isar.businessSettingsSchemas.get(1) != null;
    return catCount == 0 && itemCount == 0 && !settingsExists;
  }

  // ──────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────

  /// Run a full sync cycle: seed (if needed) → push → pull.
  Future<void> syncNow() async {
    if (_isSyncing) return; // Prevent concurrent runs
    _isSyncing = true;
    _statusNotifier.markSyncing();

    try {
      // On first launch, pull everything.
      if (await _isFirstLaunch) {
        await _seedFromBackend();
      }

      // Push pending local changes to backend.
      await _pushOutbox();

      // Pull latest changes from backend.
      await _pullFromBackend();

      _statusNotifier.markSyncComplete();
    } catch (e) {
      _statusNotifier.markSyncFailed(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // SEED — First launch: pull everything from the backend
  // ──────────────────────────────────────────────────────────────

  Future<void> _seedFromBackend() async {
    try {
      await _seedSettings();
      await _seedCategories();
      await _seedMenuItems();
      await _seedCustomers();
      await _seedExpenseCategories();
      await _seedExpenses();
      await _seedOrders();
    } catch (e) {
      // Seeding failure is non-fatal; app works with empty local DB.
      // ignore and continue
    }
  }

  Future<void> _seedSettings() async {
    final res = await _apiClient.dio.get('/settings');
    final data = res.data['data']['settings'];
    if (data == null) return;

    final s = BusinessSettingsSchema()
      ..serverId = data['_id'] ?? data['id']
      ..businessName = data['businessName'] ?? 'My Food Outlet'
      ..logo = data['logo'] ?? ''
      ..phone = data['phone'] ?? ''
      ..address = data['address'] ?? ''
      ..gstin = data['gstin'] ?? ''
      ..currency = data['currency'] ?? '₹'
      ..invoicePrefix = data['invoicePrefix'] ?? 'INV-'
      ..taxPercentage = (data['taxPercentage'] as num?)?.toDouble() ?? 5.0
      ..serviceChargePercentage =
          (data['serviceChargePercentage'] as num?)?.toDouble() ?? 0.0
      ..invoiceFooter = data['invoiceFooter'] ?? 'Thank you for dining with us!'
      ..syncStatus = SyncStatus.synced
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() => _isar.businessSettingsSchemas.put(s));
  }

  Future<void> _seedCategories() async {
    final res = await _apiClient.dio.get('/categories');
    final List catList = res.data['data']['categories'] ?? [];

    final schemas = catList.map((j) {
      return CategorySchema()
        ..serverId = j['_id'] ?? j['id']
        ..name = j['name'] ?? ''
        ..icon = j['icon'] ?? 'fastfood'
        ..sortOrder = j['sortOrder'] ?? 0
        ..isActive = j['isActive'] ?? true
        ..syncStatus = SyncStatus.synced
        ..updatedAt = DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now()
        ..createdAt = DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now();
    }).toList();

    await _isar.writeTxn(() => _isar.categorySchemas.putAll(schemas));
  }

  Future<void> _seedMenuItems() async {
    final res = await _apiClient.dio.get('/menu-items');
    final List list = res.data['data'] ?? [];

    final schemas = list.map((j) {
      String catId = '';
      String? catName;
      if (j['category'] is Map) {
        catId = j['category']['_id'] ?? j['category']['id'] ?? '';
        catName = j['category']['name'];
      } else if (j['category'] is String) {
        catId = j['category'];
      }

      return MenuItemSchema()
        ..serverId = j['_id'] ?? j['id']
        ..categoryServerId = catId
        ..categoryName = catName
        ..name = j['name'] ?? ''
        ..description = j['description'] ?? ''
        ..price = (j['price'] as num?)?.toDouble() ?? 0.0
        ..discount = (j['discount'] as num?)?.toDouble() ?? 0.0
        ..gstPercentage = (j['gstPercentage'] as num?)?.toDouble() ?? 5.0
        ..image = j['image'] ?? ''
        ..isVeg = j['isVeg'] ?? true
        ..isAvailable = j['isAvailable'] ?? true
        ..sortOrder = j['sortOrder'] ?? 0
        ..syncStatus = SyncStatus.synced
        ..updatedAt = DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now()
        ..createdAt = DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now();
    }).toList();

    await _isar.writeTxn(() => _isar.menuItemSchemas.putAll(schemas));
  }

  Future<void> _seedCustomers() async {
    final res = await _apiClient.dio.get('/customers');
    final List list = res.data['data'] ?? [];

    final schemas = list.map((j) {
      return CustomerSchema()
        ..serverId = j['_id'] ?? j['id']
        ..name = j['name'] ?? ''
        ..phone = j['phone'] ?? ''
        ..email = j['email'] ?? ''
        ..address = j['address'] ?? ''
        ..birthday = j['birthday'] != null
            ? DateTime.tryParse(j['birthday'])
            : null
        ..notes = j['notes'] ?? ''
        ..totalVisits = j['totalVisits'] ?? 0
        ..totalSpent = (j['totalSpent'] as num?)?.toDouble() ?? 0.0
        ..loyaltyPoints = j['loyaltyPoints'] ?? 0
        ..loyaltyCardNumber = j['loyaltyCardNumber'] ?? ''
        ..syncStatus = SyncStatus.synced
        ..updatedAt = DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now()
        ..createdAt = DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now();
    }).toList();

    await _isar.writeTxn(() => _isar.customerSchemas.putAll(schemas));
  }

  Future<void> _seedExpenseCategories() async {
    final res = await _apiClient.dio.get('/expense-categories');
    final List list = res.data['data'] ?? [];

    final schemas = list.map((j) {
      return ExpenseCategorySchema()
        ..serverId = j['_id'] ?? j['id']
        ..name = j['name'] ?? ''
        ..icon = j['icon'] ?? 'attach_money'
        ..isActive = j['isActive'] ?? true
        ..syncStatus = SyncStatus.synced
        ..updatedAt = DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now()
        ..createdAt = DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now();
    }).toList();

    await _isar.writeTxn(() => _isar.expenseCategorySchemas.putAll(schemas));
  }

  Future<void> _seedExpenses() async {
    final res = await _apiClient.dio.get('/expenses');
    final List list = res.data['data'] ?? [];

    final schemas = list.map((j) {
      return ExpenseSchema()
        ..serverId = j['_id'] ?? j['id']
        ..category = j['category'] ?? 'Miscellaneous'
        ..title = j['title'] ?? ''
        ..amount = (j['amount'] as num?)?.toDouble() ?? 0.0
        ..date = DateTime.tryParse(j['date'] ?? '') ?? DateTime.now()
        ..notes = j['notes'] ?? ''
        ..syncStatus = SyncStatus.synced
        ..updatedAt = DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now()
        ..createdAt = DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now();
    }).toList();

    await _isar.writeTxn(() => _isar.expenseSchemas.putAll(schemas));
  }

  Future<void> _seedOrders() async {
    final res = await _apiClient.dio.get('/orders');
    final List list = res.data['data'] ?? [];

    final schemas = list.map((j) {
      final items = (j['items'] as List? ?? []).map((i) {
        return OrderItemEmbedded()
          ..menuItemServerId =
              (i['menuItem'] is Map ? i['menuItem']['_id'] : i['menuItem']) ??
              ''
          ..name = i['name'] ?? ''
          ..price = (i['price'] as num?)?.toDouble() ?? 0.0
          ..quantity = i['quantity'] ?? 1
          ..gstPercentage = (i['gstPercentage'] as num?)?.toDouble() ?? 5.0
          ..subtotal = (i['subtotal'] as num?)?.toDouble() ?? 0.0
          ..notes = i['notes'] ?? '';
      }).toList();

      return OrderSchema()
        ..serverId = j['_id'] ?? j['id']
        ..orderNumber = j['orderNumber'] ?? ''
        ..customerServerId = j['customer']
        ..customerName = j['customerName'] ?? 'Walk-in Customer'
        ..customerPhone = j['customerPhone'] ?? ''
        ..items = items
        ..subtotal = (j['subtotal'] as num?)?.toDouble() ?? 0.0
        ..discountAmount = (j['discountAmount'] as num?)?.toDouble() ?? 0.0
        ..gstAmount = (j['gstAmount'] as num?)?.toDouble() ?? 0.0
        ..grandTotal = (j['grandTotal'] as num?)?.toDouble() ?? 0.0
        ..paymentMethod = j['paymentMethod'] ?? 'cash'
        ..paymentStatus = j['paymentStatus'] ?? 'paid'
        ..notes = j['notes'] ?? ''
        ..createdAt = DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now()
        ..syncStatus = SyncStatus.synced;
    }).toList();

    await _isar.writeTxn(() => _isar.orderSchemas.putAll(schemas));
  }

  // ──────────────────────────────────────────────────────────────
  // PUSH — Process the outbox queue
  // ──────────────────────────────────────────────────────────────

  Future<void> _pushOutbox() async {
    final ops = await _isar.syncOperationSchemas
        .filter()
        .retryCountLessThan(5)
        .sortByCreatedAt()
        .findAll();

    for (final op in ops) {
      try {
        await _pushSingleOperation(op);
        // Remove from queue on success.
        await _isar.writeTxn(() => _isar.syncOperationSchemas.delete(op.id));
      } on DioException catch (e) {
        // On 4xx (client error other than 404), mark as failed but don't retry.
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode >= 400 && statusCode < 500 && statusCode != 404) {
          await _isar.writeTxn(() async {
            op.retryCount = 5; // Skip further retries
            op.lastError = 'Client error: $statusCode';
            await _isar.syncOperationSchemas.put(op);
          });
        } else {
          await _isar.writeTxn(() async {
            op.retryCount += 1;
            op.lastError = e.toString();
            await _isar.syncOperationSchemas.put(op);
          });
        }
      } catch (e) {
        await _isar.writeTxn(() async {
          op.retryCount += 1;
          op.lastError = e.toString();
          await _isar.syncOperationSchemas.put(op);
        });
      }
    }
  }

  Future<void> _pushSingleOperation(SyncOperationSchema op) async {
    final payload = jsonDecode(op.payload) as Map<String, dynamic>;
    final endpoint = _endpointForEntity(op.entityType);

    switch (op.operationType) {
      case SyncOperationType.create:
        final res = await _apiClient.dio.post(endpoint, data: payload);
        final responseData = res.data['data'];
        // Extract the server ID from response and store it on the local record.
        final newServerId = _extractServerId(responseData, op.entityType);
        if (newServerId != null) {
          await _updateLocalServerId(op.entityType, op.localId, newServerId);
        }
        break;

      case SyncOperationType.update:
        if (op.serverId != null) {
          await _apiClient.dio.put('$endpoint/${op.serverId}', data: payload);
        }
        break;

      case SyncOperationType.delete:
        if (op.serverId != null) {
          await _apiClient.dio.delete('$endpoint/${op.serverId}');
        }
        break;
    }
  }

  String _endpointForEntity(SyncEntityType type) {
    switch (type) {
      case SyncEntityType.category:
        return '/categories';
      case SyncEntityType.menuItem:
        return '/menu-items';
      case SyncEntityType.order:
        return '/orders';
      case SyncEntityType.customer:
        return '/customers';
      case SyncEntityType.expense:
        return '/expenses';
      case SyncEntityType.expenseCategory:
        return '/expense-categories';
      case SyncEntityType.settings:
        return '/settings';
    }
  }

  String? _extractServerId(dynamic data, SyncEntityType type) {
    if (data == null) return null;
    if (data is Map) {
      // Backend responses nest data under entity name.
      final keys = {
        SyncEntityType.category: 'category',
        SyncEntityType.menuItem: 'item',
        SyncEntityType.order: 'order',
        SyncEntityType.customer: 'customer',
        SyncEntityType.expense: 'expense',
        SyncEntityType.expenseCategory: 'expenseCategory',
        SyncEntityType.settings: 'settings',
      };
      final entity = data[keys[type]] ?? data;
      if (entity is Map) {
        return entity['_id']?.toString() ?? entity['id']?.toString();
      }
    }
    return null;
  }

  Future<void> _updateLocalServerId(
    SyncEntityType type,
    int localId,
    String serverId,
  ) async {
    await _isar.writeTxn(() async {
      switch (type) {
        case SyncEntityType.category:
          final rec = await _isar.categorySchemas.get(localId);
          if (rec != null) {
            rec.serverId = serverId;
            rec.syncStatus = SyncStatus.synced;
            await _isar.categorySchemas.put(rec);
          }
          break;
        case SyncEntityType.menuItem:
          final rec = await _isar.menuItemSchemas.get(localId);
          if (rec != null) {
            rec.serverId = serverId;
            rec.syncStatus = SyncStatus.synced;
            await _isar.menuItemSchemas.put(rec);
          }
          break;
        case SyncEntityType.order:
          final rec = await _isar.orderSchemas.get(localId);
          if (rec != null) {
            rec.serverId = serverId;
            rec.syncStatus = SyncStatus.synced;
            await _isar.orderSchemas.put(rec);
          }
          break;
        case SyncEntityType.customer:
          final rec = await _isar.customerSchemas.get(localId);
          if (rec != null) {
            rec.serverId = serverId;
            rec.syncStatus = SyncStatus.synced;
            await _isar.customerSchemas.put(rec);
          }
          break;
        case SyncEntityType.expense:
          final rec = await _isar.expenseSchemas.get(localId);
          if (rec != null) {
            rec.serverId = serverId;
            rec.syncStatus = SyncStatus.synced;
            await _isar.expenseSchemas.put(rec);
          }
          break;
        case SyncEntityType.expenseCategory:
          final rec = await _isar.expenseCategorySchemas.get(localId);
          if (rec != null) {
            rec.serverId = serverId;
            rec.syncStatus = SyncStatus.synced;
            await _isar.expenseCategorySchemas.put(rec);
          }
          break;
        case SyncEntityType.settings:
          final rec = await _isar.businessSettingsSchemas.get(localId);
          if (rec != null) {
            rec.serverId = serverId;
            rec.syncStatus = SyncStatus.synced;
            await _isar.businessSettingsSchemas.put(rec);
          }
          break;
      }
    });
  }

  // ──────────────────────────────────────────────────────────────
  // PULL — Fetch recent changes from backend
  // ──────────────────────────────────────────────────────────────

  Future<void> _pullFromBackend() async {
    // Pull each entity type. For now, a full re-seed is used.
    // A production optimisation would use `?since=<last_sync>` timestamps.
    try {
      await _seedSettings();
      await _seedCategories();
      await _seedMenuItems();
      await _seedCustomers();
      await _seedExpenseCategories();
      await _seedExpenses();
      // Orders are not pulled (local is authoritative for billing).
    } catch (_) {
      // Pull failure is non-fatal.
    }
  }
}

/// Provider for [SyncService].
final syncServiceProvider = Provider<SyncService>((ref) {
  final isar = ref.watch(isarProvider);
  final apiClient = ref.watch(apiClientProvider);
  final statusNotifier = ref.watch(syncStatusProvider.notifier);
  return SyncService(isar, apiClient, statusNotifier);
});

/// Auto-disposable provider that listens to connectivity changes
/// and triggers sync when the device comes online.
final autoSyncProvider = Provider<void>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  final syncService = ref.watch(syncServiceProvider);

  isOnline.whenData((online) {
    if (online) {
      syncService.syncNow();
    }
  });
});
