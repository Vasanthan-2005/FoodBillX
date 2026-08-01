import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/constants/api_endpoints.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiEndpoints.initSavedServerUrl();

  runApp(
    const ProviderScope(
      child: FoodBillXApp(),
    ),
  );
}
