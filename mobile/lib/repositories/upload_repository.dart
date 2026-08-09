import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

class UploadRepository {
  final ApiClient _apiClient;

  UploadRepository(this._apiClient);

  /// Uploads a compressed local image file to the backend `/api/v1/upload` endpoint.
  /// Returns the hosted public image URL string (e.g. `https://foodbillx.onrender.com/uploads/dish_1722582400.jpg`).
  Future<String?> uploadDishImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) return null;

      final filename = imageFile.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: filename,
        ),
      });

      final response = await _apiClient.dio.post(
        '/api/v1/upload',
        data: formData,
      );

      if (response.statusCode == 201 && response.data != null) {
        final String? url = response.data['url'] ?? response.data['relativeUrl'];
        return url;
      }
    } catch (e) {
      debugPrint('Error uploading image to server: $e');
    }
    return null;
  }

  /// Deletes a dish image file from the backend cloud storage.
  Future<void> deleteDishImage(String imageRef) async {
    if (imageRef.trim().isEmpty) return;

    try {
      final filename = imageRef.split('/').last;
      await _apiClient.dio.delete('/api/v1/upload/$filename');
    } catch (e) {
      debugPrint('Error deleting image from server: $e');
    }
  }
}

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepository(ref.watch(apiClientProvider));
});
