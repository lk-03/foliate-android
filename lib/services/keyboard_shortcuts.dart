import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Intent to advance to the next reading page.
class PageForwardIntent extends Intent {
  const PageForwardIntent();
}

/// Intent to move back to the previous reading page.
class PageBackwardIntent extends Intent {
  const PageBackwardIntent();
}

/// Intent to open or focus in-book search.
class OpenSearchIntent extends Intent {
  const OpenSearchIntent();
}

/// Intent to open or focus the Table of Contents.
class OpenTOCIntent extends Intent {
  const OpenTOCIntent();
}

/// Intent to toggle the bookmark on the current page.
class ToggleBookmarkIntent extends Intent {
  const ToggleBookmarkIntent();
}

/// Intent to open the reader appearance & typography controls.
class OpenAppearanceIntent extends Intent {
  const OpenAppearanceIntent();
}

/// Intent to increase reader font size.
class IncreaseFontSizeIntent extends Intent {
  const IncreaseFontSizeIntent();
}

/// Intent to decrease reader font size.
class DecreaseFontSizeIntent extends Intent {
  const DecreaseFontSizeIntent();
}

/// Intent to dismiss active search, side panels, or toggle HUD.
class DismissOrEscapeIntent extends Intent {
  const DismissOrEscapeIntent();
}

/// Intent to navigate to a specific tab index in the main shell (0 to 4).
class NavigateShellTabIntent extends Intent {
  final int tabIndex;
  const NavigateShellTabIntent(this.tabIndex);
}

/// Centralized keyboard shortcut mappings for Foliate.
class FoliateShortcuts {
  /// Default keyboard shortcuts for ReaderScreen.
  static final Map<ShortcutActivator, Intent> readerShortcuts = {
    // Page turning
    const SingleActivator(LogicalKeyboardKey.space): const PageForwardIntent(),
    const SingleActivator(LogicalKeyboardKey.pageDown): const PageForwardIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight): const PageForwardIntent(),
    const SingleActivator(LogicalKeyboardKey.pageUp): const PageBackwardIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft): const PageBackwardIntent(),

    // In-book search and TOC
    const SingleActivator(LogicalKeyboardKey.keyF, control: true): const OpenSearchIntent(),
    const SingleActivator(LogicalKeyboardKey.keyT, control: true): const OpenTOCIntent(),

    // Bookmarking and Appearance
    const SingleActivator(LogicalKeyboardKey.keyB, control: true): const ToggleBookmarkIntent(),
    const SingleActivator(LogicalKeyboardKey.comma, control: true): const OpenAppearanceIntent(),

    // Font scaling
    const SingleActivator(LogicalKeyboardKey.equal, control: true): const IncreaseFontSizeIntent(),
    const SingleActivator(LogicalKeyboardKey.add, control: true): const IncreaseFontSizeIntent(),
    const SingleActivator(LogicalKeyboardKey.minus, control: true): const DecreaseFontSizeIntent(),

    // Dismissal / HUD toggle
    const SingleActivator(LogicalKeyboardKey.escape): const DismissOrEscapeIntent(),
  };

  /// Default keyboard shortcuts for MainShell tab navigation.
  static final Map<ShortcutActivator, Intent> shellShortcuts = {
    const SingleActivator(LogicalKeyboardKey.digit1, control: true): const NavigateShellTabIntent(0),
    const SingleActivator(LogicalKeyboardKey.digit2, control: true): const NavigateShellTabIntent(1),
    const SingleActivator(LogicalKeyboardKey.digit3, control: true): const NavigateShellTabIntent(2),
    const SingleActivator(LogicalKeyboardKey.digit4, control: true): const NavigateShellTabIntent(3),
    const SingleActivator(LogicalKeyboardKey.digit5, control: true): const NavigateShellTabIntent(4),

    const SingleActivator(LogicalKeyboardKey.keyH, control: true): const NavigateShellTabIntent(0),
    const SingleActivator(LogicalKeyboardKey.keyL, control: true): const NavigateShellTabIntent(1),
    const SingleActivator(LogicalKeyboardKey.keyE, control: true): const NavigateShellTabIntent(2),
  };
}
