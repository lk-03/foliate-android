import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/components.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme/theme.dart';
import 'annotations_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'open_libraries_screen.dart';
import 'profile_screen.dart';
import 'reader_screen.dart';

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
    await _reloadAnnotations();
    await _reloadHabits();
    _autoScanLinkedFolders();
    _checkFirstLaunchOnboarding();
  }

  Future<void> _checkFirstLaunchOnboarding() async {
    final isFirst = await StorageService.instance.isFirstLaunch();
    if (isFirst && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: false,
            backgroundColor: Colors.transparent,
            builder: (_) => OnboardingWelcomeSheet(
              onCompleted: () async {
                await _reloadBooks();
                await _reloadHabits();
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          );
        }
      });
    }
  }

  Future<void> _reloadBooks() async {
    final loaded = await StorageService.instance.getBooks();
    if (mounted) {
      setState(() {
        _books = loaded;
      });
    }
  }

  Future<void> _reloadAnnotations() async {
    final loaded = await StorageService.instance.getAllAnnotations();
    if (mounted) {
      setState(() {
        _annotations = loaded;
      });
    }
  }

  Future<void> _reloadHabits() async {
    final habits = await StorageService.instance.getReadingHabits();
    if (mounted) {
      setState(() {
        _readingHabits = habits;
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
    if (index == 0 || index == 4) {
      _reloadHabits();
    }
    if (index == 3) {
      _reloadAnnotations();
    }
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
  }

  ReadingHabits _readingHabits = const ReadingHabits();
  List<Annotation> _annotations = [];

  String get _currentTitle {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Library';
      case 2:
        return 'Explore';
      case 3:
        return 'Annotations';
      case 4:
        return 'Profile';
      default:
        return 'Foliate';
    }
  }

  List<Widget> _buildPages(Map<String, Book> booksMap) {
    return [
      HomeScreen(
        books: _books,
        readingHabits: _readingHabits,
        onNavigateToLibrary: () => _navigateToPage(1),
        onNavigateToExplore: () => _navigateToPage(2),
        onBooksChanged: () async {
          await _reloadBooks();
          await _reloadHabits();
        },
        onDailyGoalChanged: (newMins) async {
          final updated = await StorageService.instance.updateDailyReadingGoal(newMins);
          setState(() => _readingHabits = updated);
        },
        onYearlyGoalChanged: (newTarget) async {
          final updated = await StorageService.instance.updateYearlyReadingGoal(newTarget);
          setState(() => _readingHabits = updated);
        },
      ),
      LibraryScreen(
        books: _books,
        onRefresh: () async {
          await _autoScanLinkedFolders();
          await _reloadBooks();
        },
        onBooksChanged: _reloadBooks,
      ),
      const OpenLibrariesScreen(),
      AnnotationsScreen(
        annotations: _annotations,
        booksMap: booksMap,
        onAnnotationsChanged: _reloadAnnotations,
        onAnnotationTap: (annotation, book) {
          if (book != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReaderScreen(
                  book: book,
                  initialCfi: annotation.cfi,
                ),
              ),
            ).then((_) => _reloadAnnotations());
          }
        },
      ),
      ProfileScreen(
        books: _books,
        readingHabits: _readingHabits,
        onDailyGoalChanged: (newMins) async {
          final updated = await StorageService.instance.updateDailyReadingGoal(newMins);
          setState(() => _readingHabits = updated);
        },
        onYearlyGoalChanged: (newTarget) async {
          final updated = await StorageService.instance.updateYearlyReadingGoal(newTarget);
          setState(() => _readingHabits = updated);
        },
        onRescanStorage: () async {
          await _autoScanLinkedFolders();
          await _reloadBooks();
          await _reloadHabits();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;
    final booksMap = {for (final b in _books) b.hash: b};
    final pages = _buildPages(booksMap);
    final isWide = MediaQuery.of(context).size.width >= 850;

    return Shortcuts(
      shortcuts: FoliateShortcuts.shellShortcuts,
      child: Actions(
        actions: {
          NavigateShellTabIntent: CallbackAction<NavigateShellTabIntent>(
            onInvoke: (intent) => _navigateToPage(intent.tabIndex),
          ),
        },
        child: Focus(
          autofocus: true,
          child: isWide
              ? Scaffold(
                  backgroundColor: colors.windowBackground,
                  body: Row(
                    children: [
                      // Desktop Libadwaita Navigation Sidebar
                      _buildDesktopSidebar(colors, primaryAccent),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: colors.border,
                      ),
                      // Main Content Area
                      Expanded(
                        child: Scaffold(
                          backgroundColor: colors.windowBackground,
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
                                    const SizedBox(width: 20),
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
                                    const SizedBox(width: 12),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          body: pages[_currentIndex],
                        ),
                      ),
                    ],
                  ),
                )
              : Scaffold(
                  backgroundColor: colors.windowBackground,
                  // Mobile Top App Bar
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

                  // Swipeable PageView Body
                  body: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      if (_currentIndex == index) return;
                      HapticFeedback.selectionClick();
                      setState(() {
                        _currentIndex = index;
                      });
                      if (index == 0 || index == 4) {
                        _reloadHabits();
                      }
                      if (index == 3) {
                        _reloadAnnotations();
                      }
                    },
                    children: pages,
                  ),

                  // Stitch Signature Bottom Navigation Bar
                  bottomNavigationBar: _buildStitchBottomBar(colors, primaryAccent),
                ),
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar(FoliateThemeColors colors, Color primaryAccent) {
    final navItems = [
      (index: 0, label: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home_rounded),
      (index: 1, label: 'Library', icon: Icons.auto_stories_outlined, selectedIcon: Icons.auto_stories_rounded),
      (index: 2, label: 'Explore', icon: Icons.explore_outlined, selectedIcon: Icons.explore_rounded),
      (index: 3, label: 'Annotations', icon: Icons.bookmarks_outlined, selectedIcon: Icons.bookmarks_rounded),
      (index: 4, label: 'Profile', icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded),
    ];

    return Container(
      width: 220,
      color: colors.headerBar,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header / Brand
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Row(
                children: [
                  AppLogo(size: 30, accentColor: primaryAccent),
                  const SizedBox(width: 12),
                  const Text(
                    'Foliate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: navItems.map((item) {
                  final isSelected = _currentIndex == item.index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: isSelected
                          ? primaryAccent.withValues(alpha: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _navigateToPage(item.index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                size: 20,
                                color: isSelected ? primaryAccent : colors.textMuted,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? primaryAccent : colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Bottom Theme & Settings Tiles
            Padding(
              padding: const EdgeInsets.all(10),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      leading: const Icon(Icons.palette_outlined, size: 20),
                      title: const Text('Theme', style: TextStyle(fontSize: 13)),
                      onTap: () => AppThemeSheet.show(context),
                    ),
                    ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      leading: const Icon(Icons.settings_outlined, size: 20),
                      title: const Text('Settings', style: TextStyle(fontSize: 13)),
                      onTap: () => SettingsSheet.show(
                        context,
                        onRescan: () async {
                          await _autoScanLinkedFolders();
                          await _reloadBooks();
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

  Widget _buildStitchBottomBar(FoliateThemeColors colors, Color primaryAccent) {
    final items = [
      (
        index: 0,
        label: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
      ),
      (
        index: 1,
        label: 'Library',
        icon: Icons.auto_stories_outlined,
        selectedIcon: Icons.auto_stories_rounded,
      ),
      (
        index: 2,
        label: 'Explore',
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore_rounded,
      ),
      (
        index: 3,
        label: 'Annotations',
        icon: Icons.bookmarks_outlined,
        selectedIcon: Icons.bookmarks_rounded,
      ),
      (
        index: 4,
        label: 'Profile',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.headerBar,
        border: Border(
          top: BorderSide(
            color: colors.border.withValues(alpha: 0.8),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final isSelected = _currentIndex == item.index;
              return Expanded(
                child: InkWell(
                  onTap: () => _navigateToPage(item.index),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stitch signature pill highlight with smooth pop-up & pop-out animation
                      SizedBox(
                        width: 56,
                        height: 30,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Smooth pop-up / pop-out pill highlight
                            AnimatedScale(
                              scale: isSelected ? 1.0 : 0.0,
                              duration: Duration(milliseconds: isSelected ? 220 : 160),
                              curve: isSelected ? Curves.easeOutBack : Curves.easeInCubic,
                              child: AnimatedOpacity(
                                opacity: isSelected ? 1.0 : 0.0,
                                duration: Duration(milliseconds: isSelected ? 180 : 130),
                                curve: Curves.easeInOut,
                                child: Container(
                                  width: 56,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: primaryAccent,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),

                            // Icon with smooth scale and color response
                            AnimatedScale(
                              scale: isSelected ? 1.0 : 0.92,
                              duration: Duration(milliseconds: isSelected ? 200 : 150),
                              curve: isSelected ? Curves.easeOutCubic : Curves.easeInCubic,
                              child: Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                size: 20,
                                color: isSelected ? Colors.white : colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? primaryAccent : colors.textMuted,
                          letterSpacing: -0.1,
                        ),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}


