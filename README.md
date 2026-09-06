# Foliate Android

A modern, distraction-free e-book reader application for Android, adapted from the Foliate desktop ecosystem. Built with Flutter, GNOME Libadwaita design standards, and an offline-bundled `foliate-js` reader engine.

---

## Features

### Dual-Runtime Reading Engine
* **Offline Bundled Engine:** Powered by an offline, self-contained `foliate-js` runtime inside a sandboxed WebView. No external CDNs or network access required for reading.
* **CFI-Based Precision:** Uses EPUB Canonical Fragment Identifiers (CFIs) for character-level location accuracy across screen sizes, font scales, and orientations.
* **Gesture-Driven Page Turns:** Fast edge-tap navigation (left 28% previous, right 28% next, center 44% HUD toggle) and native swipe physics.
* **Scrubber & Location HUD:** Dynamic section and page counter (`x / n`) with auto-hiding navigation bars.

### GNOME Libadwaita Design System
* **9 Desktop Reading Palettes:** Default, Gray, Sepia, Grass, Cherry, Sky, Solarized, Gruvbox, and Nord with light mode, dark mode, and inverted color options.
* **Customizable Typography:** Bundled Noto Serif typography, publisher font override, line height adjustments, side margin steppers, full justification, and hyphenation toggles.
* **Contrast-Adaptive Logo:** Geometric logo tile dynamically adapting to system and theme modes.
* **Swipeable Mobile Shell:** Swipeable gesture navigation across Home, Library, Discover, Favorites, and Annotations.

### Library & File Management
* **Content-Addressed Book Identity:** Books are indexed by the SHA-256 hash of their raw content bytes. Renaming or moving files never duplicates catalog entries.
* **Fast In-Memory EPUB Parser:** Pure Dart ZIP extraction and OPF metadata/cover parsing (~10ms per book).
* **Linked Folders Auto-Sync:** Link entire directories (e.g. `/storage/emulated/0/Books`) with Scoped Storage support (`MANAGE_EXTERNAL_STORAGE`) for automatic re-scanning and deduplication.
* **Open Libraries Hub:** Curated directory of public domain and open-access catalogs (Project Gutenberg, Standard Ebooks, Internet Archive, Feedbooks) with custom OPDS feed support.

### In-Book Full-Text Search
* **Streaming Chapter Results:** Real-time search with match count badges and context excerpts.
* **Floating In-Reader Stepper:** Jump directly to CFIs and step across matches (`Match X of Y`, `Prev`, `Next`) without losing reading state.
* **Case-Sensitivity Toggle:** Fast switching between case-sensitive and case-insensitive matching.

---

## Architecture

Foliate Android follows a dual-runtime separation of concerns:

* **Flutter Runtime (Dart VM / AOT):** Exclusively manages mobile UI navigation, file system storage, SHA-256 stream hashing (`crypto`), in-memory EPUB unzipping (`archive`), XML metadata parsing (`xml`), Riverpod state management, and disk persistence (`shared_preferences`).
* **WebView Engine:** Exclusively manages EPUB pagination, HTML/CSS layout, CFI calculations, text search, and document rendering via vendored `foliate-js`.
* **Typed IPC Bridge:** Communication between runtimes occurs via an asynchronous typed message channel (`ReaderBridge`) with strict message schemas.

---

## Getting Started

### Prerequisites
* Flutter SDK (3.47.2 or later)
* Dart SDK (3.13.2 or later)
* Android SDK (API 34+)

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

4. Build release APK:
   ```bash
   flutter build apk --release
   ```

### Running Tests

Execute the automated unit and widget test suite:
```bash
flutter test
```

Run static analysis:
```bash
flutter analyze
```

---

## Master Roadmap

* **Phase 1: Libadwaita UI Shell & Design System** (Completed)
* **Phase 2: Core EPUB Engine & Reading Flow** (Completed)
* **Phase 3: In-Book Search & Reader Tools** (Completed)
* **Phase 4: Highlights, Annotations, Bookmarks & TTS** (Active Focus)
* **Phase 5: Cloud Sync (Supabase Backend)** (Planned)
* **Phase 6: Desktop & Tablet Adaptive Layouts** (Planned)

---

## License

GPL-3.0 License. Based on [Foliate](https://github.com/johnfactotum/foliate) by John Factotum.
