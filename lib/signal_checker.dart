import 'package:flutter/services.dart';

class SignalInfo {
  final String? connectionType;
  final int signalStrength;

  SignalInfo({required this.connectionType, required this.signalStrength});

  factory SignalInfo.fromMap(Map<dynamic, dynamic> map) {
    return SignalInfo(
      connectionType: map['connectionType'] as String?,
      signalStrength: map['signalStrength'] as int? ?? 0,
    );
  }

  @override
  String toString() => 'SignalInfo(connectionType: $connectionType, signalStrength: $signalStrength)';
}

/// Fetches signal strength level (0–4) and connection type via platform channel.
class SignalChecker {
  SignalChecker._();
  static final SignalChecker instance = SignalChecker._();

  static const _channel =
      MethodChannel('com.example.textfield_demo/signal');

  /// Returns signal level 0–4 and connection type, or null if unavailable.
  Future<SignalInfo?> check() async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getSignalStrength');
      if (result == null) return null;
      return SignalInfo.fromMap(result);
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
