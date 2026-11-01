import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/models/message_model.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../media_viewer/views/image_viewer_view.dart';
import '../../media_viewer/views/video_player_view.dart';
import 'video_thumbnail_widget.dart';

class MediaGridMessageWidget extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onDownload;

  const MediaGridMessageWidget({
    super.key,
    required this.message,
    required this.onDownload,
  });

  bool _isVideo(String url) {
    final l = url.toLowerCase();
    return l.endsWith('.mp4') || l.endsWith('.mov') || l.endsWith('.mkv') || l.endsWith('.webm') || l.endsWith('.avi');
  }

  void _open(BuildContext context, String url) {
    final isVid = _isVideo(url) || message.mediaType.isVideo;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isVid
            ? VideoPlayerView(message: message.copyWith(mediaUrl: url))
            : ImageViewerView(message: message.copyWith(mediaUrl: url)),
      ),
    );
  }

  Widget _buildTile(BuildContext context, String url, double w, double h, {BorderRadius? radius}) {
    final r = radius ?? AppSpacing.radiusSm;
    final isVid = _isVideo(url) || (message.mediaType.isVideo && message.attachmentUrls.length <= 1);
    if (isVid) {
      return VideoThumbnailWidget(
        videoUrl: url,
        width: w,
        height: h,
        borderRadius: r,
        onTap: () => _open(context, url),
      );
    }
    return GestureDetector(
      onTap: () => _open(context, url),
      child: AppCachedImage(imageUrl: url, width: w, height: h, fit: BoxFit.cover, borderRadius: r),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = message.attachmentUrls.isNotEmpty
        ? message.attachmentUrls
        : (message.mediaUrl != null ? [message.mediaUrl!] : <String>[]);

    if (urls.isEmpty) return const SizedBox.shrink();
    final total = urls.length;

    if (total == 1) {
      return RepaintBoundary(
        child: Stack(
          children: [
            _buildTile(context, urls.first, 240.w, 180.h, radius: AppSpacing.radiusMd),
            Positioned(top: 8.h, right: 8.w, child: _buildDownloadBtn()),
          ],
        ),
      );
    } else if (total == 2) {
      return RepaintBoundary(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTile(context, urls[0], 118.w, 120.h),
            SizedBox(width: 4.w),
            _buildTile(context, urls[1], 118.w, 120.h),
          ],
        ),
      );
    } else if (total == 3) {
      return RepaintBoundary(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTile(context, urls[0], 118.w, 164.h),
            SizedBox(width: 4.w),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTile(context, urls[1], 118.w, 80.h),
                SizedBox(height: 4.h),
                _buildTile(context, urls[2], 118.w, 80.h),
              ],
            ),
          ],
        ),
      );
    }

    // 4 or 4+ items: 3 proper + 4th with remaining overlay
    final showOverlay = total > 4;
    final remaining = total - 3;

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTile(context, urls[0], 118.w, 105.h),
              SizedBox(width: 4.w),
              _buildTile(context, urls[1], 118.w, 105.h),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTile(context, urls[2], 118.w, 105.h),
              SizedBox(width: 4.w),
              showOverlay
                  ? GestureDetector(
                      onTap: () => _open(context, urls[3]),
                      child: SizedBox(
                        width: 118.w,
                        height: 105.h,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildTile(context, urls[3], 118.w, 105.h),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(160),
                                borderRadius: AppSpacing.radiusSm,
                              ),
                              child: Center(
                                child: Text(
                                  '+$remaining',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildTile(context, urls[3], 118.w, 105.h),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadBtn() {
    return GestureDetector(
      onTap: onDownload,
      child: Container(
        padding: EdgeInsets.all(6.r),
        decoration: BoxDecoration(color: Colors.black.withAlpha(140), shape: BoxShape.circle),
        child: Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 16.r),
      ),
    );
  }
}
