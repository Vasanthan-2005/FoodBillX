import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/api_client.dart';
import '../network/connectivity_service.dart';
import '../storage/local_database.dart';

class SyncResult {
  final bool success;
  final int pushedCount;
  final int failedCount;
  final String message;

  const SyncResult({
    required this.success,
    this.pushedCount = 0,
    this.failedCount = 0,
    required this.message,
  });
}

class SyncManager {
  final ApiClient _apiClient;
  final ConnectivityService _connectivity;
  final LocalDatabase _localDb = LocalDatabase.instance;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  SyncManager(this._apiClient, this._connectivity);

  Future<SyncResult> sync({bool force = false}) async {
    if (_isSyncing) {
      return const SyncResult(success: false, message: 'Sync already in progress');
    }

    final isConnected = await _connectivity.isConnected();
    if (!isConnected) {
      return const SyncResult(
        success: false,
        message: 'No internet connection. Your data is safely stored on this device.',
      );
    }

    _isSyncing = true;
    try {
      // 1. Push local pending changes to cloud
      final pushRes = await _pushPendingChanges();

      // 2. Incrementally pull latest changes from cloud
      await _pullRemoteChanges();

      if (pushRes.failedCount > 0 && pushRes.pushedCount == 0) {
        return SyncResult(
          success: false,
          pushedCount: 0,
          failedCount: pushRes.failedCount,
          message: 'Failed to upload ${pushRes.failedCount} changes. Server could not be reached.',
        );
      }

      // 3. Record successful sync timestamp
      final now = DateTime.now().toIso8601String();
      await _localDb.setMetadata('last_synced_at', now);

      if (pushRes.pushedCount > 0) {
        final failedSuffix = pushRes.failedCount > 0 ? ' (${pushRes.failedCount} failed)' : '';
        return SyncResult(
          success: pushRes.failedCount == 0,
          pushedCount: pushRes.pushedCount,
          failedCount: pushRes.failedCount,
          message: '✓ ${pushRes.pushedCount} changes uploaded successfully$failedSuffix',
        );
      } else {
        return const SyncResult(
          success: true,
          pushedCount: 0,
          message: 'Your data is already up to date.',
        );
      }
    } catch (e) {
      if (kDebugMode) print('SyncManager error: $e');
      return SyncResult(
        success: false,
        message: 'Sync could not complete. Local data is safely retained.',
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Pushes all pending local changes (orders, expenses, customers) to the cloud.
  /// Runs entirely non-blocking in the background without pulling or altering local data.
  Future<SyncResult> pushOnly() async {
    if (_isSyncing) {
      return const SyncResult(success: false, message: 'Upload already in progress');
    }

    final isConnected = await _connectivity.isConnected();
    if (!isConnected) {
      return const SyncResult(
        success: false,
        message: 'No internet connection. Data safely stored offline.',
      );
    }

    _isSyncing = true;
    try {
      final pushRes = await _pushPendingChanges();

      if (pushRes.failedCount > 0 && pushRes.pushedCount == 0) {
        return SyncResult(
          success: false,
          pushedCount: 0,
          failedCount: pushRes.failedCount,
          message: 'Failed to upload ${pushRes.failedCount} changes. Server unreachable.',
        );
      }

      final now = DateTime.now().toIso8601String();
      await _localDb.setMetadata('last_synced_at', now);

      if (pushRes.pushedCount > 0) {
        final failedSuffix = pushRes.failedCount > 0 ? ' (${pushRes.failedCount} failed)' : '';
        return SyncResult(
          success: pushRes.failedCount == 0,
          pushedCount: pushRes.pushedCount,
          failedCount: pushRes.failedCount,
          message: '✓ ${pushRes.pushedCount} changes uploaded successfully$failedSuffix',
        );
      } else {
        return const SyncResult(
          success: true,
          pushedCount: 0,
          message: 'All local changes are already up to date in cloud.',
        );
      }
    } catch (e) {
      if (kDebugMode) print('SyncManager pushOnly error: $e');
      return SyncResult(
        success: false,
        message: 'Upload could not complete. Local data is safely retained.',
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<({int pushedCount, int failedCount})> _pushPendingChanges() async {
    final operations = await _localDb.getPendingOperations();
    if (operations.isEmpty) {
      return (pushedCount: 0, failedCount: 0);
    }

    int pushed = 0;
    int failed = 0;

    // Send in batches of up to 50 operations
    const batchSize = 50;
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = operations.sublist(
        i,
        i + batchSize > operations.length ? operations.length : i + batchSize,
      );

      try {
        final payload = {
          'operations': batch.map((op) => op.toJson()).toList(),
        };

        final response = await _apiClient.dio.post('sync/push', data: payload);
        final body = response.data;

        if (body is Map && body['data'] is Map && body['data']['results'] is List) {
          final results = body['data']['results'] as List;
          for (final res in results) {
            if (res is! Map) continue;
            final status = res['status']?.toString();
            final serverId = res['serverId']?.toString();
            final localId = res['localId']?.toString();
            final entityType = res['entityType']?.toString();
            final opType = res['operationType']?.toString();

            if (status == 'success' && localId != null && entityType != null) {
              await _localDb.markOperationSynced(
                entityType,
                localId,
                serverId,
                opType ?? 'create',
              );
              pushed++;
            } else {
              failed++;
            }
          }
        }
      } catch (err) {
        if (kDebugMode) print('Batch push error: $err');
        failed += batch.length;
      }
    }

    return (pushedCount: pushed, failedCount: failed);
  }

  Future<void> _pullRemoteChanges() async {
    try {
      final lastSince = await _localDb.getMetadata('last_synced_at');
      final queryParams = <String, dynamic>{};
      if (lastSince != null && lastSince.isNotEmpty) {
        queryParams['since'] = lastSince;
      }

      final response = await _apiClient.dio.get('sync/pull', queryParameters: queryParams);
      final body = response.data;

      if (body is Map && body['data'] is Map) {
        final data = Map<String, dynamic>.from(body['data']);
        await _mergeRemoteData(data);
      }
    } catch (err) {
      if (kDebugMode) print('Pull remote changes error: $err');
    }
  }

  Future<void> _mergeRemoteData(Map<String, dynamic> data) async {
    final db = await _localDb.database;

    // 1. Merge Expenses
    final remoteExpenses = data['expenses'] as List? ?? [];
    for (final e in remoteExpenses) {
      if (e is! Map) continue;
      final serverId = e['_id']?.toString() ?? e['id']?.toString();
      if (serverId == null) continue;

      final existing = await db.query('expenses', where: 'server_id = ?', whereArgs: [serverId]);
      if (existing.isNotEmpty) {
        // If local has pending changes, local intent wins!
        final localSync = existing.first['sync_status'] as String?;
        if (localSync != 'synced') continue;

        await db.update(
          'expenses',
          {
            'category': e['category'] ?? 'Miscellaneous',
            'title': e['title'] ?? e['category'] ?? '',
            'amount': (e['amount'] as num?)?.toDouble() ?? 0.0,
            'date': e['date'] ?? e['createdAt'] ?? DateTime.now().toIso8601String(),
            'notes': e['notes'] ?? '',
            'updated_at': e['updatedAt'] ?? DateTime.now().toIso8601String(),
            'sync_status': 'synced',
          },
          where: 'server_id = ?',
          whereArgs: [serverId],
        );
      } else {
        await db.insert('expenses', {
          'id': serverId,
          'server_id': serverId,
          'category': e['category'] ?? 'Miscellaneous',
          'title': e['title'] ?? e['category'] ?? '',
          'amount': (e['amount'] as num?)?.toDouble() ?? 0.0,
          'date': e['date'] ?? e['createdAt'] ?? DateTime.now().toIso8601String(),
          'notes': e['notes'] ?? '',
          'created_at': e['createdAt'] ?? DateTime.now().toIso8601String(),
          'updated_at': e['updatedAt'] ?? DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'deleted_at': null,
        });
      }
    }

    // 2. Merge Expense Categories
    final remoteExpCats = data['expenseCategories'] as List? ?? [];
    for (final c in remoteExpCats) {
      if (c is! Map) continue;
      final serverId = c['_id']?.toString();
      final name = c['name']?.toString() ?? '';
      if (name.isEmpty) continue;

      final existing = await db.query('expense_categories', where: 'name = ?', whereArgs: [name]);
      if (existing.isNotEmpty) {
        if (existing.first['sync_status'] != 'synced') continue;
        await db.update(
          'expense_categories',
          {
            'server_id': serverId,
            'icon': c['icon'] ?? 'receipt_long',
            'is_active': (c['isActive'] ?? true) ? 1 : 0,
            'updated_at': c['updatedAt'] ?? DateTime.now().toIso8601String(),
            'sync_status': 'synced',
          },
          where: 'name = ?',
          whereArgs: [name],
        );
      } else {
        await db.insert('expense_categories', {
          'id': serverId ?? name,
          'server_id': serverId,
          'name': name,
          'icon': c['icon'] ?? 'receipt_long',
          'is_active': (c['isActive'] ?? true) ? 1 : 0,
          'created_at': c['createdAt'] ?? DateTime.now().toIso8601String(),
          'updated_at': c['updatedAt'] ?? DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'deleted_at': null,
        });
      }
    }

    // 3. Merge Menu Categories
    final remoteCategories = data['categories'] as List? ?? [];
    for (final c in remoteCategories) {
      if (c is! Map) continue;
      final serverId = c['_id']?.toString();
      final name = c['name']?.toString() ?? '';
      if (serverId == null || name.isEmpty) continue;

      final existing = await db.query(
        'categories',
        where: 'server_id = ? OR name = ?',
        whereArgs: [serverId, name],
      );
      if (existing.isNotEmpty) {
        if (existing.first['sync_status'] != 'synced') continue;
        await db.update(
          'categories',
          {
            'server_id': serverId,
            'name': name,
            'icon': c['icon'] ?? 'fastfood',
            'sort_order': c['sortOrder'] ?? 0,
            'is_active': (c['isActive'] ?? true) ? 1 : 0,
            'updated_at': c['updatedAt'] ?? DateTime.now().toIso8601String(),
            'sync_status': 'synced',
          },
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        await db.insert('categories', {
          'id': serverId,
          'server_id': serverId,
          'name': name,
          'icon': c['icon'] ?? 'fastfood',
          'sort_order': c['sortOrder'] ?? 0,
          'is_active': (c['isActive'] ?? true) ? 1 : 0,
          'created_at': c['createdAt'] ?? DateTime.now().toIso8601String(),
          'updated_at': c['updatedAt'] ?? DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'deleted_at': null,
        });
      }
    }

    // 4. Merge Menu Items
    final remoteMenuItems = data['menuItems'] as List? ?? [];
    for (final m in remoteMenuItems) {
      if (m is! Map) continue;
      final serverId = m['_id']?.toString();
      final name = m['name']?.toString() ?? '';
      if (serverId == null || name.isEmpty) continue;

      // Resolve category reference
      String categoryId = '';
      final rawCat = m['category'];
      String? catServerId;
      String? catName;
      if (rawCat is Map) {
        catServerId = rawCat['_id']?.toString();
        catName = rawCat['name']?.toString();
      } else if (rawCat != null) {
        catServerId = rawCat.toString();
      }

      if (catServerId != null || catName != null) {
        final catRows = await db.query(
          'categories',
          where: 'server_id = ? OR name = ?',
          whereArgs: [catServerId ?? '', catName ?? ''],
          limit: 1,
        );
        if (catRows.isNotEmpty) {
          categoryId = catRows.first['id'] as String;
        } else if (catServerId != null) {
          categoryId = catServerId;
        }
      }

      final existing = await db.query(
        'menu_items',
        where: 'server_id = ? OR name = ?',
        whereArgs: [serverId, name],
      );
      if (existing.isNotEmpty) {
        if (existing.first['sync_status'] != 'synced') continue;
        await db.update(
          'menu_items',
          {
            'server_id': serverId,
            if (categoryId.isNotEmpty) 'category_id': categoryId,
            'name': name,
            'description': m['description'] ?? '',
            'price': (m['price'] as num?)?.toDouble() ?? 0.0,
            'discount': (m['discount'] as num?)?.toDouble() ?? 0.0,
            'gst_percentage': (m['gstPercentage'] as num?)?.toDouble() ?? 0.0,
            'image': m['image'] ?? '',
            'is_veg': (m['isVeg'] ?? true) ? 1 : 0,
            'is_available': (m['isAvailable'] ?? true) ? 1 : 0,
            'sort_order': m['sortOrder'] ?? 0,
            'updated_at': m['updatedAt'] ?? DateTime.now().toIso8601String(),
            'sync_status': 'synced',
          },
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        await db.insert('menu_items', {
          'id': serverId,
          'server_id': serverId,
          'category_id': categoryId,
          'name': name,
          'description': m['description'] ?? '',
          'price': (m['price'] as num?)?.toDouble() ?? 0.0,
          'discount': (m['discount'] as num?)?.toDouble() ?? 0.0,
          'gst_percentage': (m['gstPercentage'] as num?)?.toDouble() ?? 0.0,
          'image': m['image'] ?? '',
          'is_veg': (m['isVeg'] ?? true) ? 1 : 0,
          'is_available': (m['isAvailable'] ?? true) ? 1 : 0,
          'sort_order': m['sortOrder'] ?? 0,
          'created_at': m['createdAt'] ?? DateTime.now().toIso8601String(),
          'updated_at': m['updatedAt'] ?? DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'deleted_at': null,
        });
      }
    }

    // 5. Merge Customers
    final remoteCustomers = data['customers'] as List? ?? [];
    for (final c in remoteCustomers) {
      if (c is! Map) continue;
      final serverId = c['_id']?.toString();
      final phone = c['phone']?.toString() ?? '';
      if (phone.isEmpty) continue;

      final existing = await db.query('customers', where: 'phone = ?', whereArgs: [phone]);
      if (existing.isNotEmpty) {
        if (existing.first['sync_status'] != 'synced') continue;
        await db.update(
          'customers',
          {
            'server_id': serverId,
            'name': c['name'] ?? '',
            'address': c['address'] ?? '',
            'birthday': c['birthday'],
            'notes': c['notes'] ?? '',
            'total_visits': c['totalVisits'] ?? 0,
            'total_spent': (c['totalSpent'] as num?)?.toDouble() ?? 0.0,
            'loyalty_points': c['loyaltyPoints'] ?? 0,
            'loyalty_card_number': c['loyaltyCardNumber'] ?? '',
            'updated_at': c['updatedAt'] ?? DateTime.now().toIso8601String(),
            'sync_status': 'synced',
          },
          where: 'phone = ?',
          whereArgs: [phone],
        );
      } else {
        await db.insert('customers', {
          'id': serverId ?? phone,
          'server_id': serverId,
          'name': c['name'] ?? '',
          'phone': phone,
          'address': c['address'] ?? '',
          'birthday': c['birthday'],
          'notes': c['notes'] ?? '',
          'total_visits': c['totalVisits'] ?? 0,
          'total_spent': (c['totalSpent'] as num?)?.toDouble() ?? 0.0,
          'loyalty_points': c['loyaltyPoints'] ?? 0,
          'loyalty_card_number': c['loyaltyCardNumber'] ?? '',
          'created_at': c['createdAt'] ?? DateTime.now().toIso8601String(),
          'updated_at': c['updatedAt'] ?? DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'deleted_at': null,
        });
      }
    }

    // 6. Merge Orders
    final remoteOrders = data['orders'] as List? ?? [];
    for (final o in remoteOrders) {
      if (o is! Map) continue;
      final serverId = o['_id']?.toString();
      final orderNumber = o['orderNumber']?.toString() ?? '';
      if (serverId == null || orderNumber.isEmpty) continue;

      final existing = await db.query(
        'orders',
        where: 'server_id = ? OR order_number = ?',
        whereArgs: [serverId, orderNumber],
      );

      final rawItems = o['items'] as List? ?? [];
      final itemsJson = jsonEncode(rawItems);

      if (existing.isNotEmpty) {
        if (existing.first['sync_status'] != 'synced') continue;
        await db.update(
          'orders',
          {
            'server_id': serverId,
            'order_status': o['orderStatus'] ?? 'completed',
            'payment_status': o['paymentStatus'] ?? 'paid',
            'notes': o['notes'] ?? '',
            'updated_at': o['updatedAt'] ?? DateTime.now().toIso8601String(),
            'sync_status': 'synced',
          },
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        await db.insert('orders', {
          'id': serverId,
          'server_id': serverId,
          'order_number': orderNumber,
          'customer_id': o['customer']?.toString(),
          'customer_name': o['customerName'] ?? 'Walk-in Customer',
          'customer_phone': o['customerPhone'] ?? '',
          'loyalty_card_number': o['loyaltyCardNumber'] ?? '',
          'visit_count': o['visitCount'] ?? 1,
          'reward_status': o['rewardStatus'] ?? '',
          'order_status': o['orderStatus'] ?? 'completed',
          'items_json': itemsJson,
          'subtotal': (o['subtotal'] as num?)?.toDouble() ?? 0.0,
          'discount_amount': (o['discountAmount'] as num?)?.toDouble() ?? 0.0,
          'gst_amount': (o['gstAmount'] as num?)?.toDouble() ?? 0.0,
          'service_charge_amount': (o['serviceChargeAmount'] as num?)?.toDouble() ?? 0.0,
          'grand_total': (o['grandTotal'] as num?)?.toDouble() ?? 0.0,
          'payment_method': o['paymentMethod'] ?? 'cash',
          'payment_status': o['paymentStatus'] ?? 'paid',
          'notes': o['notes'] ?? '',
          'created_at': o['createdAt'] ?? DateTime.now().toIso8601String(),
          'updated_at': o['updatedAt'] ?? DateTime.now().toIso8601String(),
          'sync_status': 'synced',
          'deleted_at': null,
        });
      }
    }

    // 7. Merge Settings
    if (data['settings'] is Map) {
      final s = Map<String, dynamic>.from(data['settings']);
      final existing = await db.query('business_settings', where: 'id = ?', whereArgs: ['singleton']);
      if (existing.isNotEmpty && existing.first['sync_status'] == 'synced') {
        await db.update(
          'business_settings',
          {
            'server_id': s['_id']?.toString(),
            'business_name': s['businessName'] ?? 'HMB Bills',
            'logo': s['logo'] ?? '',
            'phone': s['phone'] ?? '',
            'address': s['address'] ?? '',
            'gstin': s['gstin'] ?? '',
            'currency': s['currency'] ?? '₹',
            'invoice_prefix': s['invoicePrefix'] ?? 'B',
            'tax_percentage': (s['taxPercentage'] as num?)?.toDouble() ?? 0.0,
            'service_charge_percentage': (s['serviceChargePercentage'] as num?)?.toDouble() ?? 0.0,
            'invoice_footer': s['invoiceFooter'] ?? 'Thank you for dining with us!',
            'loyalty_target_visits': s['loyaltyTargetVisits'] ?? 6,
            'loyalty_reward_type': s['loyaltyRewardType'] ?? 'Free Drink',
            'loyalty_reward_description': s['loyaltyRewardDescription'] ?? 'Free Drink',
            'updated_at': s['updatedAt'] ?? DateTime.now().toIso8601String(),
            'sync_status': 'synced',
          },
          where: 'id = ?',
          whereArgs: ['singleton'],
        );
      }
    }

    // 5. Handle Cloud Deletions / Tombstones
    final tombstones = data['tombstones'] as List? ?? [];
    for (final t in tombstones) {
      if (t is! Map) continue;
      final entityType = t['entityType']?.toString();
      final recordId = t['recordId']?.toString();
      if (entityType == null || recordId == null) continue;

      final tableName = switch (entityType) {
        'expense' => 'expenses',
        'expenseCategory' => 'expense_categories',
        'category' => 'categories',
        'menuItem' => 'menu_items',
        'customer' => 'customers',
        'order' => 'orders',
        _ => null,
      };
      if (tableName != null) {
        // Only delete if local is clean (not edited offline)
        await db.delete(
          tableName,
          where: "server_id = ? AND sync_status = 'synced'",
          whereArgs: [recordId],
        );
      }
    }
  }
}

final syncManagerProvider = Provider<SyncManager>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return SyncManager(apiClient, connectivity);
});
