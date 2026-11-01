import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_spacing.dart';

enum ChatFilterType {
  all(label: 'All'),
  unread(label: 'Unread'),
  groups(label: 'Groups'),
  media(label: 'Photos & Videos'),
  online(label: 'Online');

  final String label;
  const ChatFilterType({required this.label});
}

class ChatFilterChips extends StatelessWidget {
  final ChatFilterType activeFilter;
  final ValueChanged<ChatFilterType> onFilterSelected;

  const ChatFilterChips({
    super.key,
    required this.activeFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: ChatFilterType.values.length,
        separatorBuilder: (context, index) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final filter = ChatFilterType.values[index];
          final isSelected = filter == activeFilter;

          return GestureDetector(
            onTap: () => onFilterSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: AppSpacing.radiusFull,
                border: Border.all(
                  color: isSelected
                      ? primary
                      : (isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  filter.label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

