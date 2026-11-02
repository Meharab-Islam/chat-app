import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../data/services/voice_recording_service.dart';
import '../../../core/design_system/app_colors.dart';
import 'chat_attachment_sheet.dart';

class ChatInputBarWidget extends StatefulWidget {
  final ValueChanged<String> onSendText;
  final VoidCallback onPickMedia;
  final VoidCallback onPickAudio;
  final VoidCallback onSendFiles;
  final ValueChanged<File> onSendVoice;
  final bool hasSelectedMedia;

  const ChatInputBarWidget({
    super.key,
    required this.onSendText,
    required this.onPickMedia,
    required this.onPickAudio,
    required this.onSendFiles,
    required this.onSendVoice,
    this.hasSelectedMedia = false,
  });

  @override
  State<ChatInputBarWidget> createState() => _ChatInputBarWidgetState();
}

class _ChatInputBarWidgetState extends State<ChatInputBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final VoiceRecordingService _voiceService = VoiceRecordingService();
  bool _hasText = false;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _recordTimer?.cancel();
    _voiceService.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_hasText || widget.hasSelectedMedia) {
      widget.onSendText(_controller.text);
      _controller.clear();
    }
  }

  Future<void> _startRecording() async {
    final started = await _voiceService.startRecording();
    if (started) {
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordSeconds++);
      });
    }
  }

  Future<void> _stopAndSendVoice() async {
    _recordTimer?.cancel();
    final file = await _voiceService.stopRecording();
    setState(() => _isRecording = false);
    if (file != null) widget.onSendVoice(file);
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _voiceService.cancelRecording();
    setState(() => _isRecording = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: _isRecording
            ? _buildRecordingBar(primary, isDark)
            : _buildStandardInputBar(theme, isDark, primary),
      ),
    );
  }

  Widget _buildRecordingBar(Color primary, bool isDark) {
    final mins = (_recordSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_recordSeconds % 60).toString().padLeft(2, '0');
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: _cancelRecording,
        ),
        Container(
          width: 10.r,
          height: 10.r,
          decoration: const BoxDecoration(
            color: AppColors.danger,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          'Recording $mins:$secs',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.send_rounded, color: primary),
          onPressed: _stopAndSendVoice,
        ),
      ],
    );
  }

  Widget _buildStandardInputBar(ThemeData theme, bool isDark, Color primary) {
    final canSend = _hasText || widget.hasSelectedMedia;
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.add_circle_outline_rounded, size: 24.r),
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          onPressed: () => ChatAttachmentSheet.show(
            context: context,
            onPickMedia: widget.onPickMedia,
            onPickAudio: widget.onPickAudio,
            onSendFiles: widget.onSendFiles,
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(12)
                    : Colors.black.withAlpha(8),
                width: 0.8,
              ),
            ),
            child: TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 1,
              style: TextStyle(fontSize: 14.sp),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: canSend ? _handleSend : _startRecording,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withAlpha(isDark ? 70 : 90),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                canSend ? Icons.arrow_upward_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 20.r,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
