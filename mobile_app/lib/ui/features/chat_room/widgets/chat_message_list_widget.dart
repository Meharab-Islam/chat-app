import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/models/message_model.dart';
import '../../forward/views/forward_bottom_sheet.dart';
import '../view_models/chat_room_view_model.dart';
import 'chat_date_separator.dart';
import 'message_bubble_widget.dart';

class ChatMessageListWidget extends StatelessWidget {
  final ChatRoomViewModel vm;

  const ChatMessageListWidget({super.key, required this.vm});

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _handleDownload(
    BuildContext context,
    ChatRoomViewModel vm,
    MessageModel msg,
  ) async {
    final ok = await vm.downloadMediaToGallery(msg);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Saved to gallery!' : 'Failed to save.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 10.h),
      itemCount: vm.messages.length,
      itemBuilder: (context, index) {
        final msg = vm.messages[index];
        final isMe = msg.senderId == vm.currentUserId;
        final showDate = index == vm.messages.length - 1 ||
            !_isSameDay(
              msg.timestamp,
              vm.messages[index + 1].timestamp,
            );

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
    );
  }
}
