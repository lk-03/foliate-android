import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme.dart';
import 'app_logo.dart';

/// Bottom sheet allowing users to customize the App UI theme mode and accent color
class AppThemeSheet extends ConsumerWidget {
  const AppThemeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AppThemeSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(appThemeProvider);
    final themeNotifier = ref.read(appThemeProvider.notifier);
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Sheet Title & Live Preview
            Row(
              children: [
                AppLogo(
                  size: 36,
                  accentColor: themeState.accent.color,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Appearance',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Customize UI theme and accent color',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Theme Mode Selector
            Text(
              'INTERFACE MODE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                _buildModeOption(
                  context: context,
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  isSelected: themeState.mode == ThemeMode.dark,
                  colors: colors,
                  accentColor: themeState.accent.color,
                  onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
                ),
                const SizedBox(width: 8),
                _buildModeOption(
                  context: context,
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  isSelected: themeState.mode == ThemeMode.light,
                  colors: colors,
                  accentColor: themeState.accent.color,
                  onTap: () => themeNotifier.setThemeMode(ThemeMode.light),
                ),
                const SizedBox(width: 8),
                _buildModeOption(
                  context: context,
                  label: 'System',
                  icon: Icons.brightness_auto_rounded,
                  isSelected: themeState.mode == ThemeMode.system,
                  colors: colors,
                  accentColor: themeState.accent.color,
                  onTap: () => themeNotifier.setThemeMode(ThemeMode.system),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Accent Color Selector
            Text(
              'ACCENT COLOR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppAccentColor.values.map((accent) {
                final isSelected = themeState.accent == accent;
                return InkWell(
                  onTap: () => themeNotifier.setAccent(accent),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.color.withValues(alpha: 0.15)
                          : colors.inputBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? accent.color : colors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: accent.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          accent.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? colors.textPrimary : colors.textSecondary,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: accent.color,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required FoliateThemeColors colors,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withValues(alpha: 0.15) : colors.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accentColor : colors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? accentColor : colors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
