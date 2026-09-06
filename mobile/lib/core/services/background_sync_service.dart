import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../api/api_client.dart';
import '../constants/api_endpoints.dart';
import '../network/connectivity_service.dart';
import '../storage/local_database.dart';
import 'sync_manager.dart';

const String kBackgroundDailySyncTask = 'com.foodbillx.daily_sync_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await ApiEndpoints.initSavedServerUrl();

      final now = DateTime.now();
      // Requirement: Once per day after 8:00 PM
      if (now.hour < 20) {
        return Future.value(true);
      }

      final prefs = await SharedPreferences.getInstance();
      final todayKey = '${now.year}-${now.month}-${now.day}';
      final lastSyncDate = prefs.getString('last_auto_sync_date');
      if (lastSyncDate == todayKey) {
        return Future.value(true);
      }

      final connectivity = ConnectivityService();
      final isOnline = await connectivity.isConnected();
      if (!isOnline) {
        return Future.value(true);
      }

      final pendingCount = await LocalDatabase.instance.getPendingChangesCount();
      if (pendingCount == 0) {
        await prefs.setString('last_auto_sync_date', todayKey);
        return Future.value(true);
      }

      final apiClient = ApiClient();
      final syncManager = SyncManager(apiClient, connectivity);
      final res = await syncManager.sync();
      if (res.success) {
        await prefs.setString('last_auto_sync_date', todayKey);
      }
      return Future.value(true);
    } catch (e) {
      if (kDebugMode) print('Background sync error: $e');
      return Future.value(true);
    }
  });
}

class BackgroundSyncService {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );

      // Schedule periodic check every 3 hours (WorkManager will evaluate if >= 8 PM)
      await Workmanager().registerPeriodicTask(
        'foodbillx_daily_sync',
        kBackgroundDailySyncTask,
        frequency: const Duration(hours: 3),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } catch (e) {
      if (kDebugMode) print('Workmanager registration error: $e');
    }
  }

  /// In-app fallback: If user opens/uses app after 8:00 PM, quiet check & sync
  static Future<void> checkAndRunForegroundEveningSync(SyncManager syncManager) async {
    try {
      final now = DateTime.now();
      if (now.hour < 20) return; // Only after 8:00 PM

      final prefs = await SharedPreferences.getInstance();
      final todayKey = '${now.year}-${now.month}-${now.day}';
      final lastSyncDate = prefs.getString('last_auto_sync_date');
      if (lastSyncDate == todayKey) return; // Already synced today

      final pending = await LocalDatabase.instance.getPendingChangesCount();
      if (pending == 0) {
        await prefs.setString('last_auto_sync_date', todayKey);
        return;
      }

      final res = await syncManager.sync();
      if (res.success) {
        await prefs.setString('last_auto_sync_date', todayKey);
      }
    } catch (_) {}
  }
}
