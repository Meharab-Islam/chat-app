import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../auth/view_models/auth_view_model.dart';

class ProfilePhotoPickerSheet extends StatelessWidget {
  const ProfilePhotoPickerSheet({super.key});

  static const List<String> presetAvatars = [
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
  ];

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (_) => const ProfilePhotoPickerSheet(),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );

    if (picked != null && context.mounted) {
      final authVM = context.read<AuthViewModel>();
      await authVM.updateProfileImage(picked.path);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _selectPreset(BuildContext context, String url) async {
    final authVM = context.read<AuthViewModel>();
    await authVM.updateProfileImage(url);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preset avatar applied!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkDivider
                        : AppColors.lightDivider,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'Change Profile Photo',
                style: AppTypography.headingSmall(textPrimary),
              ),
              SizedBox(height: 4.h),
              Text(
                'Select from camera, device gallery, or choose an avatar.',
                style: AppTypography.caption(textSecondary),
              ),
              SizedBox(height: 16.h),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: theme.colorScheme.primary,
                    size: 22.r,
                  ),
                ),
                title: Text(
                  'Take Photo',
                  style: AppTypography.bodyMedium(textPrimary),
                ),
                onTap: () => _pickImage(context, ImageSource.camera),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: theme.colorScheme.primary,
                    size: 22.r,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: AppTypography.bodyMedium(textPrimary),
                ),
                onTap: () => _pickImage(context, ImageSource.gallery),
              ),
              SizedBox(height: 12.h),
              Text(
                'CURATED AVATARS',
                style: AppTypography.caption(textSecondary),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                height: 52.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: presetAvatars.length,
                  separatorBuilder: (context, index) => SizedBox(width: 12.w),
                  itemBuilder: (context, index) {
                    final url = presetAvatars[index];
                    return GestureDetector(
                      onTap: () => _selectPreset(context, url),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary.withAlpha(50),
                            width: 1.5,
                          ),
                        ),
                        child: AppCachedImage(
                          imageUrl: url,
                          width: 48.r,
                          height: 48.r,
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}
