import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

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

    Widget placeholderWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withAlpha(30)
            : AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          fallbackEmoji,
          style: TextStyle(fontSize: size * 0.5),
        ),
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
