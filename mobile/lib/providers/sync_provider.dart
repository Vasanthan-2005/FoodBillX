import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/connectivity_service.dart';
import '../core/services/sync_manager.dart';
import '../core/storage/local_database.dart';
import 'customer_provider.dart';
import 'dashboard_provider.dart';
import 'expense_provider.dart';
import 'menu_provider.dart';
import 'orders_provider.dart';
import 'settings_provider.dart';

class SyncState {
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final bool isOffline;
  final String? syncMessage;
  final SyncResult? lastResult;

  const SyncState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.isOffline = false,
    this.syncMessage,
    this.lastResult,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncedAt,
    bool? isOffline,
    String? syncMessage,
    SyncResult? lastResult,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isOffline: isOffline ?? this.isOffline,
      syncMessage: syncMessage ?? this.syncMessage,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncManager _syncManager;
  final ConnectivityService _connectivity;
  final Ref _ref;
  StreamSubscription<bool>? _connSub;

  SyncNotifier(this._syncManager, this._connectivity, this._ref)
      : super(const SyncState()) {
    refreshStatus();
    _connSub = _connectivity.onConnectivityChanged.listen((isOnline) {
      state = state.copyWith(isOffline: !isOnline);
      if (isOnline) {
        refreshStatus();
      }
    });
  }

  Future<void> refreshStatus() async {
    try {
      final isOnline = await _connectivity.isConnected();
      final pendingCount = await LocalDatabase.instance.getPendingChangesCount();
      final lastSyncStr = await LocalDatabase.instance.getMetadata('last_synced_at');
      DateTime? lastSync;
      if (lastSyncStr != null && lastSyncStr.isNotEmpty) {
        lastSync = DateTime.tryParse(lastSyncStr)?.toLocal();
      }

      state = state.copyWith(
        isOffline: !isOnline,
        pendingCount: pendingCount,
        lastSyncedAt: lastSync,
      );
    } catch (_) {}
  }

  Future<SyncResult> uploadToCloud() async {
    state = state.copyWith(isSyncing: true, syncMessage: 'Uploading...');
    final result = await _syncManager.sync();

    await refreshStatus();

    state = state.copyWith(
      isSyncing: false,
      syncMessage: result.message,
      lastResult: result,
    );

    // If changes were uploaded or pulled, quietly refresh active Riverpod providers from Local DB
    if (result.success) {
      _ref.read(expenseProvider.notifier).loadAll(forceSpinner: false);
      _ref.read(customerProvider.notifier).loadCustomers(forceSpinner: false);
      _ref.read(menuProvider.notifier).loadCategoriesAndItems(forceSpinner: false);
      _ref.read(ordersProvider.notifier).loadOrders(forceSpinner: false);
      _ref.read(settingsProvider.notifier).loadSettings();
      _ref.read(dashboardProvider.notifier).refresh(forceSpinner: false);
    }

    return result;
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final manager = ref.watch(syncManagerProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return SyncNotifier(manager, connectivity, ref);
});
