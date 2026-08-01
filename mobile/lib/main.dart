import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'local_db/isar_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the local Isar database before starting the app.
  final isar = await IsarDatabase.initialize();

  runApp(
    ProviderScope(
      overrides: [
        // Make the Isar instance available globally.
        isarProvider.overrideWithValue(isar),
      ],
      child: const FoodBillXApp(),
    ),
  );
}
