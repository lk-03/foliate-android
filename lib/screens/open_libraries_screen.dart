import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme/theme.dart';
import 'catalog_browser_screen.dart';

/// Dedicated Open Libraries & OPDS Catalogs Screen
class OpenLibrariesScreen extends StatefulWidget {
  final List<Catalog>? catalogs;

  const OpenLibrariesScreen({
    super.key,
    this.catalogs,
  });

  @override
  State<OpenLibrariesScreen> createState() => _OpenLibrariesScreenState();
}

class _OpenLibrariesScreenState extends State<OpenLibrariesScreen> {
  late List<Catalog> _catalogs;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _catalogs = List<Catalog>.from(widget.catalogs ?? Catalog.defaultCatalogs);
    if (widget.catalogs == null) {
      _loadCustomCatalogs();
    }
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _loadCustomCatalogs() async {
    final custom = await StorageService.instance.getCustomCatalogs();
    if (mounted) {
      setState(() {
        _catalogs = [
          ...Catalog.defaultCatalogs,
          ...custom,
        ];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Catalog> get _filteredCatalogs {
    if (_searchQuery.isEmpty) return _catalogs;
    return _catalogs.where((catalog) {
      return catalog.name.toLowerCase().contains(_searchQuery) ||
          catalog.description.toLowerCase().contains(_searchQuery) ||
          catalog.tag.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _showAddCatalogDialog(FoliateThemeColors colors) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.border),
        ),
        title: Row(
          children: [
            Icon(Icons.rss_feed_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 10),
            const Text(
              'Add OPDS Catalog',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the OPDS catalog feed URL (e.g. Standard Ebooks, Calibre server):',
              style: TextStyle(fontSize: 13, color: AdwaitaColors.darkTextSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Catalog Name',
                hintText: 'My Calibre Library',
                filled: true,
                fillColor: colors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'OPDS URL',
                hintText: 'https://example.com/opds',
                filled: true,
                fillColor: colors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final url = urlController.text.trim();
              if (name.isNotEmpty && url.isNotEmpty) {
                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final newCatalog = Catalog(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  description: 'Custom OPDS catalog feed',
                  url: url,
                  tag: 'Custom OPDS',
                  isCustom: true,
                );
                await StorageService.instance.saveCustomCatalog(newCatalog);
                if (mounted) {
                  setState(() {
                    _catalogs.add(newCatalog);
                  });
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Added catalog "$name"')),
                  );
                }
              }
            },
            child: const Text('Add Catalog'),
          ),
        ],
      ),
    );
  }

  void _openCatalogDetails(Catalog catalog, FoliateThemeColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.activePill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _getCatalogIcon(catalog.id),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catalog.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            catalog.tag,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                catalog.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AdwaitaColors.darkTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: AdwaitaColors.darkTextMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        catalog.url,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AdwaitaColors.darkTextMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (catalog.isCustom) ...[
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      tooltip: 'Remove catalog',
                      onPressed: () async {
                        final nav = Navigator.of(ctx);
                        await StorageService.instance.removeCustomCatalog(catalog.id);
                        if (mounted) {
                          setState(() {
                            _catalogs.removeWhere((c) => c.id == catalog.id);
                          });
                          nav.pop();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.auto_stories_rounded, size: 18),
                      label: const Text(
                        'Browse Catalog',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _browseCatalog(catalog);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _browseCatalog(Catalog catalog) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CatalogBrowserScreen(catalog: catalog),
      ),
    );
  }

  void _searchOpenLibrary(String query) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CatalogBrowserScreen(openLibraryQuery: query),
      ),
    );
  }

  Widget _getCatalogIcon(String catalogId) {
    final primaryAccent = Theme.of(context).colorScheme.primary;
    switch (catalogId) {
      case 'gutenberg':
        return Icon(Icons.auto_stories_rounded, color: primaryAccent, size: 24);
      case 'standard_ebooks':
        return const Icon(Icons.local_library_rounded, color: AdwaitaColors.amberStreak, size: 24);
      case 'internet_archive':
        return const Icon(Icons.account_balance_rounded, color: AdwaitaColors.warmTerracotta, size: 24);
      case 'feedbooks':
        return Icon(Icons.rss_feed_rounded, color: primaryAccent, size: 24);
      default:
        return Icon(Icons.public_rounded, color: primaryAccent, size: 24);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Search & Filter Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (query) {
                        final clean = query.trim();
                        if (clean.isNotEmpty) {
                          _searchOpenLibrary(clean);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Open Library by title, author, or subject...',
                        hintStyle: TextStyle(fontSize: 13, color: colors.textMuted),
                        prefixIcon: IconButton(
                          icon: Icon(Icons.search_rounded, size: 20, color: colors.textMuted),
                          onPressed: () {
                            final clean = _searchController.text.trim();
                            if (clean.isNotEmpty) {
                              _searchOpenLibrary(clean);
                            }
                          },
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text(
                            'Try: ',
                            style: TextStyle(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w600),
                          ),
                          ...[
                            'The Metamorphosis',
                            'Frankenstein',
                            'Pride and Prejudice',
                            'Moby Dick',
                            'Sherlock Holmes',
                          ].map((suggestion) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ActionChip(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                label: Text(suggestion, style: const TextStyle(fontSize: 11)),
                                backgroundColor: colors.surfaceCard,
                                side: BorderSide(color: colors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                onPressed: () {
                                  _searchController.text = suggestion;
                                  _searchOpenLibrary(suggestion);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryAccent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _searchOpenLibrary(_searchQuery),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryAccent.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.public_rounded, color: primaryAccent, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Search Open Library for "$_searchQuery"',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: primaryAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Search millions of public domain books & classics',
                                        style: TextStyle(fontSize: 11, color: colors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: primaryAccent, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Section Title and Add Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Libraries (${_filteredCatalogs.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AdwaitaColors.darkTextSecondary,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: primaryAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add OPDS', style: TextStyle(fontSize: 13)),
                        onPressed: () => _showAddCatalogDialog(colors),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Catalog Cards List
          if (_filteredCatalogs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_rounded, size: 48, color: colors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No libraries found for "$_searchQuery"',
                      style: TextStyle(fontSize: 14, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: MediaQuery.of(context).size.width >= 850
                  ? SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 110,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildCatalogCard(_filteredCatalogs[index], colors, primaryAccent),
                        childCount: _filteredCatalogs.length,
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCatalogCard(_filteredCatalogs[index], colors, primaryAccent),
                        ),
                        childCount: _filteredCatalogs.length,
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildCatalogCard(
    Catalog catalog,
    FoliateThemeColors colors,
    Color primaryAccent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openCatalogDetails(catalog, colors),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.activePill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _getCatalogIcon(catalog.id),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              catalog.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primaryAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              catalog.tag,
                              style: TextStyle(
                                fontSize: 10,
                                color: primaryAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        catalog.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

