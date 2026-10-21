import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Active playback state of the Text-to-Speech narration engine
enum TtsPlaybackState {
  stopped,
  playing,
  paused,
}

/// Controller service wrapping `flutter_tts` for chapter narration
class TtsService {
  FlutterTts? _flutterTts;
  bool _initialized = false;

  TtsPlaybackState _state = TtsPlaybackState.stopped;
  List<String> _paragraphs = const [];
  int _currentIndex = 0;
  double _speechRate = 1.0;
  double _pitch = 1.0;
  double _volume = 1.0;

  // Callbacks
  void Function(int index, String text)? onParagraphChanged;
  void Function(TtsPlaybackState state)? onStateChanged;
  VoidCallback? onChapterFinished;
  void Function(String error)? onError;

  TtsPlaybackState get state => _state;
  List<String> get paragraphs => _paragraphs;
  int get currentIndex => _currentIndex;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  int get totalParagraphs => _paragraphs.length;
  bool get isPlaying => _state == TtsPlaybackState.playing;
  bool get isPaused => _state == TtsPlaybackState.paused;

  /// Available rate presets for cycling
  static const List<double> availableRates = [0.75, 1.0, 1.25, 1.5, 2.0];

  /// Checks if the current operating platform has native `flutter_tts` plugin support
  bool get isPlatformSupported {
    if (kIsWeb) return true;
    try {
      return Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isWindows;
    } catch (_) {
      return false;
    }
  }

  /// Initialize speech engine with handlers
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (!isPlatformSupported) {
      debugPrint('TtsService: Native TTS not supported on current platform. Running in stub mode.');
      return;
    }

