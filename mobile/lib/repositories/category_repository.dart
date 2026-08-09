import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_response_parser.dart';
import '../core/constants/api_endpoints.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final ApiClient _apiClient;

  CategoryRepository(this._apiClient);

  Future<List<CategoryModel>> getAll() async {
    final response = await _apiClient.dio.get(ApiEndpoints.categories);
    final rawList = ApiResponseParser.extractList(response.data, ['categories']);
    return rawList
        .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CategoryModel> create(String name, String icon) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.categories,
      data: {'name': name, 'icon': icon},
    );
    final item = ApiResponseParser.extractMap(response.data, ['category']);
    return CategoryModel.fromJson(item);
  }

  Future<CategoryModel> update(String id, String name, String icon) async {
    final response = await _apiClient.dio.put(
      '${ApiEndpoints.categories}/$id',
      data: {'name': name, 'icon': icon},
    );
    final item = ApiResponseParser.extractMap(response.data, ['category']);
    return CategoryModel.fromJson(item);
  }

  Future<void> delete(String id) async {
    await _apiClient.dio.delete('${ApiEndpoints.categories}/$id');
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(apiClientProvider));
});
