import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:livekit_client/livekit_client.dart';

class ParticipantWidget extends StatelessWidget {
  final Participant participant;
  final bool isLocal;

  const ParticipantWidget({
    super.key,
    required this.participant,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    final videoPub = participant.videoTrackPublications.firstOrNull;
    final videoTrack = videoPub?.track as VideoTrack?;
    final isVideoEnabled =
        videoPub != null && !videoPub.muted && videoTrack != null;
    final isMuted = participant.isMuted;
    final isSpeaking = participant.isSpeaking;
    final name = participant.name.isNotEmpty
        ? participant.name
        : (isLocal ? 'You' : participant.identity);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSpeaking ? Colors.greenAccent : Colors.white10,
          width: isSpeaking ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isVideoEnabled)
            Positioned.fill(
              child: VideoTrackRenderer(videoTrack, fit: VideoViewFit.cover),
            )
          else
            Center(
              child: Container(
                width: 72.r,
                height: 72.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: isSpeaking
                      ? [
                          BoxShadow(
                            color: Colors.greenAccent.withAlpha(150),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Name and mic tag
          Positioned(
            bottom: 8.h,
            left: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(160),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLocal ? '$name (You)' : name,
                    style: TextStyle(fontSize: 11.sp, color: Colors.white),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    size: 13.sp,
                    color: isMuted
                        ? Colors.redAccent
                        : (isSpeaking ? Colors.greenAccent : Colors.white70),
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
