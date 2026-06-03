package com.example.textfield_demo

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : FlutterActivity() {

    private val BANDWIDTH_CHANNEL = "com.example.textfield_demo/bandwidth"
    private val SIGNAL_CHANNEL = "com.example.textfield_demo/signal"
    private val TAG = "NativeChannels"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        setupBandwidthChannel(flutterEngine)
        setupSignalChannel(flutterEngine)
    }

    // ─────────────────────────────────────────────────────────────
    // BANDWIDTH CHANNEL
    // ─────────────────────────────────────────────────────────────

    private fun setupBandwidthChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BANDWIDTH_CHANNEL
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
                Log.e(TAG, "Bandwidth handler error: ${e.message}")
                result.success(null)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // SIGNAL STRENGTH CHANNEL
    // ─────────────────────────────────────────────────────────────

    private fun setupSignalChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SIGNAL_CHANNEL
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getSignalStrength" -> result.success(getNetworkAndSignalInfo())
                    else -> result.notImplemented()
                }
            } catch (e: Throwable) {
                Log.e(TAG, "Signal handler error: ${e.message}")
                result.success(null)
            }
        }
    }

    /**
     * Checks the active network connection type and returns the signal strength level.
     * 1) Checks internet connectivity.
     * 2) If disconnected, returns connectionType=null, signalStrength=0.
     * 3) If WiFi, returns connectionType="wifi", signalStrength=4.
     * 4) If Cellular, targets the active data SIM and returns signalStrength (0..4).
     */
    private fun getNetworkAndSignalInfo(): Map<String, Any?> {
        try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
                ?: return mapOf("connectionType" to null, "signalStrength" to 0)

            val activeNetwork = cm.activeNetwork
            val caps = activeNetwork?.let { cm.getNetworkCapabilities(it) }

            val hasInternet = caps?.let {
                it.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            } ?: false

            if (!hasInternet) {
                return mapOf("connectionType" to null, "signalStrength" to 0)
            }

            if (caps!!.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                return mapOf("connectionType" to "wifi", "signalStrength" to 4)
            }

            if (caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                val tm = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
                    ?: return mapOf("connectionType" to "cellular", "signalStrength" to 0)

                val subId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    SubscriptionManager.getActiveDataSubscriptionId()
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    SubscriptionManager.getDefaultDataSubscriptionId()
                } else {
                    SubscriptionManager.INVALID_SUBSCRIPTION_ID
                }

                val targetedTm = if (subId != SubscriptionManager.INVALID_SUBSCRIPTION_ID && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    tm.createForSubscriptionId(subId)
                } else {
                    tm
                }

                val level = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    try {
                        targetedTm.signalStrength?.level ?: 0
                    } catch (e: SecurityException) {
                        Log.w(TAG, "SecurityException reading signalStrength: ${e.message}")
                        0
                    }
                } else {
                    0
                }

                return mapOf(
                    "connectionType" to "cellular",
                    "signalStrength" to level
                )
            }

            // Fallback for other connections (e.g. Ethernet)
            val type = when {
                caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "vpn"
                else -> "other"
            }
            return mapOf("connectionType" to type, "signalStrength" to 4)

        } catch (e: Throwable) {
            Log.e(TAG, "getNetworkAndSignalInfo failed: ${e.message}")
            return mapOf("connectionType" to null, "signalStrength" to 0)
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
