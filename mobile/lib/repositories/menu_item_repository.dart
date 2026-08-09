import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_response_parser.dart';
import '../core/constants/api_endpoints.dart';
import '../models/menu_item_model.dart';

class MenuItemRepository {
  final ApiClient _apiClient;

  MenuItemRepository(this._apiClient);

  Future<List<MenuItemModel>> getAll({
    String? categoryServerId,
    String? search,
    bool? isVeg,
  }) async {
    final queryParams = <String, dynamic>{};
    if (categoryServerId != null && categoryServerId.isNotEmpty) {
      queryParams['category'] = categoryServerId;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (isVeg != null) {
      queryParams['isVeg'] = isVeg;
    }

    final response = await _apiClient.dio.get(
      ApiEndpoints.menuItems,
      queryParameters: queryParams,
    );

    final rawList = ApiResponseParser.extractList(response.data, ['items', 'menuItems']);
    return rawList
        .map((item) => MenuItemModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<MenuItemModel> create(MenuItemModel item) async {
    _validate(item);
    final response = await _apiClient.dio.post(
      ApiEndpoints.menuItems,
      data: item.toJson(),
    );
    final rawItem = ApiResponseParser.extractMap(response.data, ['item', 'menuItem']);
    return MenuItemModel.fromJson(rawItem);
  }

  Future<MenuItemModel> update(MenuItemModel item) async {
    _validate(item);
    final response = await _apiClient.dio.put(
      '${ApiEndpoints.menuItems}/${item.id}',
      data: item.toJson(),
    );
    final rawItem = ApiResponseParser.extractMap(response.data, ['item', 'menuItem']);
    return MenuItemModel.fromJson(rawItem);
  }

  Future<MenuItemModel?> toggleAvailability(String id) async {
    final response = await _apiClient.dio.patch(
      '${ApiEndpoints.menuItems}/$id/toggle-availability',
    );
    final rawItem = ApiResponseParser.extractMap(response.data, ['item', 'menuItem']);
    return MenuItemModel.fromJson(rawItem);
  }

  Future<void> delete(String id) async {
    await _apiClient.dio.delete('${ApiEndpoints.menuItems}/$id');
  }

  void _validate(MenuItemModel item) {
    if (item.name.trim().isEmpty) throw ArgumentError('Item name is required');
    if (item.categoryId.isEmpty) throw ArgumentError('Category is required');
    if (!item.price.isFinite || item.price < 0) {
      throw ArgumentError('Price must be a valid non-negative number');
    }
    if (!item.discount.isFinite ||
        item.discount < 0 ||
        item.discount > item.price) {
      throw ArgumentError('Discount must be between zero and the item price');
    }
    if (!item.gstPercentage.isFinite ||
        item.gstPercentage < 0 ||
        item.gstPercentage > 100) {
      throw ArgumentError('GST must be between 0 and 100');
    }
  }
}

final menuItemRepositoryProvider = Provider<MenuItemRepository>((ref) {
  return MenuItemRepository(ref.watch(apiClientProvider));
});
