import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/dictionary_service.dart';
import '../theme/adwaita_colors.dart';
import '../theme/adwaita_theme.dart';

enum LookupTab { definition, wikipedia }

class DictionaryLookupSheet extends StatefulWidget {
  final String query;
  final Color? accentColor;

  const DictionaryLookupSheet({
    super.key,
    required this.query,
    this.accentColor,
  });

  static Future<void> show(
    BuildContext context, {
    required String query,
    Color? accentColor,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DictionaryLookupSheet(
        query: query,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<DictionaryLookupSheet> createState() => _DictionaryLookupSheetState();
}

class _DictionaryLookupSheetState extends State<DictionaryLookupSheet> {
  LookupTab _activeTab = LookupTab.definition;
  bool _isLoading = true;
  DictionaryEntry? _entry;
  WikipediaSummary? _wiki;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final clean = widget.query.trim();

    try {
      final results = await Future.wait([
        DictionaryService.instance.lookupWord(clean),
        DictionaryService.instance.lookupWikipedia(clean),
      ]);

      if (mounted) {
        setState(() {
          _entry = results[0] as DictionaryEntry?;
          _wiki = results[1] as WikipediaSummary?;
          _isLoading = false;

          // Auto-select Wikipedia tab if definition not found but wiki is
          if (_entry == null && _wiki != null) {
            _activeTab = LookupTab.wikipedia;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openSystemSearch() async {
    final term = Uri.encodeComponent('define ${widget.query.trim()}');
    final uri = Uri.parse('https://www.google.com/search?q=$term');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWikiArticle() async {
    if (_wiki?.articleUrl == null) return;
    final uri = Uri.parse(_wiki!.articleUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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

            // Header Bar with Word & Close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.query.trim(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_entry?.phonetic != null)
                          Text(
                            _entry!.phonetic!,
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: colors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Tab Selector Pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                height: 38,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colors.inputBackground,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        label: 'Dictionary',
                        tab: LookupTab.definition,
                        colors: colors,
                        accent: accent,
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        label: 'Wikipedia',
                        tab: LookupTab.wikipedia,
                        colors: colors,
                        accent: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Content Area
            Flexible(
              child: _isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                    )
                  : _activeTab == LookupTab.definition
                      ? _buildDefinitionContent(colors, accent)
                      : _buildWikipediaContent(colors, accent),
            ),

            // Footer System Search Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: colors.border),
                        foregroundColor: colors.textPrimary,
                      ),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text(
                        'Search in System Dictionary',
                        style: TextStyle(fontSize: 13),
                      ),
                      onPressed: _openSystemSearch,
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

  Widget _buildTabButton({
    required String label,
    required LookupTab tab,
    required FoliateThemeColors colors,
    required Color accent,
  }) {
    final isSelected = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDefinitionContent(FoliateThemeColors colors, Color accent) {
    if (_entry == null || _entry!.meanings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _error != null ? Icons.wifi_off_rounded : Icons.search_off_rounded,
                size: 40,
                color: colors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                _error != null
                    ? 'Offline or unavailable. Try searching system dictionary below.'
                    : 'No definition found for "${widget.query.trim()}".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
              ),
              if (_wiki != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      setState(() => _activeTab = LookupTab.wikipedia),
                  child: Text('View on Wikipedia instead →',
                      style: TextStyle(color: accent)),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      itemCount: _entry!.meanings.length,
      itemBuilder: (context, meaningIndex) {
        final meaning = _entry!.meanings[meaningIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Part of speech badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  meaning.partOfSpeech.toLowerCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Definitions
              ...meaning.definitions.asMap().entries.map((defEntry) {
                final idx = defEntry.key;
                final def = defEntry.value;
                final example = idx < meaning.examples.length
                    ? meaning.examples[idx]
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${idx + 1}. ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textMuted,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              def,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            if (example != null && example.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                '“$example”',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: colors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Synonyms pills if any
              if (meaning.synonyms.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: meaning.synonyms.take(6).map((syn) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.surfaceCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        syn,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildWikipediaContent(FoliateThemeColors colors, Color accent) {
    if (_wiki == null || _wiki!.extract.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded, size: 40, color: colors.textMuted),
              const SizedBox(height: 12),
              Text(
                'No Wikipedia article found for "${widget.query.trim()}".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_wiki!.description != null && _wiki!.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _wiki!.description!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ),

          if (_wiki!.thumbnailUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _wiki!.thumbnailUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),

          Text(
            _wiki!.extract,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 12),

          if (_wiki!.articleUrl != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Read full article on Wikipedia'),
                onPressed: _openWikiArticle,
              ),
            ),
        ],
      ),
    );
  }
}
