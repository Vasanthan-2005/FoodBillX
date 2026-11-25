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
  final int totalSyncCount;
  final int pushedSyncCount;
  final DateTime? lastSyncedAt;
  final bool isOffline;
  final String? syncMessage;
  final SyncResult? lastResult;

  const SyncState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.totalSyncCount = 0,
    this.pushedSyncCount = 0,
    this.lastSyncedAt,
    this.isOffline = false,
    this.syncMessage,
    this.lastResult,
  });

  double? get syncProgress =>
      totalSyncCount > 0 ? (pushedSyncCount / totalSyncCount).clamp(0.0, 1.0) : null;

  SyncState copyWith({
    bool? isSyncing,
    int? pendingCount,
    int? totalSyncCount,
    int? pushedSyncCount,
    DateTime? lastSyncedAt,
    bool? isOffline,
    String? syncMessage,
    SyncResult? lastResult,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      totalSyncCount: totalSyncCount ?? this.totalSyncCount,
      pushedSyncCount: pushedSyncCount ?? this.pushedSyncCount,
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
    refreshStatus().then((_) {
      autoSyncIfOnline();
    });
    _connSub = _connectivity.onConnectivityChanged.listen((isOnline) async {
      state = state.copyWith(isOffline: !isOnline);
      if (isOnline) {
        await refreshStatus();
        if (state.pendingCount > 0 && !state.isSyncing) {
          uploadToCloud(pushOnly: true);
        }
      }
    });
  }

  /// Automatically uploads local pending changes in background whenever app is open and online.
  /// Runs fully asynchronous and non-blocking — local database remains fast and offline.
  Future<void> autoSyncIfOnline({bool force = false}) async {
    try {
      final pendingCount = await LocalDatabase.instance.getPendingChangesCount();
      final isOnline = await _connectivity.isConnected();
      state = state.copyWith(
        isOffline: !isOnline,
        pendingCount: pendingCount,
      );
      if (state.isSyncing || !isOnline) return;

      if (pendingCount > 0) {
        await uploadToCloud(pushOnly: true);
      }
    } catch (_) {}
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

  Future<SyncResult> uploadToCloud({bool pushOnly = true}) async {
    final initialPending = await LocalDatabase.instance.getPendingChangesCount();
    state = state.copyWith(
      isSyncing: true,
      pendingCount: initialPending,
      totalSyncCount: initialPending,
      pushedSyncCount: 0,
      syncMessage: initialPending > 0
          ? 'Uploading... $initialPending remaining'
          : 'Checking for updates...',
    );

    void handleProgress(int remaining, int pushed, int failed) {
      state = state.copyWith(
        pendingCount: remaining,
        pushedSyncCount: pushed + failed,
        syncMessage: remaining > 0
            ? 'Uploading... $pushed sent, $remaining remaining'
            : 'Finishing upload...',
      );
    }

    final result = pushOnly
        ? await _syncManager.pushOnly(onProgress: handleProgress)
        : await _syncManager.sync(onProgress: handleProgress);

    await refreshStatus();

    state = state.copyWith(
      isSyncing: false,
      totalSyncCount: 0,
      pushedSyncCount: 0,
      syncMessage: result.message,
      lastResult: result,
    );

    // If full two-way sync was explicitly invoked, refresh providers
    if (result.success && !pushOnly) {
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
