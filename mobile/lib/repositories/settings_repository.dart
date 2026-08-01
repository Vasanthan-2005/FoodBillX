import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_response_parser.dart';
import '../api/local_cache_service.dart';
import '../core/constants/api_endpoints.dart';
import '../models/business_settings_model.dart';

class SettingsRepository {
  final ApiClient _apiClient;
  static const String _cacheKey = 'settings';

  SettingsRepository(this._apiClient);

  Future<BusinessSettingsModel?> get() async {
    dynamic data;
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.settings);
      data = response.data;
      await LocalCacheService.saveCache(_cacheKey, data);
    } catch (_) {
      data = await LocalCacheService.getCache(_cacheKey);
    }

    final rawItem = ApiResponseParser.extractMap(data, ['settings']);
    if (rawItem.isEmpty) return null;
    return BusinessSettingsModel.fromJson(rawItem);
  }

  Future<BusinessSettingsModel> upsert(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.settings,
      data: data,
    );
    final rawItem = ApiResponseParser.extractMap(response.data, ['settings']);
    return BusinessSettingsModel.fromJson(rawItem);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(apiClientProvider));
});
