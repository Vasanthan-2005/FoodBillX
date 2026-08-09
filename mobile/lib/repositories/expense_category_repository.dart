import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_response_parser.dart';
import '../core/constants/api_endpoints.dart';
import '../models/expense_category_model.dart';

class ExpenseCategoryRepository {
  final ApiClient _apiClient;

  ExpenseCategoryRepository(this._apiClient);

  Future<List<ExpenseCategoryModel>> getAll() async {
    final response = await _apiClient.dio.get(ApiEndpoints.expenseCategories);
    final rawList = ApiResponseParser.extractList(response.data, ['categories']);
    return rawList
        .map(
          (item) =>
              ExpenseCategoryModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<ExpenseCategoryModel> create(String name, String icon) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.expenseCategories,
      data: {'name': name, 'icon': icon},
    );
    final item = ApiResponseParser.extractMap(response.data, ['category']);
    return ExpenseCategoryModel.fromJson(item);
  }

  Future<ExpenseCategoryModel> update(
    String id,
    String name,
    String icon,
  ) async {
    final response = await _apiClient.dio.put(
      '${ApiEndpoints.expenseCategories}/$id',
      data: {'name': name, 'icon': icon},
    );
    final item = ApiResponseParser.extractMap(response.data, ['category']);
    return ExpenseCategoryModel.fromJson(item);
  }

  Future<void> delete(String id) async {
    await _apiClient.dio.delete('${ApiEndpoints.expenseCategories}/$id');
  }
}

final expenseCategoryRepositoryProvider = Provider<ExpenseCategoryRepository>((
  ref,
) {
  return ExpenseCategoryRepository(ref.watch(apiClientProvider));
});
