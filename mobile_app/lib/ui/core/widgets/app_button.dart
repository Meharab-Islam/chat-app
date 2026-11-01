import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.leading,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBg = backgroundColor ??
        (isOutlined
            ? Colors.transparent
            : theme.colorScheme.primary);

    final effectiveFg = textColor ??
        (isOutlined
            ? (isDark ? Colors.white : Colors.black87)
            : theme.colorScheme.onPrimary);

    return SizedBox(
      height: 52.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBg,
          foregroundColor: effectiveFg,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.radiusMd,
            side: isOutlined
                ? BorderSide(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  )
                : BorderSide.none,
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
        ),
        child: isLoading
            ? SizedBox(
                width: 20.r,
                height: 20.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    leading!,
                    SizedBox(width: 10.w),
                  ],
                  Text(
                    text,
                    style: AppTypography.buttonText(effectiveFg),
                  ),
                ],
              ),
      ),
    );
  }
}

