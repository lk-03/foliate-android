import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/adwaita_colors.dart';
import '../theme/adwaita_theme.dart';

enum QuoteCardFormat {
  square('Square (1:1)', 1.0),
  story('Story (9:16)', 9 / 16);

  final String label;
  final double ratio;
  const QuoteCardFormat(this.label, this.ratio);
}

enum QuoteCardTheme {
  warmPaper(
    id: 'warmPaper',
    name: 'Warm Paper',
    bg: Color(0xFFF6EFE3),
    textColor: Color(0xFF26201D),
    accentColor: Color(0xFFC85A32),
    borderColor: Color(0xFFE2D6C5),
    fontFamily: 'Noto Serif',
    isDark: false,
  ),
  amoledPitch(
    id: 'amoledPitch',
    name: 'AMOLED Pitch',
    bg: Color(0xFF000000),
    textColor: Color(0xFFF5F5F5),
    accentColor: Color(0xFFF5A623),
    borderColor: Color(0xFF2B2B2B),
    fontFamily: 'Noto Serif',
    isDark: true,
  ),
  modernSlate(
    id: 'modernSlate',
    name: 'Modern Slate',
    bg: Color(0xFF1E2227),
    textColor: Color(0xFFE6EDF3),
    accentColor: Color(0xFF58A6FF),
    borderColor: Color(0xFF323942),
    fontFamily: 'Inter',
    isDark: true,
  ),
  classicMonospace(
    id: 'classicMonospace',
    name: 'Classic Monospace',
    bg: Color(0xFFFAF9F6),
    textColor: Color(0xFF1C1C1E),
    accentColor: Color(0xFF6366F1),
    borderColor: Color(0xFFE5E5EA),
    fontFamily: 'monospace',
    isDark: false,
  );

  final String id;
  final String name;
  final Color bg;
  final Color textColor;
  final Color accentColor;
  final Color borderColor;
  final String fontFamily;
  final bool isDark;

  const QuoteCardTheme({
    required this.id,
    required this.name,
    required this.bg,
    required this.textColor,
    required this.accentColor,
    required this.borderColor,
    required this.fontFamily,
    required this.isDark,
  });
}

class QuoteCardGeneratorSheet extends StatefulWidget {
  final String quoteText;
  final String? bookTitle;
  final String? author;
  final String? coverUri;
  final Uint8List? coverBytes;
  final Color? accentColor;

  const QuoteCardGeneratorSheet({
    super.key,
    required this.quoteText,
    this.bookTitle,
    this.author,
    this.coverUri,
    this.coverBytes,
    this.accentColor,
  });

