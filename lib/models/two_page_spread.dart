import '../services/epub_service.dart';

/// Represents a two-page reading spread (Left page and Right page)
/// designed to match Foliate's desktop reader view.
class TwoPageSpread {
  final int spreadIndex;
  final int chapterIndex;
  final String? chapterTitle;
  final bool isChapterStart;
  final int leftLoc;
  final int rightLoc;
  final int totalLocs;
  final List<String> leftParagraphs;
  final List<String> rightParagraphs;
  final String cfi;
  final String href;

  const TwoPageSpread({
    required this.spreadIndex,
    required this.chapterIndex,
    this.chapterTitle,
    required this.isChapterStart,
    required this.leftLoc,
    required this.rightLoc,
    required this.totalLocs,
    required this.leftParagraphs,
    required this.rightParagraphs,
    required this.cfi,
    required this.href,
  });

  bool get isEmpty => leftParagraphs.isEmpty && rightParagraphs.isEmpty;
}

/// Paginates EPUB chapters into a continuous sequence of two-page spreads.
class DesktopSpreadPaginator {
  /// Splits chapter paragraphs into two-page spreads.
  static List<TwoPageSpread> paginate({
    required List<EpubChapter> chapters,
    int wordsPerColumn = 400,
    int? overrideTotalLocs,
  }) {
    if (chapters.isEmpty) return const [];

    final rawSpreads = <_RawSpread>[];

    for (int chIdx = 0; chIdx < chapters.length; chIdx++) {
      final ch = chapters[chIdx];
      String? title = ch.title;
      final paras = List<String>.from(ch.paragraphs);

      // Check if the first paragraph is an explicit section/chapter heading
      if (paras.isNotEmpty) {
        final p0 = paras.first.trim();
        if (p0.startsWith('[') ||
            RegExp(r'^(?:chapter|part|book|section)\s+\w+', caseSensitive: false).hasMatch(p0) ||
            (p0.length <= 40 && !p0.endsWith('.'))) {
          title = p0;
          paras.removeAt(0);
        }
      }

      // If chapter was only the heading or empty, keep title in first column
      if (paras.isEmpty) {
        rawSpreads.add(_RawSpread(
          chapterIndex: chIdx,
          chapterTitle: title,
          isChapterStart: true,
          leftParagraphs: const [],
          rightParagraphs: const [],
          cfi: ch.id,
          href: ch.href,
        ));
        continue;
      }

      // Chunk paragraphs into columns based on word count
      final columns = <List<String>>[];
      var currentColumn = <String>[];
      int currentWordCount = 0;

      for (final p in paras) {
        final words = p.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

        // If adding this paragraph exceeds wordsPerColumn and we already have content,
        // finish this column and start a new one.
        if (currentColumn.isNotEmpty && (currentWordCount + words > (wordsPerColumn * 1.2).round())) {
          columns.add(currentColumn);
          currentColumn = [p];
          currentWordCount = words;
        } else {
          currentColumn.add(p);
          currentWordCount += words;
        }
      }
      if (currentColumn.isNotEmpty) {
        columns.add(currentColumn);
      }

      // Pair columns into two-page spreads
      for (int i = 0; i < columns.length; i += 2) {
        final left = columns[i];
        final right = (i + 1 < columns.length) ? columns[i + 1] : const <String>[];
        rawSpreads.add(_RawSpread(
          chapterIndex: chIdx,
          chapterTitle: title,
          isChapterStart: (i == 0),
          leftParagraphs: left,
          rightParagraphs: right,
          cfi: ch.id,
          href: ch.href,
        ));
      }
    }

    if (rawSpreads.isEmpty) return const [];

    final computedTotalLocs = overrideTotalLocs ?? (rawSpreads.length * 2);

    final spreads = <TwoPageSpread>[];
    for (int i = 0; i < rawSpreads.length; i++) {
      final raw = rawSpreads[i];
      final leftLoc = ((i * 2) + 1).clamp(1, computedTotalLocs);
      final rightLoc = ((i * 2) + 2).clamp(1, computedTotalLocs);

      spreads.add(TwoPageSpread(
        spreadIndex: i,
        chapterIndex: raw.chapterIndex,
        chapterTitle: raw.chapterTitle,
        isChapterStart: raw.isChapterStart,
        leftLoc: leftLoc,
        rightLoc: rightLoc,
        totalLocs: computedTotalLocs,
        leftParagraphs: raw.leftParagraphs,
        rightParagraphs: raw.rightParagraphs,
        cfi: raw.cfi,
        href: raw.href,
      ));
    }

    return spreads;
  }

  /// Locates the spread index containing or closest to [targetLoc].
  static int findSpreadIndexForLoc(List<TwoPageSpread> spreads, int targetLoc) {
    if (spreads.isEmpty) return 0;
    for (int i = 0; i < spreads.length; i++) {
      if (targetLoc <= spreads[i].rightLoc) {
        return i;
      }
    }
    return spreads.length - 1;
  }

  /// Locates the starting spread index for [chapterIndex].
  static int findSpreadIndexForChapter(List<TwoPageSpread> spreads, int chapterIndex) {
    if (spreads.isEmpty) return 0;
    for (int i = 0; i < spreads.length; i++) {
      if (spreads[i].chapterIndex == chapterIndex && spreads[i].isChapterStart) {
        return i;
      }
    }
    for (int i = 0; i < spreads.length; i++) {
      if (spreads[i].chapterIndex == chapterIndex) {
        return i;
      }
    }
    return 0;
  }

