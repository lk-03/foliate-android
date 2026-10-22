import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/components/components.dart';
import 'package:foliate/models/models.dart';
import 'package:foliate/screens/home_screen.dart';
import 'package:foliate/services/storage_service.dart';
import 'package:foliate/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Onboarding StorageService logic', () {
    test('First launch detection defaults to true, false after completion', () async {
      final storage = StorageService.instance;
      expect(await storage.isFirstLaunch(), isTrue);

      await storage.setFirstLaunchDone(true);
      expect(await storage.isFirstLaunch(), isFalse);

      await storage.setFirstLaunchDone(false);
      expect(await storage.isFirstLaunch(), isTrue);
    });

    test('User name defaults to Reader and persists updates', () async {
      final storage = StorageService.instance;
      expect(await storage.getUserName(), equals('Reader'));

      await storage.setUserName('Arthur Dent');
      expect(await storage.getUserName(), equals('Arthur Dent'));

      await storage.setUserName('   ');
      expect(await storage.getUserName(), equals('Reader'));
    });

    test('Downloads directory path defaults to null and persists updates', () async {
      final storage = StorageService.instance;
      expect(await storage.getDownloadsDirectoryPath(), isNull);

      await storage.setDownloadsDirectoryPath('/storage/emulated/0/Books');
      expect(await storage.getDownloadsDirectoryPath(), equals('/storage/emulated/0/Books'));

      await storage.setDownloadsDirectoryPath(null);
      expect(await storage.getDownloadsDirectoryPath(), isNull);
    });
  });

  group('OnboardingWelcomeSheet widget', () {
    testWidgets('Renders Step 1 and completes wizard on Step 2', (tester) async {
      SharedPreferences.setMockInitialValues({});
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [FoliateThemeColors.dark],
          ),
          home: Scaffold(
            body: OnboardingWelcomeSheet(
              onCompleted: () {
                completed = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 UI
      expect(find.text('Welcome to Foliate'), findsOneWidget);
      expect(find.text('What should we call you?'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Enter name
      final nameField = find.byType(TextField);
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Kowsic');
      await tester.pumpAndSettle();

      // Advance to Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 UI
      expect(find.text('Books & Library Location'), findsOneWidget);
      expect(find.text('Start Reading'), findsOneWidget);

      // Tap Start Reading
      await tester.tap(find.text('Start Reading'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);

      // Verify persistence
      final storage = StorageService.instance;
      expect(await storage.getUserName(), equals('Kowsic'));
      expect(await storage.isFirstLaunch(), isFalse);
    });
  });

  group('HomeScreen personalized greeting', () {
    testWidgets('Greets user with custom name from StorageService', (tester) async {
      SharedPreferences.setMockInitialValues({
        'foliate_profile_user_name': 'Eleanor',
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [FoliateThemeColors.dark],
          ),
          home: Scaffold(
            body: HomeScreen(
              books: const [],
              readingHabits: const ReadingHabits(),
              onNavigateToLibrary: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Eleanor'), findsOneWidget);
    });
  });
}
