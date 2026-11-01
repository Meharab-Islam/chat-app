import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../view_models/chat_list_view_model.dart';

class ChatSearchBar extends StatelessWidget {
  const ChatSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final vm = context.read<ChatListViewModel>();

    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppSpacing.radiusXl,
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20.r, color: textSecondary),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              onChanged: vm.setSearchQuery,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: 'Search chats, people & media...',
                hintStyle: AppTypography.bodySmall(textSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

