import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/services.dart';
import '../theme/theme.dart';
import 'app_logo.dart';
import 'app_theme_sheet.dart';

/// Modal bottom sheet for app-wide settings, storage & linked folders,
/// appearance shortcuts, and about info.
/// Enforces strictly zero textual emojis.
class SettingsSheet extends ConsumerStatefulWidget {
  final VoidCallback? onRescan;

  const SettingsSheet({
    super.key,
    this.onRescan,
  });

  static Future<void> show(BuildContext context, {VoidCallback? onRescan}) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SettingsSheet(onRescan: onRescan),
    );
  }

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  int _bookCount = 0;
  List<String> _linkedFolders = [];
  bool _isRescanning = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final books = await StorageService.instance.getBooks();
    final folders = await StorageService.instance.getLinkedFolders();
    if (mounted) {
      setState(() {
        _bookCount = books.length;
        _linkedFolders = folders;
      });
    }
  }

  Future<void> _triggerRescan() async {
    if (_isRescanning) return;
    final hasPerm = await StoragePermissionService.ensurePermission(context);
    if (!hasPerm) return;

    setState(() => _isRescanning = true);
    HapticFeedback.selectionClick();

    try {
      final newBooks = await FolderSyncService.instance.scanAllLinkedFolders();
      await _loadStats();
      widget.onRescan?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newBooks.isEmpty
                  ? 'Folders are up to date'
                  : 'Imported ${newBooks.length} new book${newBooks.length == 1 ? '' : 's'}',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRescanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;
    final appTheme = ref.watch(appThemeProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colors.headerBar,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: colors.border),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colors.textMuted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 22, color: primaryAccent),
                  const SizedBox(width: 10),
                  Text(
                    'Settings & Library',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Section: Appearance
                  _buildSectionHeader('Appearance & Accent', colors),
                  Material(
                    color: colors.surfaceCard,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.palette_outlined, color: primaryAccent, size: 20),
                      ),
                      title: Text(
                        '${appTheme.accent.label} Accent',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        appTheme.mode == ThemeMode.system
                            ? 'System Theme'
                            : (appTheme.mode == ThemeMode.dark ? 'Dark Theme' : 'Light Theme'),
                        style: TextStyle(fontSize: 13, color: colors.textMuted),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: appTheme.accent.color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        AppThemeSheet.show(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section: Library & Storage
                  _buildSectionHeader('Storage & Folders', colors),
                  Material(
                    color: colors.surfaceCard,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colors.border),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.auto_stories_rounded, color: primaryAccent, size: 22),
                          title: const Text('Books in Library', style: TextStyle(fontSize: 14)),
                          trailing: Text(
                            '$_bookCount',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: primaryAccent,
                            ),
                          ),
                        ),
                        Divider(height: 1, indent: 52, color: colors.border),
                        ListTile(
                          leading: Icon(Icons.folder_copy_outlined, color: primaryAccent, size: 22),
                          title: const Text('Linked Folders', style: TextStyle(fontSize: 14)),
                          trailing: Text(
                            '${_linkedFolders.length}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Divider(height: 1, indent: 52, color: colors.border),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: _isRescanning ? null : _triggerRescan,
                              icon: _isRescanning
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.sync_rounded, size: 18),
                              label: Text(
                                _isRescanning ? 'Scanning Folders...' : 'Rescan Linked Folders',
                              ),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section: About Foliate
                  _buildSectionHeader('About', colors),
                  Material(
                    color: colors.surfaceCard,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppLogo(size: 38, accentColor: primaryAccent),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Foliate Mobile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Version 1.0.0 (Phase 3)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Minimalist, gesture-driven e-book reader for Android with offline foliate-js engine rendering.',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: primaryAccent.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 14, color: primaryAccent),
                                const SizedBox(width: 6),
                                Text(
                                  'foliate-js Engine Active',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, FoliateThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors.textMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
