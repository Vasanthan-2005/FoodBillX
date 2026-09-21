import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  BootstrapNotifier() : super(BootstrapState());

  Future<bool> initializeLocalAndOptionalSync() async {
    state = BootstrapState(isLoading: true);

    try {
      // 1. Ensure Local SQLite Database is open and ready (Source of Truth)
      await LocalDatabase.instance.database;

      // 2. Mark initialization completed without auto-pulling past data on launch
      await LocalDatabase.instance.setMetadata('initial_migration_completed', 'true');

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
  return BootstrapNotifier();
});
