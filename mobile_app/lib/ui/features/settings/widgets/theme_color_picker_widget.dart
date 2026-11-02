import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/design_system/app_colors.dart';

class ThemeColorPickerWidget extends StatelessWidget {
  final AppAccentTheme selectedAccent;
  final ValueChanged<AppAccentTheme> onSelected;

  const ThemeColorPickerWidget({
    super.key,
    required this.selectedAccent,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: AppAccentTheme.values.length,
        separatorBuilder: (context, index) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final accent = AppAccentTheme.values[index];
          final isSelected = accent == selectedAccent;

          return GestureDetector(
            onTap: () => onSelected(accent),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: accent.color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 3.r,
                      )
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accent.color.withAlpha(120),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, color: Colors.white, size: 20.r)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
