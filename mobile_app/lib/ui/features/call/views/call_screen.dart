import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../view_models/call_view_model.dart';
import 'participant_view.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CallViewModel>();
    final local = vm.callService.localParticipant;
    final remotes = vm.callService.remoteParticipants;
    final allCount = remotes.length + (local != null ? 1 : 0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) vm.endCall(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1015),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => vm.endCall(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vm.chatName,
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            vm.isConnecting
                                ? 'Connecting LiveKit WebRTC...'
                                : '${_formatDuration(vm.callDuration)} • $allCount in call',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: vm.isConnecting ? Colors.indigoAccent : Colors.greenAccent,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
                      tooltip: 'Flip Camera',
                      onPressed: vm.flipCamera,
                    ),
                  ],
                ),
              ),

              // Main Participant Grid Area
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: vm.isConnecting
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.indigoAccent,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Joining room...',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        )
                      : _buildGrid(local, remotes),
                ),
              ),

              // Bottom Call Controls Bar
              Container(
                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF161821),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mic Toggle
                    _ControlBtn(
                      icon: vm.isMuted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      isActive: !vm.isMuted,
                      activeColor: Colors.white24,
                      inactiveColor: Colors.redAccent.withAlpha(50),
                      iconColor: vm.isMuted ? Colors.redAccent : Colors.white,
                      onTap: vm.toggleMute,
                    ),
                    // Camera Toggle
                    _ControlBtn(
                      icon: vm.isCameraOff
                          ? Icons.videocam_off_rounded
                          : Icons.videocam_rounded,
                      isActive: !vm.isCameraOff,
                      activeColor: Colors.white24,
                      inactiveColor: Colors.redAccent.withAlpha(50),
                      iconColor: vm.isCameraOff
                          ? Colors.redAccent
                          : Colors.white,
                      onTap: vm.toggleCamera,
                    ),
                    // Speakerphone Toggle
                    _ControlBtn(
                      icon: vm.isSpeakerOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_down_rounded,
                      isActive: vm.isSpeakerOn,
                      activeColor: Colors.indigoAccent.withAlpha(80),
                      inactiveColor: Colors.white12,
                      iconColor: Colors.white,
                      onTap: vm.toggleSpeaker,
                    ),
                    // End Call
                    _ControlBtn(
                      icon: Icons.call_end_rounded,
                      isActive: true,
                      activeColor: Colors.redAccent,
                      inactiveColor: Colors.redAccent,
                      iconColor: Colors.white,
                      size: 58.r,
                      onTap: () => vm.endCall(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(dynamic local, List<dynamic> remotes) {
    final list = <Widget>[];
    if (local != null) {
      list.add(ParticipantWidget(participant: local, isLocal: true));
    }
    for (final r in remotes) {
      list.add(ParticipantWidget(participant: r, isLocal: false));
    }

    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for others to join...',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    if (list.length == 1) {
      return list.first;
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: list.length <= 2 ? 1 : 2,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
        childAspectRatio: list.length <= 2 ? 1.4 : 1.0,
      ),
      itemBuilder: (_, i) => list[i],
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final Color iconColor;
  final double? size;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.iconColor,
    this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final btnSize = size ?? 50.r;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: btnSize,
        height: btnSize,
        decoration: BoxDecoration(
          color: isActive ? activeColor : inactiveColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor, size: btnSize * 0.45),
      ),
    );
  }
}
