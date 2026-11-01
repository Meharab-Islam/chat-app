import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AudioMessageWidget extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const AudioMessageWidget({
    super.key,
    required this.audioUrl,
    required this.isMe,
  });

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
    } else {
      if (widget.audioUrl.startsWith('http://') || widget.audioUrl.startsWith('https://')) {
        await _player.play(UrlSource(widget.audioUrl));
      } else {
        await _player.play(DeviceFileSource(widget.audioUrl));
      }
    }
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  static const List<double> _waveHeights = [
    8, 14, 20, 12, 24, 18, 10, 22, 26, 16, 20, 10,
    18, 24, 22, 12, 16, 22, 24, 14, 18, 22, 12, 8,
  ];

  @override
  Widget build(BuildContext context) {
    final isPlaying = _state == PlayerState.playing;
    final fg = widget.isMe ? Colors.white : Colors.black87;
    final totalMs = _duration.inMilliseconds;
    final currentMs = _position.inMilliseconds;
    final progress = totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: 220.w,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              size: 34.r,
              color: fg,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _togglePlay,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                if (totalMs <= 0) return;
                final box = context.findRenderObject() as RenderBox?;
                final width = box?.size.width ?? 140.w;
                final pct = (details.localPosition.dx / width).clamp(0.0, 1.0);
                _player.seek(Duration(milliseconds: (pct * totalMs).toInt()));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 26.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(_waveHeights.length, (i) {
                        final barPct = i / _waveHeights.length;
                        final isPlayed = barPct <= progress;
                        return Container(
                          width: 3.w,
                          height: _waveHeights[i].h,
                          decoration: BoxDecoration(
                            color: isPlayed ? fg : fg.withAlpha(60),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(isPlaying ? _position : _duration),
                        style: TextStyle(fontSize: 10.sp, color: fg.withAlpha(180), fontWeight: FontWeight.w500),
                      ),
                      Icon(Icons.mic_rounded, size: 12.r, color: fg.withAlpha(140)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

