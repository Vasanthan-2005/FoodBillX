import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalImageStorageService {
  static Directory? _dishImagesDir;

  /// Initializes and returns the permanent `<app_documents>/dish_images/` directory.
  static Future<Directory> getDishImagesDirectory() async {
    if (_dishImagesDir != null && _dishImagesDir!.existsSync()) {
      return _dishImagesDir!;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDocDir.path, 'dish_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    _dishImagesDir = imagesDir;
    return imagesDir;
  }

  /// Saves image bytes or a local file path into `<app_doc>/dish_images/`.
  /// Returns the **absolute local path** to the saved file (for immediate preview and upload).
  static Future<String?> saveDishImage(
    String inputData, {
    String? oldImageCode,
  }) async {
    try {
      if (inputData.trim().isEmpty) return null;

      // 1. Delete old image file if changing dish photo
      if (oldImageCode != null && oldImageCode.isNotEmpty) {
        await deleteDishImage(oldImageCode);
      }

      final dir = await getDishImagesDirectory();
      final String filename =
          'dish_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File targetFile = File(p.join(dir.path, filename));

      List<int> bytes;
      if (inputData.startsWith('data:image')) {
        final commaIndex = inputData.indexOf(',');
        final base64Str = commaIndex != -1
            ? inputData.substring(commaIndex + 1)
            : inputData;
        bytes = base64Decode(base64Str);
      } else if (File(inputData).existsSync()) {
        // inputData is an absolute local path (e.g. from image_picker)
        bytes = await File(inputData).readAsBytes();
      } else {
        // Already a relative code or remote URL — return unchanged
        return inputData;
      }

      await targetFile.writeAsBytes(bytes, flush: true);
      // Return the ABSOLUTE path so callers can immediately open the file
      return targetFile.path;
    } catch (e) {
      debugPrint('Error saving dish image locally: $e');
      return null;
    }
  }

  /// Resolves an image code (relative filename) to a local [File] if it exists.
  static Future<File?> resolveLocalFile(String? imageCode) async {
    if (imageCode == null || imageCode.trim().isEmpty) return null;
    final code = imageCode.trim();

    // Direct local path check
    if (File(code).existsSync()) {
      return File(code);
    }

    try {
      final dir = await getDishImagesDirectory();
      final file = File(p.join(dir.path, code));
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      debugPrint('Error resolving local image file: $e');
    }
    return null;
  }

  /// Deletes a stored local image file when a dish is deleted or photo replaced.
  static Future<void> deleteDishImage(String? imageCode) async {
    if (imageCode == null || imageCode.trim().isEmpty) return;
    final code = imageCode.trim();

    try {
      if (File(code).existsSync()) {
        await File(code).delete();
        return;
      }

      final dir = await getDishImagesDirectory();
      final file = File(p.join(dir.path, code));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting local dish image: $e');
    }
  }
}
