import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';

class GroupInfoBottomSheet extends StatefulWidget {
  final String conversationId;
  final String groupName;
  final String? groupAvatar;
  final int memberCount;

  const GroupInfoBottomSheet({
    super.key,
    required this.conversationId,
    required this.groupName,
    this.groupAvatar,
    required this.memberCount,
  });

  static void show(
    BuildContext context, {
    required String conversationId,
    required String groupName,
    String? groupAvatar,
    required int memberCount,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroupInfoBottomSheet(
        conversationId: conversationId,
        groupName: groupName,
        groupAvatar: groupAvatar,
        memberCount: memberCount,
      ),
    );
  }

  @override
  State<GroupInfoBottomSheet> createState() => _GroupInfoBottomSheetState();
}

class _GroupInfoBottomSheetState extends State<GroupInfoBottomSheet> {
  late final TextEditingController _nameController;
  File? _selectedAvatarFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.groupName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedAvatarFile = File(picked.path));
    }
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    final repo = context.read<ChatRepository>();
    try {
      await repo.updateGroup(
        widget.conversationId,
        name: name,
        avatarFile: _selectedAvatarFile,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update group: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 25.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131823) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(80),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Group Info & Settings',
                style: AppTypography.headingSmall(textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: _selectedAvatarFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(40.r),
                          child: Image.file(
                            _selectedAvatarFile!,
                            width: 80.r,
                            height: 80.r,
                            fit: BoxFit.cover,
                          ),
                        )
                      : AppAvatar(
                          imageUrl: widget.groupAvatar,
                          name: widget.groupName,
                          size: 80.r,
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: CircleAvatar(
                      radius: 14.r,
                      backgroundColor: primary,
                      child: Icon(
                        Icons.camera_alt,
                        size: 15.r,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: _pickAvatar,
            child: Text(
              'Change Group Photo',
              style: TextStyle(fontSize: 12.sp, color: primary),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _nameController,
            style: TextStyle(
              fontSize: 15.sp,
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Group Name',
              labelStyle: TextStyle(color: textSecondary),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withAlpha(10)
                  : Colors.grey.withAlpha(20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(8)
                  : Colors.grey.withAlpha(15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.people_alt_rounded, size: 20.r, color: primary),
                SizedBox(width: 10.w),
                Text(
                  '${widget.memberCount > 0 ? widget.memberCount : 2} Total Members',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
