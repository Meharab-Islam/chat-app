import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/user_model.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/profile_photo_picker_sheet.dart';
import '../widgets/theme_color_picker_widget.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final authVM = context.watch<AuthViewModel>();
    final settingsVM = context.watch<SettingsViewModel>();
    final user = authVM.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.headingSmall(textPrimary)),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          children: [
            if (user != null) ...[
              _buildProfileCard(context, user, isDark, textPrimary, textSecondary, primary),
              SizedBox(height: 24.h),
            ],
            Text('APPEARANCE', style: AppTypography.caption(textSecondary)),
            SizedBox(height: 8.h),
            _buildThemeModeSelector(context, settingsVM, isDark),
            SizedBox(height: 16.h),
            Text('Accent Color', style: AppTypography.bodySmall(textPrimary)),
            SizedBox(height: 8.h),
            ThemeColorPickerWidget(
              selectedAccent: settingsVM.currentAccent,
              onSelected: settingsVM.setAccentTheme,
            ),
            SizedBox(height: 28.h),
            Text('MEDIA & STORAGE', style: AppTypography.caption(textSecondary)),
            SizedBox(height: 8.h),
            _buildAutoSaveTile(context, settingsVM, isDark, textPrimary, textSecondary),
            SizedBox(height: 36.h),
            _buildSignOutButton(context, authVM),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    UserModel user,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color primary,
  ) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppSpacing.radiusLg,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ProfilePhotoPickerSheet.show(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AppAvatar(imageUrl: user.avatarUrl, name: user.name, size: 58.r),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: EdgeInsets.all(5.r),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        width: 2.r,
                      ),
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12.r),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(user.name, style: AppTypography.headingSmall(textPrimary)),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 18.r, color: primary),
                      tooltip: 'Edit Profile',
                      onPressed: () => EditProfileDialog.show(context),
                    ),
                  ],
                ),
                if (user.status.isNotEmpty) ...[
                  Text(user.status, style: AppTypography.caption(primary)),
                  SizedBox(height: 2.h),
                ],
                Text(user.email, style: AppTypography.bodySmall(textSecondary)),
                SizedBox(height: 4.h),
                GestureDetector(
                  onTap: () => ProfilePhotoPickerSheet.show(context),
                  child: Text(
                    'Change photo',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeSelector(BuildContext context, SettingsViewModel vm, bool isDark) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('Auto')),
      ],
      selected: {vm.themeMode},
      onSelectionChanged: (set) => vm.setThemeMode(set.first),
      style: ButtonStyle(
        side: WidgetStateProperty.all(BorderSide(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        )),
      ),
    );
  }

  Widget _buildAutoSaveTile(BuildContext context, SettingsViewModel vm, bool isDark, Color textPrimary, Color textSecondary) {
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: AppSpacing.radiusMd,
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        title: Text('Auto-save to Gallery', style: AppTypography.bodyMedium(textPrimary)),
        subtitle: Text(
          'Save incoming photos and videos automatically to device photos.',
          style: AppTypography.caption(textSecondary),
        ),
        value: vm.autoSaveMedia,
        activeThumbColor: Theme.of(context).colorScheme.primary,
        onChanged: vm.toggleAutoSaveMedia,
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthViewModel authVM) {
    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
        label: const Text('Sign Out', style: TextStyle(color: AppColors.danger)),
        onPressed: () {
          authVM.signOut();
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
    );
  }
}
