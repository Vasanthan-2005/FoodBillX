import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_response_parser.dart';
import '../core/constants/api_endpoints.dart';
import '../models/business_settings_model.dart';

class SettingsRepository {
  final ApiClient _apiClient;

  SettingsRepository(this._apiClient);

  Future<BusinessSettingsModel?> get() async {
    final response = await _apiClient.dio.get(ApiEndpoints.settings);
    final rawItem = ApiResponseParser.extractMap(response.data, ['settings']);
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