  static Future<void> show(
    BuildContext context, {
    required String quoteText,
    String? bookTitle,
    String? author,
    String? coverUri,
    Uint8List? coverBytes,
    Color? accentColor,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuoteCardGeneratorSheet(
        quoteText: quoteText,
        bookTitle: bookTitle,
        author: author,
        coverUri: coverUri,
        coverBytes: coverBytes,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<QuoteCardGeneratorSheet> createState() =>
      _QuoteCardGeneratorSheetState();
}

class _QuoteCardGeneratorSheetState extends State<QuoteCardGeneratorSheet> {
  final GlobalKey _cardKey = GlobalKey();
  QuoteCardFormat _format = QuoteCardFormat.square;
  QuoteCardTheme _selectedTheme = QuoteCardTheme.warmPaper;
  bool _isExporting = false;

  Future<Uint8List?> _captureCardPng() async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing quote card: $e');
      return null;
    }
  }

  Future<void> _shareCard() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final pngBytes = await _captureCardPng();
      if (pngBytes == null) throw Exception('Could not render image');

      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      final title = widget.bookTitle ?? 'Foliate';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '“${widget.quoteText.trim()}” — $title',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share card: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _saveCard() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final pngBytes = await _captureCardPng();
      if (pngBytes == null) throw Exception('Could not render image');

      final appDir = await getApplicationDocumentsDirectory();
      final file = File(
          '${appDir.path}/foliate_quote_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved quote card to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save card: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _copyQuoteText() {
    final title = widget.bookTitle != null ? ' — ${widget.bookTitle}' : '';
    final author = widget.author != null ? ', by ${widget.author}' : '';
    final fullText = '“${widget.quoteText.trim()}”$title$author';
    Clipboard.setData(ClipboardData(text: fullText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote copied to clipboard')),
    );
  }

  double _computeFontSize() {
    final length = widget.quoteText.length;
    if (_format == QuoteCardFormat.story) {
      if (length < 80) return 22;
      if (length < 180) return 18;
      if (length < 320) return 15;
      return 13;
    } else {
      if (length < 80) return 18;
      if (length < 180) return 15;
      if (length < 320) return 13;
      return 11;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final accent = widget.accentColor ?? AdwaitaColors.terracottaDark;

    return Container(
      decoration: BoxDecoration(
        color: colors.windowBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: colors.border),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Quote Card',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copy text',
                    onPressed: _copyQuoteText,
                  ),
                ],
              ),
            ),

            // Format & Theme Selectors
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Row(
                children: [
                  // Format Picker (Square / Story)
                  Container(
                    height: 34,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colors.inputBackground,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: QuoteCardFormat.values.map((f) {
                        final isSel = _format == f;
                        return GestureDetector(
                          onTap: () => setState(() => _format = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isSel ? accent : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              f == QuoteCardFormat.square ? '1:1' : '9:16',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    isSel ? FontWeight.w600 : FontWeight.w500,
                                color: isSel ? Colors.white : colors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Theme Chips Horizontal Scroll
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: QuoteCardTheme.values.map((th) {
                          final isSel = _selectedTheme == th;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(
                                th.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSel ? Colors.white : colors.textPrimary,
                                ),
                              ),
                              selected: isSel,
                              selectedColor: accent,
                              backgroundColor: colors.inputBackground,
                              side: BorderSide(
                                color: isSel ? accent : colors.border,
                              ),
                              onSelected: (_) =>
                                  setState(() => _selectedTheme = th),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Preview Area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: _buildCardWidget(),
                  ),
                ),
              ),
            ),

            // Action Buttons Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: colors.border),
                        foregroundColor: colors.textPrimary,
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Save Image'),
                      onPressed: _isExporting ? null : _saveCard,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share_rounded, size: 18),
                      label: Text(_isExporting ? 'Sharing...' : 'Share Card'),
                      onPressed: _isExporting ? null : _shareCard,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardWidget() {
    final th = _selectedTheme;
    final isStory = _format == QuoteCardFormat.story;
    final fontSize = _computeFontSize();

    return AspectRatio(
      aspectRatio: _format.ratio,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isStory ? 28 : 24,
          vertical: isStory ? 36 : 22,
        ),
        decoration: BoxDecoration(
          color: th.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: th.borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Decorative stylized quote icon
            Text(
              '“',
              style: TextStyle(
                fontFamily: th.fontFamily,
                fontSize: isStory ? 56 : 44,
                height: 0.7,
                fontWeight: FontWeight.bold,
                color: th.accentColor,
              ),
            ),

            const SizedBox(height: 8),

            // Quote Excerpt
            Expanded(
              child: Center(
                child: Text(
                  widget.quoteText.trim(),
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: th.fontFamily,
                    fontSize: fontSize,
                    height: 1.55,
                    color: th.textColor,
                    fontStyle: th.id == 'warmPaper'
                        ? FontStyle.italic
                        : FontStyle.normal,
                    letterSpacing: th.id == 'classicMonospace' ? -0.2 : 0.1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Subtle divider
            Container(
              height: 1,
              color: th.borderColor,
              margin: const EdgeInsets.only(bottom: 12),
            ),

            // Citation Footer Row
            Row(
              children: [
                // Cover Thumbnail or Fallback Box
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: widget.coverBytes != null
                      ? Image.memory(
                          widget.coverBytes!,
                          width: 32,
                          height: 46,
                          fit: BoxFit.cover,
                        )
                      : (widget.coverUri != null &&
                              File(widget.coverUri!).existsSync())
                          ? Image.file(
                              File(widget.coverUri!),
                              width: 32,
                              height: 46,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 32,
                              height: 46,
                              color: th.borderColor,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.menu_book_rounded,
                                size: 16,
                                color: th.textColor.withValues(alpha: 0.6),
                              ),
                            ),
                ),

                const SizedBox(width: 10),

                // Title & Author
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.bookTitle ?? 'Unknown Book',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: th.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: th.textColor,
                        ),
                      ),
                      if (widget.author != null)
                        Text(
                          widget.author!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: th.fontFamily,
                            fontSize: 11,
                            color: th.textColor.withValues(alpha: 0.65),
                          ),
                        ),
                    ],
                  ),
                ),

                // Foliate brand mark
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: th.borderColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Foliate',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: th.textColor.withValues(alpha: 0.7),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
