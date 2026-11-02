import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../chat_room/views/chat_room_view.dart';
import 'create_group_dialog.dart';

class NewChatSheet extends StatefulWidget {
  const NewChatSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewChatSheet(),
    );
  }

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _users = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _performSearch(query),
    );
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    final repo = context.read<ChatRepository>();
    final results = await repo.searchUsers(query.trim());
    if (mounted) {
      setState(() {
        _users = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _startDirectChat(UserModel user) async {
    final repo = context.read<ChatRepository>();
    final chat = await repo.createDirectChat(user.id);
    if (mounted && chat != null) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomView(conversationId: chat.id, peerUser: user),
        ),
      );
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
      height: 0.85.sh,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Conversation',
                  style: AppTypography.headingSmall(textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search people by name or email...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.radiusMd,
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 12.h,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.group_add_rounded, color: primary, size: 22.r),
            ),
            title: Text(
              'New Group',
              style: AppTypography.bodyMedium(textPrimary),
            ),
            subtitle: Text(
              'Create a group chat with friends',
              style: AppTypography.caption(textSecondary),
            ),
            onTap: () {
              Navigator.pop(context);
              CreateGroupDialog.show(context);
            },
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                ? Center(
                    child: Text(
                      'No users found',
                      style: AppTypography.bodySmall(textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        leading: AppAvatar(
                          imageUrl: user.avatarUrl,
                          name: user.name,
                          isOnline: user.isOnline,
                          size: 44.r,
                        ),
                        title: Text(
                          user.name,
                          style: AppTypography.bodyMedium(textPrimary),
                        ),
                        subtitle: Text(
                          user.status.isNotEmpty ? user.status : user.email,
                          style: AppTypography.caption(textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20.r,
                          color: primary,
                        ),
                        onTap: () => _startDirectChat(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
