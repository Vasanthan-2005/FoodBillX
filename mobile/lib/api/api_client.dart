import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final base = ApiEndpoints.baseUrl;
          options.baseUrl = base.endsWith('/') ? base : '$base/';
          if (options.path.startsWith('/')) {
            options.path = options.path.substring(1);
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          String errorMessage = 'Unable to connect to backend server.';
          if (error.response != null) {
            final data = error.response?.data;
            if (data is Map && data.containsKey('message')) {
              errorMessage = data['message'].toString();
            } else {
              errorMessage =
                  'Server error (${error.response?.statusCode}). Please try again.';
            }
          } else if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            errorMessage =
                'Connection timed out. Please check your network or server URL in settings.';
          } else if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.unknown) {
            errorMessage =
                'Unable to reach backend server. Please verify your internet connection.';
          }

          final customError = DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: errorMessage,
            message: errorMessage,
          );

          return handler.next(customError);
        },
      ),
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
