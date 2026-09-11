import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/components.dart';
import '../models/models.dart';
import '../theme/theme.dart';

/// Stitch & Apple Books inspired Reader Profile Screen.
/// Provides reading metrics (streak, time, books finished, pace),
/// annual reading challenge pacing, weekly consistency tracker,
/// Folio sync status card, and appearance preferences.
class ProfileScreen extends StatefulWidget {
  final List<Book> books;
  final ReadingHabits? readingHabits;
  final ValueChanged<int>? onDailyGoalChanged;
  final ValueChanged<int>? onYearlyGoalChanged;
  final Future<void> Function()? onRescanStorage;

  const ProfileScreen({
    super.key,
    required this.books,
    this.readingHabits,
    this.onDailyGoalChanged,
    this.onYearlyGoalChanged,
    this.onRescanStorage,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _userNameKey = 'foliate_profile_user_name';
  String _userName = 'Elena Vance';
  bool _isRescanning = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_userNameKey);
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() => _userName = saved);
    }
  }

  Future<void> _saveUserName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, newName);
    if (mounted) {
      setState(() => _userName = newName);
    }
  }

  void _showEditNameDialog(FoliateThemeColors colors) {
    final controller = TextEditingController(text: _userName);
    final primaryAccent = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        title: const Text(
          'Edit Reader Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Reader Name',
            hintText: 'Enter your name',
            filled: true,
            fillColor: colors.windowBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: primaryAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                _saveUserName(val);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDailyGoalDialog(int currentGoal, FoliateThemeColors colors) {
    int selected = currentGoal;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: colors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
          title: const Text(
            'Daily Reading Goal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set how many minutes you want to read every day.',
                style: TextStyle(fontSize: 13, color: colors.textMuted),
              ),
              const SizedBox(height: 20),
              Text(
                '$selected min',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryAccent,
                ),
              ),
              const SizedBox(height: 12),
              Slider(
                value: selected.toDouble(),
                min: 5,
                max: 120,
                divisions: 23,
                activeColor: primaryAccent,
                label: '$selected min',
                onChanged: (v) => setDlgState(() => selected = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primaryAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                widget.onDailyGoalChanged?.call(selected);
                Navigator.of(ctx).pop();
              },
              child: const Text('Save Goal'),
            ),
          ],
        ),
      ),
    );
  }

  void _showYearlyGoalDialog(int currentGoal, FoliateThemeColors colors) {
    int selected = currentGoal;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: colors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
          title: const Text(
            '2026 Annual Challenge Goal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How many books do you aim to complete in 2026?',
                style: TextStyle(fontSize: 13, color: colors.textMuted),
              ),
              const SizedBox(height: 20),
              Text(
                '$selected books',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryAccent,
                ),
              ),
              const SizedBox(height: 12),
              Slider(
                value: selected.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                activeColor: primaryAccent,
                label: '$selected books',
                onChanged: (v) => setDlgState(() => selected = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primaryAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                widget.onYearlyGoalChanged?.call(selected);
                Navigator.of(ctx).pop();
              },
              child: const Text('Save Target'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReadingTime(int totalSeconds) {
    if (totalSeconds < 60) {
      return '$totalSeconds sec';
    }
    final minutes = totalSeconds ~/ 60;
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = (totalSeconds / 3600).toStringAsFixed(1);
    return '$hours hrs';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ?? FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;
    final habits = widget.readingHabits ?? const ReadingHabits();

    return Scaffold(
      backgroundColor: colors.windowBackground,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // Profile Hero Card
          _buildProfileHero(context, colors, primaryAccent),
          const SizedBox(height: 24),

          // 4-Card Analytics Grid
          _buildAnalyticsGrid(context, colors, primaryAccent, habits),
          const SizedBox(height: 24),

          // 2026 Annual Challenge Card
          _buildAnnualChallengeCard(context, colors, primaryAccent, habits),
          const SizedBox(height: 24),

          // Weekly Consistency Card
          _buildWeeklyConsistencyCard(context, colors, primaryAccent, habits),
          const SizedBox(height: 24),

          // Folio Sync & Offline Storage Card
          _buildFolioSyncCard(colors, primaryAccent),
          const SizedBox(height: 24),

          // Preferences & Quick Settings List
          _buildPreferencesSection(context, colors, primaryAccent),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHero(BuildContext context, FoliateThemeColors colors, Color primaryAccent) {
    final initials = _userName.trim().isNotEmpty
        ? _userName.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : 'EV';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          // Avatar with subtle glow
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryAccent.withValues(alpha: 0.15),
              border: Border.all(color: primaryAccent.withValues(alpha: 0.5), width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: primaryAccent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name & Membership Tier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Bibliophile Tier',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Member since 2024',
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: colors.textMuted),
            tooltip: 'Edit Profile Name',
            onPressed: () => _showEditNameDialog(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsGrid(
    BuildContext context,
    FoliateThemeColors colors,
    Color primaryAccent,
    ReadingHabits habits,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reading Metrics',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              'Live stats',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.local_fire_department_rounded,
                iconColor: AdwaitaColors.amberStreak,
                value: '${habits.currentStreak} Days',
                label: 'Reading Streak',
                subtitle: 'Longest: ${habits.longestStreak} days',
                colors: colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.schedule_rounded,
                iconColor: primaryAccent,
                value: _formatReadingTime(habits.totalReadingSeconds),
                label: 'Time Read',
                subtitle: '${habits.totalSessions} sessions',
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.menu_book_rounded,
                iconColor: primaryAccent,
                value: '${habits.booksFinishedThisYear.length} Books',
                label: 'Books Finished',
                subtitle: 'In 2026 challenge',
                colors: colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.speed_rounded,
                iconColor: primaryAccent,
                value: '240 WPM',
                label: 'Reading Pace',
                subtitle: 'Avg ~1.2 pg/min',
                colors: colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String subtitle,
    required FoliateThemeColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: colors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAnnualChallengeCard(
    BuildContext context,
    FoliateThemeColors colors,
    Color primaryAccent,
    ReadingHabits habits,
  ) {
    final finished = habits.booksFinishedThisYear.length;
    final target = habits.yearlyGoalBooks;
    final fraction = habits.yearlyProgressFraction;
    final percent = (fraction * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.military_tech_rounded, size: 22, color: primaryAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2026 Reading Challenge',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$finished of $target books completed ($percent%)',
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: colors.textMuted),
                tooltip: 'Edit Yearly Goal',
                onPressed: () => _showYearlyGoalDialog(target, colors),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                finished >= target
                    ? 'Goal completed! Keep going!'
                    : '${target - finished} book${(target - finished) == 1 ? '' : 's'} remaining',
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  finished >= target ? 'Completed' : 'On Track',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyConsistencyCard(
    BuildContext context,
    FoliateThemeColors colors,
    Color primaryAccent,
    ReadingHabits habits,
  ) {
    final activityMap = habits.getWeekActivityMap();
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final currentDayIndex = DateTime.now().weekday; // 1..7

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Consistency',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${habits.todayMinutesRead} of ${habits.dailyGoalMinutes} min today',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _showDailyGoalDialog(habits.dailyGoalMinutes, colors),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Adjust Goal',
                  style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Day bubbles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final dayNum = i + 1;
              final isActive = activityMap[dayNum] ?? false;
              final isToday = dayNum == currentDayIndex;

              return Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? primaryAccent
                          : isToday
                              ? primaryAccent.withValues(alpha: 0.15)
                              : colors.windowBackground,
                      border: Border.all(
                        color: isToday
                            ? primaryAccent
                            : isActive
                                ? primaryAccent
                                : colors.border,
                        width: isToday ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: isActive
                          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                          : isToday
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryAccent,
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? primaryAccent : colors.textMuted,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFolioSyncCard(
    FoliateThemeColors colors,
    Color primaryAccent,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.cloud_done_rounded, size: 22, color: primaryAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Folio Sync Active',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.books.length} volumes indexed locally',
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              if (_isRescanning)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: Icon(Icons.sync_rounded, size: 20, color: colors.textMuted),
                  tooltip: 'Rescan Storage Folders',
                  onPressed: () async {
                    setState(() => _isRescanning = true);
                    HapticFeedback.lightImpact();
                    await widget.onRescanStorage?.call();
                    if (mounted) {
                      setState(() => _isRescanning = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Storage scan and sync completed'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'All reading progress, bookmarks, and highlights are stored offline on this device with instant zero-latency restoration.',
            style: TextStyle(fontSize: 12, color: colors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(
    BuildContext context,
    FoliateThemeColors colors,
    Color primaryAccent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.palette_outlined, size: 20, color: primaryAccent),
            ),
            title: const Text('App Theme & Accent Color', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Midnight, Light, Sepia & custom accents', style: TextStyle(fontSize: 12, color: colors.textMuted)),
            trailing: Icon(Icons.chevron_right_rounded, size: 20, color: colors.textMuted),
            onTap: () => AppThemeSheet.show(context),
          ),
          Divider(height: 1, color: colors.border),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.folder_outlined, size: 20, color: primaryAccent),
            ),
            title: const Text('Storage & Linked Directories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Manage auto-synced book directories', style: TextStyle(fontSize: 12, color: colors.textMuted)),
            trailing: Icon(Icons.chevron_right_rounded, size: 20, color: colors.textMuted),
            onTap: () => SettingsSheet.show(
              context,
              onRescan: () async {
                await widget.onRescanStorage?.call();
              },
            ),
          ),
          Divider(height: 1, color: colors.border),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline_rounded, size: 20, color: primaryAccent),
            ),
            title: const Text('About Foliate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Version 1.0.0 • Open Source EPUB Engine', style: TextStyle(fontSize: 12, color: colors.textMuted)),
            trailing: Icon(Icons.chevron_right_rounded, size: 20, color: colors.textMuted),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Foliate',
                applicationVersion: '1.0.0',
                applicationLegalese: 'Crafted with Flutter & Foliate.js core.',
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}
