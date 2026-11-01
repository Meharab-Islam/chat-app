import 'package:flutter/material.dart';

enum AppAccentTheme {
  blue(name: 'Electric Blue', color: Color(0xFF2563EB)),
  emerald(name: 'Emerald Green', color: Color(0xFF10B981)),
  violet(name: 'Royal Violet', color: Color(0xFF8B5CF6)),
  orange(name: 'Sunset Orange', color: Color(0xFFF97316)),
  rose(name: 'Rose Pink', color: Color(0xFFEC4899)),
  slate(name: 'Monochrome Slate', color: Color(0xFF475569));

  final String name;
  final Color color;
  const AppAccentTheme({required this.name, required this.color});
}

class AppColors {
  AppColors._();

  // Pure White Theme
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFF1F5F9);
  static const Color lightBubbleSender = Color(0xFF2563EB);
  static const Color lightBubbleReceiver = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightDivider = Color(0xFFE2E8F0);
  static const Color lightInputBackground = Color(0xFFF8FAFC);

  // True Black Theme (OLED / Pitch Black)
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF0F0F11);
  static const Color darkCard = Color(0xFF18181B);
  static const Color darkBubbleSender = Color(0xFF2563EB);
  static const Color darkBubbleReceiver = Color(0xFF1E2430);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkDivider = Color(0xFF27272A);
  static const Color darkInputBackground = Color(0xFF141416);

  // Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
  static const Color shimmerDarkBase = Color(0xFF1E2024);
  static const Color shimmerDarkHighlight = Color(0xFF2E3138);
}

