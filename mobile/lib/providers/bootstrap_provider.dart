import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/connectivity_service.dart';
import '../core/services/sync_manager.dart';
import '../core/storage/local_database.dart';

class BootstrapState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  BootstrapState({
    this.isLoading = false,
    this.isSuccess = true,
    this.errorMessage,
  });
}

class BootstrapNotifier extends StateNotifier<BootstrapState> {
  final SyncManager _syncManager;
  final ConnectivityService _connectivity;

  BootstrapNotifier(this._syncManager, this._connectivity) : super(BootstrapState());

  Future<bool> initializeLocalAndOptionalSync() async {
    state = BootstrapState(isLoading: true);

    try {
      // 1. Ensure Local SQLite Database is open and ready (Source of Truth)
      await LocalDatabase.instance.database;

      // 2. Non-blocking initial sync if online & first time
      final isOnline = await _connectivity.isConnected();
      final hasCompletedInitial = await LocalDatabase.instance.getMetadata('initial_migration_completed');

      if (isOnline && hasCompletedInitial != 'true') {
        try {
          final res = await _syncManager.sync();
          if (res.success) {
            await LocalDatabase.instance.setMetadata('initial_migration_completed', 'true');
          }
        } catch (e) {
          if (kDebugMode) print('Initial migration pull failed, continuing offline: $e');
        }
      }

      state = BootstrapState(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      if (kDebugMode) print('Bootstrap initialization error: $e');
      // Even if error occurs, allow local app launch
      state = BootstrapState(isLoading: false, isSuccess: true);
      return true;
    }
  }
}

final bootstrapProvider =
    StateNotifierProvider<BootstrapNotifier, BootstrapState>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return BootstrapNotifier(syncManager, connectivity);
});
