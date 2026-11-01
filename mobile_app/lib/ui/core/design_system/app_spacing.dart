import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSpacing {
  AppSpacing._();

  // Spacing dimensions
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 12.w;
  static double get lg => 16.w;
  static double get xl => 20.w;
  static double get xxl => 24.w;
  static double get xxxl => 32.w;

  // Insets
  static EdgeInsets get screenPadding => EdgeInsets.symmetric(horizontal: 16.w);
  static EdgeInsets get listPadding => EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h);
  static EdgeInsets get bubblePadding => EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h);
  static EdgeInsets get inputPadding => EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h);

  // Border Radii
  static BorderRadius get radiusXs => BorderRadius.circular(6.r);
  static BorderRadius get radiusSm => BorderRadius.circular(10.r);
  static BorderRadius get radiusMd => BorderRadius.circular(14.r);
  static BorderRadius get radiusLg => BorderRadius.circular(18.r);
  static BorderRadius get radiusXl => BorderRadius.circular(24.r);
  static BorderRadius get radiusFull => BorderRadius.circular(999.r);

  // Icon Sizes
  static double get iconSm => 18.r;
  static double get iconMd => 22.r;
  static double get iconLg => 28.r;

  // Avatar Sizes
  static double get avatarSm => 34.r;
  static double get avatarMd => 46.r;
  static double get avatarLg => 64.r;
}

