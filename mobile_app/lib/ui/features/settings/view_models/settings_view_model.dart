import 'package:flutter/material.dart';

import '../../../../data/services/storage_service.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/theme_provider.dart';

class SettingsViewModel extends ChangeNotifier {
  final StorageService storageService;
  final ThemeProvider themeProvider;
  bool _autoSaveMedia = false;

  SettingsViewModel({
    required this.storageService,
    required this.themeProvider,
  }) {
    _autoSaveMedia = storageService.getAutoSaveMedia();
  }

  bool get autoSaveMedia => _autoSaveMedia;
  ThemeMode get themeMode => themeProvider.themeMode;
  AppAccentTheme get currentAccent => themeProvider.accent;

  Future<void> toggleAutoSaveMedia(bool value) async {
    _autoSaveMedia = value;
    notifyListeners();
    await storageService.setAutoSaveMedia(value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await themeProvider.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setAccentTheme(AppAccentTheme accent) async {
    await themeProvider.setAccentTheme(accent);
    notifyListeners();
  }
}
