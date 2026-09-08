import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import 'reader_hud_controls.dart';

// Reusable UI helpers
Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AdwaitaColors.darkTextSecondary,
        letterSpacing: -0.1,
      ),
    ),
  );
}

Widget _buildCard({
  required List<Widget> children,
  required FoliateThemeColors colors,
}) {
  return Material(
    color: colors.surfaceCard,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: colors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

Widget _buildStepper({
  required String label,
  required String valueText,
  required VoidCallback? onDecrement,
  required VoidCallback? onIncrement,
  required FoliateThemeColors colors,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Container(
          decoration: BoxDecoration(
            color: colors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 18),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: onDecrement,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  valueText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: onIncrement,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Dedicated Bottom Sheet for Reader Layout, Margins, Hyphenation & Flow Mode
class ReaderLayoutSheet extends StatefulWidget {
  final ReaderSettings settings;
  final ValueChanged<ReaderSettings> onSettingsChanged;
  final Color? accentColor;

  const ReaderLayoutSheet({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.accentColor,
  });

  @override
  State<ReaderLayoutSheet> createState() => _ReaderLayoutSheetState();
}

class _ReaderLayoutSheetState extends State<ReaderLayoutSheet> {
  late ReaderSettings _current;

  @override
  void initState() {
    super.initState();
    _current = widget.settings;
  }

  void _update(ReaderSettings newSettings) {
    setState(() => _current = newSettings);
    widget.onSettingsChanged(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final activeColor = widget.accentColor ?? AdwaitaColors.foliateGreen;

    return Container(
      decoration: BoxDecoration(
        color: colors.windowBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: colors.border),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close layout',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Layout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Sheet Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Page & Margins'),
                    _buildCard(
                      colors: colors,
                      children: [
                        _buildStepper(
                          label: 'Side Margins',
                          valueText: '${(_current.margin * 100).round()}%',
                          onDecrement: _current.margin > 0.025
                              ? () => _update(_current.copyWith(
                                    margin: double.parse((_current.margin - 0.02).toStringAsFixed(2)),
                                  ))
                              : null,
                          onIncrement: _current.margin < 0.20
                              ? () => _update(_current.copyWith(
                                    margin: double.parse((_current.margin + 0.02).toStringAsFixed(2)),
                                  ))
                              : null,
                          colors: colors,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    _buildSectionHeader('Typography Layout'),
                    _buildCard(
                      colors: colors,
                      children: [
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          title: const Text('Hyphenation', style: TextStyle(fontSize: 14)),
                          subtitle: Text(
                            'Hyphenates long words at the end of lines',
                            style: TextStyle(fontSize: 12, color: colors.textMuted),
                          ),
                          value: _current.hyphenation,
                          activeThumbColor: activeColor,
                          onChanged: (val) => _update(_current.copyWith(hyphenation: val)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    _buildSectionHeader('Flow & Columns'),
                    _buildCard(
                      colors: colors,
                      children: [
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          title: const Text('Continuous Scrolled Mode', style: TextStyle(fontSize: 14)),
                          subtitle: Text(
                            'Scroll vertically through chapters instead of turning pages',
                            style: TextStyle(fontSize: 12, color: colors.textMuted),
                          ),
                          value: _current.pageFlipping == 'vertical',
                          activeThumbColor: activeColor,
                          onChanged: (val) => _update(_current.copyWith(
                            pageFlipping: val ? 'vertical' : 'horizontal',
                          )),
                        ),
                        Divider(color: colors.border, height: 1),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          title: const Text('Two Columns (Landscape)', style: TextStyle(fontSize: 14)),
                          subtitle: Text(
                            'Show two side-by-side pages in horizontal orientation',
                            style: TextStyle(fontSize: 12, color: colors.textMuted),
                          ),
                          value: _current.twoPagesLandscape,
                          activeThumbColor: activeColor,
                          onChanged: (val) => _update(_current.copyWith(twoPagesLandscape: val)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    _buildSectionHeader('Reading Progress Display'),
                    _buildCard(
                      colors: colors,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Display Type', style: TextStyle(fontSize: 14)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildChoiceChip(
                                    label: 'Pages Left',
                                    isSelected: _current.progressDisplayType == ProgressDisplayType.pagesLeftInChapter,
                                    onSelected: () => _update(_current.copyWith(progressDisplayType: ProgressDisplayType.pagesLeftInChapter)),
                                    colors: colors,
                                    activeColor: activeColor,
                                  ),
                                  _buildChoiceChip(
                                    label: 'Time Left',
                                    isSelected: _current.progressDisplayType == ProgressDisplayType.timeLeftInChapter,
                                    onSelected: () => _update(_current.copyWith(progressDisplayType: ProgressDisplayType.timeLeftInChapter)),
                                    colors: colors,
                                    activeColor: activeColor,
                                  ),
                                  _buildChoiceChip(
                                    label: 'Percentage',
                                    isSelected: _current.progressDisplayType == ProgressDisplayType.percentage,
                                    onSelected: () => _update(_current.copyWith(progressDisplayType: ProgressDisplayType.percentage)),
                                    colors: colors,
                                    activeColor: activeColor,
                                  ),
                                  _buildChoiceChip(
                                    label: 'Page Number',
                                    isSelected: _current.progressDisplayType == ProgressDisplayType.pageNumber,
                                    onSelected: () => _update(_current.copyWith(progressDisplayType: ProgressDisplayType.pageNumber)),
                                    colors: colors,
                                    activeColor: activeColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Divider(color: colors.border, height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Display Location', style: TextStyle(fontSize: 14)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildChoiceChip(
                                    label: 'Bottom Center',
                                    isSelected: _current.progressDisplayLocation == ProgressDisplayLocation.bottomCenter,
                                    onSelected: () => _update(_current.copyWith(progressDisplayLocation: ProgressDisplayLocation.bottomCenter)),
                                    colors: colors,
                                    activeColor: activeColor,
                                  ),
                                  _buildChoiceChip(
                                    label: 'Top Center',
                                    isSelected: _current.progressDisplayLocation == ProgressDisplayLocation.topCenter,
                                    onSelected: () => _update(_current.copyWith(progressDisplayLocation: ProgressDisplayLocation.topCenter)),
                                    colors: colors,
                                    activeColor: activeColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required FoliateThemeColors colors,
    required Color activeColor,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : colors.textMuted,
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: colors.inputBackground,
      side: BorderSide(
        color: isSelected ? activeColor : colors.border,
        width: 1,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

/// Detailed Bottom Sheet for Typography & Theme Customization with Live Text Preview
class ReaderThemeCustomizeSheet extends StatefulWidget {
  final ReaderSettings settings;
  final ValueChanged<ReaderSettings> onSettingsChanged;
  final String? sampleExcerpt;
  final Color? accentColor;

  const ReaderThemeCustomizeSheet({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.sampleExcerpt,
    this.accentColor,
  });

  @override
  State<ReaderThemeCustomizeSheet> createState() => _ReaderThemeCustomizeSheetState();
}

class _ReaderThemeCustomizeSheetState extends State<ReaderThemeCustomizeSheet> {
  late ReaderSettings _current;
  bool _isFontListExpanded = false;

  @override
  void initState() {
    super.initState();
    _current = widget.settings;
  }

  void _update(ReaderSettings newSettings) {
    setState(() => _current = newSettings);
    widget.onSettingsChanged(newSettings);
  }

  static const List<({String id, String label, String? flutterFamily})> _availableFonts = [
    (id: 'publisher', label: 'Original', flutterFamily: null),
    (id: 'serif', label: 'Noto Serif', flutterFamily: 'Noto Serif'),
    (id: 'literata', label: 'Literata', flutterFamily: 'Literata'),
    (id: 'ebgaramond', label: 'EB Garamond', flutterFamily: 'EB Garamond'),
    (id: 'newsreader', label: 'Newsreader', flutterFamily: 'Newsreader'),
    (id: 'lora', label: 'Lora', flutterFamily: 'Lora'),
    (id: 'sourceserif4', label: 'Source Serif 4', flutterFamily: 'Source Serif 4'),
    (id: 'bitter', label: 'Bitter', flutterFamily: 'Bitter'),
    (id: 'sans', label: 'Inter', flutterFamily: 'Inter'),
    (id: 'monospace', label: 'Monospace', flutterFamily: 'monospace'),
  ];

  String get _currentFontLabel {
    for (final f in _availableFonts) {
      if (f.id == _current.fontFamily) return f.label;
    }
    return 'Noto Serif';
  }

  String? get _currentFlutterFamily {
    for (final f in _availableFonts) {
      if (f.id == _current.fontFamily) return f.flutterFamily;
    }
    return 'Noto Serif';
  }

  ({Color bg, Color text}) get _themePreviewColors {
    for (final opt in kReaderThemeOptions) {
      if (opt.mode == _current.theme) {
        return (bg: opt.bg, text: opt.text);
      }
    }
    if (_current.isDarkMode) {
      return (bg: const Color(0xFF1E1D1B), text: const Color(0xFFEDEDED));
    }
    return (bg: const Color(0xFFFFFFFF), text: const Color(0xFF1A1A1A));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final activeColor = widget.accentColor ?? AdwaitaColors.foliateGreen;
    final previewColors = _themePreviewColors;

    final previewTextAlign = _current.fullJustification
        ? TextAlign.justify
        : (_current.textAlign == 'center'
            ? TextAlign.center
            : (_current.textAlign == 'right' ? TextAlign.right : TextAlign.left));

    final excerptText = widget.sampleExcerpt ??
        'He sighed. \u201cBel, you have known your whole life that you cannot remain in Tyre.\u201d \u201cI am not a child,\u201d I hissed, heat rising in my cheeks...';

    return Container(
      decoration: BoxDecoration(
        color: colors.windowBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: colors.border),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Customize Theme',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_rounded, size: 22),
                    tooltip: 'Done',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- LIVE TEXT PREVIEW BOX (Inspired by Reference Images 3 & 4) ---
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: previewColors.bg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.8),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aa',
                            style: TextStyle(
                              fontSize: 26,
                              fontFamily: _currentFlutterFamily,
                              fontWeight: _current.fontWeight >= 600
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: previewColors.text,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 180),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontFamily: _currentFlutterFamily,
                              fontWeight: _current.fontWeight >= 600
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              height: _current.lineHeight,
                              color: previewColors.text.withValues(alpha: 0.92),
                            ),
                            textAlign: previewTextAlign,
                            child: Text(excerptText),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- TEXT SECTION ---
                    _buildSectionHeader('Text'),
                    _buildCard(
                      colors: colors,
                      children: [
                        // Font Family Selector Tile
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          leading: const Text(
                            'Aa',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          title: const Text('Font', style: TextStyle(fontSize: 14)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentFontLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textMuted,
                                  fontFamily: _currentFlutterFamily,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _isFontListExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_right_rounded,
                                size: 20,
                                color: colors.textMuted,
                              ),
                            ],
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isFontListExpanded = !_isFontListExpanded);
                          },
                        ),

                        // Expanded Font List (Matching Reference Image 4)
                        if (_isFontListExpanded) ...[
                          Divider(color: colors.border, height: 1),
                          Container(
                            color: colors.surfaceCard.withValues(alpha: 0.5),
                            child: Column(
                              children: _availableFonts.map((f) {
                                final isSelected = f.id == _current.fontFamily;
                                return InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    _update(_current.copyWith(fontFamily: f.id));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          f.label,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: f.flutterFamily,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? activeColor : colors.textPrimary,
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_rounded,
                                            size: 18,
                                            color: activeColor,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],

                        Divider(color: colors.border, height: 1),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          title: const Text('Override Publisher Font', style: TextStyle(fontSize: 14)),
                          subtitle: Text(
                            'Enforces selected font across all book chapters',
                            style: TextStyle(fontSize: 12, color: colors.textMuted),
                          ),
                          value: _current.overridePublisherFont,
                          activeThumbColor: activeColor,
                          onChanged: (val) => _update(_current.copyWith(overridePublisherFont: val)),
                        ),
                        Divider(color: colors.border, height: 1),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          title: const Text('Bold Text', style: TextStyle(fontSize: 14)),
                          value: _current.fontWeight >= 600,
                          activeThumbColor: activeColor,
                          onChanged: (val) => _update(_current.copyWith(fontWeight: val ? 700 : 400)),
                        ),
                        Divider(color: colors.border, height: 1),

                        // Line Spacing (Moved from menu)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Line Spacing', style: TextStyle(fontSize: 14)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [1.2, 1.4, 1.6, 1.8, 2.0].map((lh) {
                                  final isLh = (_current.lineHeight - lh).abs() < 0.08;
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      _update(_current.copyWith(lineHeight: lh));
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isLh ? activeColor : colors.inputBackground,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isLh ? activeColor : colors.border,
                                        ),
                                      ),
                                      child: Text(
                                        '${lh}x',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isLh ? FontWeight.bold : FontWeight.w500,
                                          color: isLh ? Colors.white : colors.textMuted,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        Divider(color: colors.border, height: 1),

                        // Text Alignment (Moved from menu)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Alignment', style: TextStyle(fontSize: 14)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildAlignIconButton(
                                    icon: Icons.format_align_justify_rounded,
                                    tooltip: 'Full Justification',
                                    isSelected: _current.fullJustification,
                                    onTap: () => _update(_current.copyWith(
                                      fullJustification: true,
                                      textAlign: 'justify',
                                    )),
                                    colors: colors,
                                    activeColor: activeColor,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildAlignIconButton(
                                    icon: Icons.format_align_left_rounded,
                                    tooltip: 'Left Align',
                                    isSelected: !_current.fullJustification && _current.textAlign != 'center',
                                    onTap: () => _update(_current.copyWith(
                                      fullJustification: false,
                                      textAlign: 'left',
                                    )),
                                    colors: colors,
                                    activeColor: activeColor,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildAlignIconButton(
                                    icon: Icons.format_align_center_rounded,
                                    tooltip: 'Center Align',
                                    isSelected: !_current.fullJustification && _current.textAlign == 'center',
                                    onTap: () => _update(_current.copyWith(
                                      fullJustification: false,
                                      textAlign: 'center',
                                    )),
                                    colors: colors,
                                    activeColor: activeColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Reset Theme Button
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.redAccent),
                        label: const Text(
                          'Reset Typography',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _update(_current.copyWith(
                            fontFamily: 'serif',
                            lineHeight: 1.50,
                            fullJustification: true,
                            fontWeight: 400,
                            overridePublisherFont: true,
                            textAlign: 'justify',
                          ));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlignIconButton({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
    required FoliateThemeColors colors,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.18) : colors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : colors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? activeColor : colors.textMuted,
        ),
      ),
    );
  }
}

/// Slide-up Hierarchical Table of Contents & Bookmarks Sheet
class ReaderTOCSheet extends StatefulWidget {
  final List<TOCItem> toc;
  final List<Bookmark> bookmarks;
  final ValueChanged<String> onChapterSelected;
  final ValueChanged<Bookmark>? onDeleteBookmark;

  const ReaderTOCSheet({
    super.key,
    required this.toc,
    this.bookmarks = const [],
    required this.onChapterSelected,
    this.onDeleteBookmark,
  });

  @override
  State<ReaderTOCSheet> createState() => _ReaderTOCSheetState();
}

class _ReaderTOCSheetState extends State<ReaderTOCSheet> {
  int _selectedTab = 0; // 0: Contents, 1: Bookmarks

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Segmented Header Bar
            Row(
              children: [
                _buildTabButton('Contents', 0, colors),
                const SizedBox(width: 8),
                _buildTabButton('Bookmarks (${widget.bookmarks.length})', 1, colors),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _selectedTab == 0
                  ? (widget.toc.isEmpty
                      ? Center(
                          child: Text(
                            'No chapters found',
                            style: TextStyle(color: colors.textMuted),
                          ),
                        )
                      : ListView(
                          children: _buildTOCList(widget.toc, colors, context),
                        ))
                  : (widget.bookmarks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bookmark_border_rounded,
                                  size: 40,
                                  color: colors.textMuted,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No Bookmarks Yet',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap the top-right ribbon while reading to bookmark any page.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: widget.bookmarks.length,
                          separatorBuilder: (_, _) => Divider(color: colors.border, height: 1),
                          itemBuilder: (context, index) {
                            final b = widget.bookmarks[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.bookmark_rounded,
                                color: Color(0xFFE01B24),
                                size: 22,
                              ),
                              title: Text(
                                b.chapterTitle ?? 'Page ${b.pageNumber ?? 1}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${b.percentage.round()}% through book',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textMuted,
                                ),
                              ),
                              trailing: widget.onDeleteBookmark != null
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                      tooltip: 'Delete Bookmark',
                                      onPressed: () {
                                        widget.onDeleteBookmark!(b);
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              onTap: () {
                                widget.onChapterSelected(b.cfi);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int tabIndex, FoliateThemeColors colors) {
    final isSelected = _selectedTab == tabIndex;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTab = tabIndex);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.activePill : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AdwaitaColors.foliateGreen : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colors.textPrimary : colors.textMuted,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTOCList(
    List<TOCItem> items,
    FoliateThemeColors colors,
    BuildContext context,
  ) {
    final list = <Widget>[];
    for (final item in items) {
      list.add(
        ListTile(
          contentPadding: EdgeInsets.only(left: 12.0 + (item.depth * 16.0), right: 12.0),
          title: Text(
            item.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: item.depth == 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onTap: () {
            if (item.href != null) {
              widget.onChapterSelected(item.href!);
              Navigator.of(context).pop();
            }
          },
        ),
      );
      if (item.subitems.isNotEmpty) {
        list.addAll(_buildTOCList(item.subitems, colors, context));
      }
    }
    return list;
  }
}

/// In-book Search Sheet with live streaming results, chapter grouping, and bold excerpts
class ReaderSearchSheet extends StatefulWidget {
  final String initialQuery;
  final bool initialMatchCase;
  final ValueNotifier<List<SearchSection>> sectionsNotifier;
  final ValueNotifier<bool> isSearchingNotifier;
  final ValueNotifier<int> totalMatchesNotifier;
  final void Function(String query, bool matchCase) onSearch;
  final VoidCallback onClear;
  final void Function(SearchResultItem match, int globalIndex) onSelectMatch;

  const ReaderSearchSheet({
    super.key,
    this.initialQuery = '',
    this.initialMatchCase = false,
    required this.sectionsNotifier,
    required this.isSearchingNotifier,
    required this.totalMatchesNotifier,
    required this.onSearch,
    required this.onClear,
    required this.onSelectMatch,
  });

  @override
  State<ReaderSearchSheet> createState() => _ReaderSearchSheetState();
}

class _ReaderSearchSheetState extends State<ReaderSearchSheet> {
  late final TextEditingController _controller;
  late bool _matchCase;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _matchCase = widget.initialMatchCase;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String text) {
    _debounceTimer?.cancel();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      widget.onClear();
      setState(() {});
      return;
    }
    setState(() {});
    if (trimmed.length < 2) return;
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      widget.onSearch(trimmed, _matchCase);
    });
  }

  void _submitNow() {
    _debounceTimer?.cancel();
    final trimmed = _controller.text.trim();
    if (trimmed.isNotEmpty) {
      widget.onSearch(trimmed, _matchCase);
    }
  }

  void _toggleMatchCase() {
    setState(() => _matchCase = !_matchCase);
    final trimmed = _controller.text.trim();
    if (trimmed.isNotEmpty) {
      widget.onSearch(trimmed, _matchCase);
    }
  }

  void _clearInput() {
    _debounceTimer?.cancel();
    _controller.clear();
    widget.onClear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Column(
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Search Bar Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
                    onSubmitted: (_) => _submitNow(),
                    autofocus: widget.initialQuery.isEmpty,
                    decoration: InputDecoration(
                      hintText: 'Search in book...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_controller.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: _clearInput,
                              tooltip: 'Clear',
                            ),
                          // [Aa] Case Sensitive Toggle Pill
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: InkWell(
                              onTap: _toggleMatchCase,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _matchCase
                                      ? AdwaitaColors.foliateGreen.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _matchCase
                                        ? AdwaitaColors.foliateGreen
                                        : colors.border,
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  'Aa',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _matchCase
                                        ? AdwaitaColors.foliateGreen
                                        : colors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      filled: true,
                      fillColor: colors.inputBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: widget.isSearchingNotifier,
                  builder: (context, isSearching, _) {
                    return isSearching
                        ? Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded),
                            tooltip: 'Search',
                            onPressed: _submitNow,
                          );
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Match count header bar
            ValueListenableBuilder<int>(
              valueListenable: widget.totalMatchesNotifier,
              builder: (context, totalMatches, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: widget.isSearchingNotifier,
                  builder: (context, isSearching, _) {
                    if (totalMatches == 0 && !isSearching) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isSearching
                            ? (totalMatches > 0
                                ? '$totalMatches matches found so far (searching...)'
                                : 'Searching chapters...')
                            : '$totalMatches match${totalMatches == 1 ? '' : 'es'} found',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSearching ? AdwaitaColors.foliateGreen : colors.textMuted,
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 6),

            // Results List
            Expanded(
              child: ValueListenableBuilder<List<SearchSection>>(
                valueListenable: widget.sectionsNotifier,
                builder: (context, sections, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: widget.isSearchingNotifier,
                    builder: (context, isSearching, _) {
                      if (_controller.text.trim().isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_rounded, size: 48, color: colors.textMuted.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'Type to search the book',
                                style: TextStyle(color: colors.textMuted, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }

                      if (sections.isEmpty) {
                        if (isSearching) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Scanning chapters...',
                                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Center(
                            child: Text(
                              'No matches found for "${_controller.text}"',
                              style: TextStyle(color: colors.textMuted, fontSize: 13),
                            ),
                          );
                        }
                      }

                      // Build grouped list
                      int runningIndex = 0;
                      final sectionStartIndices = <int>[];
                      for (final sec in sections) {
                        sectionStartIndices.add(runningIndex);
                        runningIndex += sec.subitems.length;
                      }

                      return ListView.builder(
                        itemCount: sections.length,
                        itemBuilder: (context, sectionIdx) {
                          final section = sections[sectionIdx];
                          final startIdx = sectionStartIndices[sectionIdx];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Chapter header
                              Container(
                                margin: const EdgeInsets.only(top: 8, bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colors.inputBackground,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.bookmark_outline_rounded, size: 15, color: colors.textMuted),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        section.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: colors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colors.surfaceCard,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${section.matchCount}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AdwaitaColors.foliateGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Excerpts in section
                              ...List.generate(section.subitems.length, (itemIdx) {
                                final item = section.subitems[itemIdx];
                                final globalIdx = startIdx + itemIdx;

                                return InkWell(
                                  onTap: () => widget.onSelectMatch(item, globalIdx),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    margin: const EdgeInsets.symmetric(vertical: 2),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: colors.border.withValues(alpha: 0.5), width: 0.5),
                                      ),
                                    ),
                                    child: _buildExcerptText(item.excerpt, colors),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExcerptText(SearchExcerpt excerpt, FoliateThemeColors colors) {
    if (excerpt.match.isEmpty) {
      return Text(
        excerpt.fullText,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, height: 1.4, color: colors.textSecondary),
      );
    }

    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: colors.textSecondary,
        ),
        children: [
          TextSpan(text: excerpt.pre),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AdwaitaColors.foliateGreen.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AdwaitaColors.foliateGreen.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Text(
                excerpt.match,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AdwaitaColors.foliateGreen,
                ),
              ),
            ),
          ),
          TextSpan(text: excerpt.post),
        ],
      ),
    );
  }
}


/// Floating contextual highlight palette triggered on text selection
class ReaderAnnotationBar extends StatefulWidget {
  final String selectedText;
  final String? cfi;
  final void Function(String cfi, String color, String? note) onSave;
  final VoidCallback onDismiss;

  const ReaderAnnotationBar({
    super.key,
    required this.selectedText,
    required this.cfi,
    required this.onSave,
    required this.onDismiss,
  });

  @override
  State<ReaderAnnotationBar> createState() => _ReaderAnnotationBarState();
}

class _ReaderAnnotationBarState extends State<ReaderAnnotationBar> {
  String _selectedColor = Annotation.colorYellow;
  final TextEditingController _noteController = TextEditingController();
  bool _showNoteField = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Quote Preview
          Row(
            children: [
              Expanded(
                child: Text(
                  '“${widget.selectedText}”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.selectedText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quote copied to clipboard')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: widget.onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Color Chips Row
          Row(
            children: [
              for (final colorHex in Annotation.defaultColors)
                GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorHex),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _parseHex(colorHex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == colorHex
                            ? Colors.white
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showNoteField ? Icons.speaker_notes_off_rounded : Icons.note_add_rounded,
                  size: 20,
                ),
                tooltip: 'Add Note',
                onPressed: () => setState(() => _showNoteField = !_showNoteField),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AdwaitaColors.foliateGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                onPressed: () {
                  if (widget.cfi != null) {
                    widget.onSave(
                      widget.cfi!,
                      _selectedColor,
                      _noteController.text.trim().isNotEmpty
                          ? _noteController.text.trim()
                          : null,
                    );
                  }
                  widget.onDismiss();
                },
                child: const Text('Highlight'),
              ),
            ],
          ),

          // Note Field (if enabled)
          if (_showNoteField) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Add an optional note...',
                filled: true,
                fillColor: colors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Modal bottom sheet to view, edit color/note, or delete an existing highlight
class AnnotationEditSheet extends StatefulWidget {
  final Annotation annotation;
  final void Function(Annotation updated) onUpdate;
  final VoidCallback onDelete;

  const AnnotationEditSheet({
    super.key,
    required this.annotation,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<AnnotationEditSheet> createState() => _AnnotationEditSheetState();
}

class _AnnotationEditSheetState extends State<AnnotationEditSheet> {
  late String _currentColor;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.annotation.color;
    _noteController = TextEditingController(text: widget.annotation.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: colors.border),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Highlight',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copy',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.annotation.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quote copied to clipboard')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AdwaitaColors.libadwaitaRed,
                  ),
                  tooltip: 'Delete',
                  onPressed: () {
                    widget.onDelete();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.inputBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                '“${widget.annotation.text}”',
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Color selection row
            Row(
              children: [
                for (final colorHex in Annotation.defaultColors)
                  GestureDetector(
                    onTap: () {
                      setState(() => _currentColor = colorHex);
                      final updated = widget.annotation.copyWith(
                        color: colorHex,
                        note: _noteController.text.trim().isNotEmpty
                            ? _noteController.text.trim()
                            : null,
                      );
                      widget.onUpdate(updated);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _parseHex(colorHex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _currentColor == colorHex
                              ? Colors.white
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Add an optional note...',
                filled: true,
                fillColor: colors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (text) {
                final updated = widget.annotation.copyWith(
                  color: _currentColor,
                  note: text.trim().isNotEmpty ? text.trim() : null,
                );
                widget.onUpdate(updated);
              },
            ),
          ],
        ),
      ),
    );
  }
}
