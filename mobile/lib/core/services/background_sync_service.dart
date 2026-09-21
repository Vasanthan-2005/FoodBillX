import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../../api/api_client.dart';
import '../constants/api_endpoints.dart';
import '../network/connectivity_service.dart';
import '../storage/local_database.dart';
import 'sync_manager.dart';

const String kBackgroundDailySyncTask = 'com.foodbillx.daily_10pm_sync_task';
const String kBackgroundDailySyncUniqueName = 'foodbillx_nightly_10pm_sync';

// ==============================================================================
// ⏰ AUTO-SYNC SCHEDULE CONFIGURATION
// Target: Daily after 10:00 PM night (22:00)
// ==============================================================================
const int kAutoSyncTargetHour = 22; // 24-hour format (22 = 10:00 PM)
const int kAutoSyncTargetMinute = 0; // Minute (0 = sharp)

/// Calculate the exact duration from now until the upcoming 10:00 PM
Duration calculateDelayUntilNext10Pm() {
  final now = DateTime.now();
  DateTime target = DateTime(
    now.year,
    now.month,
    now.day,
    kAutoSyncTargetHour,
    kAutoSyncTargetMinute,
    0,
  );

  // If already past 10:00 PM today, target is tomorrow at 10:00 PM
  if (now.isAfter(target)) {
    target = target.add(const Duration(days: 1));
  }

  final delay = target.difference(now);
  return delay.isNegative ? Duration.zero : delay;
}

/// Helper to check if current device time has reached or passed 10:00 PM
/// Also covers after-midnight restaurant closing hours (10:00 PM to 4:00 AM)
bool isAutoSyncTimeReached(DateTime now) {
  if (now.hour >= kAutoSyncTargetHour || now.hour < 4) {
    return true;
  }
  return false;
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // 1. Mandatory for background Flutter isolates: initialize bindings
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await ApiEndpoints.initSavedServerUrl();

      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      if (kDebugMode) {
        print('[BackgroundSyncWorker] Woke up at $timeStr for 10:00 PM sync.');
      }

      // 2. Schedule next day's 10:00 PM sync immediately
      await BackgroundSyncService.scheduleNightly10PmTask();

      // 3. Check connectivity
      final connectivity = ConnectivityService();
      final isOnline = await connectivity.isConnected();
      if (!isOnline) {
        if (kDebugMode) {
          print('[BackgroundSyncWorker] Device is offline at $timeStr. Will retry when connected.');
        }
        return Future.value(false); // Returning false causes WorkManager to retry when online
      }

      // 4. Check for unsynced changes only (delta sync)
      final pendingCount = await LocalDatabase.instance.getPendingChangesCount();
      if (pendingCount == 0) {
        if (kDebugMode) {
          print('[BackgroundSyncWorker] 0 pending changes at $timeStr. All data is already up to date in cloud.');
        }
        return Future.value(true);
      }

      if (kDebugMode) {
        print('[BackgroundSyncWorker] 10:00 PM triggered! Uploading $pendingCount unsynced records...');
      }

      // 5. Send unsynced changes to backend
      final apiClient = ApiClient();
      final syncManager = SyncManager(apiClient, connectivity);
      final res = await syncManager.sync();

      if (res.success) {
        if (kDebugMode) {
          print('[BackgroundSyncWorker] ✅ Nightly 10:00 PM auto-sync completed! ${res.message}');
        }
        return Future.value(true);
      } else {
        if (kDebugMode) {
          print('[BackgroundSyncWorker] ❌ Auto-sync failed: ${res.message}. Will retry.');
        }
        return Future.value(false);
      }
    } catch (e) {
      if (kDebugMode) print('[BackgroundSyncWorker] Error during background sync: $e');
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  static bool _isInitialized = false;
  static Timer? _foregroundDailyTimer;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await Workmanager().initialize(callbackDispatcher);
        await scheduleNightly10PmTask();
      }
    } catch (e) {
      if (kDebugMode) print('Workmanager registration error: $e');
    }
  }

  /// Schedules a one-off task targeted at 10:00 PM sharp, plus a 24-hour recurring safety net
  static Future<void> scheduleNightly10PmTask() async {
    try {
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        return;
      }

      final initialDelay = calculateDelayUntilNext10Pm();
      final hours = initialDelay.inHours;
      final minutes = initialDelay.inMinutes % 60;

      if (kDebugMode) {
        print('[BackgroundSyncService] Scheduling 10:00 PM sync. Delay until run: ${hours}h ${minutes}m.');
      }

      // 1. One-off task with exact delay to 10:00 PM tonight
      await Workmanager().registerOneOffTask(
        kBackgroundDailySyncUniqueName,
        kBackgroundDailySyncTask,
        initialDelay: initialDelay,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      // 2. 24-Hour recurring backup task
      await Workmanager().registerPeriodicTask(
        'foodbillx_daily_10pm_periodic',
        kBackgroundDailySyncTask,
        frequency: const Duration(hours: 24),
        initialDelay: initialDelay,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } catch (e) {
      if (kDebugMode) print('[BackgroundSyncService] Failed to schedule nightly sync: $e');
    }
  }

  /// Foreground timer: If the app is open on the counter at 10:00 PM, trigger sync directly
  static void startForegroundDailyTimer(SyncManager syncManager) {
    _foregroundDailyTimer?.cancel();
    final delay = calculateDelayUntilNext10Pm();

    if (kDebugMode) {
      print('[BackgroundSyncService] Foreground 10:00 PM timer set in ${delay.inMinutes} minutes (${delay.inHours}h ${delay.inMinutes % 60}m).');
    }

    _foregroundDailyTimer = Timer(delay, () async {
      if (kDebugMode) {
        print('[BackgroundSyncService] Foreground 10:00 PM timer fired!');
      }
      await checkAndRunForegroundEveningSync(syncManager);
      // Reschedule for tomorrow's 10:00 PM
      startForegroundDailyTimer(syncManager);
    });
  }

  /// In-app fallback: If user opens/uses app at or after 10:00 PM, check & sync unsynced records
  static Future<void> checkAndRunForegroundEveningSync(
    SyncManager syncManager,
  ) async {
    try {
      final now = DateTime.now();
      if (!isAutoSyncTimeReached(now)) {
        return; // Before 10:00 PM
      }

      final pending = await LocalDatabase.instance.getPendingChangesCount();
      if (pending == 0) {
        if (kDebugMode) {
          print('[ForegroundAutoSync] After 10:00 PM checked. All records are already synced.');
        }
        return;
      }

      if (kDebugMode) {
        print('[ForegroundAutoSync] After 10:00 PM triggered! Syncing $pending unsynced changes to cloud...');
      }

      final res = await syncManager.sync();
      if (res.success) {
        if (kDebugMode) {
          print('[ForegroundAutoSync] ✅ Auto-sync finished successfully! ${res.message}');
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
