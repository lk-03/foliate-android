import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';

/// Service managing device storage access permissions for Android 10-16.
/// Automatically bypasses on desktop and test environments.
/// Enforces strictly zero textual emojis.
class StoragePermissionService {
  static const MethodChannel _channel =
      MethodChannel('com.foliate.foliate/storage_permissions');

  /// Returns true if the application has permission to read external storage/folders.
  static Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('hasStoragePermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system settings or permission prompt for storage management.
  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('requestStoragePermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Ensures storage permission is granted. If not, displays a friendly explanation dialog
  /// and directs the user to grant access in system settings.
  static Future<bool> ensurePermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    final granted = await hasPermission();
    if (granted) return true;

    if (!context.mounted) return false;

    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        title: Row(
          children: [
            Icon(Icons.folder_shared_rounded, color: primaryAccent, size: 24),
            const SizedBox(width: 10),
            const Text(
              'Storage Access Needed',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To scan and import e-books from your device folders, Foliate needs permission to read files.',
              style: TextStyle(fontSize: 13, color: colors.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.inputBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: primaryAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Please toggle "Allow access to manage all files" on the next screen.',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Grant Access'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      await requestPermission();
    }
    return false;
  }
}
