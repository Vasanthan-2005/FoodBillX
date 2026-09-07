import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'local_image_storage_service.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Picks and compresses an image from Camera or Gallery, then saves to local disk.
  /// Returns a relative image code string suitable for database storage.
  static Future<String?> pickAndCompressImage({
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

  /// Shows a dialog to select between Camera and Gallery.
  /// Uses showDialog instead of nested showModalBottomSheet to avoid
  /// conflicting modal route transitions and framework assertion failures.
  static Future<String?> showImageSourceDialog(BuildContext context) async {
    final source = await showDialog<ImageSource?>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.photo_camera_rounded, color: Colors.amber),
              SizedBox(width: 10),
              Text(
                'Select Dish Image',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(isDark ? 50 : 30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.blue,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Take Photo (Camera)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(isDark ? 50 : 30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.purple,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (source == null) return null;

    // Settle the dialog route pop animation before launching the native activity
    await Future.delayed(const Duration(milliseconds: 120));

    return pickAndCompressImage(source: source);
  }
}
