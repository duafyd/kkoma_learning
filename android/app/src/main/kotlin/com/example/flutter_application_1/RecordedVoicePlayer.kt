package com.example.flutter_application_1

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.FileNotFoundException

/** Bundled speech only. A method result completes after playback, never on start. */
class RecordedVoicePlayer(private val context: Context) {
    private val handler = Handler(Looper.getMainLooper())
    private val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val attributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
    private var active = true
    private var released = false
    private data class Pending(
        val token: String, val player: MediaPlayer, val result: MethodChannel.Result,
        var focus: AudioFocusRequest? = null,
        var focusListener: AudioManager.OnAudioFocusChangeListener? = null,
        var timeout: Runnable? = null
    )
    private var pending: Pending? = null

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "stop" -> {
                val token = call.argument<String>("token")
                val current = pending
                if (current != null && (token == null || current.token == token)) finish(current, "cancelled")
                result.success(null)
            }
            "play" -> {
                val id = call.argument<String>("id")
                val token = call.argument<String>("token")
                val bytes = call.argument<Number>("bytes")?.toLong() ?: 0L
                val volume = call.argument<Number>("volume")?.toFloat() ?: 0f
                if (released || !active) { result.success("cancelled"); return }
                if (id == null || !id.startsWith("voice-") || id.any { it in "/\\:*?\"<>|" } ||
                    token.isNullOrEmpty() || !volume.isFinite() || volume <= 0f || volume > 1f || bytes !in 44L..6000000L) {
                    result.success("failed"); return
                }
                pending?.let { finish(it, "cancelled") }
                val player = MediaPlayer()
                val request = Pending(token, player, result)
                pending = request
                try {
                    player.setAudioAttributes(attributes)
                    player.setOnPreparedListener {
                        if (pending !== request || !active || released) return@setOnPreparedListener
                        try {
                            if (!requestFocus(request)) { finish(request, "cancelled"); return@setOnPreparedListener }
                            if (pending !== request) return@setOnPreparedListener
                            player.setVolume(volume, volume)
                            player.start()
                        } catch (_: Exception) { finish(request, "failed") }
                    }
                    player.setOnCompletionListener { finish(request, "completed") }
                    player.setOnErrorListener { _, _, _ -> finish(request, "failed"); true }
                    val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("assets/audio/$id.wav")
                    context.assets.openFd(key).use { descriptor ->
                        if (descriptor.length != bytes) throw IllegalArgumentException("Voice length differs from bundle index")
                        player.setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
                    }
                    request.timeout = Runnable { finish(request, "failed") }
                    handler.postDelayed(request.timeout!!, 65000)
                    player.prepareAsync()
                } catch (_: FileNotFoundException) { finish(request, "missing") }
                catch (_: Exception) { finish(request, "failed") }
            }
            else -> result.notImplemented()
        }
    }

    @Suppress("DEPRECATION")
    private fun requestFocus(request: Pending): Boolean {
        val listener = AudioManager.OnAudioFocusChangeListener { change ->
            if (change != AudioManager.AUDIOFOCUS_GAIN) finish(request, "cancelled")
        }
        request.focusListener = listener
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val focus = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(attributes).setOnAudioFocusChangeListener(listener, handler)
                .setAcceptsDelayedFocusGain(false).build()
            request.focus = focus
            audio.requestAudioFocus(focus) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            audio.requestAudioFocus(listener, AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    @Suppress("DEPRECATION")
    private fun finish(request: Pending, outcome: String) {
        if (pending !== request) return
        pending = null
        request.timeout?.let { handler.removeCallbacks(it) }
        request.player.setOnPreparedListener(null)
        request.player.setOnCompletionListener(null)
        request.player.setOnErrorListener(null)
        request.player.release()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            request.focus?.let { audio.abandonAudioFocusRequest(it) }
        } else {
            request.focusListener?.let { audio.abandonAudioFocus(it) }
        }
        request.result.success(outcome)
    }

    fun setActive(value: Boolean) {
        active = value
        if (!value) pending?.let { finish(it, "cancelled") }
    }
    fun release() {
        if (released) return
        released = true
        pending?.let { finish(it, "cancelled") }
    }
}
