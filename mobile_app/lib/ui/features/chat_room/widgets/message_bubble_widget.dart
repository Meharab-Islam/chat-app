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
import 'message_status_icon.dart';

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
    final primary = theme.colorScheme.primary;

    final bubbleBg = isMe
        ? primary
        : (isDark ? AppColors.darkBubbleReceiver : AppColors.lightBubbleReceiver);
    final textColor = isMe
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final timeColor = isMe
        ? Colors.white.withAlpha(220)
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageActionSheet(context),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 3.5.h),
          constraints: BoxConstraints(maxWidth: 285.w),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: message.isUnsent ? Colors.grey.withAlpha(50) : (isMe ? null : bubbleBg),
            gradient: message.isUnsent
                ? null
                : (isMe
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primary, primary.withAlpha(225)],
                      )
                    : (isDark
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF222938), Color(0xFF181D28)],
                          )
                        : null)),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18.r),
              topRight: Radius.circular(18.r),
              bottomLeft: Radius.circular(isMe ? 18.r : 4.r),
              bottomRight: Radius.circular(isMe ? 4.r : 18.r),
            ),
            border: isMe
                ? null
                : Border.all(
                    color: isDark ? const Color(0xFF384358) : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
            boxShadow: [
              BoxShadow(
                color: isMe
                    ? primary.withAlpha(isDark ? 55 : 60)
                    : (isDark ? Colors.black.withAlpha(90) : const Color(0xFF0F172A).withAlpha(18)),
                blurRadius: isDark ? 8 : 7,
                offset: const Offset(0, 2.5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.replyToText != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                  margin: EdgeInsets.only(bottom: 6.h),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.black.withAlpha(28)
                        : (isDark ? Colors.white.withAlpha(12) : primary.withAlpha(12)),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border(
                      left: BorderSide(
                        color: isMe ? Colors.white70 : primary,
                        width: 3.w,
                      ),
                    ),
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
              Container(
                margin: EdgeInsets.only(top: 2.h),
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.black.withAlpha(35)
                      : (isDark ? Colors.white.withAlpha(14) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(message.timestamp),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: timeColor,
                      ),
                    ),
                    if (isMe && !message.isUnsent) ...[
                      SizedBox(width: 4.w),
                      MessageStatusIcon(status: message.status, isMe: isMe),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                onTap: () { Navigator.pop(ctx); onReply?.call(); },
              ),
            ListTile(
              leading: const Icon(Icons.forward_rounded),
              title: const Text('Forward'),
              onTap: () { Navigator.pop(ctx); onForward(); },
            ),
            if (isMe && !message.isUnsent && onUnsend != null)
              ListTile(
                leading: const Icon(Icons.undo, color: Colors.red),
                title: const Text('Unsend', style: TextStyle(color: Colors.red)),
                onTap: () { Navigator.pop(ctx); onUnsend?.call(); },
              ),
            if (onDeleteForMe != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete for me'),
                onTap: () { Navigator.pop(ctx); onDeleteForMe?.call(); },
              ),
          ],
        ),
      ),
    );
  }
}
