import 'package:flutter/material.dart';

/// Foliate GNOME / Libadwaita color palette replicated directly from
/// the desktop Foliate Linux application screenshots.
class AdwaitaColors {
  AdwaitaColors._();

  // --- Dark Mode (Desktop Default) ---
  /// Main application background (warm dark tone)
  static const Color darkWindowBg = Color(0xFF1E1D1B);

  /// Header bar / Title bar surface
  static const Color darkHeaderBar = Color(0xFF1B1918);

  /// Sidebar / Navigation list background
  static const Color darkSidebarBg = Color(0xFF211F1D);

  /// Elevated card / popover surface
  static const Color darkSurfaceCard = Color(0xFF262422);

  /// Inner input background (e.g. location/identifier boxes in popover)
  static const Color darkInputBg = Color(0xFF1B1918);

  /// Selected / Active pill background (e.g. "All Books", active chapter)
  static const Color darkActivePill = Color(0xFF3B3632);

  /// Hover pill background
  static const Color darkHoverPill = Color(0xFF2E2A28);

  /// Subtle borders and dividers
  static const Color darkBorder = Color(0xFF33302D);
  static const Color darkDivider = Color(0xFF2C2927);

  /// Typography
  static const Color darkTextPrimary = Color(0xFFEDEDED);
  static const Color darkTextSecondary = Color(0xFF9E9A95);
  static const Color darkTextMuted = Color(0xFF736F6B);

  // --- Light Mode ---
  static const Color lightWindowBg = Color(0xFFFAFAFA);
  static const Color lightHeaderBar = Color(0xFFF2F2F2);
  static const Color lightSidebarBg = Color(0xFFF6F6F6);
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightInputBg = Color(0xFFF0F0F0);
  static const Color lightActivePill = Color(0xFFE2DDD8);
  static const Color lightHoverPill = Color(0xFFEFECE9);
  static const Color lightBorder = Color(0xFFE0DBD6);
  static const Color lightDivider = Color(0xFFE8E4DF);
  static const Color lightTextPrimary = Color(0xFF1C1C1E);
  static const Color lightTextSecondary = Color(0xFF6B6864);
  static const Color lightTextMuted = Color(0xFF9E9A95);

  // --- Foliate & Libadwaita Accents ---
  /// Foliate Leaf green accent
  static const Color foliateGreen = Color(0xFF3DB88F);

  /// Libadwaita default blue accent
  static const Color libadwaitaBlue = Color(0xFF3584E4);

  /// Libadwaita destructive red
  static const Color libadwaitaRed = Color(0xFFE01B24);

  /// Libadwaita warning orange
  static const Color libadwaitaOrange = Color(0xFFFF7800);

  /// Warm Terracotta primary editorial accent from Apple Books reference
  static const Color terracottaAccent = Color(0xFFC2410C);

  /// Warm Terracotta for Dark mode
  static const Color terracottaDark = Color(0xFFD97736);

  /// Warm Terracotta for Light mode
  static const Color terracottaLight = Color(0xFFC2410C);

  /// Warm Terracotta / Warm Paper tone
  static const Color warmTerracotta = Color(0xFFC6782E);

  /// Burnished Amber for streak flame and habit progress ring
  static const Color amberStreak = Color(0xFFD97706);

  // --- Reader Background Themes ---
  /// Day Theme (Light)
  static const Color readerDayBg = Color(0xFFFFFFFF);
  static const Color readerDayText = Color(0xFF1C1C1E);
  static const Color readerDaySurface = Color(0xFFF4F4F6);

  /// Sepia Theme (Warm Paper)
  static const Color readerSepiaBg = Color(0xFFF8F1E5);
  static const Color readerSepiaText = Color(0xFF4A3B32);
  static const Color readerSepiaSurface = Color(0xFFEDE3D2);

  /// Night Theme (Dark Slate)
  static const Color readerNightBg = Color(0xFF1E1D1B);
  static const Color readerNightText = Color(0xFFE5E5EA);
  static const Color readerNightSurface = Color(0xFF282523);

  /// Black Theme (AMOLED Pitch Black)
  static const Color readerBlackBg = Color(0xFF000000);
  static const Color readerBlackText = Color(0xFFD1D1D6);
  static const Color readerBlackSurface = Color(0xFF161616);

