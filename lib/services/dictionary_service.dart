import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DictionaryMeaning {
  final String partOfSpeech;
  final List<String> definitions;
  final List<String> examples;
  final List<String> synonyms;

  const DictionaryMeaning({
    required this.partOfSpeech,
    required this.definitions,
    this.examples = const [],
    this.synonyms = const [],
  });

  Map<String, dynamic> toJson() => {
        'partOfSpeech': partOfSpeech,
        'definitions': definitions,
        'examples': examples,
        'synonyms': synonyms,
      };

  factory DictionaryMeaning.fromJson(Map<String, dynamic> json) {
    return DictionaryMeaning(
      partOfSpeech: json['partOfSpeech'] as String? ?? 'general',
      definitions: (json['definitions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      synonyms: (json['synonyms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class DictionaryEntry {
  final String word;
  final String? phonetic;
  final String? audioUrl;
  final List<DictionaryMeaning> meanings;

  const DictionaryEntry({
    required this.word,
    this.phonetic,
    this.audioUrl,
    required this.meanings,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'phonetic': phonetic,
        'audioUrl': audioUrl,
        'meanings': meanings.map((m) => m.toJson()).toList(),
      };

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      word: json['word'] as String? ?? '',
      phonetic: json['phonetic'] as String?,
      audioUrl: json['audioUrl'] as String?,
      meanings: (json['meanings'] as List<dynamic>?)
              ?.map((m) =>
                  DictionaryMeaning.fromJson(Map<String, dynamic>.from(m as Map)))
              .toList() ??
          const [],
    );
  }
}

class WikipediaSummary {
  final String title;
  final String? description;
  final String extract;
  final String? thumbnailUrl;
  final String? articleUrl;

  const WikipediaSummary({
    required this.title,
    this.description,
    required this.extract,
    this.thumbnailUrl,
    this.articleUrl,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'extract': extract,
        'thumbnailUrl': thumbnailUrl,
        'articleUrl': articleUrl,
      };

  factory WikipediaSummary.fromJson(Map<String, dynamic> json) {
    return WikipediaSummary(
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      extract: json['extract'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      articleUrl: json['articleUrl'] as String?,
    );
  }
}

class DictionaryService {
  DictionaryService._();
  static final DictionaryService instance = DictionaryService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      headers: {
        'User-Agent': 'FoliateAndroid/1.0 (https://github.com/lk-03/foliate)',
      },
    ),
  );

  final Map<String, DictionaryEntry> _memoryCache = {};
  final Map<String, WikipediaSummary> _wikiMemoryCache = {};

  static const String _prefPrefixDict = 'dict_cache_';
  static const String _prefPrefixWiki = 'wiki_cache_';

  void clearCache() {
    _memoryCache.clear();
    _wikiMemoryCache.clear();
  }

  String _cleanWord(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '');
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll(RegExp(r'&[a-zA-Z0-9#]+;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  DictionaryEntry? _parseWiktionaryData(String word, Map<String, dynamic> data) {
    final enList = data['en'];
    if (enList is! List || enList.isEmpty) return null;

    final Map<String, List<String>> posDefinitions = {};
    final Map<String, List<String>> posExamples = {};

    for (final item in enList) {
      if (item is! Map) continue;
      final pos = (item['partOfSpeech'] as String? ?? 'general').toLowerCase();
      final defsList = item['definitions'];
      if (defsList is! List) continue;

      for (final defItem in defsList) {
        if (defItem is! Map) continue;
        final rawDef = defItem['definition'] as String?;
        if (rawDef != null) {
          final cleanDef = _stripHtml(rawDef);
          if (cleanDef.isNotEmpty &&
              !cleanDef.startsWith('↑') &&
              cleanDef != '.') {
            posDefinitions.putIfAbsent(pos, () => []).add(cleanDef);
          }
        }

        final parsedExamples = defItem['parsedExamples'];
        if (parsedExamples is List) {
          for (final exItem in parsedExamples) {
            if (exItem is Map && exItem['example'] is String) {
              final cleanEx = _stripHtml(exItem['example'] as String);
              if (cleanEx.isNotEmpty && !cleanEx.startsWith('↑')) {
                posExamples.putIfAbsent(pos, () => []).add(cleanEx);
              }
            }
          }
        } else {
          final examples = defItem['examples'];
          if (examples is List) {
            for (final ex in examples) {
              if (ex is String) {
                final cleanEx = _stripHtml(ex);
                if (cleanEx.isNotEmpty && !cleanEx.startsWith('↑')) {
                  posExamples.putIfAbsent(pos, () => []).add(cleanEx);
                }
              }
            }
          }
        }
      }
    }

    if (posDefinitions.isEmpty) return null;

    final meanings = posDefinitions.entries.map((e) {
      return DictionaryMeaning(
        partOfSpeech: e.key,
        definitions: e.value,
        examples: posExamples[e.key] ?? const [],
      );
    }).toList();

    return DictionaryEntry(
      word: word,
      meanings: meanings,
    );
  }

  /// Query Wiktionary REST API for definitions and examples.
  Future<DictionaryEntry?> _lookupWiktionary(String word) async {
    try {
      final response = await _dio.get(
        'https://en.wiktionary.org/api/rest_v1/page/definition/${Uri.encodeComponent(word)}',
      );
      if (response.statusCode == 200 && response.data is Map) {
        final entry = _parseWiktionaryData(word, response.data as Map<String, dynamic>);
        if (entry != null && entry.meanings.isNotEmpty) {
          return entry;
        }
      }
    } catch (_) {}

    // Fallback: if lowercase is different, try with lowercase
    final lower = word.toLowerCase();
    if (lower != word) {
      try {
        final response = await _dio.get(
          'https://en.wiktionary.org/api/rest_v1/page/definition/${Uri.encodeComponent(lower)}',
        );
        if (response.statusCode == 200 && response.data is Map) {
          final entry = _parseWiktionaryData(lower, response.data as Map<String, dynamic>);
          if (entry != null && entry.meanings.isNotEmpty) {
            return entry;
          }
        }
      } catch (_) {}
    }

    return null;
  }

  /// Query Free Dictionary API for phonetic, audio pronunciation, and definitions.
  Future<DictionaryEntry?> _lookupFreeDictionary(String word) async {
    try {
      final response = await _dio.get(
        'https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(word)}',
        options: Options(
          sendTimeout: const Duration(milliseconds: 2500),
          receiveTimeout: const Duration(milliseconds: 2500),
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        if (list.isNotEmpty && list.first is Map) {
          final data = list.first as Map<String, dynamic>;
          final parsedWord = data['word'] as String? ?? word;

          String? phonetic = data['phonetic'] as String?;
          String? audioUrl;

          if (data['phonetics'] is List) {
            for (final p in data['phonetics'] as List) {
              if (p is Map) {
                if (phonetic == null && p['text'] is String) {
                  phonetic = p['text'] as String;
                }
                final audio = p['audio'] as String?;
                if (audio != null && audio.isNotEmpty && audio.endsWith('.mp3')) {
                  audioUrl = audio;
                  break;
                }
              }
            }
          }

          final meanings = <DictionaryMeaning>[];
          if (data['meanings'] is List) {
            for (final m in data['meanings'] as List) {
              if (m is Map) {
                final partOfSpeech = m['partOfSpeech'] as String? ?? 'general';
                final definitions = <String>[];
                final examples = <String>[];
                final synonyms = <String>[];

                if (m['definitions'] is List) {
                  for (final d in m['definitions'] as List) {
                    if (d is Map) {
                      final def = d['definition'] as String?;
                      if (def != null && def.isNotEmpty) definitions.add(def);
                      final ex = d['example'] as String?;
                      if (ex != null && ex.isNotEmpty) examples.add(ex);
                    }
                  }
                }

                if (m['synonyms'] is List) {
                  for (final s in m['synonyms'] as List) {
                    if (s is String && s.isNotEmpty) synonyms.add(s);
                  }
                }

                if (definitions.isNotEmpty) {
                  meanings.add(
                    DictionaryMeaning(
                      partOfSpeech: partOfSpeech,
                      definitions: definitions,
                      examples: examples,
                      synonyms: synonyms,
                    ),
                  );
                }
              }
            }
          }

          return DictionaryEntry(
            word: parsedWord,
            phonetic: phonetic,
            audioUrl: audioUrl,
            meanings: meanings,
          );
        }
      }
    } catch (e) {
      debugPrint('Free Dictionary API lookup error for $word: $e');
    }
    return null;
  }

  /// Look up English word definitions using Wiktionary with Free Dictionary API fallback and local cache.
  Future<DictionaryEntry?> lookupWord(String rawWord) async {
    final word = _cleanWord(rawWord);
    if (word.isEmpty) return null;

    if (_memoryCache.containsKey(word)) {
      return _memoryCache[word];
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('$_prefPrefixDict$word');
      if (cachedJson != null) {
        final entry = DictionaryEntry.fromJson(
            jsonDecode(cachedJson) as Map<String, dynamic>);
        _memoryCache[word] = entry;
        return entry;
      }
    } catch (_) {}

    // Wiktionary REST API is primary: reliable, ultra-fast global CDN, 99.99% uptime.
    DictionaryEntry? entry = await _lookupWiktionary(word);

    // Fall back to Free Dictionary API if Wiktionary did not return an entry.
    entry ??= await _lookupFreeDictionary(word);

    if (entry != null) {
      _memoryCache[word] = entry;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            '$_prefPrefixDict$word', jsonEncode(entry.toJson()));
      } catch (_) {}
    }

    return entry;
  }

  /// Look up concept, place, or term overview on Wikipedia REST API.
  Future<WikipediaSummary?> lookupWikipedia(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return null;
    final normalizedKey = query.toLowerCase();

    if (_wikiMemoryCache.containsKey(normalizedKey)) {
      return _wikiMemoryCache[normalizedKey];
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('$_prefPrefixWiki$normalizedKey');
      if (cachedJson != null) {
        final summary = WikipediaSummary.fromJson(
            jsonDecode(cachedJson) as Map<String, dynamic>);
        _wikiMemoryCache[normalizedKey] = summary;
        return summary;
      }
    } catch (_) {}

    try {
      final response = await _dio.get(
        'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(query)}',
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final title = data['title'] as String? ?? query;
        final description = data['description'] as String?;
        final extract = data['extract'] as String? ?? '';
        String? thumbnailUrl;
        if (data['thumbnail'] is Map) {
          thumbnailUrl = data['thumbnail']['source'] as String?;
        }
        String? articleUrl;
        if (data['content_urls'] is Map &&
            data['content_urls']['mobile'] is Map) {
          articleUrl = data['content_urls']['mobile']['page'] as String?;
        }

        if (extract.isNotEmpty) {
          final summary = WikipediaSummary(
            title: title,
            description: description,
            extract: extract,
            thumbnailUrl: thumbnailUrl,
            articleUrl: articleUrl,
          );

          _wikiMemoryCache[normalizedKey] = summary;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
                '$_prefPrefixWiki$normalizedKey', jsonEncode(summary.toJson()));
          } catch (_) {}

          return summary;
        }
      }
    } catch (e) {
      debugPrint('Wikipedia lookup error for $query: $e');
    }

    return null;
  }
}
