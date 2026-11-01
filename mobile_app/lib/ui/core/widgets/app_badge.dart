import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';

class AppBadge extends StatelessWidget {
  final int count;

  const AppBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final text = count > 99 ? '99+' : count.toString();
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      constraints: BoxConstraints(minWidth: 18.r, minHeight: 18.r),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: AppSpacing.radiusFull,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AppForwardedTag extends StatelessWidget {
  final String? originalSenderName;

  const AppForwardedTag({super.key, this.originalSenderName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.reply_rounded, size: 13.r, color: fg),
        SizedBox(width: 4.w),
        Text(
          originalSenderName != null ? 'Forwarded from $originalSenderName' : 'Forwarded',
          style: TextStyle(
            fontSize: 11.sp,
            fontStyle: FontStyle.italic,
            color: fg,
          ),
        ),
      ],
    );
  }
}

