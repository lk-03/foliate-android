import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme/theme.dart';

/// Interactive Libadwaita bottom sheet for selecting favorite reading niches and genres.
class NicheSelectorSheet extends StatefulWidget {
  final List<String>? initialSelectedNiches;
  final ValueChanged<List<String>>? onSaved;

  const NicheSelectorSheet({
    super.key,
    this.initialSelectedNiches,
    this.onSaved,
  });

  /// Displays the niche selector modal bottom sheet.
  static Future<List<String>?> show(
    BuildContext context, {
    List<String>? initialSelectedNiches,
    ValueChanged<List<String>>? onSaved,
  }) async {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NicheSelectorSheet(
        initialSelectedNiches: initialSelectedNiches,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<NicheSelectorSheet> createState() => _NicheSelectorSheetState();
}

class _NicheSelectorSheetState extends State<NicheSelectorSheet> {
  final Set<String> _selectedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialSelections();
  }

  Future<void> _loadInitialSelections() async {
    if (widget.initialSelectedNiches != null &&
        widget.initialSelectedNiches!.isNotEmpty) {
      setState(() {
        _selectedIds.addAll(
          widget.initialSelectedNiches!.map((n) => n.toLowerCase()),
        );
        _isLoading = false;
      });
    } else {
      final saved = await StorageService.instance.getFavoriteNiches();
      if (mounted) {
        setState(() {
          _selectedIds.addAll(saved.map((n) => n.toLowerCase()));
          _isLoading = false;
        });
      }
    }
  }

  void _toggleNiche(String id) {
    setState(() {
      final normalized = id.toLowerCase();
      if (_selectedIds.contains(normalized)) {
        if (_selectedIds.length > 1) {
          _selectedIds.remove(normalized);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please keep at least one favorite niche selected.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _selectedIds.add(normalized);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds.clear();
      _selectedIds.addAll(ReadingNiche.allNiches.map((n) => n.id.toLowerCase()));
    });
  }

  void _resetToDefault() {
    setState(() {
      _selectedIds.clear();
      _selectedIds.addAll(
        ReadingNiche.defaultNicheIds.map((n) => n.toLowerCase()),
      );
    });
  }

  Future<void> _saveAndClose() async {
    final list = _selectedIds.toList();
    await StorageService.instance.setFavoriteNiches(list);
    widget.onSaved?.call(list);
    if (mounted) {
      Navigator.of(context).pop(list);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<FoliateThemeColors>() ?? FoliateThemeColors.dark;
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colors.windowBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.8)),
          left: BorderSide(color: colors.border.withValues(alpha: 0.8)),
          right: BorderSide(color: colors.border.withValues(alpha: 0.8)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_awesome_outlined,
                    size: 22,
                    color: primaryAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reading Tastes & Niches',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select genres to shape your dashboard recommendations',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action shortcuts row (Reset / Select All)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                TextButton(
                  onPressed: _resetToDefault,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(
                    'Default Niches',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(
                    'Select All (${ReadingNiche.allNiches.length})',
                    style: TextStyle(fontSize: 12, color: primaryAccent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Divider(height: 1, color: colors.border.withValues(alpha: 0.6)),

          // Niches Grid / List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: ReadingNiche.allNiches.length,
                    itemBuilder: (context, index) {
                      final niche = ReadingNiche.allNiches[index];
                      final isSelected =
                          _selectedIds.contains(niche.id.toLowerCase());

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleNiche(niche.id),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryAccent.withValues(alpha: 0.12)
                                    : colors.surfaceCard.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryAccent
                                      : colors.border.withValues(alpha: 0.6),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primaryAccent.withValues(alpha: 0.2)
                                          : colors.windowBackground,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryAccent.withValues(alpha: 0.4)
                                            : colors.border.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Icon(
                                      niche.icon,
                                      size: 20,
                                      color: isSelected
                                          ? primaryAccent
                                          : colors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          niche.label,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? colors.textPrimary
                                                : colors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          niche.description,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colors.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: primaryAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (_) => _toggleNiche(niche.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Bar with Save Button
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: 12 + MediaQuery.of(context).viewPadding.bottom,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              border: Border(
                top: BorderSide(color: colors.border.withValues(alpha: 0.8)),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_selectedIds.length} niches selected',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Updated in real-time',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _saveAndClose,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Apply Tastes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
