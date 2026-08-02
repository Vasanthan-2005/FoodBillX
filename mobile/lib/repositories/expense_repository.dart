import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_response_parser.dart';
import '../api/local_cache_service.dart';
import '../core/constants/api_endpoints.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final ApiClient _apiClient;
  static const String _cacheKey = 'expenses';

  ExpenseRepository(this._apiClient);

  Future<List<ExpenseModel>> getAll({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    dynamic data;
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.expenses,
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

    final rawList = ApiResponseParser.extractList(data, ['expenses']);
    return rawList
        .map((item) => ExpenseModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ExpenseModel> create(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.expenses,
      data: data,
    );
    final item = ApiResponseParser.extractMap(response.data, ['expense']);
    return ExpenseModel.fromJson(item);
  }

  Future<ExpenseModel> update(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put(
      '${ApiEndpoints.expenses}/$id',
      data: data,
    );
    final item = ApiResponseParser.extractMap(response.data, ['expense']);
    return ExpenseModel.fromJson(item);
  }

  Future<void> delete(String id) async {
    await _apiClient.dio.delete('${ApiEndpoints.expenses}/$id');
  }

  Future<double> getTodayTotal() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final expenses = await getAll(startDate: startOfDay, endDate: endOfDay);
    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(apiClientProvider));
});
