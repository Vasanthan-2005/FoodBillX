import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'local_image_storage_service.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Picks and compresses an image from Camera or Gallery, then saves to local disk.
  /// Returns a relative image code string suitable for database storage.
  static Future<String?> pickAndCompressImage(
    BuildContext context, {
    required ImageSource source,
    String? oldImageCode,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 75,
      );

      if (file == null) return null;

      final String? relativeFilename = await LocalImageStorageService.saveDishImage(
        file.path,
        oldImageCode: oldImageCode,
      );
      return relativeFilename;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Shows a modal sheet to select between Camera and Gallery.
  static Future<String?> showImageSourceDialog(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Dish Image',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: Colors.blue),
                  title: const Text('Take Photo (Camera)'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: Colors.purple),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null || !context.mounted) return null;
    return pickAndCompressImage(context, source: source);
  }
}