  // --- Foliate Reading Themes Curated for Warm Terracotta / Amber Palette ---
  static const List<FoliateThemePreset> foliateThemes = [
    FoliateThemePreset(
      id: 'default',
      label: 'Default',
      lightBg: Color(0xFFFFFFFF),
      lightText: Color(0xFF1A1A1A),
      darkBg: Color(0xFF1E1D1B),
      darkText: Color(0xFFEDEDED),
    ),
    FoliateThemePreset(
      id: 'sepia',
      label: 'Calm Sepia',
      lightBg: Color(0xFFF8F1E5),
      lightText: Color(0xFF4D3826),
      darkBg: Color(0xFF24201C),
      darkText: Color(0xFFD4C5B0),
    ),
    FoliateThemePreset(
      id: 'solarized',
      label: 'Warm Cream',
      lightBg: Color(0xFFFDF6E3),
      lightText: Color(0xFF5F4B32),
      darkBg: Color(0xFF211E1B),
      darkText: Color(0xFFD9CEC2),
    ),
    FoliateThemePreset(
      id: 'night',
      label: 'Quiet Black',
      lightBg: Color(0xFF1E1D1B),
      lightText: Color(0xFFEDEDED),
      darkBg: Color(0xFF1E1D1B),
      darkText: Color(0xFFEDEDED),
    ),
    FoliateThemePreset(
      id: 'black',
      label: 'Contrast Black',
      lightBg: Color(0xFF000000),
      lightText: Color(0xFFD1D1D6),
      darkBg: Color(0xFF000000),
      darkText: Color(0xFFD1D1D6),
    ),
    FoliateThemePreset(
      id: 'gray',
      label: 'Gray',
      lightBg: Color(0xFFF0F0F0),
      lightText: Color(0xFF202020),
      darkBg: Color(0xFF2E2E2E),
      darkText: Color(0xFFD8D8D8),
    ),
    FoliateThemePreset(
      id: 'gruvbox',
      label: 'Gruvbox',
      lightBg: Color(0xFFFBF1C7),
      lightText: Color(0xFF3C3836),
      darkBg: Color(0xFF282828),
      darkText: Color(0xFFEBDBB2),
    ),
    FoliateThemePreset(
      id: 'nord',
      label: 'Nord',
      lightBg: Color(0xFFECEFF4),
      lightText: Color(0xFF2E3440),
      darkBg: Color(0xFF2E3440),
      darkText: Color(0xFFECEFF4),
    ),
  ];

  /// Returns the theme-specific accent color for the reader HUD and controls,
  /// harmonized with the Warm Terracotta and Amber signature aesthetic.
  static Color getThemeAccent(String themeId, bool isDarkMode) {
    switch (themeId.toLowerCase()) {
      case 'sepia':
      case 'warm':
      case 'solarized':
        return warmTerracotta;
      case 'black':
      case 'contrast':
        return amberStreak;
      case 'gruvbox':
        return const Color(0xFFD79921);
      case 'night':
        return terracottaDark;
      case 'day':
      case 'light':
        return terracottaLight;
      case 'nord':
      case 'gray':
      case 'grey':
      case 'default':
      case 'defaulttheme':
      default:
        return isDarkMode ? terracottaDark : terracottaLight;
    }
  }

  /// Returns the background color for a given theme preset
  static Color getReaderBgColor(String themeId, bool isDarkMode) {
    for (final theme in foliateThemes) {
      if (theme.id.toLowerCase() == themeId.toLowerCase()) {
        return theme.bg(isDarkMode);
      }
    }
    return isDarkMode ? darkWindowBg : lightWindowBg;
  }

  /// Returns the foreground text color for a given theme preset
  static Color getReaderFgColor(String themeId, bool isDarkMode) {
    for (final theme in foliateThemes) {
      if (theme.id.toLowerCase() == themeId.toLowerCase()) {
        return theme.text(isDarkMode);
      }
    }
    return isDarkMode ? darkTextPrimary : lightTextPrimary;
  }
}

/// Representation of a Foliate theme with light and dark mode color pairs
class FoliateThemePreset {
  final String id;
  final String label;
  final Color lightBg;
  final Color lightText;
  final Color darkBg;
  final Color darkText;

  const FoliateThemePreset({
    required this.id,
    required this.label,
    required this.lightBg,
    required this.lightText,
    required this.darkBg,
    required this.darkText,
  });

  Color bg(bool isDark) => isDark ? darkBg : lightBg;
  Color text(bool isDark) => isDark ? darkText : lightText;
}
