import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/design_system/app_spacing.dart';

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final innerBg = isDark ? const Color(0xFF14161A) : Colors.white;
    final titleCol = isDark ? Colors.white : const Color(0xFF111827);
    final subCol = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: widget.isLoading ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isLoading
            ? null
            : (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              },
        onTapCancel: () => setState(() => _isPressed = false),
        child: Container(
          height: 60.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.radiusXl,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4285F4), // Google Blue
                Color(0xFFEA4335), // Google Red
                Color(0xFFFBBC05), // Google Yellow
                Color(0xFF34A853), // Google Green
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4285F4).withAlpha(isDark ? 38 : 45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(1.6.r),
          child: Container(
            decoration: BoxDecoration(
              color: innerBg,
              borderRadius: BorderRadius.circular(22.4.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: widget.isLoading
                ? Center(
                    child: SizedBox(
                      width: 22.r,
                      height: 22.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(titleCol),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 38.r,
                        height: 38.r,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2127) : const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(8.r),
                        child: const _GoogleLogoGlyph(),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: titleCol,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Fast & Secure One-Tap Login',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w400,
                                color: subCol,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32.r,
                        height: 32.r,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F232B) : const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16.r,
                          color: isDark ? Colors.white70 : const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoGlyph extends StatelessWidget {
  const _GoogleLogoGlyph();

  @override
  Widget build(BuildContext context) {
    return Image.network(
      'https://fonts.gstatic.com/s/i/productlogos/googleg/v6/24px.svg',
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.g_mobiledata_rounded,
        size: 22,
        color: Color(0xFF4285F4),
      ),
    );
  }
}
