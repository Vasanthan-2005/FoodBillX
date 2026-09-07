import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../api/api_client.dart';
import '../constants/api_endpoints.dart';
import '../network/connectivity_service.dart';
import '../storage/local_database.dart';
import 'sync_manager.dart';

const String kBackgroundDailySyncTask = 'com.foodbillx.daily_sync_task';

// ==============================================================================
// ⏰ AUTO-SYNC SCHEDULE CONFIGURATION (EDIT HERE FOR TESTING)
// ==============================================================================
// Set the target time below to test auto-sync at any specific time:
// Examples:
//   - For 10:30 PM testing:  kAutoSyncTargetHour = 22; kAutoSyncTargetMinute = 30;
//   - For 8:00 PM default:   kAutoSyncTargetHour = 20; kAutoSyncTargetMinute = 0;
const int kAutoSyncTargetHour = 22; // 24-hour format (22 = 10 PM, 20 = 8 PM)
const int kAutoSyncTargetMinute = 40; // Minute (0 - 59)

// When testing, set this to true so you can trigger tests repeatedly
// without being blocked by the "already synced today" check.
const bool kTestBypassAlreadySyncedCheck = true;
// ==============================================================================

/// Helper to check if current device time has reached or passed the target time
bool isAutoSyncTimeReached(DateTime now) {
  if (now.hour > kAutoSyncTargetHour) {
    return true;
  }
  if (now.hour == kAutoSyncTargetHour && now.minute >= kAutoSyncTargetMinute) {
    return true;
  }
  return false;
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await ApiEndpoints.initSavedServerUrl();

      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final targetStr =
          '${kAutoSyncTargetHour.toString().padLeft(2, '0')}:${kAutoSyncTargetMinute.toString().padLeft(2, '0')}';

      if (kDebugMode) {
        print(
          '[BackgroundSyncWorker] Woke up at $timeStr. Target schedule is $targetStr.',
        );
      }

      if (!isAutoSyncTimeReached(now)) {
        if (kDebugMode) {
          print(
            '[BackgroundSyncWorker] Time ($timeStr) not reached yet (target $targetStr). Skipping.',
          );
        }
        return Future.value(true);
      }

      final prefs = await SharedPreferences.getInstance();
      final todayKey = '${now.year}-${now.month}-${now.day}';
      final lastSyncDate = prefs.getString('last_auto_sync_date');
      if (!kTestBypassAlreadySyncedCheck && lastSyncDate == todayKey) {
        if (kDebugMode) {
          print(
            '[BackgroundSyncWorker] Already completed auto-sync today ($lastSyncDate). Skipping.',
          );
        }
        return Future.value(true);
      }

      final connectivity = ConnectivityService();
      final isOnline = await connectivity.isConnected();
      if (!isOnline) {
        if (kDebugMode) print('[BackgroundSyncWorker] Offline. Skipping sync.');
        return Future.value(true);
      }

      final pendingCount = await LocalDatabase.instance
          .getPendingChangesCount();
      if (pendingCount == 0) {
        if (kDebugMode) {
          print('[BackgroundSyncWorker] 0 pending changes to sync.');
        }
        await prefs.setString('last_auto_sync_date', todayKey);
        return Future.value(true);
      }

      if (kDebugMode) {
        print(
          '[BackgroundSyncWorker] Target time reached ($timeStr >= $targetStr)! Syncing $pendingCount pending items...',
        );
      }

      final apiClient = ApiClient();
      final syncManager = SyncManager(apiClient, connectivity);
      final res = await syncManager.sync();
      if (res.success) {
        await prefs.setString('last_auto_sync_date', todayKey);
        if (kDebugMode) {
          print(
            '[BackgroundSyncWorker] ✅ Auto-sync completed successfully at $timeStr!',
          );
        }
      } else {
        if (kDebugMode) {
          print('[BackgroundSyncWorker] ❌ Auto-sync failed: ${res.message}');
        }
      }
      return Future.value(true);
    } catch (e) {
      if (kDebugMode) print('[BackgroundSyncWorker] Error: $e');
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
      await Workmanager().initialize(callbackDispatcher);

      // Schedule periodic check every 3 hours (WorkManager will evaluate if target time reached)
      await Workmanager().registerPeriodicTask(
        'foodbillx_daily_sync',
        kBackgroundDailySyncTask,
        frequency: const Duration(hours: 3),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } catch (e) {
      if (kDebugMode) print('Workmanager registration error: $e');
    }
  }

  /// In-app fallback: If user opens/uses app at or after target time, check & sync
  static Future<void> checkAndRunForegroundEveningSync(
    SyncManager syncManager,
  ) async {
    try {
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final targetStr =
          '${kAutoSyncTargetHour.toString().padLeft(2, '0')}:${kAutoSyncTargetMinute.toString().padLeft(2, '0')}';

      if (!isAutoSyncTimeReached(now)) {
        if (kDebugMode) {
          print(
            '[ForegroundAutoSync] Check at $timeStr: before target ($targetStr). Skipping.',
          );
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final todayKey = '${now.year}-${now.month}-${now.day}';
      final lastSyncDate = prefs.getString('last_auto_sync_date');
      if (!kTestBypassAlreadySyncedCheck && lastSyncDate == todayKey) {
        if (kDebugMode) {
          print(
            '[ForegroundAutoSync] Already synced today ($lastSyncDate). Skipping.',
          );
        }
        return;
      }

      final pending = await LocalDatabase.instance.getPendingChangesCount();
      if (pending == 0) {
        if (kDebugMode) {
          print(
            '[ForegroundAutoSync] Target time reached ($timeStr >= $targetStr). 0 pending changes.',
          );
        }
        await prefs.setString('last_auto_sync_date', todayKey);
        return;
      }

      if (kDebugMode) {
        print(
          '[ForegroundAutoSync] Target time reached ($timeStr >= $targetStr)! Syncing $pending changes...',
        );
      }

      final res = await syncManager.sync();
      if (res.success) {
        await prefs.setString('last_auto_sync_date', todayKey);
        if (kDebugMode) {
          print(
            '[ForegroundAutoSync] ✅ Auto-sync finished successfully at $timeStr!',
          );
        }
      } else {
        if (kDebugMode) {
          print('[ForegroundAutoSync] ❌ Auto-sync failed: ${res.message}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('[ForegroundAutoSync] Error: $e');
    }
  }
}
