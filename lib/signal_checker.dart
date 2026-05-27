import 'package:flutter/services.dart';

/// Fetches signal strength level (0–4) via platform channel.
class SignalChecker {
  SignalChecker._();
  static final SignalChecker instance = SignalChecker._();

  static const _channel =
      MethodChannel('com.example.textfield_demo/signal');

  /// Returns signal level 0–4, or null if unavailable.
  Future<int?> check() async {
    try {
      final result = await _channel.invokeMethod<int>('getSignalStrength');
      return result;
    } on PlatformException {
      return null;
    }
  }
}
