import 'dart:convert';

/// Reading theme modes matching Foliate Linux / Libadwaita
enum ReaderThemeMode {
  defaultTheme,
  gray,
  sepia,
  grass,
  cherry,
  sky,
  solarized,
  gruvbox,
  nord,
  // Backwards compatibility aliases
  day,
  night,
  black;

  String get id {
    switch (this) {
      case ReaderThemeMode.defaultTheme:
        return 'default';
      case ReaderThemeMode.day:
        return 'day';
      case ReaderThemeMode.night:
        return 'night';
      case ReaderThemeMode.black:
        return 'black';
      default:
        return name;
    }
  }

  static ReaderThemeMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'default':
      case 'defaulttheme':
        return ReaderThemeMode.defaultTheme;
      case 'gray':
      case 'grey':
        return ReaderThemeMode.gray;
      case 'sepia':
        return ReaderThemeMode.sepia;
      case 'grass':
        return ReaderThemeMode.grass;
      case 'cherry':
        return ReaderThemeMode.cherry;
      case 'sky':
        return ReaderThemeMode.sky;
      case 'solarized':
        return ReaderThemeMode.solarized;
      case 'gruvbox':
        return ReaderThemeMode.gruvbox;
      case 'nord':
        return ReaderThemeMode.nord;
      case 'night':
      case 'dark':
        return ReaderThemeMode.night;
      case 'black':
        return ReaderThemeMode.black;
      case 'day':
      case 'light':
        return ReaderThemeMode.day;
      default:
        return ReaderThemeMode.defaultTheme;
    }
  }
}

/// Comprehensive reader settings for typography, appearance, and layout.
class ReaderSettings {
  final ReaderThemeMode theme;
  final bool isDarkMode;
  final double fontSize;
  final double minFontSize;
  final String fontFamily; // 'serif' | 'sans' | 'monospace' | 'publisher'
  final bool overridePublisherFont;
  final double lineHeight;
  final bool fullJustification;
  final bool hyphenation;
  final double margin; // 0.0 to 0.20 (e.g. 0.06)
  final int fontWeight;
  final String pageFlipping; // 'horizontal' | 'vertical' (scrolled)
  final String textAlign; // 'justify' | 'left' | 'center' | 'right'
  final bool pageMargins;
  final bool twoPagesLandscape;
  final bool reduceAnimation;
  final bool invertColors;

  const ReaderSettings({
    this.theme = ReaderThemeMode.defaultTheme,
    this.isDarkMode = true,
    this.fontSize = 16.0,
    this.minFontSize = 0.0,
    this.fontFamily = 'serif',
    this.overridePublisherFont = true,
    this.lineHeight = 1.50,
    this.fullJustification = true,
    this.hyphenation = true,
    this.margin = 0.06,
    this.fontWeight = 400,
    this.pageFlipping = 'horizontal',
    this.textAlign = 'justify',
    this.pageMargins = true,
    this.twoPagesLandscape = false,
    this.reduceAnimation = false,
    this.invertColors = false,
  });

  ReaderSettings copyWith({
    ReaderThemeMode? theme,
    bool? isDarkMode,
    double? fontSize,
    double? minFontSize,
    String? fontFamily,
    bool? overridePublisherFont,
    double? lineHeight,
    bool? fullJustification,
    bool? hyphenation,
    double? margin,
    int? fontWeight,
    String? pageFlipping,
    String? textAlign,
    bool? pageMargins,
    bool? twoPagesLandscape,
    bool? reduceAnimation,
    bool? invertColors,
  }) {
    return ReaderSettings(
      theme: theme ?? this.theme,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontSize: fontSize ?? this.fontSize,
      minFontSize: minFontSize ?? this.minFontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      overridePublisherFont: overridePublisherFont ?? this.overridePublisherFont,
      lineHeight: lineHeight ?? this.lineHeight,
      fullJustification: fullJustification ?? this.fullJustification,
      hyphenation: hyphenation ?? this.hyphenation,
      margin: margin ?? this.margin,
      fontWeight: fontWeight ?? this.fontWeight,
      pageFlipping: pageFlipping ?? this.pageFlipping,
      textAlign: textAlign ?? this.textAlign,
      pageMargins: pageMargins ?? this.pageMargins,
      twoPagesLandscape: twoPagesLandscape ?? this.twoPagesLandscape,
      reduceAnimation: reduceAnimation ?? this.reduceAnimation,
      invertColors: invertColors ?? this.invertColors,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme.id,
      'isDarkMode': isDarkMode,
      'fontSize': fontSize,
      'minFontSize': minFontSize,
      'fontFamily': fontFamily,
      'overridePublisherFont': overridePublisherFont,
      'lineHeight': lineHeight,
      'fullJustification': fullJustification,
      'hyphenation': hyphenation,
      'margin': margin,
      'fontWeight': fontWeight,
      'pageFlipping': pageFlipping,
      'textAlign': textAlign,
      'pageMargins': pageMargins,
      'twoPagesLandscape': twoPagesLandscape,
      'reduceAnimation': reduceAnimation,
      'invertColors': invertColors,
    };
  }

  factory ReaderSettings.fromMap(Map<String, dynamic> map) {
    return ReaderSettings(
      theme: ReaderThemeMode.fromString(map['theme'] as String? ?? 'default'),
      isDarkMode: map['isDarkMode'] as bool? ?? true,
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 16.0,
      minFontSize: (map['minFontSize'] as num?)?.toDouble() ?? 0.0,
      fontFamily: map['fontFamily'] as String? ?? 'serif',
      overridePublisherFont: map['overridePublisherFont'] as bool? ?? true,
      lineHeight: (map['lineHeight'] as num?)?.toDouble() ?? 1.50,
      fullJustification: map['fullJustification'] as bool? ?? true,
      hyphenation: map['hyphenation'] as bool? ?? true,
      margin: (map['margin'] as num?)?.toDouble() ?? 0.06,
      fontWeight: (map['fontWeight'] as num?)?.toInt() ?? 400,
      pageFlipping: map['pageFlipping'] as String? ?? 'horizontal',
      textAlign: map['textAlign'] as String? ?? 'justify',
      pageMargins: map['pageMargins'] as bool? ?? true,
      twoPagesLandscape: map['twoPagesLandscape'] as bool? ?? false,
      reduceAnimation: map['reduceAnimation'] as bool? ?? false,
      invertColors: map['invertColors'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory ReaderSettings.fromJson(String source) =>
      ReaderSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReaderSettings &&
        other.theme == theme &&
        other.isDarkMode == isDarkMode &&
        other.fontSize == fontSize &&
        other.minFontSize == minFontSize &&
        other.fontFamily == fontFamily &&
        other.overridePublisherFont == overridePublisherFont &&
        other.lineHeight == lineHeight &&
        other.fullJustification == fullJustification &&
        other.hyphenation == hyphenation &&
        other.margin == margin &&
        other.fontWeight == fontWeight &&
        other.pageFlipping == pageFlipping &&
        other.textAlign == textAlign &&
        other.pageMargins == pageMargins &&
        other.twoPagesLandscape == twoPagesLandscape &&
        other.reduceAnimation == reduceAnimation &&
        other.invertColors == invertColors;
  }

  @override
  int get hashCode => Object.hash(
        theme,
        isDarkMode,
        fontSize,
        minFontSize,
        fontFamily,
        overridePublisherFont,
        lineHeight,
        fullJustification,
        hyphenation,
        margin,
        fontWeight,
        pageFlipping,
        textAlign,
        pageMargins,
        twoPagesLandscape,
        reduceAnimation,
        invertColors,
      );
}
