import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_update_info.dart';

/// Service responsible for GitHub release checks, APK binary download with
/// streaming progress, and launching the native Android package installer.
class UpdateService {
  static const String defaultRepository = 'lk-03/foliate-android';
  static const String currentAppVersion = '1.1.0+2';

  static UpdateService? _instance;
  static UpdateService get instance => _instance ??= UpdateService._();

  @visibleForTesting
  static void setMockInstance(UpdateService? service) {
    _instance = service;
  }

  final Dio _dio;
  static const _channel = MethodChannel('com.foliate.foliate/updater');

  UpdateService._({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(minutes: 5),
                headers: {
                  'Accept': 'application/vnd.github.v3+json',
                  'User-Agent':
                      'Foliate/1.0.0 (Android; +https://github.com/lk-03/foliate-android)',
                },
              ),
            );

  @visibleForTesting
  UpdateService.withDio(Dio dio) : _dio = dio;

  /// Queries GitHub Releases for the latest version of Foliate.
  Future<AppUpdateInfo?> checkForUpdate({
    String repository = defaultRepository,
    String currentVersion = currentAppVersion,
  }) async {
    if (repository.isEmpty) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/$repository/releases/latest',
      );

      if (response.statusCode == 200 && response.data != null) {
        return AppUpdateInfo.fromGitHubReleaseJson(
          response.data!,
          currentVersion: currentVersion,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error checking for app updates: $e');
      return null;
    }
  }

  /// Downloads the release APK to local temporary cache with live progress callback.
  Future<String> downloadApk({
    required String url,
    void Function(double progress, int receivedBytes, int totalBytes)?
        onProgress,
    CancelToken? cancelToken,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('In-app APK downloading is only supported on Android.');
    }

    final tempDir = await getTemporaryDirectory();
    final savePath = '${tempDir.path}/foliate-update.apk';

    final file = File(savePath);
    if (await file.exists()) {
      await file.delete();
    }

    await _dio.download(
      url,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          final progress = (received / total).clamp(0.0, 1.0);
          onProgress(progress, received, total);
        } else if (onProgress != null) {
          onProgress(0.0, received, total);
        }
      },
    );

    return savePath;
  }

  /// Triggers Android's native package installer sheet via FileProvider.
  Future<bool> installApk(String filePath) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'installApk',
        {'filePath': filePath},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to launch native package installer: ${e.message}');
      return false;
    }
  }
}
