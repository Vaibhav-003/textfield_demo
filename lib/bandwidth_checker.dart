import 'package:flutter/services.dart';

/// Quality level of the current network connection.
enum ConnectionQuality { good, moderate, poor, none }

/// Actual measured bandwidth information from a real download probe.
class BandwidthInfo {
  final bool isConnected;

  /// Time-to-first-byte in ms (DNS + TCP + TLS + server processing).
  final int latencyMs;

  /// Actual measured download speed in Kbps.
  final double downloadSpeedKbps;

  /// Transport type: "wifi", "cellular", "ethernet", "vpn", "unknown", "none".
  final String connectionType;

  /// Bytes downloaded during the test.
  final int bytesDownloaded;

  /// Total test duration in ms.
  final int testDurationMs;

  /// Error message if the test failed, null otherwise.
  final String? error;

  const BandwidthInfo({
    required this.isConnected,
    required this.latencyMs,
    required this.downloadSpeedKbps,
    required this.connectionType,
    required this.bytesDownloaded,
    required this.testDurationMs,
    this.error,
  });

  factory BandwidthInfo.fromMap(Map<String, dynamic> map) {
    return BandwidthInfo(
      isConnected: map['isConnected'] as bool? ?? false,
      latencyMs: (map['latencyMs'] as num?)?.toInt() ?? -1,
      downloadSpeedKbps: (map['downloadSpeedKbps'] as num?)?.toDouble() ?? 0.0,
      connectionType: map['connectionType'] as String? ?? 'unknown',
      bytesDownloaded: (map['bytesDownloaded'] as num?)?.toInt() ?? 0,
      testDurationMs: (map['testDurationMs'] as num?)?.toInt() ?? 0,
      error: map['error'] as String?,
    );
  }

  /// Classifies connection quality based on actual measured speed.
  ///
  /// Thresholds (adjustable to your needs):
  /// - good:     >= 2000 Kbps (2 Mbps) and latency < 500ms
  /// - moderate: >= 500 Kbps  and latency < 1000ms
  /// - poor:     connected but below moderate thresholds
  /// - none:     not connected
  ConnectionQuality get quality {
    if (!isConnected) return ConnectionQuality.none;
    if (error != null) return ConnectionQuality.poor;
    if (downloadSpeedKbps >= 2000 && latencyMs < 500) {
      return ConnectionQuality.good;
    }
    if (downloadSpeedKbps >= 500 && latencyMs < 1000) {
      return ConnectionQuality.moderate;
    }
    return ConnectionQuality.poor;
  }

  bool get isGoodEnough =>
      quality == ConnectionQuality.good ||
      quality == ConnectionQuality.moderate;

  @override
  String toString() =>
      'BandwidthInfo(connected: $isConnected, latency: ${latencyMs}ms, '
      'speed: ${downloadSpeedKbps.toStringAsFixed(1)}kbps, '
      'type: $connectionType, quality: ${quality.name}'
      '${error != null ? ', error: $error' : ''})';
}

/// Measures actual internet speed by downloading a small file.
///
/// Uses Android's [HttpURLConnection] under the hood to download a real
/// payload and measure throughput + latency.
///
/// Usage:
/// ```dart
/// final info = await BandwidthChecker.instance.check();
/// if (!info.isGoodEnough) {
///   // Show poor connectivity warning
/// }
///
/// // Or as a quick gate before API calls:
/// if (await BandwidthChecker.instance.isPoorConnectivity()) {
///   showWarning('Slow internet — this may take a while');
/// }
/// ```
class BandwidthChecker {
  BandwidthChecker._();
  static final BandwidthChecker instance = BandwidthChecker._();

  static const _channel =
      MethodChannel('com.example.textfield_demo/bandwidth');

  /// Measures actual bandwidth by downloading a small file.
  ///
  /// Returns [BandwidthInfo] on success, or `null` if the check itself
  /// failed due to an exception (this is NOT the same as no-connection —
  /// a genuine no-connection returns [BandwidthInfo] with `isConnected: false`).
  ///
  /// [testUrl] — URL to download. Defaults to Google's favicon (~5KB).
  ///   For best results, point this at your own API server's health endpoint.
  /// [timeoutMs] — Max time for the entire test. Default: 5000ms.
  Future<BandwidthInfo?> check({
    String? testUrl,
    int timeoutMs = 5000,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'measureBandwidth',
        {
          if (testUrl != null) 'testUrl': testUrl,
          'timeoutMs': timeoutMs,
        },
      );

      // null means an exception occurred on the native side —
      // we can't determine connectivity, so return null.
      if (result == null) return null;
      return BandwidthInfo.fromMap(result);
    } on PlatformException {
      return null;
    }
  }

  /// Returns `true` if connectivity is poor or absent.
  /// Returns `false` if the check itself failed (benefit of the doubt).
  Future<bool> isPoorConnectivity({String? testUrl}) async {
    final info = await check(testUrl: testUrl);
    if (info == null) return false; // check failed, don't block the user
    return !info.isGoodEnough;
  }
}
