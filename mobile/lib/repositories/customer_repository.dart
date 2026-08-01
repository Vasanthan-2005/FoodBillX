import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_response_parser.dart';
import '../api/local_cache_service.dart';
import '../core/constants/api_endpoints.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final ApiClient _apiClient;
  static const String _cacheKey = 'customers';

  CustomerRepository(this._apiClient);

  Future<List<CustomerModel>> getAll({
    String? search,
    String? cardNumber,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (cardNumber != null && cardNumber.isNotEmpty) {
      queryParams['cardNumber'] = cardNumber;
    }

    dynamic data;
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.customers,
        queryParameters: queryParams,
      );
      data = response.data;
      if (queryParams.isEmpty) {
        await LocalCacheService.saveCache(_cacheKey, data);
      }
    } catch (_) {
      if (queryParams.isEmpty) {
        data = await LocalCacheService.getCache(_cacheKey);
      }
    }

    final rawList = ApiResponseParser.extractList(data, ['customers']);
    return rawList
        .map((item) => CustomerModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CustomerModel> create(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.customers,
      data: data,
    );
    final item = ApiResponseParser.extractMap(response.data, ['customer']);
    return CustomerModel.fromJson(item);
  }

  Future<CustomerModel> update(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put(
      '${ApiEndpoints.customers}/$id',
      data: data,
    );
    final item = ApiResponseParser.extractMap(response.data, ['customer']);
    return CustomerModel.fromJson(item);
  }

  Future<void> delete(String id) async {
    await _apiClient.dio.delete('${ApiEndpoints.customers}/$id');
  }

  Future<CustomerModel> assignLoyaltyCard(String id, String cardNumber) async {
    final response = await _apiClient.dio.post(
      '${ApiEndpoints.customers}/$id/assign-loyalty-card',
      data: {'cardNumber': cardNumber},
    );
    final item = ApiResponseParser.extractMap(response.data, ['customer']);
    return CustomerModel.fromJson(item);
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(apiClientProvider));
});