  /// Locates the starting spread index matching [href].
  static int findSpreadIndexForHref(List<TwoPageSpread> spreads, String href) {
    if (spreads.isEmpty) return 0;
    final cleanHref = href.split('#').first.replaceAll('\\', '/').toLowerCase();
    for (int i = 0; i < spreads.length; i++) {
      final spreadHref = spreads[i].href.split('#').first.replaceAll('\\', '/').toLowerCase();
      if (spreadHref.endsWith(cleanHref) || cleanHref.endsWith(spreadHref)) {
        return i;
      }
    }
    return 0;
  }
}

class _RawSpread {
  final int chapterIndex;
  final String? chapterTitle;
  final bool isChapterStart;
  final List<String> leftParagraphs;
  final List<String> rightParagraphs;
  final String cfi;
  final String href;

  const _RawSpread({
    required this.chapterIndex,
    this.chapterTitle,
    required this.isChapterStart,
    required this.leftParagraphs,
    required this.rightParagraphs,
    required this.cfi,
    required this.href,
  });
}

/// Represents a single-page reading view on mobile devices.
class MobilePage {
  final int pageIndex;
  final int chapterIndex;
  final String? chapterTitle;
  final bool isChapterStart;
  final int loc;
  final int totalLocs;
  final List<String> paragraphs;
  final String cfi;
  final String href;

  const MobilePage({
    required this.pageIndex,
    required this.chapterIndex,
    this.chapterTitle,
    required this.isChapterStart,
    required this.loc,
    required this.totalLocs,
    required this.paragraphs,
    required this.cfi,
    required this.href,
  });

  bool get isEmpty => paragraphs.isEmpty;
}

/// Paginates EPUB chapters into individual single pages for mobile displays.
class MobilePagePaginator {
  static List<MobilePage> paginate({
    required List<EpubChapter> chapters,
    int wordsPerPage = 200,
    int? overrideTotalLocs,
  }) {
    if (chapters.isEmpty) return const [];

    final rawPages = <_RawPage>[];

    for (int chIdx = 0; chIdx < chapters.length; chIdx++) {
      final ch = chapters[chIdx];
      String? title = ch.title;
      final paras = List<String>.from(ch.paragraphs);

      if (paras.isNotEmpty) {
        final p0 = paras.first.trim();
        if (p0.startsWith('[') ||
            RegExp(r'^(?:chapter|part|book|section)\s+\w+', caseSensitive: false).hasMatch(p0) ||
            (p0.length <= 40 && !p0.endsWith('.'))) {
          title = p0;
          paras.removeAt(0);
        }
      }

      if (paras.isEmpty) {
        rawPages.add(_RawPage(
          chapterIndex: chIdx,
          chapterTitle: title,
          isChapterStart: true,
          paragraphs: const [],
          cfi: ch.id,
          href: ch.href,
        ));
        continue;
      }

      final pages = <List<String>>[];
      var currentPage = <String>[];
      int currentWordCount = 0;

      for (final p in paras) {
        final words = p.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

        if (currentPage.isNotEmpty && (currentWordCount + words > (wordsPerPage * 1.2).round())) {
          pages.add(currentPage);
          currentPage = [p];
          currentWordCount = words;
        } else {
          currentPage.add(p);
          currentWordCount += words;
        }
      }
      if (currentPage.isNotEmpty) {
        pages.add(currentPage);
      }

      for (int i = 0; i < pages.length; i++) {
        rawPages.add(_RawPage(
          chapterIndex: chIdx,
          chapterTitle: title,
          isChapterStart: (i == 0),
          paragraphs: pages[i],
          cfi: ch.id,
          href: ch.href,
        ));
      }
    }

    if (rawPages.isEmpty) return const [];

    final computedTotalLocs = overrideTotalLocs ?? rawPages.length;

    final result = <MobilePage>[];
    for (int i = 0; i < rawPages.length; i++) {
      final raw = rawPages[i];
      final loc = (i + 1).clamp(1, computedTotalLocs);

      result.add(MobilePage(
        pageIndex: i,
        chapterIndex: raw.chapterIndex,
        chapterTitle: raw.chapterTitle,
        isChapterStart: raw.isChapterStart,
        loc: loc,
        totalLocs: computedTotalLocs,
        paragraphs: raw.paragraphs,
        cfi: raw.cfi,
        href: raw.href,
      ));
    }

    return result;
  }

  static int findPageIndexForLoc(List<MobilePage> pages, int targetLoc) {
    if (pages.isEmpty) return 0;
    for (int i = 0; i < pages.length; i++) {
      if (targetLoc <= pages[i].loc) {
        return i;
      }
    }
    return pages.length - 1;
  }

  static int findPageIndexForChapter(List<MobilePage> pages, int chapterIndex) {
    if (pages.isEmpty) return 0;
    for (int i = 0; i < pages.length; i++) {
      if (pages[i].chapterIndex == chapterIndex && pages[i].isChapterStart) {
        return i;
      }
    }
    for (int i = 0; i < pages.length; i++) {
      if (pages[i].chapterIndex == chapterIndex) {
        return i;
      }
    }
    return 0;
  }

  static int findPageIndexForHref(List<MobilePage> pages, String href) {
    if (pages.isEmpty) return 0;
    final cleanHref = href.split('#').first.replaceAll('\\', '/').toLowerCase();
    for (int i = 0; i < pages.length; i++) {
      final pageHref = pages[i].href.split('#').first.replaceAll('\\', '/').toLowerCase();
      if (pageHref.endsWith(cleanHref) || cleanHref.endsWith(pageHref)) {
        return i;
      }
    }
    return 0;
  }
}

class _RawPage {
  final int chapterIndex;
  final String? chapterTitle;
  final bool isChapterStart;
  final List<String> paragraphs;
  final String cfi;
  final String href;

  const _RawPage({
    required this.chapterIndex,
    this.chapterTitle,
    required this.isChapterStart,
    required this.paragraphs,
    required this.cfi,
    required this.href,
  });
}
