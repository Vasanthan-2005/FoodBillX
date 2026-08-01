import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../local_db/isar_database.dart';
import '../../local_db/schemas/sync_operation_schema.dart';

/// Tracks the current synchronisation status for UI display.
class SyncStatusState {
  final bool isSyncing;
  final DateTime? lastSyncedAt;
  final int pendingCount;
  final String? lastError;

  const SyncStatusState({
    this.isSyncing = false,
    this.lastSyncedAt,
    this.pendingCount = 0,
    this.lastError,
  });

  SyncStatusState copyWith({
    bool? isSyncing,
    DateTime? lastSyncedAt,
    int? pendingCount,
    String? lastError,
    bool clearError = false,
  }) {
    return SyncStatusState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingCount: pendingCount ?? this.pendingCount,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Notifier that exposes live sync status to the UI.
class SyncStatusNotifier extends StateNotifier<SyncStatusState> {
  final Isar _isar;

  SyncStatusNotifier(this._isar) : super(const SyncStatusState()) {
    _refreshPendingCount();
  }

  Future<void> _refreshPendingCount() async {
    final count = await _isar.syncOperationSchemas.count();
    state = state.copyWith(pendingCount: count);
  }

  void markSyncing() {
    state = state.copyWith(isSyncing: true, clearError: true);
  }

  void markSyncComplete() {
    state = state.copyWith(isSyncing: false, lastSyncedAt: DateTime.now());
    _refreshPendingCount();
  }

  void markSyncFailed(String error) {
    state = state.copyWith(isSyncing: false, lastError: error);
    _refreshPendingCount();
  }

  /// Call this after any local write that adds an outbox entry.
  void refreshPending() => _refreshPendingCount();
}

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatusState>((ref) {
      final isar = ref.watch(isarProvider);
      return SyncStatusNotifier(isar);
    });
