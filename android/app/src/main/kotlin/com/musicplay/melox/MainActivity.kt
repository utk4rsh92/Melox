// android/app/src/main/kotlin/com/musicplay/melox/MainActivity.kt

package com.musicplay.melox

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val channelName = "com.musicplay.melox/equalizer"
    private val equalizerManager = EqualizerManager()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    val sessionId = call.argument<Int>("audioSessionId") ?: 0
                    val success = equalizerManager.init(sessionId)
                    result.success(success)
                }
                "setBandLevel" -> {
                    val band = call.argument<Int>("band") ?: 0
                    val level = call.argument<Int>("level") ?: 0
                    equalizerManager.setBandLevel(band, level)
                    result.success(null)
                }
                "getBandLevel" -> {
                    val band = call.argument<Int>("band") ?: 0
                    result.success(equalizerManager.getBandLevel(band))
                }
                "getNumberOfBands" -> {
                    result.success(equalizerManager.getNumberOfBands())
                }
                "getBandLevelRange" -> {
                    val range = equalizerManager.getBandLevelRange()
                    result.success(listOf(range.first, range.second))
                }
                "getCenterFrequencies" -> {
                    result.success(equalizerManager.getCenterFrequencies())
                }
                "deleteSong" -> {
                    val songId = call.argument<Int>("songId") ?: 0
                    try {
                        val uri = android.net.Uri.withAppendedPath(
                            android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                            songId.toString()
                        )
                        val deleted = contentResolver.delete(uri, null, null)
                        result.success(deleted > 0)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "setEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    equalizerManager.setEnabled(enabled)
                    result.success(null)
                }
                "release" -> {
                    equalizerManager.release()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}