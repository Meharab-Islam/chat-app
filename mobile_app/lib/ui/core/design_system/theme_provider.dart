import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'app_theme_mode';
  static const String _accentIndexKey = 'app_accent_index';

  final SharedPreferences prefs;
  ThemeMode _themeMode = ThemeMode.system;
  AppAccentTheme _accent = AppAccentTheme.blue;

  ThemeProvider({required this.prefs}) {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  AppAccentTheme get accent => _accent;
  Color get accentColor => _accent.color;

  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void _loadSettings() {
    final modeIndex = prefs.getInt(_themeModeKey);
    if (modeIndex != null &&
        modeIndex >= 0 &&
        modeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[modeIndex];
    }
    final accentIndex = prefs.getInt(_accentIndexKey);
    if (accentIndex != null &&
        accentIndex >= 0 &&
        accentIndex < AppAccentTheme.values.length) {
      _accent = AppAccentTheme.values[accentIndex];
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setAccentTheme(AppAccentTheme accent) async {
    if (_accent == accent) return;
    _accent = accent;
    notifyListeners();
    await prefs.setInt(_accentIndexKey, accent.index);
  }
}
