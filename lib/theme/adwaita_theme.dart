import 'package:flutter/material.dart';
import '../models/reader_settings.dart';
import 'adwaita_colors.dart';

/// Custom theme extension for Foliate/Libadwaita specific semantic surfaces
class FoliateThemeColors extends ThemeExtension<FoliateThemeColors> {
  final Color windowBackground;
  final Color headerBar;
  final Color sidebar;
  final Color surfaceCard;
  final Color inputBackground;
  final Color activePill;
  final Color hoverPill;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const FoliateThemeColors({
    required this.windowBackground,
    required this.headerBar,
    required this.sidebar,
    required this.surfaceCard,
    required this.inputBackground,
    required this.activePill,
    required this.hoverPill,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  static const dark = FoliateThemeColors(
    windowBackground: AdwaitaColors.darkWindowBg,
    headerBar: AdwaitaColors.darkHeaderBar,
    sidebar: AdwaitaColors.darkSidebarBg,
    surfaceCard: AdwaitaColors.darkSurfaceCard,
    inputBackground: AdwaitaColors.darkInputBg,
    activePill: AdwaitaColors.darkActivePill,
    hoverPill: AdwaitaColors.darkHoverPill,
    border: AdwaitaColors.darkBorder,
    textPrimary: AdwaitaColors.darkTextPrimary,
    textSecondary: AdwaitaColors.darkTextSecondary,
    textMuted: AdwaitaColors.darkTextMuted,
  );

  static const light = FoliateThemeColors(
    windowBackground: AdwaitaColors.lightWindowBg,
    headerBar: AdwaitaColors.lightHeaderBar,
    sidebar: AdwaitaColors.lightSidebarBg,
    surfaceCard: AdwaitaColors.lightSurfaceCard,
    inputBackground: AdwaitaColors.lightInputBg,
    activePill: AdwaitaColors.lightActivePill,
    hoverPill: AdwaitaColors.lightHoverPill,
    border: AdwaitaColors.lightBorder,
    textPrimary: AdwaitaColors.lightTextPrimary,
    textSecondary: AdwaitaColors.lightTextSecondary,
    textMuted: AdwaitaColors.lightTextMuted,
  );

  @override
  ThemeExtension<FoliateThemeColors> copyWith({
    Color? windowBackground,
    Color? headerBar,
    Color? sidebar,
    Color? surfaceCard,
    Color? inputBackground,
    Color? activePill,
    Color? hoverPill,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return FoliateThemeColors(
      windowBackground: windowBackground ?? this.windowBackground,
      headerBar: headerBar ?? this.headerBar,
      sidebar: sidebar ?? this.sidebar,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      inputBackground: inputBackground ?? this.inputBackground,
      activePill: activePill ?? this.activePill,
      hoverPill: hoverPill ?? this.hoverPill,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  ThemeExtension<FoliateThemeColors> lerp(
    covariant ThemeExtension<FoliateThemeColors>? other,
    double t,
  ) {
    if (other is! FoliateThemeColors) return this;
    return FoliateThemeColors(
      windowBackground: Color.lerp(windowBackground, other.windowBackground, t)!,
      headerBar: Color.lerp(headerBar, other.headerBar, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      activePill: Color.lerp(activePill, other.activePill, t)!,
      hoverPill: Color.lerp(hoverPill, other.hoverPill, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

/// Helper for retrieving reader theme color presets
class ReaderThemeColors {
  final Color background;
  final Color text;
  final Color surface;

  const ReaderThemeColors({
    required this.background,
    required this.text,
    required this.surface,
  });

  static ReaderThemeColors forMode(ReaderThemeMode mode, {bool isDark = true}) {
    switch (mode) {
      case ReaderThemeMode.day:
        return const ReaderThemeColors(
          background: AdwaitaColors.readerDayBg,
          text: AdwaitaColors.readerDayText,
          surface: AdwaitaColors.readerDaySurface,
        );
      case ReaderThemeMode.sepia:
        return const ReaderThemeColors(
          background: AdwaitaColors.readerSepiaBg,
          text: AdwaitaColors.readerSepiaText,
          surface: AdwaitaColors.readerSepiaSurface,
        );
      case ReaderThemeMode.black:
        return const ReaderThemeColors(
          background: AdwaitaColors.readerBlackBg,
          text: AdwaitaColors.readerBlackText,
          surface: AdwaitaColors.readerBlackSurface,
        );
      case ReaderThemeMode.night:
        return const ReaderThemeColors(
          background: AdwaitaColors.readerNightBg,
          text: AdwaitaColors.readerNightText,
          surface: AdwaitaColors.readerNightSurface,
        );
      default:
        final cleanId = mode == ReaderThemeMode.defaultTheme ? 'default' : mode.name.toLowerCase();
        final preset = AdwaitaColors.foliateThemes.firstWhere(
          (t) => t.id == cleanId,
          orElse: () => AdwaitaColors.foliateThemes.first,
        );
        return ReaderThemeColors(
          background: preset.bg(isDark),
          text: preset.text(isDark),
          surface: isDark ? AdwaitaColors.darkSurfaceCard : AdwaitaColors.lightSurfaceCard,
        );
    }
  }
}

/// Provides GNOME Libadwaita theme configurations for Foliate
class AdwaitaTheme {
  AdwaitaTheme._();

  static ThemeData dark({Color? accentColor}) {
    final accent = accentColor ?? AdwaitaColors.foliateGreen;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AdwaitaColors.darkWindowBg,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: AdwaitaColors.libadwaitaBlue,
        surface: AdwaitaColors.darkSurfaceCard,
        onSurface: AdwaitaColors.darkTextPrimary,
        outline: AdwaitaColors.darkBorder,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AdwaitaColors.darkHeaderBar,
        foregroundColor: AdwaitaColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AdwaitaColors.darkTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AdwaitaColors.darkSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AdwaitaColors.darkBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AdwaitaColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AdwaitaColors.darkTextPrimary,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AdwaitaColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AdwaitaColors.darkTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AdwaitaColors.darkTextPrimary,
          fontSize: 14,
        ),
        bodyMedium: TextStyle(
          color: AdwaitaColors.darkTextSecondary,
          fontSize: 13,
        ),
        labelSmall: TextStyle(
          color: AdwaitaColors.darkTextMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      extensions: const [
        FoliateThemeColors.dark,
      ],
    );
  }

  static ThemeData light({Color? accentColor}) {
    final accent = accentColor ?? AdwaitaColors.foliateGreen;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AdwaitaColors.lightWindowBg,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: AdwaitaColors.libadwaitaBlue,
        surface: AdwaitaColors.lightSurfaceCard,
        onSurface: AdwaitaColors.lightTextPrimary,
        outline: AdwaitaColors.lightBorder,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AdwaitaColors.lightHeaderBar,
        foregroundColor: AdwaitaColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AdwaitaColors.lightTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AdwaitaColors.lightSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AdwaitaColors.lightBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AdwaitaColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AdwaitaColors.lightTextPrimary,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AdwaitaColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AdwaitaColors.lightTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AdwaitaColors.lightTextPrimary,
          fontSize: 14,
        ),
        bodyMedium: TextStyle(
          color: AdwaitaColors.lightTextSecondary,
          fontSize: 13,
        ),
        labelSmall: TextStyle(
          color: AdwaitaColors.lightTextMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      extensions: const [
        FoliateThemeColors.light,
      ],
    );
  }
}