    try {
      _flutterTts = FlutterTts();
      await _flutterTts?.setLanguage('en-US');
      await _flutterTts?.setPitch(_pitch);
      await _flutterTts?.setVolume(_volume);
      await _applySpeechRate(_speechRate);

      _flutterTts?.setStartHandler(() {
        if (_state != TtsPlaybackState.playing) {
          _state = TtsPlaybackState.playing;
          onStateChanged?.call(_state);
        }
      });

      _flutterTts?.setCompletionHandler(() {
        _onParagraphComplete();
      });

      _flutterTts?.setCancelHandler(() {
        if (_state != TtsPlaybackState.stopped) {
          _state = TtsPlaybackState.stopped;
          onStateChanged?.call(_state);
        }
      });

      _flutterTts?.setPauseHandler(() {
        _state = TtsPlaybackState.paused;
        onStateChanged?.call(_state);
      });

      _flutterTts?.setContinueHandler(() {
        _state = TtsPlaybackState.playing;
        onStateChanged?.call(_state);
      });

      _flutterTts?.setErrorHandler((msg) {
        debugPrint('TtsService native error: $msg');
        onError?.call(msg.toString());
      });
    } catch (e) {
      debugPrint('TtsService init exception: $e');
    }
  }

  /// Start narrating a list of chapter paragraphs starting from [startIndex]
  Future<void> startNarration({
    required List<String> paragraphs,
    int startIndex = 0,
  }) async {
    await init();
    _paragraphs = List.unmodifiable(paragraphs);
    _currentIndex = (startIndex >= 0 && startIndex < _paragraphs.length) ? startIndex : 0;

    if (_paragraphs.isEmpty) {
      _state = TtsPlaybackState.stopped;
      onStateChanged?.call(_state);
      return;
    }

    _state = TtsPlaybackState.playing;
    onStateChanged?.call(_state);
    await _speakCurrent();
  }

  /// Resume playback if paused
  Future<void> play() async {
    if (_paragraphs.isEmpty) return;
    if (_state == TtsPlaybackState.paused) {
      _state = TtsPlaybackState.playing;
      onStateChanged?.call(_state);
      await _speakCurrent();
    } else if (_state == TtsPlaybackState.stopped) {
      await startNarration(paragraphs: _paragraphs, startIndex: _currentIndex);
    }
  }

  /// Pause speech playback
  Future<void> pause() async {
    if (_state != TtsPlaybackState.playing) return;
    _state = TtsPlaybackState.paused;
    onStateChanged?.call(_state);
    if (isPlatformSupported && _flutterTts != null) {
      await _flutterTts?.pause();
    }
  }

  /// Stop playback and reset queue position
  Future<void> stop() async {
    _state = TtsPlaybackState.stopped;
    onStateChanged?.call(_state);
    if (isPlatformSupported && _flutterTts != null) {
      await _flutterTts?.stop();
    }
  }

  /// Step forward to the next paragraph
  Future<void> nextParagraph() async {
    if (_currentIndex < _paragraphs.length - 1) {
      _currentIndex++;
      if (_state == TtsPlaybackState.playing) {
        await _speakCurrent();
      } else {
        onParagraphChanged?.call(_currentIndex, _paragraphs[_currentIndex]);
      }
    } else {
      await stop();
      onChapterFinished?.call();
    }
  }

  /// Step backward to the previous paragraph
  Future<void> previousParagraph() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      if (_state == TtsPlaybackState.playing) {
        await _speakCurrent();
      } else {
        onParagraphChanged?.call(_currentIndex, _paragraphs[_currentIndex]);
      }
    }
  }

  /// Jump directly to a paragraph by index
  Future<void> jumpToParagraph(int index) async {
    if (index >= 0 && index < _paragraphs.length) {
      _currentIndex = index;
      if (_state == TtsPlaybackState.playing) {
        await _speakCurrent();
      } else {
        onParagraphChanged?.call(_currentIndex, _paragraphs[_currentIndex]);
      }
    }
  }

  /// Cycle to the next rate preset
  Future<void> cycleSpeechRate() async {
    final curIdx = availableRates.indexOf(_speechRate);
    final nextIdx = (curIdx + 1) % availableRates.length;
    await setSpeechRate(availableRates[nextIdx]);
  }

  /// Set speech rate
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _applySpeechRate(rate);
  }

  /// Set speech pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    if (isPlatformSupported && _flutterTts != null) {
      try {
        await _flutterTts?.setPitch(pitch);
      } catch (_) {}
    }
  }

  /// Set speech volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume;
    if (isPlatformSupported && _flutterTts != null) {
      try {
        await _flutterTts?.setVolume(volume);
      } catch (_) {}
    }
  }

  Future<void> _applySpeechRate(double rate) async {
    if (!isPlatformSupported || _flutterTts == null) return;
    try {
      // flutter_tts uses 0.5 as normal speed on iOS/macOS, while Android uses 1.0.
      double platformRate = rate;
      if (!kIsWeb) {
        try {
          if (Platform.isIOS || Platform.isMacOS) {
            platformRate = (rate * 0.5).clamp(0.0, 1.0);
          }
        } catch (_) {}
      }
      await _flutterTts?.setSpeechRate(platformRate);
    } catch (_) {}
  }

  Future<void> _speakCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _paragraphs.length) {
      await stop();
      onChapterFinished?.call();
      return;
    }

    final text = _paragraphs[_currentIndex];
    onParagraphChanged?.call(_currentIndex, text);

    if (isPlatformSupported && _flutterTts != null) {
      try {
        await _flutterTts?.stop();
        await _flutterTts?.speak(text);
      } catch (e) {
        debugPrint('TtsService speak exception: $e');
      }
    }
  }

  void _onParagraphComplete() {
    if (_state != TtsPlaybackState.playing) return;
    if (_currentIndex < _paragraphs.length - 1) {
      _currentIndex++;
      _speakCurrent();
    } else {
      _state = TtsPlaybackState.stopped;
      onStateChanged?.call(_state);
      onChapterFinished?.call();
    }
  }

  /// Clean up audio resources and listeners
  void dispose() {
    try {
      _flutterTts?.stop();
    } catch (_) {}
    onParagraphChanged = null;
    onStateChanged = null;
    onChapterFinished = null;
    onError = null;
  }
}
