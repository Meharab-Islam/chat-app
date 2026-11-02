import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/services/media_service.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/chat_room_view_model.dart';
import '../widgets/chat_input_bar_widget.dart';
import '../widgets/chat_message_list_widget.dart';
import '../widgets/chat_reply_preview_widget.dart';
import '../widgets/chat_room_app_bar_actions.dart';
import '../widgets/group_info_bottom_sheet.dart';
import '../widgets/selected_media_preview_widget.dart';

class ChatRoomView extends StatelessWidget {
  final String conversationId;
  final UserModel peerUser;
  final bool isGroup;
  final int memberCount;

  const ChatRoomView({
    super.key,
    required this.conversationId,
    required this.peerUser,
    this.isGroup = false,
    this.memberCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final authVM = context.read<AuthViewModel>();
    final currentUserId = authVM.currentUser?.id ?? 'me';

    return ChangeNotifierProvider(
      create: (_) => ChatRoomViewModel(
        conversationId: conversationId,
        peerUser: peerUser,
        currentUserId: currentUserId,
        chatRepository: context.read<ChatRepository>(),
        mediaService: context.read<MediaService>(),
      ),
      child: _ChatRoomContent(
        conversationId: conversationId,
        peerUser: peerUser,
        isGroup: isGroup,
        memberCount: memberCount,
      ),
    );
  }
}

class _ChatRoomContent extends StatelessWidget {
  final String conversationId;
  final UserModel peerUser;
  final bool isGroup;
  final int memberCount;

  const _ChatRoomContent({
    required this.conversationId,
    required this.peerUser,
    required this.isGroup,
    required this.memberCount,
  });

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
    final primary = theme.colorScheme.primary;

    final vm = context.watch<ChatRoomViewModel>();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            color: isDark
                ? Colors.white.withAlpha(15)
                : Colors.black.withAlpha(12),
            height: 0.8,
          ),
        ),
        title: vm.isSearching
            ? TextField(
                autofocus: true,
                style: TextStyle(fontSize: 14.sp, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search messages in this chat...',
                  hintStyle: TextStyle(fontSize: 14.sp, color: textSecondary),
                  border: InputBorder.none,
                ),
                onChanged: vm.setSearchQuery,
              )
            : GestureDetector(
                onTap: isGroup
                    ? () => GroupInfoBottomSheet.show(
                        context,
                        conversationId: conversationId,
                        groupName: peerUser.name,
                        groupAvatar: peerUser.avatarUrl,
                        memberCount: memberCount,
                      )
                    : null,
                child: Row(
                  children: [
                    AppAvatar(
                      imageUrl: peerUser.avatarUrl,
                      name: peerUser.name,
                      isOnline: peerUser.isOnline,
                      size: 38.r,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            peerUser.name,
                            style: AppTypography.headingSmall(textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            vm.isPeerTyping
                                ? 'typing...'
                                : (isGroup
                                      ? '${memberCount > 0 ? memberCount : 2} members • Click to edit'
                                      : (peerUser.isOnline
                                            ? 'Online'
                                            : 'Offline')),
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: vm.isPeerTyping
                                  ? Colors.green
                                  : (isGroup
                                        ? primary
                                        : (peerUser.isOnline
                                              ? AppColors.success
                                              : textSecondary)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        actions: [
          ChatRoomAppBarActions(
            conversationId: conversationId,
            peerUser: peerUser,
            isGroup: isGroup,
            memberCount: memberCount,
            vm: vm,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF0D0F15), Color(0xFF090A0E)]
                : const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ChatMessageListWidget(vm: vm),
            ),
            if (vm.replyingTo != null)
              ChatReplyPreviewWidget(
                replyingTo: vm.replyingTo!,
                onCancel: () => vm.setReplyingTo(null),
              ),
            if (vm.selectedMedia.isNotEmpty)
              SelectedMediaPreviewWidget(
                files: vm.selectedMedia,
                onRemove: vm.removeSelectedMedia,
                onClear: vm.clearSelectedMedia,
                onAddMore: vm.pickMedia,
              ),
            ChatInputBarWidget(
              hasSelectedMedia: vm.selectedMedia.isNotEmpty,
              onSendText: (t) => vm.selectedMedia.isNotEmpty
                  ? vm.sendMediaMessage(caption: t)
                  : vm.sendTextMessage(t),
              onPickMedia: vm.pickMedia,
              onPickAudio: vm.pickAudio,
              onSendFiles: vm.pickAndSendFiles,
              onSendVoice: vm.sendVoiceMessage,
            ),
          ],
        ),
      ),
    );
  }
}
