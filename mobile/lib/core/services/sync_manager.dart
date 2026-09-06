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

      // 3. Record successful sync timestamp
      final now = DateTime.now().toIso8601String();
      await _localDb.setMetadata('last_synced_at', now);

      if (pushRes.pushedCount > 0) {
        return SyncResult(
          success: true,
          pushedCount: pushRes.pushedCount,
          message: '✓ ${pushRes.pushedCount} changes uploaded successfully',
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

    // 3. Merge Customers
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

    // 4. Merge Settings
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
