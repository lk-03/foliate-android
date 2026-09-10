import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service controlling screen awake lock (FLAG_KEEP_SCREEN_ON).
/// Keeps screen illuminated during long reading sessions when enabled.
/// Safely bypasses on desktop and test environments.
class ScreenAwakeService {
  static const MethodChannel _channel =
      MethodChannel('com.foliate.foliate/storage_permissions');

  static final ScreenAwakeService instance = ScreenAwakeService._();
  ScreenAwakeService._();

  bool _isKeptOn = false;
  bool get isKeptOn => _isKeptOn;

  /// Sets screen keep-on flag.
  Future<bool> setKeepScreenOn(bool enabled) async {
    _isKeptOn = enabled;
    if (kIsWeb || (!kIsWeb && !Platform.isAndroid)) {
      return true;
    }
    try {
      final bool? res = await _channel.invokeMethod<bool>(
        'setKeepScreenOn',
        {'enabled': enabled},
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
