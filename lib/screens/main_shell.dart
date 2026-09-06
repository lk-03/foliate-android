import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/components.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme/theme.dart';
import 'annotations_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';

/// Top-level mobile navigation shell hosting the Swipeable PageView,
/// Bottom Navigation Bar, and HeaderBar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final PageController _pageController;

  List<Book> _books = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _initStorageAndBooks();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initStorageAndBooks() async {
    await StorageService.instance.preseedSampleBookIfNeeded();
    await _reloadBooks();
    _autoScanLinkedFolders();
  }

  Future<void> _reloadBooks() async {
    final loaded = await StorageService.instance.getBooks();
    if (mounted) {
      setState(() {
        _books = loaded;
      });
    }
  }

  Future<void> _autoScanLinkedFolders() async {
    final newBooks = await FolderSyncService.instance.scanAllLinkedFolders();
    if (newBooks.isNotEmpty && mounted) {
      await _reloadBooks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-synced ${newBooks.length} new book${newBooks.length == 1 ? '' : 's'} from linked folder'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToPage(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  final List<Annotation> _annotations = [
    const Annotation(
      id: 'ann-1',
      bookHash: 'a1b2c3d4e5f601',
      cfi: 'epubcfi(/6/10!/4/2/2)',
      text: 'JB was going through, as he put it, his hair phase.',
      note: 'Key introductory line',
      color: Annotation.colorYellow,
      createdAt: 1725458000000,
    ),
  ];

  String get _currentTitle {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Library';
      case 2:
        return 'Favorites';
      case 3:
        return 'Notes';
      default:
        return 'Foliate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;
    final booksMap = {for (final b in _books) b.hash: b};

    return Scaffold(
      backgroundColor: colors.windowBackground,
      // Clean Android Top App Bar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(54),
        child: Container(
          decoration: BoxDecoration(
            color: colors.headerBar,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const SizedBox(width: 16),
                AppLogo(
                  size: 28,
                  accentColor: primaryAccent,
                ),
                const SizedBox(width: 12),
                Text(
                  _currentTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.palette_outlined, size: 22),
                  tooltip: 'App Theme & Accent',
                  onPressed: () => AppThemeSheet.show(context),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  tooltip: 'Settings & Storage',
                  onPressed: () => SettingsSheet.show(
                    context,
                    onRescan: () async {
                      await _autoScanLinkedFolders();
                      await _reloadBooks();
                    },
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),

      // Instagram-Style Swipeable PageView Body
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          HapticFeedback.selectionClick();
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          HomeScreen(
            books: _books,
            onNavigateToLibrary: () => _navigateToPage(1),
            onBooksChanged: _reloadBooks,
          ),
          LibraryScreen(
            books: _books,
            onRefresh: () async {
              await _autoScanLinkedFolders();
              await _reloadBooks();
            },
            onBooksChanged: _reloadBooks,
          ),
          FavoritesScreen(books: _books),
          AnnotationsScreen(
            annotations: _annotations,
            booksMap: booksMap,
          ),
        ],
      ),

      // Material 3 Expressive Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.headerBar,
          border: Border(top: BorderSide(color: colors.border.withValues(alpha: 0.5), width: 0.8)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _navigateToPage,
          backgroundColor: colors.headerBar,
          indicatorColor: primaryAccent.withValues(alpha: 0.2),
          elevation: 0,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: primaryAccent),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories_rounded, color: primaryAccent),
              label: 'Library',
            ),
            NavigationDestination(
              icon: const Icon(Icons.favorite_outline_rounded),
              selectedIcon: Icon(Icons.favorite_rounded, color: primaryAccent),
              label: 'Favorites',
            ),
            NavigationDestination(
              icon: const Icon(Icons.bookmarks_outlined),
              selectedIcon: Icon(Icons.bookmarks_rounded, color: primaryAccent),
              label: 'Notes',
            ),
          ],
        ),
      ),
    );
  }
}


