import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../data/models/message_model.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../media_viewer/views/video_player_view.dart';

class VideoMessageWidget extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onDownload;

  const VideoMessageWidget({
    super.key,
    required this.message,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerView(message: message),
            ),
          );
        },
        child: Container(
          width: 240.w,
          height: 160.h,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: AppSpacing.radiusMd,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Play icon glyph
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30.r,
                  ),
                ),
              ),
              // Duration Tag
              if (message.durationSeconds != null)
                Positioned(
                  bottom: 8.h,
                  left: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: AppSpacing.radiusXs,
                    ),
                    child: Text(
                      '${message.durationSeconds}s',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              // Download Button
              Positioned(
                top: 8.h,
                right: 8.w,
                child: GestureDetector(
                  onTap: onDownload,
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(140),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      color: Colors.white,
                      size: 16.r,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
