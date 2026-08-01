import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService _storageService;

  ApiClient(this._storageService) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          String errorMessage = 'An unexpected error occurred';
          if (error.response != null) {
            final data = error.response?.data;
            if (data is Map && data.containsKey('message')) {
              errorMessage = data['message'].toString();
            } else {
              errorMessage = 'Server error: ${error.response?.statusCode}';
            }
          } else if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            errorMessage = 'Connection timed out. Please check your network.';
          } else if (error.type == DioExceptionType.connectionError) {
            errorMessage = 'Network connection failed. Offline mode active.';
          }

          final customError = DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: errorMessage,
          );

          return handler.next(customError);
        },
      ),
    );
  }
}
