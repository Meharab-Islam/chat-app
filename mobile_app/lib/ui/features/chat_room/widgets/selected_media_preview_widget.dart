import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_spacing.dart';

class SelectedMediaPreviewWidget extends StatelessWidget {
  final List<File> files;
  final ValueChanged<int> onRemove;
  final VoidCallback onClear;
  final VoidCallback onAddMore;

  const SelectedMediaPreviewWidget({
    super.key,
    required this.files,
    required this.onRemove,
    required this.onClear,
    required this.onAddMore,
  });

  bool _isVideo(String path) {
    final l = path.toLowerCase();
    return l.endsWith('.mp4') || l.endsWith('.mov') || l.endsWith('.mkv') || l.endsWith('.webm') || l.endsWith('.3gp') || l.endsWith('.avi');
  }

  bool _isAudio(String path) {
    final l = path.toLowerCase();
    return l.endsWith('.mp3') || l.endsWith('.wav') || l.endsWith('.m4a') || l.endsWith('.aac') || l.endsWith('.ogg') || l.endsWith('.opus') || l.endsWith('.flac');
  }

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Media & Audio (${files.length})',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              GestureDetector(
                onTap: onClear,
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.danger),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 72.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: files.length + 1,
              separatorBuilder: (_, _) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                if (index == files.length) {
                  return GestureDetector(
                    onTap: onAddMore,
                    child: Container(
                      width: 68.w,
                      height: 68.h,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black12,
                        borderRadius: AppSpacing.radiusSm,
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded, size: 22.r),
                          SizedBox(height: 2.h),
                          Text('Add More', style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }

                final file = files[index];
                final isVideo = _isVideo(file.path);
                final isAudio = _isAudio(file.path);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: AppSpacing.radiusSm,
                      child: Container(
                        width: 68.w,
                        height: 68.h,
                        color: Colors.black87,
                        child: isAudio
                            ? Container(
                                color: const Color(0xFF0F172A),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(5.r),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF0284C7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.audiotrack_rounded, color: Colors.white, size: 16.r),
                                    ),
                                    SizedBox(height: 3.h),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                                      child: Text(
                                        file.path.split('/').last,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : (isVideo
                                ? Container(
                                    color: const Color(0xFF1E2028),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        const Center(child: Icon(Icons.videocam_rounded, color: Colors.white38)),
                                        Center(
                                          child: Container(
                                            padding: EdgeInsets.all(4.r),
                                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                            child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18.r),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 2.h,
                                          left: 4.w,
                                          child: Text('VIDEO', style: TextStyle(color: Colors.white70, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  )
                                : Image.file(file, fit: BoxFit.cover)),
                      ),
                    ),
                    Positioned(
                      top: -4.h,
                      right: -4.w,
                      child: GestureDetector(
                        onTap: () => onRemove(index),
                        child: Container(
                          padding: EdgeInsets.all(2.r),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 14.r, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
