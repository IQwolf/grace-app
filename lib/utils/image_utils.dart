import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Utilities for safely rendering images from potentially empty/invalid URLs.
class ImageUtils {
  const ImageUtils._();

  static bool isValidUrl(String? url) => url != null && url.trim().isNotEmpty;

  /// Returns a safe ImageProvider. Falls back to a bundled asset placeholder when the URL is empty/invalid.
  /// Note: This returns a raster ImageProvider; SVGs are not supported as ImageProviders.
  static ImageProvider<Object> providerOrPlaceholder(String? url) {
    if (isValidUrl(url)) {
      return CachedNetworkImageProvider(url!.trim());
    }
    return const AssetImage('assets/images/logo.png');
  }

  /// Builds a safe CachedNetworkImage replacement that gracefully falls back
  /// to an asset when the URL is empty.
  static Widget safeNetworkImage(
    String? url, {
    BoxFit fit = BoxFit.cover,
    Color? placeholderColor,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    final Widget fallback = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Container(
        width: width,
        height: height,
        color: placeholderColor ?? Colors.grey.withValues(alpha: 0.04),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          width: width != null ? (width * 0.8) : 120,
          height: height != null ? (height * 0.8) : 120,
          fit: BoxFit.contain,
        ),
      ),
    );

    if (!isValidUrl(url)) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          width: width,
          height: height,
          fit: BoxFit.contain,
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: url!.trim(),
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, _) => fallback,
        errorWidget: (context, _, __) => fallback,
      ),
    );
  }
}