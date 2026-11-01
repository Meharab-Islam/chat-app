import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    required this.width,
    required this.height,
    this.borderRadius,
    this.onTap,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initThumbnail();
  }

  Future<void> _initThumbnail() async {
    try {
      if (widget.videoUrl.startsWith('http://') ||
          widget.videoUrl.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      } else {
        _controller = VideoPlayerController.file(File(widget.videoUrl));
      }
      await _controller!.initialize();
      await _controller!.seekTo(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(8.r);

    return ClipRRect(
      borderRadius: radius,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
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
                  color: const Color(0xFF1E1E1E),
                  child: Center(
                    child: Icon(
                      Icons.videocam_rounded,
                      color: Colors.white38,
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

