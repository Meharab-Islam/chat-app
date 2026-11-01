import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/chat_conversation_model.dart';
import '../../../../data/models/message_model.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_badge.dart';

class ChatTileWidget extends StatelessWidget {
  final ChatConversationModel conversation;
  final String? currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChatTileWidget({
    super.key,
    required this.conversation,
    this.currentUserId,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final peer = conversation.peerUser;
    final lastMsg = conversation.lastMessage;
    final timeStr = lastMsg != null ? _formatTime(lastMsg.timestamp) : '';

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: AppSpacing.radiusMd,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                AppAvatar(
                  imageUrl: peer.avatarUrl,
                  name: peer.name,
                  isOnline: peer.isOnline,
                  size: 50.r,
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              peer.name,
                              style: AppTypography.headingSmall(textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            timeStr,
                            style: AppTypography.caption(textSecondary),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSubtitle(lastMsg, textSecondary),
                          ),
                          if (conversation.unreadCount > 0) ...[
                            SizedBox(width: 8.w),
                            AppBadge(count: conversation.unreadCount),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(MessageModel? message, Color color) {
    if (message == null) return const SizedBox.shrink();

    final isMe = currentUserId != null && message.senderId == currentUserId;
    final isAttachment = message.mediaType != MessageMediaType.none ||
        (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) ||
        message.attachmentUrls.isNotEmpty;

    IconData? mediaIcon;
    String text;

    if (message.isUnsent) {
      text = 'This message was unsent';
    } else if (isAttachment) {
      mediaIcon = Icons.attach_file_rounded;
      text = isMe ? 'You: Attachment' : 'Attachment';
    } else {
      text = isMe && message.text.isNotEmpty ? 'You: ${message.text}' : message.text;
    }

    return Row(
      children: [
        if (mediaIcon != null) ...[
          Icon(mediaIcon, size: 14.r, color: color),
          SizedBox(width: 4.w),
        ],
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall(color),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return DateFormat('h:mm a').format(dt);
    }
    return DateFormat('MMM d').format(dt);
  }
}

