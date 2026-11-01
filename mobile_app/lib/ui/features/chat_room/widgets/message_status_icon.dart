import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MessageStatusIcon extends StatelessWidget {
  final String status;
  final bool isMe;

  const MessageStatusIcon({
    super.key,
    required this.status,
    this.isMe = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isMe) return const SizedBox.shrink();

    switch (status.toLowerCase()) {
      case 'sending':
        return SizedBox(
          width: 12.r,
          height: 12.r,
          child: const CircularProgressIndicator(
            strokeWidth: 1.6,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        );
      case 'sent':
        return Icon(
          Icons.check_rounded,
          size: 14.sp,
          color: Colors.white.withAlpha(200),
        );
      case 'delivered':
        return Icon(
          Icons.done_all_rounded,
          size: 15.sp,
          color: Colors.white,
        );
      case 'read':
        return Icon(
          Icons.done_all_rounded,
          size: 15.sp,
          color: const Color(0xFF00E5FF),
        );
      case 'failed':
        return Icon(
          Icons.error_outline_rounded,
          size: 14.sp,
          color: const Color(0xFFFF5252),
        );
      default:
        return Icon(
          Icons.check_rounded,
          size: 14.sp,
          color: Colors.white.withAlpha(180),
        );
    }
  }
}

