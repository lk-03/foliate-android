import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/services/keyboard_shortcuts.dart';

void main() {
  group('Keyboard Shortcuts Tests', () {
    test('readerShortcuts contains essential page navigation and reader actions', () {
      final shortcuts = FoliateShortcuts.readerShortcuts;

      // Page forward intents
      expect(
        shortcuts.values.whereType<PageForwardIntent>().isNotEmpty,
        isTrue,
      );

      // Page backward intents
      expect(
        shortcuts.values.whereType<PageBackwardIntent>().isNotEmpty,
        isTrue,
      );

      // Open search intent (Ctrl+F)
      expect(
        shortcuts.values.whereType<OpenSearchIntent>().isNotEmpty,
        isTrue,
      );

      // Open TOC intent (Ctrl+T)
      expect(
        shortcuts.values.whereType<OpenTOCIntent>().isNotEmpty,
        isTrue,
      );

      // Toggle bookmark intent (Ctrl+B)
      expect(
        shortcuts.values.whereType<ToggleBookmarkIntent>().isNotEmpty,
        isTrue,
      );

      // Font size increase/decrease intents
      expect(
        shortcuts.values.whereType<IncreaseFontSizeIntent>().isNotEmpty,
        isTrue,
      );
      expect(
        shortcuts.values.whereType<DecreaseFontSizeIntent>().isNotEmpty,
        isTrue,
      );

      // Escape / dismiss intent
      expect(
        shortcuts.values.whereType<DismissOrEscapeIntent>().isNotEmpty,
        isTrue,
      );
    });

    test('shellShortcuts maps Ctrl+1 through Ctrl+5 to NavigateShellTabIntent', () {
      final shortcuts = FoliateShortcuts.shellShortcuts;
      final tabIntents = shortcuts.values.whereType<NavigateShellTabIntent>().toList();

      expect(tabIntents.length, 8);
      final indices = tabIntents.map((intent) => intent.tabIndex).toSet();
      expect(indices, {0, 1, 2, 3, 4});
    });

    test('SingleActivator key verification for standard desktop actions', () {
      final shortcuts = FoliateShortcuts.readerShortcuts;

      // Verify Escape is mapped to DismissOrEscapeIntent
      final escapeActivator = shortcuts.keys.firstWhere(
        (k) => k is SingleActivator && k.trigger == LogicalKeyboardKey.escape,
      );
      expect(shortcuts[escapeActivator], isA<DismissOrEscapeIntent>());

      // Verify Space is mapped to PageForwardIntent
      final spaceActivator = shortcuts.keys.firstWhere(
        (k) => k is SingleActivator && k.trigger == LogicalKeyboardKey.space && !k.control,
      );
      expect(shortcuts[spaceActivator], isA<PageForwardIntent>());
    });
  });
}
