import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the device currently has a usable network connection.
///
/// Exposes a [StreamProvider] ([isOnlineProvider]) that the sync engine
/// and UI can watch to react to connectivity changes.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Returns `true` if any network interface (WiFi, mobile, ethernet) is active.
  Future<bool> checkOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  /// Emits `true`/`false` whenever the connectivity state changes.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_isConnected);
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
  }
}

/// Provider for [ConnectivityService].
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Emits `true` when the device has a network connection, `false` otherwise.
final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});
