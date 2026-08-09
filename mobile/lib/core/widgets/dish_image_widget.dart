import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../utils/local_image_storage_service.dart';

/// A StatefulWidget that safely displays a dish image from any source:
/// cloud URL (cached), local absolute path, relative code, or Base64.
///
/// Converting from StatelessWidget to StatefulWidget eliminates the
/// `_dependents.isEmpty` Flutter assertion error that occurs when a
/// FutureBuilder captures a BuildContext reference from an outer build()
/// call and the context becomes stale during async completion.
class DishImageWidget extends StatefulWidget {
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
  State<DishImageWidget> createState() => _DishImageWidgetState();
}

class _DishImageWidgetState extends State<DishImageWidget> {
  // Resolved local File when imageUrl is a relative image code
  File? _resolvedLocalFile;
  String? _lastResolvedUrl;

  @override
  void initState() {
    super.initState();
    _tryResolveLocalFile();
  }

  @override
  void didUpdateWidget(DishImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolvedLocalFile = null;
      _tryResolveLocalFile();
    }
  }

  void _tryResolveLocalFile() {
    final url = widget.imageUrl?.trim() ?? '';
    if (url.isEmpty) return;

    // Only attempt async resolution for codes that are NOT already handled
    // synchronously (not a URL, not absolute path, not base64).
    if (url.startsWith('http') ||
        url.startsWith('data:image') ||
        File(url).existsSync()) {
      return;
    }

    if (_lastResolvedUrl == url) return; // Avoid duplicate requests
    _lastResolvedUrl = url;

    LocalImageStorageService.resolveLocalFile(url).then((file) {
      if (mounted) {
        setState(() {
          _resolvedLocalFile = file;
        });
      }
    });
  }

  Widget _placeholder(bool isDark) {
    final showLabel = widget.size >= 60;
    return Container(
      width: widget.size,
      height: widget.size,
      padding: EdgeInsets.all(showLabel ? 4 : 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(widget.borderRadius),
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
            size: showLabel ? widget.size * 0.35 : widget.size * 0.45,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
          if (showLabel) ...[
            const SizedBox(height: 2),
            Text(
              'No Preview',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (widget.size * 0.15).clamp(8.0, 11.0),
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url = widget.imageUrl?.trim() ?? '';

    if (url.isEmpty) {
      return _placeholder(isDark);
    }

    // 1. Base64 Image Data (legacy support)
    if (url.startsWith('data:image')) {
      try {
        final commaIndex = url.indexOf(',');
        final base64Str =
            commaIndex != -1 ? url.substring(commaIndex + 1) : url;
        final bytes = base64Decode(base64Str);
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Image.memory(
            bytes,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => _placeholder(isDark),
          ),
        );
      } catch (_) {
        return _placeholder(isDark);
      }
    }

    // 2. HTTP/HTTPS — cloud URL with CachedNetworkImage (offline cached)
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: CachedNetworkImage(
          imageUrl: url,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          placeholder: (ctx, url) => Container(
            width: widget.size,
            height: widget.size,
            color: Colors.grey.withAlpha(30),
            child: const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          ),
          errorWidget: (ctx, url, error) => _placeholder(isDark),
        ),
      );
    }

    // 3. Absolute local file path (e.g. from image_picker before upload)
    final absoluteFile = File(url);
    if (absoluteFile.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Image.file(
          absoluteFile,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _placeholder(isDark),
        ),
      );
    }

    // 4. Relative image code — resolved asynchronously in initState/didUpdateWidget
    if (_resolvedLocalFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Image.file(
          _resolvedLocalFile!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _placeholder(isDark),
        ),
      );
    }

    // Resolving in progress or no match — show placeholder
    return _placeholder(isDark);
  }
}
