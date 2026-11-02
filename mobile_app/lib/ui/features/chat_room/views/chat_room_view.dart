import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/services/media_service.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../forward/views/forward_bottom_sheet.dart';
import '../view_models/chat_room_view_model.dart';
import '../widgets/chat_date_separator.dart';
import '../widgets/chat_input_bar_widget.dart';
import '../widgets/group_info_bottom_sheet.dart';
import '../widgets/message_bubble_widget.dart';
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
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
            color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(12),
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
                onTap: isGroup ? () => GroupInfoBottomSheet.show(context, conversationId: conversationId, groupName: peerUser.name, groupAvatar: peerUser.avatarUrl, memberCount: memberCount) : null,
                child: Row(
                  children: [
                    AppAvatar(imageUrl: peerUser.avatarUrl, name: peerUser.name, isOnline: peerUser.isOnline, size: 38.r),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(peerUser.name, style: AppTypography.headingSmall(textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            vm.isPeerTyping ? 'typing...' : (isGroup ? '${memberCount > 0 ? memberCount : 2} members • Click to edit' : (peerUser.isOnline ? 'Online' : 'Offline')),
                            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: vm.isPeerTyping ? Colors.green : (isGroup ? primary : (peerUser.isOnline ? AppColors.success : textSecondary))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        actions: [
          if (isGroup && !vm.isSearching)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              tooltip: 'Group Settings',
              onPressed: () => GroupInfoBottomSheet.show(context, conversationId: conversationId, groupName: peerUser.name, groupAvatar: peerUser.avatarUrl, memberCount: memberCount),
            ),
          IconButton(
            icon: Icon(vm.isSearching ? Icons.close : Icons.search_rounded),
            tooltip: vm.isSearching ? 'Close Search' : 'Search in Conversation',
            onPressed: () => vm.toggleSearch(!vm.isSearching),
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
              child: ListView.builder(
                reverse: true,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                itemCount: vm.messages.length,
                itemBuilder: (context, index) {
                  final msg = vm.messages[index];
                  final isMe = msg.senderId == vm.currentUserId;
                  final showDate = index == vm.messages.length - 1 ||
                      !_isSameDay(msg.timestamp, vm.messages[index + 1].timestamp);

                  final bubble = MessageBubbleWidget(
                    message: msg,
                    isMe: isMe,
                    onForward: () => ForwardBottomSheet.show(context, msg),
                    onDownload: () => _handleDownload(context, vm, msg),
                    onReply: () => vm.setReplyingTo(msg),
                    onReact: (emoji) => vm.reactToMessage(msg.id, emoji),
                    onUnsend: () => vm.unsendMessage(msg.id),
                    onDeleteForMe: () => vm.deleteForMe(msg.id),
                  );

                  if (showDate) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ChatDateSeparator(date: msg.timestamp),
                        bubble,
                      ],
                    );
                  }
                  return bubble;
                },
              ),
            ),
          if (vm.replyingTo != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              color: Colors.black12,
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text('Replying to: ${vm.replyingTo!.text}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp)),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => vm.setReplyingTo(null)),
                ],
              ),
            ),
          if (vm.selectedMedia.isNotEmpty)
            SelectedMediaPreviewWidget(
              files: vm.selectedMedia,
              onRemove: vm.removeSelectedMedia,
              onClear: vm.clearSelectedMedia,
              onAddMore: vm.pickMixedMedia,
            ),
          ChatInputBarWidget(
            hasSelectedMedia: vm.selectedMedia.isNotEmpty,
            onSendText: (t) => vm.selectedMedia.isNotEmpty ? vm.sendMediaMessage(caption: t) : vm.sendTextMessage(t),
            onPickMedia: vm.pickMedia,
            onPickMixedMedia: vm.pickMixedMedia,
            onPickAudio: vm.pickAudio,
            onSendFiles: vm.pickAndSendFiles,
            onSendVoice: vm.sendVoiceMessage,
          ),
        ],
      ),
    ),
    );
  }

  void _handleDownload(BuildContext context, ChatRoomViewModel vm, MessageModel msg) async {
    final ok = await vm.downloadMediaToGallery(msg);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Saved to gallery!' : 'Failed to save.'), behavior: SnackBarBehavior.floating),
      );
    }
  }
}
