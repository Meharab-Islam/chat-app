import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/models/message_model.dart';

class ChatReplyPreviewWidget extends StatelessWidget {
  final MessageModel replyingTo;
  final VoidCallback onCancel;

  const ChatReplyPreviewWidget({
    super.key,
    required this.replyingTo,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      color: Colors.black12,
      child: Row(
        children: [
          const Icon(Icons.reply, size: 16),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Replying to: ${replyingTo.text}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

