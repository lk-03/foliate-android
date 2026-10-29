# Foliate Android & Linux Desktop

A modern, distraction-free e-book reader application for Android and Linux Desktop, adapted from the Foliate desktop ecosystem. Built with Flutter, GNOME Libadwaita design standards, an offline-bundled `foliate-js` engine, and a pure-Dart fallback engine.

---

## Features

### Dual-Runtime Reading Engine
* **Offline Bundled Engine:** Powered by an offline, self-contained `foliate-js` runtime inside a sandboxed WebView. No external CDNs or network access required for reading.
* **Pure-Dart Fallback Engine:** Pure-Dart EPUB parser and layout engine with watchdog timeout protection for platforms and environments lacking native WebViews.
* **CFI-Based Precision:** Uses EPUB Canonical Fragment Identifiers (CFIs) for character-level location accuracy across screen sizes, font scales, and orientations.
* **Desktop Two-Page Spread Layout:** Dual-page horizontal spread layout on wide desktop and tablet displays (width >= 850px) with responsive margins, interactive chapter markers, and reading location scrub bar.
* **Mobile Single-Page Swipe Reader:** Single-page horizontal swipe navigation on mobile screens with ample vertical breathing room above and below page content, combined with responsive edge-tap page turns (left edge previous, right edge next, center HUD toggle).
* **Hardware Keyboard Shortcuts:** Comprehensive keyboard navigation for paging, chapter jumps, fullscreen toggle, HUD controls, and quick search.

### GNOME Libadwaita Design System
* **9 Reading Palettes:** Default, Gray, Sepia, Grass, Cherry, Sky, Solarized, Gruvbox, and Nord with light mode, dark mode, and inverted color options.
* **Customizable Typography:** Bundled Noto Serif typography, publisher font override, line height adjustments, side margin steppers, full justification, and hyphenation toggles.
* **Contrast-Adaptive Logo:** Geometric logo tile dynamically adapting to system and theme modes.
* **Swipeable Mobile Shell:** Swipeable gesture navigation across Home, Library, Discover, Favorites, and Annotations.

### Library & File Management
* **Content-Addressed Book Identity:** Books are indexed by the SHA-256 hash of their raw content bytes. Renaming or moving files never duplicates catalog entries.
* **Fast In-Memory EPUB Parser:** Pure Dart ZIP extraction and OPF metadata/cover parsing (~10ms per book).
* **Linked Folders Auto-Sync:** Link entire directories (e.g. `/storage/emulated/0/Books`) with Scoped Storage support (`MANAGE_EXTERNAL_STORAGE`) for automatic re-scanning and deduplication.
* **Personalized Recommendations:** 12 literary niches and genres with dynamic scoring based on explicit preferences and favorite books.

### Catalogs & Open Libraries
* **Open Library Direct Search:** Dedicated search interface for Open Library books with direct Internet Archive and Open Library EPUB downloads.
* **OPDS 1.2 Feed Integration:** Pre-configured open-access feeds (Project Gutenberg, Standard Ebooks, Internet Archive, Feedbooks) with custom OPDS server connectivity (Calibre, Calibre-Web, Kavita, Komga).
* **Multi-Task Download Manager:** Multi-task queue with pause, resume, cancel, transfer speed calculation, and Header HUD indicator across application views.

### In-App Self-Updater
* **Automated Release Checks:** Periodic and manual update checks against GitHub Releases API (`lk-03/foliate-android`).
* **Direct APK Download & Installation:** In-app background binary download with live progress indicator and native Android `ACTION_INSTALL_PACKAGE` package installer invocation via FileProvider.

### In-Book Full-Text Search
* **Streaming Chapter Results:** Real-time search with match count badges and context excerpts.
* **Floating In-Reader Stepper:** Jump directly to CFIs and step across matches (`Match X of Y`, `Prev`, `Next`) without losing reading state.
* **Case-Sensitivity Toggle:** Fast switching between case-sensitive and case-insensitive matching.

---

## Architecture

Foliate follows a dual-runtime separation of concerns:

* **Flutter Runtime (Dart VM / AOT):** Exclusively manages UI navigation, file system storage, SHA-256 stream hashing (`crypto`), in-memory EPUB unzipping (`archive`), XML metadata parsing (`xml`), Riverpod state management, and disk persistence (`shared_preferences`).
* **WebView Engine:** Exclusively manages EPUB pagination, HTML/CSS layout, CFI calculations, text search, and document rendering via vendored `foliate-js`.
* **Typed IPC Bridge:** Communication between runtimes occurs via an asynchronous typed message channel (`ReaderBridge`) with strict message schemas.

---

## Getting Started

### Prerequisites
* Flutter SDK (3.47.2 or later)
* Dart SDK (3.13.2 or later)
* Android SDK (API 34+) or Linux C/C++ toolchain (clang, cmake, gtk3)

### Installation & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/lk-03/foliate-android.git
   cd foliate-android
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Run on a connected device:
   ```bash
   flutter run
   ```

4. Build release artifacts:
   ```bash
   # Android APK
   flutter build apk --release

   # Linux Desktop bundle
   flutter build linux --release
   ```

### Running Tests

Execute the automated unit and widget test suite:
```bash
flutter test
```

Run static analysis:
```bash
dart analyze
```

---

## Releases & Downloads

Release assets are published on [GitHub Releases](https://github.com/lk-03/foliate-android/releases):
* **Android:** `foliate-v<version>-android.apk` (Universal release APK for arm64, armeabi-v7a, x86_64)
* **Linux:** `foliate-v<version>-linux-x64.tar.gz` (Standalone bundle for Linux x86_64)

---

## Master Roadmap

* **Phase 1: Libadwaita UI Shell & Design System** (Completed)
* **Phase 2: Core EPUB Engine & Reading Flow** (Completed)
* **Phase 3: In-Book Search & Reader Tools** (Completed)
* **Phase 4: Highlights, Annotations, Bookmarks & TTS** (Completed)
* **Phase 5: Desktop Spread Reader & Mobile Swipe Navigation** (Completed)
* **Phase 6: In-App Self-Updater & Catalog Search** (Completed)
* **Phase 7: Cloud Sync Backend** (Planned)

---

## License

GPL-3.0 License. Based on [Foliate](https://github.com/johnfactotum/foliate) by John Factotum.
