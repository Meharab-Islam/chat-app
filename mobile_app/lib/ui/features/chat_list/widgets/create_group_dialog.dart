import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../chat_room/views/chat_room_view.dart';

class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const CreateGroupDialog(),
    );
  }

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  List<UserModel> _availableUsers = [];
  bool _isLoading = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final repo = context.read<ChatRepository>();
    final users = await repo.searchUsers('a');
    if (mounted) {
      setState(() {
        _availableUsers = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCreateGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one member')),
      );
      return;
    }

    setState(() => _isCreating = true);
    final repo = context.read<ChatRepository>();
    final groupChat = await repo.createGroupChat(
      name,
      _selectedUserIds.toList(),
    );

    if (mounted) {
      setState(() => _isCreating = false);
      if (groupChat != null) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomView(
              conversationId: groupChat.id,
              peerUser: groupChat.peerUser,
              isGroup: true,
              memberCount: groupChat.memberCount > 0
                  ? groupChat.memberCount
                  : _selectedUserIds.length + 1,
            ),
          ),
        );
      }
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

    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusLg),
      title: Text(
        'New Group Chat',
        style: AppTypography.headingSmall(textPrimary),
      ),
      content: SizedBox(
        width: 0.85.sw,
        height: 0.55.sh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter group name...',
                prefixIcon: const Icon(Icons.groups_outlined),
                border: OutlineInputBorder(borderRadius: AppSpacing.radiusMd),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Select Members (${_selectedUserIds.length} selected):',
              style: AppTypography.caption(textSecondary),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _availableUsers.isEmpty
                  ? Center(
                      child: Text(
                        'No users found',
                        style: AppTypography.caption(textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _availableUsers.length,
                      itemBuilder: (context, index) {
                        final user = _availableUsers[index];
                        final isSelected = _selectedUserIds.contains(user.id);
                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: primary,
                          contentPadding: EdgeInsets.zero,
                          secondary: AppAvatar(
                            imageUrl: user.avatarUrl,
                            name: user.name,
                            size: 36.r,
                          ),
                          title: Text(
                            user.name,
                            style: AppTypography.bodySmall(textPrimary),
                          ),
                          subtitle: Text(
                            user.email,
                            style: AppTypography.caption(textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedUserIds.add(user.id);
                              } else {
                                _selectedUserIds.remove(user.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: textSecondary)),
        ),
        AppButton(
          text: 'Create',
          isLoading: _isCreating,
          onPressed: _handleCreateGroup,
        ),
      ],
    );
  }
}
