import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../data/models/message_model.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../media_viewer/views/image_viewer_view.dart';

class ImageMessageWidget extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onDownload;

  const ImageMessageWidget({
    super.key,
    required this.message,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final urls = message.attachmentUrls.isNotEmpty
        ? message.attachmentUrls
        : (message.mediaUrl != null ? [message.mediaUrl!] : <String>[]);

    if (urls.isEmpty) return const SizedBox.shrink();

    if (urls.length == 1) {
      return _buildSingleImage(context, urls.first);
    }

    return RepaintBoundary(
      child: Wrap(
        spacing: 4.w,
        runSpacing: 4.h,
        children: urls.map((u) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ImageViewerView(message: message.copyWith(mediaUrl: u)),
                ),
              );
            },
            child: AppCachedImage(
              imageUrl: u,
              width: 110.w,
              height: 110.w,
              fit: BoxFit.cover,
              borderRadius: AppSpacing.radiusSm,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSingleImage(BuildContext context, String url) {
    return RepaintBoundary(
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ImageViewerView(message: message.copyWith(mediaUrl: url)),
                ),
              );
            },
            child: AppCachedImage(
              imageUrl: url,
              width: 240.w,
              height: 200.h,
              fit: BoxFit.cover,
              borderRadius: AppSpacing.radiusMd,
            ),
          ),
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
    );
  }
}
