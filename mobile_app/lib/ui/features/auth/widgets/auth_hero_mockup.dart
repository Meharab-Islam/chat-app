import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/widgets/app_avatar.dart';

class AuthHeroMockup extends StatelessWidget {
  const AuthHeroMockup({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final cardBg = isDark ? const Color(0xFF16181D) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF262930)
        : const Color(0xFFE5E7EB);
    final textCol = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSub = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return SizedBox(
      height: 220.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient soft glow
          Positioned(
            top: 20.h,
            child: Container(
              width: 180.w,
              height: 180.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primary.withAlpha(isDark ? 55 : 35),
                    primary.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),

          // Bubble 1 (Top Left, tilted slightly)
          Positioned(
            top: 14.h,
            left: 8.w,
            child: Transform.rotate(
              angle: -0.04,
              child: _buildBubbleCard(
                cardBg: cardBg,
                borderColor: borderColor,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppAvatar(
                      name: 'Sarah Connor',
                      imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
                      size: 28,
                    ),
                    SizedBox(width: 8.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sarah Connor',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: textCol,
                          ),
                        ),
                        Text(
                          'Sent 4K video clip 🎬',
                          style: TextStyle(fontSize: 10.sp, color: textSub),
                        ),
                      ],
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(25),
                        borderRadius: AppSpacing.radiusXs,
                      ),
                      child: Text(
                        '0:30',
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bubble 2 (Right Side, Accent color themed)
          Positioned(
            top: 86.h,
            right: 8.w,
            child: Transform.rotate(
              angle: 0.03,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                    bottomLeft: Radius.circular(16.r),
                    bottomRight: Radius.circular(4.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withAlpha(80),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      size: 14.r,
                      color: Colors.white70,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'Forwarded instant • 0s lag',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.done_all_rounded,
                      size: 14.r,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bubble 3 (Bottom Left Floating Pill)
          Positioned(
            bottom: 12.h,
            left: 20.w,
            child: _buildBubbleCard(
              cardBg: cardBg,
              borderColor: borderColor,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7.r,
                    height: 7.r,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Text(
                    'Auto-saved to Gallery',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: textCol,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.photo_library_outlined,
                    size: 13.r,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleCard({
    required Color cardBg,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
