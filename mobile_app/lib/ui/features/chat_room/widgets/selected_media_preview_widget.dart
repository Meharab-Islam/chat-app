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
    return l.endsWith('.mp4') || l.endsWith('.mov') || l.endsWith('.mkv') || l.endsWith('.webm');
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
                'Selected Media (${files.length})',
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
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Icon(Icons.add_photo_alternate_outlined, size: 26.r),
                    ),
                  );
                }

                final file = files[index];
                final isVideo = _isVideo(file.path);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: AppSpacing.radiusSm,
                      child: Container(
                        width: 68.w,
                        height: 68.h,
                        color: Colors.black87,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (!isVideo)
                              Image.file(file, fit: BoxFit.cover)
                            else
                              Container(
                                color: const Color(0xFF222222),
                                child: const Center(
                                  child: Icon(Icons.videocam, color: Colors.white70),
                                ),
                              ),
                            if (isVideo)
                              Center(
                                child: Container(
                                  padding: EdgeInsets.all(4.r),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 18.r,
                                  ),
                                ),
                              ),
                          ],
                        ),
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
