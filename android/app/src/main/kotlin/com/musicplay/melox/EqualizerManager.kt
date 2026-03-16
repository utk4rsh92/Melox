package com.musicplay.melox

import android.media.audiofx.Equalizer
import android.util.Log

class EqualizerManager {
    private var equalizer: Equalizer? = null
    private val tag = "EqualizerManager"

    fun init(audioSessionId: Int): Boolean {
        return try {
            release() // release any existing instance first
            equalizer = Equalizer(0, audioSessionId)
            equalizer?.enabled = true
            Log.d(tag, "Equalizer initialized for session $audioSessionId")
            true
        } catch (e: Exception) {
            Log.e(tag, "Failed to init equalizer: ${e.message}")
            false
        }
    }

    fun setBandLevel(band: Int, levelMillibels: Int) {
        try {
            equalizer?.setBandLevel(band.toShort(), levelMillibels.toShort())
        } catch (e: Exception) {
            Log.e(tag, "Failed to set band $band: ${e.message}")
        }
    }

    fun getBandLevel(band: Int): Int {
        return try {
            equalizer?.getBandLevel(band.toShort())?.toInt() ?: 0
        } catch (e: Exception) { 0 }
    }

    fun getNumberOfBands(): Int {
        return try {
            equalizer?.numberOfBands?.toInt() ?: 5
        } catch (e: Exception) { 5 }
    }

    fun getBandLevelRange(): Pair<Int, Int> {
        return try {
            val range = equalizer?.bandLevelRange
            Pair(
                range?.get(0)?.toInt() ?: -1500,
                range?.get(1)?.toInt() ?: 1500
            )
        } catch (e: Exception) {
            Pair(-1500, 1500)
        }
    }

    fun getCenterFrequencies(): List<Int> {
        return try {
            val bands = equalizer?.numberOfBands?.toInt() ?: 5
            (0 until bands).map { i ->
                (equalizer?.getCenterFreq(i.toShort()) ?: 0) / 1000
            }
        } catch (e: Exception) {
            listOf(60, 230, 910, 4000, 14000)
        }
    }

    fun setEnabled(enabled: Boolean) {
        equalizer?.enabled = enabled
    }

    fun release() {
        try {
            equalizer?.release()
            equalizer = null
        } catch (e: Exception) {
            Log.e(tag, "Failed to release equalizer: ${e.message}")
        }
    }
}