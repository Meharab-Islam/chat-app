import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../data/models/message_model.dart';
import '../../../../data/services/video_thumbnail_cache.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../media_viewer/views/image_viewer_view.dart';
import '../../media_viewer/views/video_player_view.dart';
import 'video_thumbnail_widget.dart';

class SingleMediaMessageWidget extends StatefulWidget {
  final MessageModel message;
  final String url;
  final bool isVideo;
  final VoidCallback onDownload;

  const SingleMediaMessageWidget({
    super.key,
    required this.message,
    required this.url,
    required this.isVideo,
    required this.onDownload,
  });

  @override
  State<SingleMediaMessageWidget> createState() =>
      _SingleMediaMessageWidgetState();
}

class _SingleMediaMessageWidgetState extends State<SingleMediaMessageWidget> {
  static final Map<String, double> _aspectRatioCache = {};

  double? _aspectRatio;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _aspectRatio = VideoThumbnailCache.getCachedRatio(widget.url);
    } else {
      _aspectRatio = _aspectRatioCache[widget.url];
      if (_aspectRatio == null) _resolveImageRatio();
    }
  }

  void _resolveImageRatio() {
    try {
      final ImageProvider provider =
          widget.url.startsWith('http://') || widget.url.startsWith('https://')
          ? CachedNetworkImageProvider(widget.url)
          : FileImage(File(widget.url)) as ImageProvider;
      _imageStream = provider.resolve(const ImageConfiguration());
      _imageListener = ImageStreamListener((ImageInfo info, bool _) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        if (h > 0 && mounted) {
          final ratio = w / h;
          _aspectRatioCache[widget.url] = ratio;
          setState(() => _aspectRatio = ratio);
        }
      }, onError: (err, stack) {});
      _imageStream?.addListener(_imageListener!);
    } catch (_) {}
  }

  @override
  void didUpdateWidget(SingleMediaMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      if (_imageStream != null && _imageListener != null) {
        _imageStream?.removeListener(_imageListener!);
      }
      if (widget.isVideo) {
        _aspectRatio = VideoThumbnailCache.getCachedRatio(widget.url);
      } else {
        _aspectRatio = _aspectRatioCache[widget.url];
        if (_aspectRatio == null) _resolveImageRatio();
      }
    }
  }

  @override
  void dispose() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream?.removeListener(_imageListener!);
    }
    super.dispose();
  }

  Size _calculateSize(double ratio) {
    final r = ratio.clamp(0.52, 2.2);
    final maxW = 255.w;
    final maxH = 310.h;
    final minW = 160.w;
    final minH = 130.h;

    if (r < 1.0) {
      final h = maxH;
      final w = (h * r).clamp(minW, maxW);
      final adjustedH = (w / r).clamp(minH, maxH);
      return Size(w, adjustedH);
    } else {
      final w = maxW;
      final h = (w / r).clamp(minH, maxH);
      return Size(w, h);
    }
  }

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => widget.isVideo
            ? VideoPlayerView(
                message: widget.message.copyWith(mediaUrl: widget.url),
              )
            : ImageViewerView(
                message: widget.message.copyWith(mediaUrl: widget.url),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _aspectRatio ?? (widget.isVideo ? (16 / 9) : (4 / 3));
    final size = _calculateSize(ratio);
    final radius = BorderRadius.circular(14.r);

    return RepaintBoundary(
      child: Stack(
        children: [
          if (widget.isVideo)
            VideoThumbnailWidget(
              videoUrl: widget.url,
              width: size.width,
              height: size.height,
              borderRadius: radius,
              onAspectRatioResolved: (r) {
                if (mounted && _aspectRatio != r && r > 0) {
                  _aspectRatioCache[widget.url] = r;
                  setState(() => _aspectRatio = r);
                }
              },
              onTap: () => _open(context),
            )
          else
            GestureDetector(
              onTap: () => _open(context),
              child: AppCachedImage(
                imageUrl: widget.url,
                width: size.width,
                height: size.height,
                fit: BoxFit.cover,
                borderRadius: radius,
              ),
            ),
          Positioned(
            top: 8.h,
            right: 8.w,
            child: GestureDetector(
              onTap: widget.onDownload,
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
          if (widget.isVideo && widget.message.durationSeconds != null)
            Positioned(
              bottom: 8.h,
              left: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(160),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '${widget.message.durationSeconds}s',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
