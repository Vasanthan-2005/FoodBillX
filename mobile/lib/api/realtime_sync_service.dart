import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants/api_endpoints.dart';
import '../core/network/connectivity_service.dart';
import '../providers/customer_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/orders_provider.dart';

class RealtimeSyncState {
  final bool isLive;
  final DateTime? lastSyncedAt;

  RealtimeSyncState({
    this.isLive = false,
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
  StreamSubscription? _connectivitySub;

  RealtimeSyncNotifier(this._ref) : super(RealtimeSyncState(isLive: false)) {
    _initConnectionManagement();
  }

  Future<void> _initConnectionManagement() async {
    final connectivity = _ref.read(connectivityServiceProvider);
    final isOnline = await connectivity.isConnected();
    if (isOnline) {
      _initSocket();
    }

    _connectivitySub = connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        if (_socket == null || !(_socket!.connected)) {
          _initSocket();
        }
      } else {
        _socket?.disconnect();
        state = state.copyWith(isLive: false);
      }
    });
  }

  void _initSocket() {
    try {
      final serverUrl = ApiEndpoints.baseUrl.replaceAll('/api/v1', '');
      _socket = io.io(
        serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(3000)
            .build(),
      );

      _socket?.onConnect((_) {
        state = state.copyWith(isLive: true, lastSyncedAt: DateTime.now());
      });

      _socket?.onDisconnect((_) {
        state = state.copyWith(isLive: false);
      });

      _socket?.onConnectError((_) {
        state = state.copyWith(isLive: false);
      });

      _socket?.on('data_updated', (_) => triggerRefresh());
      _socket?.on('order_created', (_) {
        _ref.read(dashboardProvider.notifier).refresh();
        _ref.read(ordersProvider.notifier).loadOrders(forceSpinner: false);
      });
      _socket?.on('expense_added', (_) {
        _ref.read(dashboardProvider.notifier).refresh();
        _ref.read(expenseProvider.notifier).loadAll(forceSpinner: false);
      });
      _socket?.on('menu_updated', (_) {
        _ref.read(menuProvider.notifier).loadCategoriesAndItems();
      });
    } catch (e) {
      if (kDebugMode) print('Socket initialization error: $e');
    }
  }

  Future<void> triggerRefresh({bool silent = true}) async {
    try {
      state = state.copyWith(lastSyncedAt: DateTime.now(), isLive: true);
      _ref.read(dashboardProvider.notifier).refresh(forceSpinner: !silent);
      _ref.read(menuProvider.notifier).loadCategoriesAndItems();
      _ref.read(customerProvider.notifier).loadCustomers();
      _ref.read(ordersProvider.notifier).loadOrders(forceSpinner: false);
      _ref.read(expenseProvider.notifier).loadAll(forceSpinner: false);
    } catch (e) {
      if (kDebugMode) print('Realtime refresh error: $e');
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}

final realtimeSyncProvider =
    StateNotifierProvider<RealtimeSyncNotifier, RealtimeSyncState>((ref) {
  return RealtimeSyncNotifier(ref);
});
