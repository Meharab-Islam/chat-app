import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/message_model.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/widgets/app_badge.dart';
import 'audio_message_widget.dart';
import 'file_message_widget.dart';
import 'media_grid_message_widget.dart';

class MessageBubbleWidget extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback onForward;
  final VoidCallback onDownload;
  final Function(String emoji)? onReact;
  final VoidCallback? onReply;
  final VoidCallback? onUnsend;
  final VoidCallback? onDeleteForMe;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.isMe,
    required this.onForward,
    required this.onDownload,
    this.onReact,
    this.onReply,
    this.onUnsend,
    this.onDeleteForMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bubbleBg = isMe
        ? theme.colorScheme.primary
        : (isDark ? AppColors.darkBubbleReceiver : AppColors.lightBubbleReceiver);
    final textColor = isMe
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final timeColor = isMe
        ? Colors.white.withAlpha(200)
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageActionSheet(context),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          constraints: BoxConstraints(maxWidth: 280.w),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: message.isUnsent ? Colors.grey.withAlpha(50) : bubbleBg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
              bottomRight: Radius.circular(isMe ? 4.r : 16.r),
            ),
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.replyToText != null) ...[
                Container(
                  padding: EdgeInsets.all(6.r),
                  margin: EdgeInsets.only(bottom: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    message.replyToText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.sp, fontStyle: FontStyle.italic, color: textColor),
                  ),
                ),
              ],
              if (message.isForwarded) ...[
                AppForwardedTag(originalSenderName: message.originalSenderName),
                SizedBox(height: 4.h),
              ],
              if ((message.mediaType.isImage || message.mediaType.isVideo) && !message.isUnsent) ...[
                MediaGridMessageWidget(message: message, onDownload: onDownload),
                if (message.text.isNotEmpty) SizedBox(height: 4.h),
              ] else if (message.mediaType.isAudio && !message.isUnsent && message.mediaUrl != null) ...[
                AudioMessageWidget(audioUrl: message.mediaUrl!, isMe: isMe),
                if (message.text.isNotEmpty) SizedBox(height: 4.h),
              ] else if (message.mediaType.isDocumentOrFile && !message.isUnsent) ...[
                FileMessageWidget(message: message, isMe: isMe),
                if (message.text.isNotEmpty) SizedBox(height: 4.h),
              ],
              if (message.isUnsent || message.text.isNotEmpty) ...[
                Text(
                  message.isUnsent
                      ? (isMe ? 'Unsent by you' : 'This message was unsent')
                      : message.text,
                  style: message.isUnsent
                      ? TextStyle(fontStyle: FontStyle.italic, color: timeColor, fontSize: 13.sp)
                      : AppTypography.bodyMedium(textColor),
                ),
                SizedBox(height: 2.h),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: TextStyle(fontSize: 10.sp, color: timeColor),
                  ),
                  if (isMe && !message.isUnsent) ...[
                    SizedBox(width: 4.w),
                    _buildStatusIcon(message.status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    if (status == 'sending') {
      return SizedBox(
        width: 12.r,
        height: 12.r,
        child: const CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
        ),
      );
    } else if (status == 'read') {
      return Icon(Icons.done_all, size: 14.sp, color: Colors.cyanAccent);
    } else if (status == 'delivered') {
      return Icon(Icons.done_all, size: 14.sp, color: Colors.white70);
    } else if (status == 'failed') {
      return Icon(Icons.error_outline, size: 14.sp, color: Colors.redAccent);
    }
    return Icon(Icons.done, size: 14.sp, color: Colors.white70);
  }

  void _showMessageActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['👍', '❤️', '😂', '😮', '😢', '🔥'].map((emoji) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      onReact?.call(emoji);
                    },
                    child: Text(emoji, style: TextStyle(fontSize: 26.sp)),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(ctx);
                  onReply?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.forward_rounded),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(ctx);
                onForward();
              },
            ),
            if (isMe && !message.isUnsent && onUnsend != null)
              ListTile(
                leading: const Icon(Icons.undo, color: Colors.red),
                title: const Text('Unsend', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  onUnsend?.call();
                },
              ),
            if (onDeleteForMe != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete for me'),
                onTap: () {
                  Navigator.pop(ctx);
                  onDeleteForMe?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}
