import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';

class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppSpacing.radiusMd;

    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.file(
          File(imageUrl),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) =>
              errorWidget ??
              Container(
                width: width,
                height: height,
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                child: const Icon(Icons.broken_image_outlined, size: 28),
              ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: width != null ? (width! * 2).toInt() : 800,
        placeholder: (context, url) =>
            placeholder ??
            Container(
              width: width,
              height: height,
              color: isDark
                  ? AppColors.shimmerDarkBase
                  : AppColors.shimmerBase,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary.withAlpha(128),
                    ),
                  ),
                ),
              ),
            ),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              child: Icon(
                Icons.broken_image_outlined,
                size: 28,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
      ),
    );
  }
}
