import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_response_parser.dart';
import '../api/local_cache_service.dart';
import '../core/constants/api_endpoints.dart';
import '../models/order_model.dart';

class OrderRepository {
  final ApiClient _apiClient;
  static const String _cacheKey = 'orders';

  OrderRepository(this._apiClient);

  Future<List<OrderModel>> getAll({
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
    String? status,
    int limit = 100,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      queryParams['paymentMethod'] = paymentMethod;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
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
        ApiEndpoints.orders,
        queryParameters: queryParams,
      );
      data = response.data;
      if (startDate == null && endDate == null && paymentMethod == null) {
        await LocalCacheService.saveCache(_cacheKey, data);
      }
    } catch (_) {
      if (startDate == null && endDate == null && paymentMethod == null) {
        data = await LocalCacheService.getCache(_cacheKey);
      }
    }

    final rawList = ApiResponseParser.extractList(data, ['orders']);
    return rawList
        .map((item) => OrderModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<OrderModel> create({
    String? orderNumber,
    String? customerServerId,
    required String customerName,
    required String customerPhone,
    String loyaltyCardNumber = '',
    required List<OrderItemModel> items,
    required double subtotal,
    required double discountAmount,
    required double gstAmount,
    required double serviceChargeAmount,
    required double grandTotal,
    required String paymentMethod,
    String notes = '',
  }) async {
    final payload = {
      if (orderNumber != null && orderNumber.isNotEmpty) 'orderNumber': orderNumber,
      'customerId': customerServerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'loyaltyCardNumber': loyaltyCardNumber,
      'paymentMethod': paymentMethod,
      'discountAmount': discountAmount,
      'serviceChargeAmount': serviceChargeAmount,
      'items': items.map((i) => i.toJson()).toList(),
      'notes': notes,
    };

    final response = await _apiClient.dio.post(
      ApiEndpoints.orders,
      data: payload,
    );
    final rawItem = ApiResponseParser.extractMap(response.data, ['order']);
    return OrderModel.fromJson(rawItem);
  }

  Future<OrderModel> refund(String orderId) async {
    final response = await _apiClient.dio.post(
      '${ApiEndpoints.orders}/$orderId/refund',
    );
    final rawItem = ApiResponseParser.extractMap(response.data, ['order']);
    return OrderModel.fromJson(rawItem);
  }

  Future<void> delete(String orderId) async {
    await _apiClient.dio.delete('${ApiEndpoints.orders}/$orderId');
  }

  Future<List<OrderModel>> getBetween(DateTime start, DateTime end) async {
    return getAll(startDate: start, endDate: end, limit: 1000);
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(apiClientProvider));
});
