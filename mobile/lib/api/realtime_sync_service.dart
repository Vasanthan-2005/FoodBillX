import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants/api_endpoints.dart';
import '../providers/customer_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/menu_provider.dart';

class RealtimeSyncState {
  final bool isLive;
  final DateTime? lastSyncedAt;

  RealtimeSyncState({
    this.isLive = true,
    this.lastSyncedAt,
  });

  RealtimeSyncState copyWith({
    bool? isLive,
    DateTime? lastSyncedAt,
  }) {
    return RealtimeSyncState(
      isLive: isLive ?? this.isLive,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class RealtimeSyncNotifier extends StateNotifier<RealtimeSyncState> {
  final Ref _ref;
  io.Socket? _socket;
  Timer? _pollingTimer;

  RealtimeSyncNotifier(this._ref) : super(RealtimeSyncState()) {
    _initSocket();
    _startPeriodicSync();
  }

  void _initSocket() {
    try {
      final serverUrl = ApiEndpoints.baseUrl.replaceAll('/api/v1', '');
      _socket = io.io(
        serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        state = state.copyWith(isLive: true, lastSyncedAt: DateTime.now());
      });

      _socket?.onDisconnect((_) {
        state = state.copyWith(isLive: false);
      });

      _socket?.onConnectError((_) {
        state = state.copyWith(isLive: false);
      });

      _socket?.on('data_updated', (_) => triggerSync());
      _socket?.on('order_created', (_) => triggerSync());
      _socket?.on('expense_added', (_) => triggerSync());
      _socket?.on('menu_updated', (_) => triggerSync());
    } catch (e) {
      if (kDebugMode) print('Socket initialization error: $e');
    }
  }

  void _startPeriodicSync() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      triggerSync(silent: true);
    });
  }

  Future<void> triggerSync({bool silent = false}) async {
    try {
      state = state.copyWith(lastSyncedAt: DateTime.now(), isLive: true);
      _ref.read(dashboardProvider.notifier).refresh(forceSpinner: !silent);
      _ref.read(menuProvider.notifier).loadCategoriesAndItems();
      _ref.read(customerProvider.notifier).loadCustomers();
    } catch (e) {
      if (kDebugMode) print('Realtime sync error: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}

final realtimeSyncProvider =
    StateNotifierProvider<RealtimeSyncNotifier, RealtimeSyncState>((ref) {
  return RealtimeSyncNotifier(ref);
});
