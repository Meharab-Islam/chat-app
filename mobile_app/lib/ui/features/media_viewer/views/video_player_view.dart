import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/services/media_service.dart';
import '../../forward/views/forward_bottom_sheet.dart';

class VideoPlayerView extends StatefulWidget {
  final MessageModel message;

  const VideoPlayerView({super.key, required this.message});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = widget.message.mediaUrl;
    if (url == null) return;

    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await _controller.initialize();
    _controller.setLooping(true);
    _controller.play();

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _downloadVideo() async {
    if (widget.message.mediaUrl == null || _isSaving) return;
    setState(() => _isSaving = true);

    final mediaService = context.read<MediaService>();
    final success = await mediaService.saveVideoToGallery(widget.message.mediaUrl!);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Video saved to gallery!' : 'Failed to save video to gallery.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.forward_rounded),
            tooltip: 'Forward',
            onPressed: () => ForwardBottomSheet.show(context, widget.message),
          ),
          IconButton(
            icon: _isSaving
                ? SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download_rounded),
            tooltip: 'Download to Gallery',
            onPressed: _downloadVideo,
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_controller),
                    _buildControls(),
                  ],
                ),
              )
            : const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black38,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _controller.value.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 26.r,
            ),
            onPressed: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
          ),
          Expanded(
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

