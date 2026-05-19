package com.example.textfield_demo

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.textfield_demo/bandwidth"
    private val TAG = "BandwidthChecker"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "measureBandwidth" -> {
                        val testUrl = call.argument<String>("testUrl")
                            ?: "https://www.google.com/favicon.ico"
                        val timeoutMs = call.argument<Int>("timeoutMs") ?: 5000

                        Thread {
                            val info = performSpeedTest(testUrl, timeoutMs)
                            try {
                                runOnUiThread { result.success(info) }
                            } catch (e: Throwable) {
                                Log.w(TAG, "Could not deliver result: ${e.message}")
                            }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Throwable) {
                Log.e(TAG, "MethodChannel handler error: ${e.message}")
                result.success(null)
            }
        }
    }

    /**
     * Downloads a small file and measures actual throughput.
     * Every possible failure path returns a safe result map — never throws.
     */
    private fun performSpeedTest(testUrl: String, timeoutMs: Int): Map<String, Any>? {
        // --- Step 1: Check connectivity (wrapped in its own try-catch) ---
        val connectionType: String
        try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            if (cm == null) {
                Log.w(TAG, "ConnectivityManager unavailable")
                return null
            }

            val network = cm.activeNetwork
            val caps = network?.let {
                try {
                    cm.getNetworkCapabilities(it)
                } catch (e: SecurityException) {
                    Log.w(TAG, "Missing ACCESS_NETWORK_STATE permission: ${e.message}")
                    null
                }
            }

            if (network == null || caps == null) {
                return noConnectionResult()
            }

            connectionType = resolveConnectionType(caps)
        } catch (e: Throwable) {
            Log.e(TAG, "Connectivity check failed: ${e.message}")
            // Can't determine connectivity — still attempt download
            return performDownloadOnly(testUrl, timeoutMs, "unknown")
        }

        // --- Step 2: Download probe ---
        return performDownloadOnly(testUrl, timeoutMs, connectionType)
    }

    /**
     * Performs the actual HTTP download and measures speed.
     * Guaranteed to never throw — all exceptions produce a safe result map.
     */
    private fun performDownloadOnly(
        testUrl: String,
        timeoutMs: Int,
        connectionType: String
    ): Map<String, Any>? {
        var conn: HttpURLConnection? = null
        return try {
            val url = URL(testUrl)
            conn = (url.openConnection() as HttpURLConnection).apply {
                connectTimeout = timeoutMs
                readTimeout = timeoutMs
                requestMethod = "GET"
                useCaches = false
                setRequestProperty("Cache-Control", "no-cache, no-store")
            }

            val startNanos = System.nanoTime()
            conn.connect()

            // Reading responseCode triggers the HTTP request and waits for
            // the status line → this is effectively Time-To-First-Byte.
            conn.responseCode
            val ttfbNanos = System.nanoTime()

            // Read entire response body
            val inputStream = conn.inputStream
            var totalBytes = 0L
            val buffer = ByteArray(8192)
            var n: Int
            while (inputStream.read(buffer).also { n = it } != -1) {
                totalBytes += n
            }
            val endNanos = System.nanoTime()

            try { inputStream.close() } catch (_: Throwable) {}

            val totalTimeMs = (endNanos - startNanos) / 1_000_000.0
            val latencyMs = (ttfbNanos - startNanos) / 1_000_000.0

            // speedKbps = (bytes * 8 bits) / timeMs
            // bits / ms == kilo-bits / s
            val speedKbps = if (totalTimeMs > 0) {
                (totalBytes * 8.0) / totalTimeMs
            } else 0.0

            mapOf(
                "isConnected" to true,
                "latencyMs" to latencyMs.toLong(),
                "downloadSpeedKbps" to speedKbps,
                "connectionType" to connectionType,
                "bytesDownloaded" to totalBytes,
                "testDurationMs" to totalTimeMs.toLong()
            )
        } catch (e: Throwable) {
            Log.w(TAG, "Download probe failed: ${e.message}")
            null
        } finally {
            try { conn?.disconnect() } catch (_: Throwable) {}
        }
    }

    private fun resolveConnectionType(caps: NetworkCapabilities): String = try {
        when {
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "vpn"
            else -> "unknown"
        }
    } catch (e: Throwable) {
        "unknown"
    }

    private fun noConnectionResult(): Map<String, Any> = mapOf(
        "isConnected" to false,
        "latencyMs" to -1L,
        "downloadSpeedKbps" to 0.0,
        "connectionType" to "none",
        "bytesDownloaded" to 0L,
        "testDurationMs" to 0L
    )
}
