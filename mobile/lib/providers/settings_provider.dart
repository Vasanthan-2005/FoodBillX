import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/sync/sync_status_notifier.dart';
import '../models/business_settings_model.dart';
import '../repositories/settings_repository.dart';

class SettingsState {
  final BusinessSettingsModel? settings;
  final bool isLoading;
  final String? errorMessage;

  SettingsState({this.settings, this.isLoading = false, this.errorMessage});

  SettingsState copyWith({
    BusinessSettingsModel? settings,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repo;
  final SyncStatusNotifier _syncStatus;

  SettingsNotifier(this._repo, this._syncStatus) : super(SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final settings = await _repo.get();
      state = state.copyWith(settings: settings, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> updateData) async {
    state = state.copyWith(isLoading: true);
    try {
      final updated = await _repo.upsert(updateData);
      state = state.copyWith(settings: updated, isLoading: false);
      _syncStatus.refreshPending();
      return true;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final repo = ref.watch(settingsRepositoryProvider);
    final syncStatus = ref.watch(syncStatusProvider.notifier);
    return SettingsNotifier(repo, syncStatus);
  },
);
