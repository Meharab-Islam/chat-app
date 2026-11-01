import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/view_models/auth_view_model.dart';

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const EditProfileDialog(),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _statusController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _statusController = TextEditingController(text: user?.status ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final status = _statusController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    final authVM = context.read<AuthViewModel>();
    final success = await authVM.updateProfileInfo(name: name, status: status);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authVM.errorMessage ?? 'Failed to update profile'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusLg),
      title: Text('Edit Profile', style: AppTypography.headingSmall(textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Display Name', style: AppTypography.caption(textSecondary)),
            SizedBox(height: 6.h),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: AppSpacing.radiusMd),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              ),
            ),
            SizedBox(height: 16.h),
            Text('Status / About', style: AppTypography.caption(textSecondary)),
            SizedBox(height: 6.h),
            TextField(
              controller: _statusController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Available, At work, In a meeting...',
                prefixIcon: const Icon(Icons.info_outline),
                border: OutlineInputBorder(borderRadius: AppSpacing.radiusMd),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: textSecondary)),
        ),
        AppButton(
          text: 'Save',
          isLoading: _isSaving,
          onPressed: _handleSave,
        ),
      ],
    );
  }
}
