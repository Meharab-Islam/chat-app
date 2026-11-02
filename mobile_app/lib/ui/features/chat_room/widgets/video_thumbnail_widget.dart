import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

import '../../../../data/services/video_thumbnail_cache.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final ValueChanged<double>? onAspectRatioResolved;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    required this.width,
    required this.height,
    this.borderRadius,
    this.onTap,
    this.onAspectRatioResolved,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initThumbnail();
  }

  @override
  void didUpdateWidget(VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _initThumbnail();
    }
  }

  Future<void> _initThumbnail() async {
    final cached = VideoThumbnailCache.getInitialized(widget.videoUrl);
    if (cached != null) {
      _controller = cached;
      _isInitialized = true;
      if (cached.value.aspectRatio > 0) {
        widget.onAspectRatioResolved?.call(cached.value.aspectRatio);
      }
      return;
    }

    final ctrl = await VideoThumbnailCache.getOrInit(
      widget.videoUrl,
      onRatio: widget.onAspectRatioResolved,
    );

    if (mounted && ctrl != null && ctrl.value.isInitialized) {
      setState(() {
        _controller = ctrl;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final radius = widget.borderRadius ?? BorderRadius.circular(8.r);

    return ClipRRect(
      borderRadius: radius,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFF16181D),
            borderRadius: radius,
          ),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              if (_isInitialized && _controller != null)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _controller!.value.size.width > 0
                        ? _controller!.value.size.width
                        : widget.width,
                    height: _controller!.value.size.height > 0
                        ? _controller!.value.size.height
                        : widget.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                Container(
                  color: const Color(0xFF1E2028),
                  child: Center(
                    child: Icon(
                      Icons.videocam_rounded,
                      color: Colors.white24,
                      size: 28.r,
                    ),
                  ),
                ),
              Center(
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(140),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24.r,
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
