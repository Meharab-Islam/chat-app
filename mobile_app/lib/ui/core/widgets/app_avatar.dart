import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/services/api_client.dart';
import '../design_system/app_colors.dart';
import 'app_cached_image.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double? size;
  final bool isOnline;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = size ?? 46.r;
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';

    final resolvedUrl = ApiClient.resolveUrl(imageUrl);
    Widget avatarWidget;
    if (resolvedUrl.isNotEmpty) {
      if (resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://')) {
        avatarWidget = AppCachedImage(
          imageUrl: resolvedUrl,
          width: avatarSize,
          height: avatarSize,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(avatarSize / 2),
        );
      } else {
        final file = File(resolvedUrl);
        avatarWidget = ClipRRect(
          borderRadius: BorderRadius.circular(avatarSize / 2),
          child: Image.file(
            file,
            width: avatarSize,
            height: avatarSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildInitials(context, avatarSize, initials),
          ),
        );
      }
    } else {
      avatarWidget = _buildInitials(context, avatarSize, initials);
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12.r,
                height: 12.r,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2.r,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitials(BuildContext context, double size, String initials) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(38),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: (size * 0.4).sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
