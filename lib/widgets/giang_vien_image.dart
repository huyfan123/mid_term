import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Reusable widget for displaying GiangVien's image.
/// Supports both Image URLs (http/https) and Base64 encoded strings
/// with proper fallbacks for errors and empty states.
class GiangVienImage extends StatelessWidget {
  final String imageSource;
  final double width;
  final double height;
  final BoxFit fit;
  final double borderRadius;

  const GiangVienImage({
    super.key,
    required this.imageSource,
    this.width = 60,
    this.height = 60,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: _buildImageContent(context),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    final trimmed = imageSource.trim();

    if (trimmed.isEmpty) {
      return _buildFallback(context);
    }

    // Case 1: HTTP / HTTPS Network URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: width * 0.4,
              height: height * 0.4,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );
    }

    // Case 2: Base64 String
    try {
      String cleanBase64 = trimmed;
      // Strip data URI prefix if present (e.g. data:image/png;base64,...)
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }
      // Remove any whitespace or newline
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');

      final Uint8List bytes = base64Decode(cleanBase64);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );
    } catch (_) {
      // If decoding fails, show fallback icon
      return _buildFallback(context);
    }
  }

  Widget _buildFallback(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: width * 0.55,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
      ),
    );
  }
}

