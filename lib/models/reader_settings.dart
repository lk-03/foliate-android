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

/// What reading progress metric to display in the reader HUD
enum ProgressDisplayType {
  pagesLeftInChapter,
  timeLeftInChapter,
  timeLeftInBook,
  pageNumber,
  percentage;

  String get id => name;

  String get label {
    switch (this) {
      case ProgressDisplayType.pagesLeftInChapter:
        return 'Pages Left in Chapter';
      case ProgressDisplayType.timeLeftInChapter:
        return 'Time Left in Chapter';
      case ProgressDisplayType.timeLeftInBook:
        return 'Time Left in Book';
      case ProgressDisplayType.pageNumber:
        return 'Page Number';
      case ProgressDisplayType.percentage:
        return 'Percentage';
    }
  }

  ProgressDisplayType next() {
    final values = ProgressDisplayType.values;
    return values[(index + 1) % values.length];
  }

  static ProgressDisplayType fromString(String? value) {
    if (value == null) return ProgressDisplayType.pagesLeftInChapter;
    for (final v in ProgressDisplayType.values) {
      if (v.name.toLowerCase() == value.toLowerCase()) return v;
    }
    return ProgressDisplayType.pagesLeftInChapter;
  }
}

/// Screen position for the reading progress indicator
enum ProgressDisplayLocation {
  bottomCenter,
  topCenter,
  bottomLeft,
  bottomRight,
  topLeft,
  topRight,
  hidden;

  String get id => name;

  String get label {
    switch (this) {
      case ProgressDisplayLocation.bottomCenter:
        return 'Bottom Center';
      case ProgressDisplayLocation.topCenter:
        return 'Top Center';
      case ProgressDisplayLocation.bottomLeft:
        return 'Bottom Left';
      case ProgressDisplayLocation.bottomRight:
        return 'Bottom Right';
      case ProgressDisplayLocation.topLeft:
        return 'Top Left';
      case ProgressDisplayLocation.topRight:
        return 'Top Right';
      case ProgressDisplayLocation.hidden:
        return 'Hidden';
    }
  }

  static ProgressDisplayLocation fromString(String? value) {
    if (value == null) return ProgressDisplayLocation.bottomCenter;
    for (final v in ProgressDisplayLocation.values) {
      if (v.name.toLowerCase() == value.toLowerCase()) return v;
    }
    return ProgressDisplayLocation.bottomCenter;
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
  final ProgressDisplayType progressDisplayType;
  final ProgressDisplayLocation progressDisplayLocation;
  final bool quickActionsBar;
  final bool showPageSlider;
  final double paddingTop;
  final double paddingBottom;

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
    this.margin = 0.08,
    this.fontWeight = 400,
    this.pageFlipping = 'horizontal',
    this.textAlign = 'justify',
    this.pageMargins = true,
    this.twoPagesLandscape = false,
    this.reduceAnimation = false,
    this.invertColors = false,
    this.progressDisplayType = ProgressDisplayType.pagesLeftInChapter,
    this.progressDisplayLocation = ProgressDisplayLocation.bottomCenter,
    this.quickActionsBar = false,
    this.showPageSlider = false,
    this.paddingTop = 84.0,
    this.paddingBottom = 88.0,
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
    ProgressDisplayType? progressDisplayType,
    ProgressDisplayLocation? progressDisplayLocation,
    bool? quickActionsBar,
    bool? showPageSlider,
    double? paddingTop,
    double? paddingBottom,
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
      progressDisplayType: progressDisplayType ?? this.progressDisplayType,
      progressDisplayLocation: progressDisplayLocation ?? this.progressDisplayLocation,
      quickActionsBar: quickActionsBar ?? this.quickActionsBar,
      showPageSlider: showPageSlider ?? this.showPageSlider,
      paddingTop: paddingTop ?? this.paddingTop,
      paddingBottom: paddingBottom ?? this.paddingBottom,
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
      'progressDisplayType': progressDisplayType.id,
      'progressDisplayLocation': progressDisplayLocation.id,
      'quickActionsBar': quickActionsBar,
      'showPageSlider': showPageSlider,
      'paddingTop': paddingTop,
      'paddingBottom': paddingBottom,
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
      margin: (map['margin'] as num?)?.toDouble() ?? 0.08,
      fontWeight: (map['fontWeight'] as num?)?.toInt() ?? 400,
      pageFlipping: map['pageFlipping'] as String? ?? 'horizontal',
      textAlign: map['textAlign'] as String? ?? 'justify',
      pageMargins: map['pageMargins'] as bool? ?? true,
      twoPagesLandscape: map['twoPagesLandscape'] as bool? ?? false,
      reduceAnimation: map['reduceAnimation'] as bool? ?? false,
      invertColors: map['invertColors'] as bool? ?? false,
      progressDisplayType: ProgressDisplayType.fromString(map['progressDisplayType'] as String?),
      progressDisplayLocation: ProgressDisplayLocation.fromString(map['progressDisplayLocation'] as String?),
      quickActionsBar: map['quickActionsBar'] as bool? ?? false,
      showPageSlider: map['showPageSlider'] as bool? ?? false,
      paddingTop: (map['paddingTop'] as num?)?.toDouble() ?? 84.0,
      paddingBottom: (map['paddingBottom'] as num?)?.toDouble() ?? 88.0,
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
        other.invertColors == invertColors &&
        other.progressDisplayType == progressDisplayType &&
        other.progressDisplayLocation == progressDisplayLocation &&
        other.quickActionsBar == quickActionsBar &&
        other.showPageSlider == showPageSlider &&
        other.paddingTop == paddingTop &&
        other.paddingBottom == paddingBottom;
  }

  @override
  int get hashCode => Object.hashAll([
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
        progressDisplayType,
        progressDisplayLocation,
        quickActionsBar,
        showPageSlider,
        paddingTop,
        paddingBottom,
      ]);
}
