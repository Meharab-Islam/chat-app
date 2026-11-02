import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/call_model.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../view_models/call_view_model.dart';

class IncomingCallOverlay extends StatelessWidget {
  final IncomingCallData call;

  const IncomingCallOverlay({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    final isVideo = call.callType == 'video';

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: EdgeInsets.all(16.r),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B).withAlpha(245),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.indigo.withAlpha(120), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(150),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AppAvatar(
                    imageUrl: call.callerAvatar,
                    name: call.callerName,
                    size: 48.r,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          call.callerName,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          call.isGroup
                              ? '${call.chatName} • Incoming ${isVideo ? "Video" : "Audio"} Call'
                              : 'Incoming ${isVideo ? "Video" : "Audio"} Call...',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withAlpha(40),
                        foregroundColor: Colors.redAccent,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: const BorderSide(
                            color: Colors.redAccent,
                            width: 0.8,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.call_end_rounded, size: 18),
                      label: const Text('Decline'),
                      onPressed: () =>
                          context.read<CallViewModel>().rejectCall(),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      icon: Icon(
                        isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                        size: 18,
                      ),
                      label: const Text('Accept'),
                      onPressed: () =>
                          context.read<CallViewModel>().acceptCall(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
