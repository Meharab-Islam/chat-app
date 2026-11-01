import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/auth_hero_mockup.dart';
import '../widgets/google_sign_in_button.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 12.h),
              _buildTopPillBadge(primary),
              SizedBox(height: 16.h),
              const AuthHeroMockup(),
              SizedBox(height: 16.h),
              Text(
                'Connect In Flow',
                style: AppTypography.headingLarge(textPrimary).copyWith(
                  fontSize: 28.sp,
                  letterSpacing: -0.8,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Silky smooth chatting, dynamic themes,\nand instant media sharing without redownloads.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(textSecondary).copyWith(
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16.h),
              _buildFeatureChips(isDark, primary),
              const Spacer(),
              Consumer<AuthViewModel>(
                builder: (context, authVM, _) {
                  return Column(
                    children: [
                      if (authVM.errorMessage != null) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 8.h,
                          ),
                          margin: EdgeInsets.only(bottom: 12.h),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withAlpha(25),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: AppColors.danger.withAlpha(80),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16.r,
                                color: AppColors.danger,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  authVM.errorMessage!,
                                  style: TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      GoogleSignInButton(
                        isLoading: authVM.isLoading,
                        onPressed: () => authVM.signInWithGoogle(),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 14.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 13.r, color: textSecondary),
                  SizedBox(width: 4.w),
                  Text(
                    'Protected with Google Authentication',
                    style: AppTypography.caption(textSecondary),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopPillBadge(Color primary) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: primary.withAlpha(20),
        borderRadius: AppSpacing.radiusFull,
        border: Border.all(color: primary.withAlpha(50), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.r,
            height: 6.r,
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
          Text(
            'FLUID MESSENGER',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChips(bool isDark, Color primary) {
    final chips = ['⚡ 0s Forward', '🎨 Dynamic Palette', '📸 Auto-Gallery'];
    final chipBg = isDark ? const Color(0xFF16181D) : const Color(0xFFF3F4F6);
    final border = isDark ? const Color(0xFF262930) : const Color(0xFFE5E7EB);

    return Wrap(
      spacing: 8.w,
      runSpacing: 6.h,
      alignment: WrapAlignment.center,
      children: chips.map((label) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: AppSpacing.radiusFull,
            border: Border.all(color: border, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            ),
          ),
        );
      }).toList(),
    );
  }
}
