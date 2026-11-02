import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/chat_conversation_model.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../chat_room/views/chat_room_view.dart';
import '../../settings/views/settings_view.dart';
import '../view_models/chat_list_view_model.dart';
import '../widgets/chat_filter_chips.dart';
import '../widgets/chat_search_bar.dart';
import '../widgets/chat_tile_widget.dart';
import '../widgets/new_chat_sheet.dart';

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

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

    final authVM = context.watch<AuthViewModel>();
    final currentUser = authVM.currentUser;
    final userName = currentUser?.name.split(' ').first ?? 'Friend';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(
              context,
              userName,
              currentUser,
              textPrimary,
              textSecondary,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 10.h),
              child: const ChatSearchBar(),
            ),
            Consumer<ChatListViewModel>(
              builder: (context, vm, _) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: ChatFilterChips(
                    activeFilter: vm.activeFilter,
                    onFilterSelected: vm.setActiveFilter,
                  ),
                );
              },
            ),
            Expanded(
              child: Consumer<ChatListViewModel>(
                builder: (context, vm, _) {
                  final list = vm.conversations;
                  return RefreshIndicator(
                    onRefresh: () => vm.loadConversations(),
                    child: list.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            children: [
                              SizedBox(height: 120.h),
                              _buildEmptyState(textSecondary),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: list.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              indent: 80.w,
                              endIndent: 16.w,
                              color: isDark
                                  ? AppColors.darkDivider
                                  : AppColors.lightDivider,
                            ),
                            itemBuilder: (context, index) {
                              final item = list[index];
                              return ChatTileWidget(
                                conversation: item,
                                currentUserId: vm.currentUserId,
                                onTap: () {
                                  vm.markChatAsRead(item.id);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatRoomView(
                                        conversationId: item.id,
                                        peerUser: item.peerUser,
                                        isGroup: item.isGroup,
                                        memberCount: item.memberCount,
                                      ),
                                    ),
                                  );
                                },
                                onLongPress: () =>
                                    _showOptions(context, vm, item),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => NewChatSheet.show(context),
        backgroundColor: primary,
        elevation: 3,
        shape: const CircleBorder(),
        tooltip: 'New Chat',
        child: const Icon(
          Icons.edit_note_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  void _showOptions(
    BuildContext context,
    ChatListViewModel vm,
    ChatConversationModel item,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.mark_chat_read_outlined),
              title: const Text('Mark as read'),
              onTap: () {
                Navigator.pop(ctx);
                vm.markChatAsRead(item.id);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
              ),
              title: const Text(
                'Delete chat',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, vm, item.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ChatListViewModel vm,
    String chatId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Conversation?'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.deleteConversation(chatId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(
    BuildContext context,
    String userName,
    dynamic currentUser,
    Color textPrimary,
    Color textSecondary,
  ) {
    final vm = context.watch<ChatListViewModel>();
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $userName 👋',
                style: AppTypography.caption(textSecondary)
                    .copyWith(fontSize: 12.sp, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 2.h),
              Text(
                'Messages',
                style: AppTypography.headingLarge(textPrimary)
                    .copyWith(fontSize: 26.sp, letterSpacing: -0.8),
              ),
            ],
          ),
          Row(
            children: [
              if (vm.totalUnreadCount > 0)
                IconButton(
                  icon: const Icon(Icons.done_all_rounded),
                  tooltip: 'Mark all as read',
                  onPressed: () => vm.markAllAsRead(),
                ),
              IconButton(
                icon: Icon(Icons.tune_rounded, size: 22.r, color: textPrimary),
                tooltip: 'Settings & Theme',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsView()),
                  );
                },
              ),
              if (currentUser != null) ...[
                SizedBox(width: 4.w),
                AppAvatar(
                  imageUrl: currentUser.avatarUrl,
                  name: currentUser.name,
                  size: 38.r,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsView()),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48.r,
            color: textSecondary.withAlpha(120),
          ),
          SizedBox(height: 12.h),
          Text(
            'No conversations found',
            style: AppTypography.bodyMedium(textSecondary),
          ),
        ],
      ),
    );
  }
}
