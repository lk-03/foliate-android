import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/components/components.dart';
import 'package:foliate/models/models.dart';
import 'package:foliate/services/services.dart';

void main() {
  group('AppUpdateInfo version comparison tests', () {
    test('Correctly identifies newer patch version', () {
      expect(AppUpdateInfo.isRemoteNewer('v1.0.1', '1.0.0'), isTrue);
      expect(AppUpdateInfo.isRemoteNewer('1.0.1', '1.0.0'), isTrue);
    });

    test('Correctly identifies newer minor and major versions', () {
      expect(AppUpdateInfo.isRemoteNewer('v1.1.0', '1.0.9'), isTrue);
      expect(AppUpdateInfo.isRemoteNewer('v2.0.0', '1.9.9'), isTrue);
    });

    test('Correctly compares build numbers when semver matches', () {
      expect(AppUpdateInfo.isRemoteNewer('v1.0.0+2', '1.0.0+1'), isTrue);
      expect(AppUpdateInfo.isRemoteNewer('1.0.0+1', '1.0.0+2'), isFalse);
    });

    test('Returns false when remote is older or identical', () {
      expect(AppUpdateInfo.isRemoteNewer('v1.0.0', '1.0.0'), isFalse);
      expect(AppUpdateInfo.isRemoteNewer('1.0.0', '1.0.0'), isFalse);
      expect(AppUpdateInfo.isRemoteNewer('v0.9.0', '1.0.0'), isFalse);
      expect(AppUpdateInfo.isRemoteNewer('1.0.0', '1.0.1'), isFalse);
    });

    test('Handles malformed or edge case version strings safely', () {
      expect(AppUpdateInfo.isRemoteNewer('', '1.0.0'), isFalse);
      expect(AppUpdateInfo.isRemoteNewer('invalid', '1.0.0'), isFalse);
      expect(AppUpdateInfo.isRemoteNewer('v1.0.0.1', '1.0.0.0'), isTrue);
    });
  });

  group('AppUpdateInfo JSON parsing tests', () {
    test('Parses complete GitHub release payload with APK asset', () {
      final json = {
        'tag_name': 'v1.1.0',
        'body': 'Initial update with in-app updater support.',
        'html_url': 'https://github.com/lk-03/foliate-android/releases/tag/v1.1.0',
        'published_at': '2026-10-27T12:00:00Z',
        'assets': [
          {
            'name': 'source-code.tar.gz',
            'browser_download_url': 'https://github.com/downloads/src.tar.gz',
          },
          {
            'name': 'foliate-v1.1.0-android.apk',
            'browser_download_url':
                'https://github.com/downloads/foliate-v1.1.0-android.apk',
          },
        ],
      };

      final info = AppUpdateInfo.fromGitHubReleaseJson(
        json,
        currentVersion: '1.0.0',
      );

      expect(info.tagName, equals('v1.1.0'));
      expect(info.version, equals('1.1.0'));
      expect(info.releaseNotes, contains('in-app updater'));
      expect(info.htmlUrl, contains('/releases/tag/v1.1.0'));
      expect(
        info.apkDownloadUrl,
        equals('https://github.com/downloads/foliate-v1.1.0-android.apk'),
      );
      expect(info.publishedAt, isNotNull);
      expect(info.hasUpdate, isTrue);
    });

    test('Handles release payload with no APK asset', () {
      final json = {
        'tag_name': 'v1.0.0',
        'body': '',
        'assets': <dynamic>[],
      };

      final info = AppUpdateInfo.fromGitHubReleaseJson(
        json,
        currentVersion: '1.0.0',
      );

      expect(info.apkDownloadUrl, isNull);
      expect(info.hasUpdate, isFalse);
      expect(info.releaseNotes, equals('No release notes provided.'));
    });
  });

  group('UpdateService tests', () {
    test('checkForUpdate parses successfully on 200 response', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'tag_name': 'v1.0.5',
                  'body': 'Bug fixes and performance improvements.',
                  'html_url': 'https://github.com/lk-03/foliate-android/releases/tag/v1.0.5',
                  'assets': [
                    {
                      'name': 'foliate-v1.0.5-android.apk',
                      'browser_download_url': 'https://example.com/app.apk',
                    }
                  ],
                },
              ),
            );
          },
        ),
      );

      final service = UpdateService.withDio(dio);
      final updateInfo = await service.checkForUpdate(currentVersion: '1.0.0');

      expect(updateInfo, isNotNull);
      expect(updateInfo!.tagName, equals('v1.0.5'));
      expect(updateInfo.hasUpdate, isTrue);
      expect(updateInfo.apkDownloadUrl, equals('https://example.com/app.apk'));
    });

    test('checkForUpdate returns null on network exception', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Network unreachable',
              ),
            );
          },
        ),
      );

      final service = UpdateService.withDio(dio);
      final updateInfo = await service.checkForUpdate();

      expect(updateInfo, isNull);
    });
  });

  group('UpdateAvailableDialog widget tests', () {
    testWidgets('Renders update dialog with version pill and release notes',
        (tester) async {
      const updateInfo = AppUpdateInfo(
        tagName: 'v1.2.0',
        version: '1.2.0',
        releaseNotes: 'New feature: live in-app updater.',
        apkDownloadUrl: 'https://example.com/update.apk',
        htmlUrl: 'https://github.com/lk-03/foliate-android/releases/tag/v1.2.0',
        hasUpdate: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => UpdateAvailableDialog.show(
                  context,
                  updateInfo: updateInfo,
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('v1.2.0'), findsOneWidget);
      expect(find.text('New feature: live in-app updater.'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);

      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(find.text('Update Available'), findsNothing);
    });
  });
}
