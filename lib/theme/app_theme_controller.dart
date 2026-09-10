import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adwaita_colors.dart';

/// App signature accent definition - unified Warm Terracotta and Amber
enum AppAccentColor {
  terracotta(
    label: 'Warm Terracotta',
    color: AdwaitaColors.terracottaDark,
  );

  final String label;
  final Color color;

  const AppAccentColor({
    required this.label,
    required this.color,
  });

  static AppAccentColor fromString(String? val) {
    return AppAccentColor.terracotta;
  }
}

class AppThemeState {
  final ThemeMode mode;
  final AppAccentColor accent;

  const AppThemeState({
    this.mode = ThemeMode.dark,
    this.accent = AppAccentColor.terracotta,
  });

  Color get primaryColor => mode == ThemeMode.light
      ? AdwaitaColors.terracottaLight
      : AdwaitaColors.terracottaDark;

  AppThemeState copyWith({
    ThemeMode? mode,
    AppAccentColor? accent,
  }) {
    return AppThemeState(
      mode: mode ?? this.mode,
      accent: accent ?? this.accent,
    );
  }
}

class AppThemeNotifier extends StateNotifier<AppThemeState> {
  static const String _modePrefKey = 'foliate_app_ui_theme_mode';
  static const String _accentPrefKey = 'foliate_app_ui_accent_color';

  AppThemeNotifier() : super(const AppThemeState()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Purge any legacy saved accent preference from previous versions
      if (prefs.containsKey(_accentPrefKey)) {
        await prefs.remove(_accentPrefKey);
      }

      final modeStr = prefs.getString(_modePrefKey);
      ThemeMode mode = ThemeMode.dark;
      if (modeStr == 'light') mode = ThemeMode.light;
      if (modeStr == 'system') mode = ThemeMode.system;

      state = AppThemeState(mode: mode, accent: AppAccentColor.terracotta);
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      String val = 'dark';
      if (mode == ThemeMode.light) val = 'light';
      if (mode == ThemeMode.system) val = 'system';
      await prefs.setString(_modePrefKey, val);
    } catch (_) {}
  }

  Future<void> setAccent(AppAccentColor accent) async {
    state = state.copyWith(accent: AppAccentColor.terracotta);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accentPrefKey);
    } catch (_) {}
  }
}

final appThemeProvider = StateNotifierProvider<AppThemeNotifier, AppThemeState>((ref) {
  return AppThemeNotifier();
});
