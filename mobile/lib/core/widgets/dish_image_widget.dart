import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DishImageWidget extends StatelessWidget {
  final String? imageUrl;
  final String fallbackEmoji;
  final double size;
  final double borderRadius;

  const DishImageWidget({
    super.key,
    this.imageUrl,
    this.fallbackEmoji = '🍲',
    this.size = 40,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final showLabel = size >= 60;
    Widget placeholderWidget = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(showLabel ? 4 : 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: showLabel ? size * 0.35 : size * 0.45,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
          if (showLabel) ...[
            const SizedBox(height: 2),
            Text(
              'No Preview',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (size * 0.15).clamp(8.0, 11.0),
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return placeholderWidget;
    }

    final url = imageUrl!.trim();

    // 1. Base64 Image Data
    if (url.startsWith('data:image')) {
      try {
        final commaIndex = url.indexOf(',');
        final base64Str = commaIndex != -1 ? url.substring(commaIndex + 1) : url;
        final bytes = base64Decode(base64Str);
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => placeholderWidget,
          ),
        );
      } catch (_) {
        return placeholderWidget;
      }
    }

    // 2. HTTP/HTTPS Network Image with Caching
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            color: Colors.grey.withAlpha(30),
            child: const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          ),
          errorWidget: (context, url, error) => placeholderWidget,
        ),
      );
    }

    // 3. Local File Path
    if (File(url).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          File(url),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => placeholderWidget,
        ),
      );
    }

    return placeholderWidget;
  }
}
