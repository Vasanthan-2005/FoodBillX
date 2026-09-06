import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/local_database.dart';
import '../models/business_settings_model.dart';

class SettingsRepository {
  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<BusinessSettingsModel?> get() async {
    return await _localDb.getSettings();
  }

  Future<BusinessSettingsModel> upsert(Map<String, dynamic> data) async {
    return await _localDb.upsertSettings(data);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});
