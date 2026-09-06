import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/constants/api_endpoints.dart';
import 'core/services/background_sync_service.dart';
import 'core/storage/local_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize custom server URL from storage
  await ApiEndpoints.initSavedServerUrl();

  // 2. Initialize Local Database (Primary Source of Truth)
  await LocalDatabase.instance.database;

  // 3. Initialize background scheduled sync (once per day after 8 PM)
  await BackgroundSyncService.initialize();

  runApp(
    const ProviderScope(
      child: FoodBillXApp(),
    ),
  );
}
