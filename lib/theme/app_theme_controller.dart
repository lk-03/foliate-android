import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available Libadwaita / Android accent color palettes
enum AppAccentColor {
  emerald(
    label: 'Emerald',
    color: Color(0xFF3DB88F),
  ),
  blue(
    label: 'Ocean Blue',
    color: Color(0xFF3584E4),
  ),
  amber(
    label: 'Sunset Amber',
    color: Color(0xFFE5A50A),
  ),
  rose(
    label: 'Coral Rose',
    color: Color(0xFFE06377),
  ),
  purple(
    label: 'Royal Violet',
    color: Color(0xFF9141AC),
  ),
  slate(
    label: 'Neutral Slate',
    color: Color(0xFF77767B),
  );

  final String label;
  final Color color;

  const AppAccentColor({
    required this.label,
    required this.color,
  });

  static AppAccentColor fromString(String? val) {
    if (val == null) return AppAccentColor.emerald;
    return AppAccentColor.values.firstWhere(
      (e) => e.name == val,
      orElse: () => AppAccentColor.emerald,
    );
  }
}

class AppThemeState {
  final ThemeMode mode;
  final AppAccentColor accent;

  const AppThemeState({
    this.mode = ThemeMode.dark,
    this.accent = AppAccentColor.emerald,
  });

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
      final modeStr = prefs.getString(_modePrefKey);
      final accentStr = prefs.getString(_accentPrefKey);

      ThemeMode mode = ThemeMode.dark;
      if (modeStr == 'light') mode = ThemeMode.light;
      if (modeStr == 'system') mode = ThemeMode.system;

      final accent = AppAccentColor.fromString(accentStr);

      state = AppThemeState(mode: mode, accent: accent);
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
    state = state.copyWith(accent: accent);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accentPrefKey, accent.name);
    } catch (_) {}
  }
}

final appThemeProvider = StateNotifierProvider<AppThemeNotifier, AppThemeState>((ref) {
  return AppThemeNotifier();
});
