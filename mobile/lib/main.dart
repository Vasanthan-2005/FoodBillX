import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'core/constants/api_endpoints.dart';
import 'core/services/background_sync_service.dart';
import 'core/storage/local_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite for Desktop platforms (Windows, Linux, macOS)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

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
