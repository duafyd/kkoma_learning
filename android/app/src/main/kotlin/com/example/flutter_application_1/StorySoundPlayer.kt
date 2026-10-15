package com.example.flutter_application_1

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.FlutterInjector
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** One short effect at a time; cancelling also clears deferred load playback. */
class StorySoundPlayer(private val context: Context) {
    private val pool = SoundPool.Builder().setMaxStreams(1).setAudioAttributes(
        AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
    ).build()
    private val samples = mutableMapOf<String, Int>()
    private val ready = mutableSetOf<Int>()
    private var stream = 0
    private var released = false
    private var active = true
    private data class Pending(val id: Int, val volume: Float, val result: MethodChannel.Result)
    private var pending: Pending? = null

    init {
        pool.setOnLoadCompleteListener { _, id, status ->
            if (!released) {
                if (status == 0) ready.add(id)
                else samples.entries.removeAll { it.value == id }
                val request = pending
                if (request != null && request.id == id) {
                    pending = null
                    request.result.success(status == 0 && play(id, request.volume))
                }
            }
        }
    }

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "stop" -> { stop(); result.success(null) }
            "play" -> {
                val name = call.argument<String>("sound")
                val volume = (call.argument<Number>("volume")?.toFloat() ?: 0f).coerceIn(0f, 1f)
                if (released || !active || name !in setOf("pageTurn", "friend", "sparkle") || !volume.isFinite()) {
                    result.success(false)
                    return
                }
                stop()
                if (volume == 0f) { result.success(false); return }
                try {
                    val id = samples.getOrPut(name!!) {
                        val key = FlutterInjector.instance().flutterLoader()
                            .getLookupKeyForAsset("assets/audio/effects/$name.wav")
                        context.assets.openFd(key).use { pool.load(it, 1) }
                    }
                    if (id == 0) { result.success(false) }
                    else if (id in ready) { result.success(play(id, volume)) }
                    else { pending = Pending(id, volume, result) }
                } catch (error: Exception) {
                    result.error("effect_unavailable", error.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun play(id: Int, volume: Float): Boolean {
        stream = pool.play(id, volume, volume, 1, 0, 1f)
        return stream != 0
    }

    fun stop() {
        pending?.result?.success(false)
        pending = null
        if (stream != 0) { pool.stop(stream); stream = 0 }
    }

    fun release() {
        if (released) return
        stop()
        released = true
        pool.release()
    }

    fun setActive(value: Boolean) {
        active = value
        if (!value) stop()
    }
}
