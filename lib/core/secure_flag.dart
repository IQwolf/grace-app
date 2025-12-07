import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lightweight bridge to toggle Android FLAG_SECURE from Dart.
///
/// On non-Android platforms (iOS, web, desktop), calls are no-ops.
class SecureFlag {
  static const MethodChannel _channel = MethodChannel('app.secure');

  static bool get _isAndroid => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android);

  static Future<void> enableSecure() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('enableSecure');
    } catch (e) {
      debugPrint('SecureFlag.enableSecure failed: $e');
    }
  }

  static Future<void> disableSecure() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('disableSecure');
    } catch (e) {
      debugPrint('SecureFlag.disableSecure failed: $e');
    }
  }
}
