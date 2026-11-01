import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTypography {
  AppTypography._();

  static TextStyle headingLarge(Color color) => TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle headingMedium(Color color) => TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle headingSmall(Color color) => TextStyle(
        fontSize: 17.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle bodyLarge(Color color) => TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: color,
      );

  static TextStyle bodyMedium(Color color) => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: color,
      );

  static TextStyle bodySmall(Color color) => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle caption(Color color) => TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: color,
      );

  static TextStyle buttonText(Color color) => TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: color,
      );
}

