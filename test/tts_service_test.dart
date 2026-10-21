import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/components/components.dart';
import 'package:foliate/services/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TtsService Unit Tests', () {
    test('initial state is stopped with 1.0x rate', () {
      final tts = TtsService();
      expect(tts.state, equals(TtsPlaybackState.stopped));
      expect(tts.speechRate, equals(1.0));
      expect(tts.currentIndex, equals(0));
      expect(tts.totalParagraphs, equals(0));
      expect(tts.isPlaying, isFalse);
      expect(tts.isPaused, isFalse);
    });

    test('speech rate cycling cycles through presets', () async {
      final tts = TtsService();
      expect(tts.speechRate, equals(1.0));

      await tts.cycleSpeechRate();
      expect(tts.speechRate, equals(1.25));

      await tts.cycleSpeechRate();
      expect(tts.speechRate, equals(1.5));

      await tts.cycleSpeechRate();
      expect(tts.speechRate, equals(2.0));

      await tts.cycleSpeechRate();
      expect(tts.speechRate, equals(0.75));

      await tts.cycleSpeechRate();
      expect(tts.speechRate, equals(1.0));
    });

    test('startNarration sets paragraphs and updates state', () async {
      final tts = TtsService();
      final paragraphs = [
        'Call me Ishmael.',
        'Some years ago—never mind how long precisely.',
        'There now is your insular city of the Manhattoes.',
      ];

      int reportedIndex = -1;
      String reportedText = '';
      TtsPlaybackState? reportedState;

      tts.onParagraphChanged = (idx, text) {
        reportedIndex = idx;
        reportedText = text;
      };

      tts.onStateChanged = (state) {
        reportedState = state;
      };

      await tts.startNarration(paragraphs: paragraphs, startIndex: 1);

      expect(tts.currentIndex, equals(1));
      expect(tts.totalParagraphs, equals(3));
      expect(tts.state, equals(TtsPlaybackState.playing));
      expect(reportedIndex, equals(1));
      expect(reportedText, equals(paragraphs[1]));
      expect(reportedState, equals(TtsPlaybackState.playing));

      await tts.nextParagraph();
      expect(tts.currentIndex, equals(2));
      expect(reportedIndex, equals(2));

      await tts.previousParagraph();
      expect(tts.currentIndex, equals(1));
      expect(reportedIndex, equals(1));

      await tts.previousParagraph();
      expect(tts.currentIndex, equals(0));
      expect(reportedIndex, equals(0));

      // Attempt previous when already at 0
      await tts.previousParagraph();
      expect(tts.currentIndex, equals(0));

      // Jump to paragraph
      await tts.jumpToParagraph(2);
      expect(tts.currentIndex, equals(2));

      // Pause and resume
      await tts.pause();
      expect(tts.state, equals(TtsPlaybackState.paused));
      expect(tts.isPaused, isTrue);

      await tts.play();
      expect(tts.state, equals(TtsPlaybackState.playing));
      expect(tts.isPlaying, isTrue);

      // Stop
      await tts.stop();
      expect(tts.state, equals(TtsPlaybackState.stopped));

      tts.dispose();
    });

    test('nextParagraph at the end triggers onChapterFinished', () async {
      final tts = TtsService();
      final paragraphs = ['Single paragraph.'];
      bool chapterFinished = false;

      tts.onChapterFinished = () {
        chapterFinished = true;
      };

      await tts.startNarration(paragraphs: paragraphs);
      expect(tts.currentIndex, equals(0));

      await tts.nextParagraph();
      expect(chapterFinished, isTrue);
      expect(tts.state, equals(TtsPlaybackState.stopped));

      tts.dispose();
    });
  });

  group('TtsFloatingBar Widget Tests', () {
    testWidgets('renders chapter title, progress and responds to taps', (tester) async {
      bool playPauseTapped = false;
      bool previousTapped = false;
      bool nextTapped = false;
      bool cycleSpeedTapped = false;
      bool closeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TtsFloatingBar(
              state: TtsPlaybackState.playing,
              currentIndex: 2,
              totalParagraphs: 10,
              speechRate: 1.25,
              chapterTitle: 'Chapter 1: Loomings',
              accentColor: const Color(0xFFE5A50A),
              isDarkMode: true,
              onPlayPause: () => playPauseTapped = true,
              onPrevious: () => previousTapped = true,
              onNext: () => nextTapped = true,
              onCycleSpeed: () => cycleSpeedTapped = true,
              onClose: () => closeTapped = true,
            ),
          ),
        ),
      );

      // Verify text
      expect(find.text('Chapter 1: Loomings'), findsOneWidget);
      expect(find.text('Paragraph 3 of 10'), findsOneWidget);
      expect(find.text('1.25x'), findsOneWidget);

      // Tap Play/Pause (which shows pause icon when playing)
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.pause_rounded));
      expect(playPauseTapped, isTrue);

      // Tap Previous
      await tester.tap(find.byIcon(Icons.skip_previous_rounded));
      expect(previousTapped, isTrue);

      // Tap Next
      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      expect(nextTapped, isTrue);

      // Tap Speed chip
      await tester.tap(find.text('1.25x'));
      expect(cycleSpeedTapped, isTrue);

      // Tap Close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(closeTapped, isTrue);
    });

    testWidgets('displays play icon when paused or stopped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TtsFloatingBar(
              state: TtsPlaybackState.paused,
              currentIndex: 0,
              totalParagraphs: 5,
              speechRate: 1.0,
              chapterTitle: '',
              accentColor: const Color(0xFFE5A50A),
              isDarkMode: false,
              onPlayPause: () {},
              onPrevious: () {},
              onNext: () {},
              onCycleSpeed: () {},
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('Reading Aloud'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  });
}
